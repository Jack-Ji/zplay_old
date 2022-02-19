const std = @import("std");
const zp = @import("zplay");
const dig = zp.deps.dig;
const alg = zp.deps.alg;
const Vec3 = alg.Vec3;
const Vec4 = alg.Vec4;
const Mat4 = alg.Mat4;
const gfx = zp.graphics;
const Framebuffer = gfx.gpu.Framebuffer;
const Texture = gfx.gpu.Texture;
const Renderer = gfx.Renderer;
const Mesh = gfx.Mesh;
const Material = gfx.Material;
const Camera = gfx.Camera;
const SimpleRenderer = gfx.@"3d".SimpleRenderer;
const TextureDisplay = gfx.post_processing.TextureDisplay;
const Skybox = gfx.@"3d".Skybox;

var scene_renderer: SimpleRenderer = undefined;
var screen_renderer: TextureDisplay = undefined;
var skybox: Skybox = undefined;
var skybox_material: Material = undefined;
var transform_array: *Renderer.InstanceTransformArray = undefined;
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
var scene_render_data: Renderer.Input = undefined;

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
    ctx.graphics.getDrawableSize(ctx.window, &width, &height);
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
    transform_array = try Renderer.InstanceTransformArray.init(std.testing.allocator);
    var vertex_data = cube.getVertexData(&cube_material, Renderer.LocalTransform{ .instanced = transform_array });
    scene_render_data = try Renderer.Input.init(
        std.testing.allocator,
        &ctx.graphics,
        &.{vertex_data},
        projection,
        &camera,
        &color_material,
        null,
    );
    vertex_data = quad.getVertexData(&fb_material, null);

    // toggle graphics caps
    ctx.graphics.toggleCapability(.multisample, enable_msaa);
}

fn loop(ctx: *zp.Context) void {
    const S = struct {
        var frame1: f32 = 0;
        var frame2: f32 = 0;
    };
    if (rotate_cubes) S.frame1 += 1;
    if (rotate_scene) S.frame2 += 1;

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

    var width: u32 = undefined;
    var height: u32 = undefined;
    ctx.graphics.getDrawableSize(ctx.window, &width, &height);

    // render to custom framebuffer
    Framebuffer.use(if (enable_msaa) fb_msaa else fb);
    {
        ctx.graphics.toggleCapability(.depth_test, true);
        ctx.graphics.clear(true, true, true, [4]f32{ 0.2, 0.3, 0.3, 1.0 });

        // draw boxes
        ctx.graphics.setPolygonMode(if (wireframe_mode) .line else .fill);
        renderBoxes(ctx, S.frame1);

        // draw skybox
        skybox.draw(.{
            .ctx = &ctx.graphics,
            .projection = scene_render_data.projection,
            .camera = &camera,
            .material = &skybox_material,
        }) catch unreachable;
    }

    // final draw
    Framebuffer.use(null);
    {
        // copy pixels
        if (enable_msaa) {
            Framebuffer.blitData(fb_msaa, fb);
        }

        ctx.graphics.clear(true, false, false, [4]f32{ 0.3, 0.2, 0.3, 1.0 });
        var transform = Mat4.fromRotation(S.frame2, Vec3.forward());
        screen_renderer.draw(.{
            .ctx = &ctx.graphics,
            .material = &fb_material,
            .custom = &transform,
        }) catch unreachable;
    }

    // settings
    dig.beginFrame();
    {
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
            _ = dig.checkbox("wireframe", &wireframe_mode);
            if (dig.checkbox("outlined", &outlined)) {
                ctx.graphics.toggleCapability(.stencil_test, outlined);
            }
            _ = dig.checkbox("rotate cubes", &rotate_cubes);
            _ = dig.checkbox("rotate scene", &rotate_scene);
            _ = dig.checkbox("msaa", &enable_msaa);
        }
        dig.end();
    }
    dig.endFrame();
}

fn renderBoxes(ctx: *zp.Context, frame: f32) void {
    // draw cubes
    if (outlined) {
        ctx.graphics.setStencilOption(.{
            .test_func = .always,
            .test_ref = 1,
            .action_dppass = .replace,
        });
    }
    for (cube_positions) |pos, i| {
        cube_transforms[i] = Mat4.fromRotation(
            20 * @intToFloat(f32, i) + frame,
            Vec3.new(1, 0.3, 0.5),
        ).translate(pos);
    }
    transform_array.updateTransforms(&cube_transforms) catch unreachable;
    scene_renderer.draw(scene_render_data) catch unreachable;

    // outline cubes
    // draw scaled up cubes, using single color
    if (outlined) {
        ctx.graphics.setStencilOption(.{
            .test_func = .not_equal,
            .test_ref = 1,
        });
        for (cube_transforms) |*tr| {
            tr.* = tr.mult(Mat4.fromScale(Vec3.set(1.01)));
        }
        transform_array.updateTransforms(&cube_transforms) catch unreachable;
        scene_render_data.vds.?.items[0].material = null;
        defer scene_render_data.vds.?.items[0].material = &cube_material;
        scene_renderer.draw(scene_render_data) catch unreachable;
    }
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
