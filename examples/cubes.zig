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
const RenderPipeline = gfx.RenderPipeline;
const Material = gfx.Material;
const TextureDisplay = gfx.post_processing.TextureDisplay;
const SimpleRenderer = gfx.@"3d".SimpleRenderer;
const SkyboxRenderer = gfx.@"3d".SkyboxRenderer;
const Mesh = gfx.@"3d".Mesh;
const Model = gfx.@"3d".Model;
const Scene = gfx.@"3d".Scene;

var scene_renderer: SimpleRenderer = undefined;
var screen_renderer: TextureDisplay = undefined;
var skybox: SkyboxRenderer = undefined;
var skybox_material: Material = undefined;
var fb: Framebuffer = undefined;
var cube: *Model = undefined;
var fb_material: Material = undefined;
var render_data_skybox: Renderer.Input = undefined;
var render_data_screen: Renderer.Input = undefined;
var scene: *Scene = undefined;
var wireframe_mode = false;
var rotate_cubes = false;
var rotate_scene = false;
var frame1: f32 = 0;
var frame2: f32 = 0;
var screen_transform: Mat4 = undefined;

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
    skybox = SkyboxRenderer.init(std.testing.allocator);

    // allocate framebuffer stuff
    const size = ctx.graphics.getDrawableSize();
    fb = try Framebuffer.init(
        std.testing.allocator,
        size.w,
        size.h,
        .{},
    );

    // simple renderer
    scene_renderer = SimpleRenderer.init(.{});
    screen_renderer = try TextureDisplay.init(std.testing.allocator);

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
    });
    fb_material = Material.init(.{ .single_texture = fb.tex.? });

    // init model
    var material = Material.init(.{
        .single_texture = try Texture.init2DFromFilePath(
            std.testing.allocator,
            "assets/wall.jpg",
            false,
            .{},
        ),
    });
    cube = try Model.init(
        std.testing.allocator,
        try Mesh.genCube(std.testing.allocator, 1, 1, 1),
        Mat4.identity(),
        material,
        &.{material.data.single_texture},
    );

    // init scene
    scene = try Scene.init(std.testing.allocator, .{
        .viewer_frustrum = .{
            .perspective = .{
                .fov = 45,
                .aspect_ratio = ctx.graphics.viewport.getAspectRatio(),
                .near = 0.1,
                .far = 100,
            },
        },
        .viewer_position = Vec3.new(0, 0, 3),
    });
    for (cube_positions) |pos, i| {
        cube_transforms[i] = Mat4.fromRotation(
            20 * @intToFloat(f32, i),
            Vec3.new(1, 0.3, 0.5),
        ).translate(pos);
    }
    try scene.addModel(cube, &cube_transforms, null, false);
    render_data_skybox = .{
        .camera = &scene.viewer_camera,
        .material = &skybox_material,
    };
    render_data_screen = .{
        .material = &fb_material,
        .custom = &screen_transform,
    };
    try scene.setRenderPasses(&[_]Scene.RenderPassOption{
        .{
            .fb = fb,
            .beforeFn = beforeSceneRendering,
            .rd = scene_renderer.renderer(),
            .rdata = &scene.rdata_scene,
        },
        .{
            .fb = fb,
            .rd = skybox.renderer(),
            .rdata = &render_data_skybox,
        },
        .{
            .beforeFn = beforeScreenRendering,
            .rd = screen_renderer.renderer(),
            .rdata = &render_data_screen,
        },
    });
}

fn beforeSceneRendering(ctx: *GraphicsContext, custom: ?*anyopaque) void {
    _ = custom;
    for (cube_positions) |pos, i| {
        cube_transforms[i] = Mat4.fromRotation(
            20 * @intToFloat(f32, i) + frame1,
            Vec3.new(1, 0.3, 0.5),
        ).translate(pos);
    }
    scene.setTransform(cube, &cube_transforms) catch unreachable;
    ctx.clear(true, true, true, [4]f32{ 0.2, 0.3, 0.3, 1.0 });
}

fn beforeScreenRendering(ctx: *GraphicsContext, custom: ?*anyopaque) void {
    _ = custom;
    screen_transform = Mat4.fromRotation(frame2, Vec3.forward());
    ctx.clear(true, false, false, [4]f32{ 0.3, 0.2, 0.3, 1.0 });
}

fn loop(ctx: *zp.Context) void {
    if (rotate_cubes) frame1 += 1;
    if (rotate_scene) frame2 += 1;

    // camera movement
    const distance = ctx.delta_tick * scene.viewer_camera.move_speed;
    if (ctx.isKeyPressed(.w)) {
        scene.viewer_camera.move(.forward, distance);
    }
    if (ctx.isKeyPressed(.s)) {
        scene.viewer_camera.move(.backward, distance);
    }
    if (ctx.isKeyPressed(.a)) {
        scene.viewer_camera.move(.left, distance);
    }
    if (ctx.isKeyPressed(.d)) {
        scene.viewer_camera.move(.right, distance);
    }
    if (ctx.isKeyPressed(.left)) {
        scene.viewer_camera.rotate(0, -1);
    }
    if (ctx.isKeyPressed(.right)) {
        scene.viewer_camera.rotate(0, 1);
    }
    if (ctx.isKeyPressed(.up)) {
        scene.viewer_camera.rotate(1, 0);
    }
    if (ctx.isKeyPressed(.down)) {
        scene.viewer_camera.rotate(-1, 0);
    }

    while (ctx.pollEvent()) |e| {
        _ = dig.processEvent(e);
        switch (e) {
            .keyboard_event => |key| {
                if (key.trigger_type == .up) {
                    switch (key.scan_code) {
                        .escape => ctx.kill(),
                        .f2 => {
                            fb.tex.?.saveToFile(
                                std.testing.allocator,
                                "test.png",
                                .{},
                            ) catch unreachable;
                            fb.tex.?.saveToFile(
                                std.testing.allocator,
                                "test.bmp",
                                .{ .format = .bmp },
                            ) catch unreachable;
                            fb.tex.?.saveToFile(
                                std.testing.allocator,
                                "test.tga",
                                .{ .format = .tga },
                            ) catch unreachable;
                            fb.tex.?.saveToFile(
                                std.testing.allocator,
                                "test.jpg",
                                .{ .format = .jpg },
                            ) catch unreachable;
                        },
                        else => {},
                    }
                }
            },
            .quit_event => ctx.kill(),
            else => {},
        }
    }

    // render the scene
    scene.draw(&ctx.graphics) catch unreachable;

    // settings
    dig.beginFrame();
    {
        dig.setNextWindowPos(
            .{ .x = @intToFloat(f32, ctx.graphics.viewport.w) - 10, .y = 50 },
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
            _ = dig.checkbox("rotate cubes", &rotate_cubes);
            _ = dig.checkbox("rotate scene", &rotate_scene);
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
        .enable_depth_test = true,
    });
}
