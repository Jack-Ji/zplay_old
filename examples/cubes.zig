const std = @import("std");
const zp = @import("zplay");
const dig = zp.deps.dig;
const alg = zp.deps.alg;
const Vec3 = alg.Vec3;
const Vec4 = alg.Vec4;
const Mat4 = alg.Mat4;
const gfx = zp.graphics;
const GraphicsContext = gfx.gpu.Context;
const Framebuffer = gfx.gpu.Framebuffer;
const Texture = gfx.gpu.Texture;
const Renderer = gfx.Renderer;
const Mesh = gfx.Mesh;
const render_pass = gfx.render_pass;
const Material = gfx.Material;
const Camera = gfx.Camera;
const SimpleRenderer = gfx.@"3d".SimpleRenderer;
const TextureDisplay = gfx.post_processing.TextureDisplay;
const Skybox = gfx.@"3d".Skybox;

var scene_renderer: SimpleRenderer = undefined;
var screen_renderer: TextureDisplay = undefined;
var skybox: Skybox = undefined;
var skybox_material: Material = undefined;
var fb: Framebuffer = undefined;
var fb_msaa: Framebuffer = undefined;
var cube: Mesh = undefined;
var quad: Mesh = undefined;
var cube_material: Material = undefined;
var color_material: Material = undefined;
var fb_material: Material = undefined;
var wireframe_mode = false;
var outlined = false;
var rotate_cubes = false;
var rotate_scene = false;
var enable_msaa = true;
var camera = Camera.fromPositionAndTarget(
    Vec3.new(0, 0, 3),
    Vec3.zero(),
    null,
);
var frame1: f32 = 0;
var frame2: f32 = 0;
var cubes_transform_array: *Renderer.InstanceTransformArray = undefined;
var screen_transform: Mat4 = undefined;
var render_data_scene: Renderer.Input = undefined;
var render_data_skybox: Renderer.Input = undefined;
var render_data_screen: Renderer.Input = undefined;
var render_pipeline: render_pass.Pipeline = undefined;
var render_pipeline_outlined: render_pass.Pipeline = undefined;

const cube_positions = [_]Vec3{
    Vec3.new(0.0, 0.0, 0.0),
    Vec3.new(2.0, 5.0, -15.0),
    Vec3.new(-1.5, -2.2, -2.5),
    Vec3.new(-3.8, -2.0, -12.3),
    Vec3.new(2.4, -0.4, -3.5),
    Vec3.new(-1.7, 3.0, -7.5),
    Vec3.new(1.3, -2.0, -2.5),
    Vec3.new(1.5, 2.0, -2.5),
    Vec3.new(1.5, 0.2, -1.5),
    Vec3.new(-1.3, 1.0, -1.5),
};
var cube_transforms: [cube_positions.len]Mat4 = undefined;

fn init(ctx: *zp.Context) anyerror!void {
    std.log.info("game init", .{});

    // init imgui
    try dig.init(ctx.window);

    // allocate skybox
    skybox = Skybox.init(std.testing.allocator);

    // allocate framebuffer stuff
    var width: u32 = undefined;
    var height: u32 = undefined;
    ctx.graphics.getDrawableSize(&width, &height);
    fb = try Framebuffer.init(
        std.testing.allocator,
        width,
        height,
        .{},
    );
    fb_msaa = try Framebuffer.init(
        std.testing.allocator,
        width,
        height,
        .{
            .multisamples = 4,
            .compose_depth_stencil = false,
        },
    );

    // simple renderer
    scene_renderer = SimpleRenderer.init(.{});
    screen_renderer = try TextureDisplay.init(std.testing.allocator);

    // init meshes
    cube = try Mesh.genCube(std.testing.allocator, 1, 1, 1);
    quad = try Mesh.genQuad(std.testing.allocator, 2, 2);

    // init materials
    skybox_material = Material.init(.{
        .single_cubemap = try Texture.initCubeFromFilePaths(
            std.testing.allocator,
            "assets/skybox/right.jpg",
            "assets/skybox/left.jpg",
            "assets/skybox/top.jpg",
            "assets/skybox/bottom.jpg",
            "assets/skybox/front.jpg",
            "assets/skybox/back.jpg",
            false,
        ),
    }, true);
    cube_material = Material.init(.{
        .single_texture = try Texture.init2DFromFilePath(
            std.testing.allocator,
            "assets/wall.jpg",
            false,
            .{},
        ),
    }, true);
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
    fb_material = Material.init(.{ .single_texture = fb.tex.? }, false);

    // alloc texture unit
    var unit = cube_material.allocTextureUnit(0);
    unit = skybox_material.allocTextureUnit(unit);
    unit = color_material.allocTextureUnit(unit);
    _ = fb_material.allocTextureUnit(unit);

    // compose renderer's input
    const projection = Mat4.perspective(
        45,
        @intToFloat(f32, width) / @intToFloat(f32, height),
        0.1,
        100,
    );
    cubes_transform_array = try Renderer.InstanceTransformArray.init(std.testing.allocator);
    var vertex_data = cube.getVertexData(
        &cube_material,
        Renderer.LocalTransform{ .instanced = cubes_transform_array },
    );
    render_data_scene = try Renderer.Input.init(
        std.testing.allocator,
        &ctx.graphics,
        &.{vertex_data},
        projection,
        &camera,
        null,
        null,
    );
    render_data_skybox = .{
        .ctx = &ctx.graphics,
        .projection = projection,
        .camera = &camera,
        .material = &skybox_material,
    };
    render_data_screen = .{
        .ctx = &ctx.graphics,
        .material = &fb_material,
        .custom = &screen_transform,
    };

    // compose render pipeline
    render_pipeline = try render_pass.Pipeline.init(
        std.testing.allocator,
        &[_]render_pass.RenderPass{
            .{
                .fb = if (enable_msaa) fb_msaa else fb,
                .beforeFn = beforeSceneRendering,
                .rd = scene_renderer.renderer(),
                .data = &render_data_scene,
            },
            .{
                .fb = if (enable_msaa) fb_msaa else fb,
                .rd = skybox.renderer(),
                .data = &render_data_skybox,
            },
            .{
                .beforeFn = beforeScreenRendering,
                .rd = screen_renderer.renderer(),
                .data = &render_data_screen,
            },
        },
    );
    render_pipeline_outlined = try render_pass.Pipeline.init(
        std.testing.allocator,
        &[_]render_pass.RenderPass{
            .{
                .fb = if (enable_msaa) fb_msaa else fb,
                .beforeFn = beforeSceneRenderingOutlined1,
                .rd = scene_renderer.renderer(),
                .data = &render_data_scene,
            },
            .{
                .fb = if (enable_msaa) fb_msaa else fb,
                .beforeFn = beforeSceneRenderingOutlined2,
                .afterFn = afterSceneRenderingOutlined2,
                .rd = scene_renderer.renderer(),
                .data = &render_data_scene,
            },
            .{
                .fb = if (enable_msaa) fb_msaa else fb,
                .rd = skybox.renderer(),
                .data = &render_data_skybox,
            },
            .{
                .beforeFn = beforeScreenRendering,
                .rd = screen_renderer.renderer(),
                .data = &render_data_screen,
            },
        },
    );

    // toggle graphics caps
    ctx.graphics.toggleCapability(.multisample, enable_msaa);
    ctx.graphics.toggleCapability(.depth_test, true);
}

fn beforeSceneRendering(ctx: *GraphicsContext, custom: ?*anyopaque) void {
    _ = custom;
    for (cube_positions) |pos, i| {
        cube_transforms[i] = Mat4.fromRotation(
            20 * @intToFloat(f32, i) + frame1,
            Vec3.new(1, 0.3, 0.5),
        ).translate(pos);
    }
    cubes_transform_array.updateTransforms(&cube_transforms) catch unreachable;
    ctx.clear(true, true, true, [4]f32{ 0.2, 0.3, 0.3, 1.0 });
}

fn beforeSceneRenderingOutlined1(ctx: *GraphicsContext, custom: ?*anyopaque) void {
    _ = custom;
    ctx.setStencilOption(.{
        .test_func = .always,
        .test_ref = 1,
        .action_dppass = .replace,
    });
    for (cube_positions) |pos, i| {
        cube_transforms[i] = Mat4.fromRotation(
            20 * @intToFloat(f32, i) + frame1,
            Vec3.new(1, 0.3, 0.5),
        ).translate(pos);
    }
    cubes_transform_array.updateTransforms(&cube_transforms) catch unreachable;
    ctx.clear(true, true, true, [4]f32{ 0.2, 0.3, 0.3, 1.0 });
}

fn beforeSceneRenderingOutlined2(ctx: *GraphicsContext, custom: ?*anyopaque) void {
    _ = custom;
    ctx.setStencilOption(.{
        .test_func = .not_equal,
        .test_ref = 1,
    });
    for (cube_transforms) |*tr| {
        tr.* = tr.mul(Mat4.fromScale(Vec3.set(1.01)));
    }
    cubes_transform_array.updateTransforms(&cube_transforms) catch unreachable;
    render_data_scene.vds.?.items[0].material = &color_material;
}

fn afterSceneRenderingOutlined2(ctx: *GraphicsContext, custom: ?*anyopaque) void {
    _ = ctx;
    _ = custom;
    render_data_scene.vds.?.items[0].material = &cube_material;
}

fn beforeScreenRendering(ctx: *GraphicsContext, custom: ?*anyopaque) void {
    _ = custom;
    if (enable_msaa) {
        Framebuffer.blitData(fb_msaa, fb);
    }
    screen_transform = Mat4.fromRotation(frame2, Vec3.forward());
    ctx.clear(true, false, false, [4]f32{ 0.3, 0.2, 0.3, 1.0 });
}

fn loop(ctx: *zp.Context) void {
    if (rotate_cubes) frame1 += 1;
    if (rotate_scene) frame2 += 1;

    // camera movement
    const distance = ctx.delta_tick * camera.move_speed;
    if (ctx.isKeyPressed(.w)) {
        camera.move(.forward, distance);
    }
    if (ctx.isKeyPressed(.s)) {
        camera.move(.backward, distance);
    }
    if (ctx.isKeyPressed(.a)) {
        camera.move(.left, distance);
    }
    if (ctx.isKeyPressed(.d)) {
        camera.move(.right, distance);
    }
    if (ctx.isKeyPressed(.left)) {
        camera.rotate(0, -1);
    }
    if (ctx.isKeyPressed(.right)) {
        camera.rotate(0, 1);
    }
    if (ctx.isKeyPressed(.up)) {
        camera.rotate(1, 0);
    }
    if (ctx.isKeyPressed(.down)) {
        camera.rotate(-1, 0);
    }

    while (ctx.pollEvent()) |e| {
        _ = dig.processEvent(e);
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
                        .f1 => ctx.toggleFullscreeen(null),
                        else => {},
                    }
                }
            },
            .quit_event => ctx.kill(),
            else => {},
        }
    }

    // render the scene
    if (outlined) {
        render_pipeline_outlined.run() catch unreachable;
    } else {
        render_pipeline.run() catch unreachable;
    }

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
            dig.c.ImGuiWindowFlags_NoMove |
                dig.c.ImGuiWindowFlags_NoResize |
                dig.c.ImGuiWindowFlags_AlwaysAutoResize,
        )) {
            if (dig.checkbox("wireframe", &wireframe_mode)) {
                ctx.graphics.setPolygonMode(if (wireframe_mode) .line else .fill);
            }
            if (dig.checkbox("outlined", &outlined)) {
                ctx.graphics.toggleCapability(.stencil_test, outlined);
            }
            _ = dig.checkbox("rotate cubes", &rotate_cubes);
            _ = dig.checkbox("rotate scene", &rotate_scene);
            if (dig.checkbox("msaa", &enable_msaa)) {
                render_pipeline.passes.items[0].fb = if (enable_msaa) fb_msaa else fb;
                render_pipeline.passes.items[1].fb = if (enable_msaa) fb_msaa else fb;
                render_pipeline_outlined.passes.items[0].fb = if (enable_msaa) fb_msaa else fb;
                render_pipeline_outlined.passes.items[1].fb = if (enable_msaa) fb_msaa else fb;
                render_pipeline_outlined.passes.items[2].fb = if (enable_msaa) fb_msaa else fb;
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
        .enable_msaa = true,
    });
}
