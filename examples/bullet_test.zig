const std = @import("std");
const math = std.math;
const assert = std.debug.assert;
const zp = @import("zplay");
const dig = zp.deps.dig;
const alg = zp.deps.alg;
const bt = zp.deps.bt;
const Vec3 = alg.Vec3;
const Vec4 = alg.Vec4;
const Mat4 = alg.Mat4;
const gfx = zp.graphics;
const Context = gfx.gpu.Context;
const Framebuffer = gfx.gpu.Framebuffer;
const Texture = gfx.gpu.Texture;
const Renderer = gfx.Renderer;
const render_pass = gfx.render_pass;
const Material = gfx.Material;
const Camera = gfx.Camera;
const SimpleRenderer = gfx.SimpleRenderer;
const PhongRenderer = gfx.@"3d".PhongRenderer;
const light = gfx.@"3d".light;
const Model = gfx.@"3d".Model;
const BulletWorld = zp.physics.BulletWorld;

var app_context: *zp.Context = undefined;
var shadow_fb: Framebuffer = undefined;
var shadow_map_renderer: SimpleRenderer = undefined;
var simple_renderer: SimpleRenderer = undefined;
var phong_renderer: PhongRenderer = undefined;
var color_material: Material = undefined;
var wireframe_mode = false;
var light_view_camera: Camera = undefined;
var person_view_camera: Camera = undefined;
var physics_world: BulletWorld = undefined;
const Actor = struct {
    model: *Model,
    physics_id: u32,
};
var all_actors: std.ArrayList(Actor) = undefined;
var render_data_shadow: Renderer.Input = undefined;
var render_data_scene: Renderer.Input = undefined;
var render_data_outlined: Renderer.Input = undefined;
var render_pipeline: render_pass.Pipeline = undefined;

const shadow_width = 2048;
const shadow_height = 2048;

fn init(ctx: *zp.Context) anyerror!void {
    std.log.info("game init", .{});
    app_context = ctx;

    // init imgui
    try dig.init(ctx.window);

    // allocate framebuffer stuff
    var width: u32 = undefined;
    var height: u32 = undefined;
    ctx.graphics.getDrawableSize(&width, &height);
    shadow_fb = try Framebuffer.initForShadowMapping(
        std.testing.allocator,
        shadow_width,
        shadow_height,
    );

    // create renderer
    var light_pos = Vec3.new(0, 30, 0);
    var light_dir = Vec3.new(0.1, -1, 0);
    light_view_camera = Camera.fromPositionAndTarget(
        .{
            .orthographic = .{
                .left = -50,
                .right = 50,
                .bottom = -50,
                .top = 50,
                .near = 0.1,
                .far = 100,
            },
        },
        light_pos,
        light_pos.add(light_dir),
        null,
    );
    person_view_camera = Camera.fromPositionAndTarget(
        .{
            .perspective = .{
                .fov = 45,
                .aspect_ratio = @intToFloat(f32, width) / @intToFloat(f32, height),
                .near = 0.1,
                .far = 100,
            },
        },
        Vec3.new(5, 10, 25),
        Vec3.new(-4, 8, 0),
        null,
    );
    shadow_map_renderer = SimpleRenderer.init(.{ .no_draw = true });
    simple_renderer = SimpleRenderer.init(.{});
    phong_renderer = PhongRenderer.init(.{ .has_shadow = true });
    phong_renderer.applyLights(&[_]light.Light{
        .{
            .directional = .{
                .ambient = Vec3.new(0.8, 0.8, 0.8),
                .diffuse = Vec3.new(0.5, 0.5, 0.3),
                .specular = Vec3.new(0.1, 0.1, 0.1),
                .direction = light_dir,
                .space_matrix = light_view_camera.getViewProjectMatrix(),
            },
        },
    });

    // init physics world
    physics_world = try BulletWorld.init(std.testing.allocator, -9.8);
    try physics_world.enableDebugDraw(std.testing.allocator);
    all_actors = try std.ArrayList(Actor).initCapacity(std.testing.allocator, 6);
    addActor(
        Vec3.zero(),
        try Model.fromGLTF(
            std.testing.allocator,
            "assets/world.gltf",
            false,
            try Texture.init2DFromPixels(
                std.testing.allocator,
                &.{ 128, 128, 128 },
                .rgb,
                1,
                1,
                .{},
            ),
        ),
        null,
        .{ .friction = 0.15 },
    );
    addActor(
        Vec3.new(-5, 15, -2),
        try Model.fromGLTF(
            std.testing.allocator,
            "assets/capsule.gltf",
            false,
            null,
        ),
        blk: {
            var shape = bt.shapeAllocate(bt.c.CBT_SHAPE_TYPE_CAPSULE);
            bt.shapeCapsuleCreate(shape, 1, 2, bt.c.CBT_LINEAR_AXIS_Y);
            break :blk shape;
        },
        .{ .mass = 10 },
    );
    addActor(
        Vec3.new(-5, 11, -2),
        try Model.fromGLTF(
            std.testing.allocator,
            "assets/cylinder.gltf",
            false,
            null,
        ),
        blk: {
            var shape = bt.shapeAllocate(bt.c.CBT_SHAPE_TYPE_CYLINDER);
            bt.shapeCylinderCreate(
                shape,
                &Vec3.new(1.5, 2.0, 1.5).toArray(),
                bt.c.CBT_LINEAR_AXIS_Y,
            );
            break :blk shape;
        },
        .{ .mass = 10 },
    );
    addActor(
        Vec3.new(-5, 8, -2),
        try Model.fromGLTF(
            std.testing.allocator,
            "assets/cube.gltf",
            false,
            null,
        ),
        blk: {
            var shape = bt.shapeAllocate(bt.c.CBT_SHAPE_TYPE_BOX);
            bt.shapeBoxCreate(shape, &Vec3.new(0.5, 1.0, 2.0).toArray());
            break :blk shape;
        },
        .{ .mass = 10 },
    );
    addActor(
        Vec3.new(-5, 6, -2),
        try Model.fromGLTF(
            std.testing.allocator,
            "assets/cone.gltf",
            false,
            null,
        ),
        blk: {
            var shape = bt.shapeAllocate(bt.c.CBT_SHAPE_TYPE_CONE);
            bt.shapeConeCreate(shape, 1.0, 2.0, bt.c.CBT_LINEAR_AXIS_Y);
            break :blk shape;
        },
        .{ .mass = 10 },
    );
    addActor(
        Vec3.new(-5, 3.5, -2),
        try Model.fromGLTF(
            std.testing.allocator,
            "assets/sphere.gltf",
            false,
            null,
        ),
        blk: {
            var shape = bt.shapeAllocate(bt.c.CBT_SHAPE_TYPE_SPHERE);
            bt.shapeSphereCreate(shape, 1.5);
            break :blk shape;
        },
        .{ .mass = 10 },
    );

    // init render data annd pipeline
    color_material = Material.init(.{
        .single_texture = try Texture.init2DFromPixels(
            std.testing.allocator,
            &.{ 0, 255, 0 },
            .rgb,
            1,
            1,
            .{},
        ),
    }, true);
    render_data_shadow = try Renderer.Input.init(
        std.testing.allocator,
        &.{},
        &light_view_camera,
        null,
        null,
    );
    render_data_scene = try Renderer.Input.init(
        std.testing.allocator,
        &.{},
        &person_view_camera,
        null,
        null,
    );
    render_data_outlined = try Renderer.Input.init(
        std.testing.allocator,
        &.{},
        &person_view_camera,
        null,
        null,
    );
    for (all_actors.items) |a| {
        try a.model.appendVertexData(
            &render_data_shadow,
            physics_world.getTransformation(a.physics_id),
            null,
        );
        try a.model.appendVertexData(
            &render_data_scene,
            physics_world.getTransformation(a.physics_id),
            null,
        );
        render_data_scene.vds.?.items[
            render_data_scene.vds.?.items.len - 1
        ].material.?.data.phong.shadow_map = shadow_fb.depth_stencil.?.tex;
    }
    render_pipeline = try render_pass.Pipeline.init(
        std.testing.allocator,
        &[_]render_pass.RenderPass{
            .{
                .fb = shadow_fb,
                .beforeFn = beforeShadowMapGeneration,
                .rd = shadow_map_renderer.renderer(),
                .data = &render_data_shadow,
            },
            .{
                .beforeFn = beforeRenderingScene,
                .rd = phong_renderer.renderer(),
                .data = &render_data_scene,
            },
            .{
                .beforeFn = beforeRenderingOutlined,
                .rd = simple_renderer.renderer(),
                .data = &render_data_outlined,
            },
        },
    );

    // graphics init
    ctx.graphics.toggleCapability(.depth_test, true);
    ctx.graphics.toggleCapability(.stencil_test, true);
    ctx.graphics.toggleCapability(.multisample, true);
}

fn beforeShadowMapGeneration(ctx: *Context, custom: ?*anyopaque) void {
    _ = custom;
    ctx.setViewport(0, 0, shadow_width, shadow_height);
    ctx.clear(false, true, false, null);
}

fn beforeRenderingScene(ctx: *Context, custom: ?*anyopaque) void {
    _ = custom;
    var width: u32 = undefined;
    var height: u32 = undefined;
    ctx.getDrawableSize(&width, &height);
    ctx.setViewport(0, 0, width, height);
    ctx.clear(true, true, true, [_]f32{ 0.2, 0.3, 0.3, 1.0 });
    ctx.setStencilOption(.{
        .test_func = .always,
        .test_ref = 1,
        .action_dppass = .replace,
    });
}

fn beforeRenderingOutlined(ctx: *Context, custom: ?*anyopaque) void {
    _ = custom;
    var width: u32 = undefined;
    var height: u32 = undefined;
    ctx.getDrawableSize(&width, &height);
    const mouse_state = app_context.getMouseState();
    var result = physics_world.getRayTestResult(
        person_view_camera.position,
        person_view_camera.getRayTestTarget(
            width,
            height,
            @intCast(u32, mouse_state.x),
            @intCast(u32, mouse_state.y),
        ),
    );

    // only draw selected object, scaled up
    render_data_outlined.vds.?.clearRetainingCapacity();
    if (result) |id| {
        if (id != 0) {
            all_actors.items[id].model.appendVertexData(
                &render_data_outlined,
                physics_world.getTransformation(id)
                    .mul(Mat4.fromScale(Vec3.set(1.05))),
                &color_material,
            ) catch unreachable;
        }
    }

    ctx.setStencilOption(.{
        .test_func = .not_equal,
        .test_ref = 1,
    });
}

fn addActor(
    pos: Vec3,
    model: *Model,
    shape: ?bt.Shape,
    phy: BulletWorld.PhysicsParam,
) void {
    all_actors.append(.{
        .model = model,
        .physics_id = physics_world.addObjectWithModel(
            std.testing.allocator,
            pos,
            model,
            shape,
            phy,
        ) catch unreachable,
    }) catch unreachable;
}

fn loop(ctx: *zp.Context) void {
    // person_view_camera movement
    const distance = ctx.delta_tick * person_view_camera.move_speed;
    if (ctx.isKeyPressed(.w)) {
        person_view_camera.move(.forward, distance);
    }
    if (ctx.isKeyPressed(.s)) {
        person_view_camera.move(.backward, distance);
    }
    if (ctx.isKeyPressed(.a)) {
        person_view_camera.move(.left, distance);
    }
    if (ctx.isKeyPressed(.d)) {
        person_view_camera.move(.right, distance);
    }
    if (ctx.isKeyPressed(.left)) {
        person_view_camera.rotate(0, -1);
    }
    if (ctx.isKeyPressed(.right)) {
        person_view_camera.rotate(0, 1);
    }
    if (ctx.isKeyPressed(.up)) {
        person_view_camera.rotate(1, 0);
    }
    if (ctx.isKeyPressed(.down)) {
        person_view_camera.rotate(-1, 0);
    }

    while (ctx.pollEvent()) |e| {
        switch (e) {
            .window_event => |we| {
                switch (we.data) {
                    .resized => |size| {
                        ctx.graphics.setViewport(0, 0, size.width, size.height);
                    },
                    else => {},
                }
            },
            .keyboard_event => |key| {
                if (key.trigger_type == .up) {
                    switch (key.scan_code) {
                        .escape => ctx.kill(),
                        else => {},
                    }
                }
            },
            .quit_event => ctx.kill(),
            else => {},
        }
    }

    // update physics world's status
    physics_world.update(.{ .delta_time = ctx.delta_tick });
    var idx: u32 = 0;
    for (all_actors.items) |a| {
        var j: u32 = idx;
        const end = idx + @intCast(u32, a.model.meshes.items.len);
        while (j < end) : (j += 1) {
            render_data_shadow.vds.?.items[j].transform = .{
                .single = physics_world.getTransformation(a.physics_id)
                    .mul(a.model.transforms.items[j - idx]),
            };
            render_data_scene.vds.?.items[j].transform = .{
                .single = physics_world.getTransformation(a.physics_id)
                    .mul(a.model.transforms.items[j - idx]),
            };
        }
        idx = end;
    }

    // render the scene
    render_pipeline.run(&ctx.graphics) catch unreachable;
    physics_world.debugDraw(
        &ctx.graphics,
        &person_view_camera,
        3,
    );

    // settings
    dig.beginFrame();
    {
        var width: u32 = undefined;
        var height: u32 = undefined;
        ctx.graphics.getDrawableSize(&width, &height);
        dig.setNextWindowPos(
            .{ .x = @intToFloat(f32, width) - 10, .y = 50 },
            .{
                .cond = dig.c.ImGuiCond_Always,
                .pivot = .{ .x = 1, .y = 0 },
            },
        );
        if (dig.begin(
            "settings",
            null,
            dig.c.ImGuiWindowFlags_NoResize |
                dig.c.ImGuiWindowFlags_AlwaysAutoResize,
        )) {
            if (dig.checkbox("wireframe", &wireframe_mode)) {
                ctx.graphics.setPolygonMode(if (wireframe_mode) .line else .fill);
            }
        }
        dig.end();
    }
    dig.endFrame();
}

fn quit(ctx: *zp.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
}

pub fn main() anyerror!void {
    try zp.run(.{
        .initFn = init,
        .loopFn = loop,
        .quitFn = quit,
        .width = 1600,
        .height = 900,
        .enable_msaa = true,
    });
}
