const std = @import("std");
const zp = @import("zplay");
const dig = zp.deps.dig;
const alg = zp.deps.alg;
const Vec2 = alg.Vec2;
const Vec3 = alg.Vec3;
const Vec4 = alg.Vec4;
const Mat4 = alg.Mat4;
const gfx = zp.graphics;
const GraphicsContext = gfx.gpu.Context;
const Texture = gfx.gpu.Texture;
const Material = gfx.Material;
const Renderer = gfx.Renderer;
const SimpleRenderer = gfx.SimpleRenderer;
const Model = gfx.@"3d".Model;
const SkyboxRenderer = gfx.@"3d".SkyboxRenderer;
const Scene = gfx.@"3d".Scene;

var skybox: SkyboxRenderer = undefined;
var skybox_material: Material = undefined;
var simple_renderer: SimpleRenderer = undefined;
var wireframe_mode = false;
var merge_meshes = true;
var vsync_mode = false;
var dog: *Model = undefined;
var girl: *Model = undefined;
var helmet: *Model = undefined;
var total_vertices: u32 = undefined;
var total_meshes: u32 = undefined;
var face_culling: bool = false;
var render_data_skybox: Renderer.Input = undefined;
var scene: *Scene = undefined;
var global_tick: f32 = 0;

fn init(ctx: *zp.Context) anyerror!void {
    std.log.info("game init", .{});

    // init imgui
    try dig.init(ctx.window);

    // create renderer
    skybox = SkyboxRenderer.init(std.testing.allocator);
    simple_renderer = SimpleRenderer.init(.{});

    // load scene
    try loadScene(ctx);

    // enable depth test
    ctx.graphics.toggleCapability(.depth_test, true);
}

fn loop(ctx: *zp.Context) void {
    global_tick = ctx.tick;
    var width: u32 = undefined;
    var height: u32 = undefined;
    ctx.graphics.getDrawableSize(&width, &height);

    while (ctx.pollEvent()) |e| {
        if (e == .mouse_event and dig.getIO().*.WantCaptureMouse) {
            _ = dig.processEvent(e);
            continue;
        }
        switch (e) {
            .keyboard_event => |key| {
                if (key.trigger_type == .up) {
                    switch (key.scan_code) {
                        .escape => ctx.kill(),
                        else => {},
                    }
                }
            },
            .mouse_event => |me| {
                switch (me.data) {
                    .wheel => |scroll| {
                        scene.viewer_camera.frustrum.perspective.fov -= @intToFloat(f32, scroll.scroll_y);
                        if (scene.viewer_camera.frustrum.perspective.fov < 1) {
                            scene.viewer_camera.frustrum.perspective.fov = 1;
                        }
                        if (scene.viewer_camera.frustrum.perspective.fov > 45) {
                            scene.viewer_camera.frustrum.perspective.fov = 45;
                        }
                    },
                    else => {},
                }
            },
            .quit_event => ctx.kill(),
            else => {},
        }
    }

    scene.draw(&ctx.graphics) catch unreachable;

    // settings
    dig.beginFrame();
    {
        dig.setNextWindowPos(
            .{ .x = @intToFloat(f32, width) - 30, .y = 50 },
            .{
                .cond = dig.c.ImGuiCond_Always,
                .pivot = .{ .x = 1, .y = 0 },
            },
        );
        if (dig.begin(
            "control",
            null,
            dig.c.ImGuiWindowFlags_NoMove |
                dig.c.ImGuiWindowFlags_NoResize |
                dig.c.ImGuiWindowFlags_AlwaysAutoResize,
        )) {
            var buf: [32]u8 = undefined;
            dig.text(std.fmt.bufPrintZ(&buf, "FPS: {d:.2}", .{dig.getIO().*.Framerate}) catch unreachable);
            dig.text(std.fmt.bufPrintZ(&buf, "ms/frame: {d:.2}", .{ctx.delta_tick * 1000}) catch unreachable);
            dig.text(std.fmt.bufPrintZ(&buf, "Total Vertices: {d}", .{total_vertices}) catch unreachable);
            dig.text(std.fmt.bufPrintZ(&buf, "Total Meshes: {d}", .{total_meshes}) catch unreachable);
            dig.separator();
            if (dig.checkbox("wireframe", &wireframe_mode)) {
                ctx.graphics.setPolygonMode(if (wireframe_mode) .line else .fill);
            }
            if (dig.checkbox("vsync", &vsync_mode)) {
                ctx.graphics.setVsyncMode(vsync_mode);
            }
            if (dig.checkbox("face culling", &face_culling)) {
                ctx.graphics.toggleCapability(.cull_face, face_culling);
            }
            if (dig.checkbox("merge meshes", &merge_meshes)) {
                loadScene(ctx) catch unreachable;
            }
        }
        dig.end();

        const S = struct {
            const MAX_SIZE = 20000;
            var data = std.ArrayList(f32).init(std.testing.allocator);
            var offset: u32 = 0;
            var history: f32 = 10;
            var interval: f32 = 0;
            var count: f32 = 0;
        };
        S.interval += ctx.delta_tick;
        S.count += 1;
        if (S.interval > 0.1) {
            var mpf = S.interval / S.count;
            if (S.data.items.len < S.MAX_SIZE) {
                S.data.appendSlice(&.{ ctx.tick, mpf }) catch unreachable;
            } else {
                S.data.items[S.offset] = ctx.tick;
                S.data.items[S.offset + 1] = mpf;
                S.offset = (S.offset + 2) % S.MAX_SIZE;
            }
            S.interval = 0;
            S.count = 0;
        }
        const plot = dig.ext.plot;
        if (dig.begin("monitor", null, 0)) {
            _ = dig.sliderFloat("History", &S.history, 1, 30, .{});
            plot.setNextPlotLimitsX(ctx.tick - S.history, ctx.tick, dig.c.ImGuiCond_Always);
            plot.setNextPlotLimitsY(0, 0.02, .{});
            if (plot.beginPlot("milliseconds per frame", .{})) {
                if (S.data.items.len > 0) {
                    plot.plotLine_PtrPtr(
                        "line",
                        f32,
                        &S.data.items[0],
                        &S.data.items[1],
                        @intCast(u32, S.data.items.len / 2),
                        .{ .offset = @intCast(c_int, S.offset) },
                    );
                }
                plot.endPlot();
            }
        }
        dig.end();
    }
    dig.endFrame();
}

fn loadScene(ctx: *zp.Context) !void {
    const S = struct {
        var loaded = false;
    };
    if (S.loaded) {
        skybox_material.deinit();
        dog.deinit();
        girl.deinit();
        helmet.deinit();
        scene.deinit();
    }

    // allocate skybox
    skybox_material = Material.init(.{
        .single_cubemap = Texture.initCubeFromFilePaths(
            std.testing.allocator,
            "assets/skybox/right.jpg",
            "assets/skybox/left.jpg",
            "assets/skybox/top.jpg",
            "assets/skybox/bottom.jpg",
            "assets/skybox/front.jpg",
            "assets/skybox/back.jpg",
            false,
        ) catch unreachable,
    }, true);

    // load models
    total_vertices = 0;
    total_meshes = 0;
    dog = Model.fromGLTF(std.testing.allocator, "assets/dog.gltf", merge_meshes, null) catch unreachable;
    girl = Model.fromGLTF(std.testing.allocator, "assets/girl.glb", merge_meshes, null) catch unreachable;
    helmet = Model.fromGLTF(std.testing.allocator, "assets/SciFiHelmet/SciFiHelmet.gltf", merge_meshes, null) catch unreachable;
    for (dog.meshes.items) |m| {
        total_vertices += @intCast(u32, m.positions.items.len);
        total_meshes += 1;
    }
    for (girl.meshes.items) |m| {
        total_vertices += @intCast(u32, m.positions.items.len);
        total_meshes += 1;
    }
    for (helmet.meshes.items) |m| {
        total_vertices += @intCast(u32, m.positions.items.len);
        total_meshes += 1;
    }

    // init scene
    var width: u32 = undefined;
    var height: u32 = undefined;
    ctx.graphics.getDrawableSize(&width, &height);
    scene = try Scene.init(std.testing.allocator, .{
        .viewer_frustrum = .{
            .perspective = .{
                .fov = 45,
                .aspect_ratio = @intToFloat(f32, width) / @intToFloat(f32, height),
                .near = 0.1,
                .far = 100,
            },
        },
        .viewer_position = Vec3.new(0, 0, 3),
    });
    try scene.addModel(dog, &[_]Mat4{Mat4.identity()}, null, false);
    try scene.addModel(girl, &[_]Mat4{Mat4.identity()}, null, false);
    try scene.addModel(helmet, &[_]Mat4{Mat4.identity()}, null, false);
    render_data_skybox = .{
        .camera = scene.rdata_scene.camera,
        .material = &skybox_material,
    };
    try scene.setRenderPasses(&[_]Scene.RenderPassOption{
        .{
            .beforeFn = beforeSceneRendering,
            .rd = simple_renderer.renderer(),
            .rdata = &scene.rdata_scene,
        },
        .{
            .rd = skybox.renderer(),
            .rdata = &render_data_skybox,
        },
    });

    S.loaded = true;
}

fn beforeSceneRendering(ctx: *GraphicsContext, custom: ?*anyopaque) void {
    _ = custom;
    ctx.clear(true, true, false, [_]f32{ 0.2, 0.3, 0.3, 1.0 });
    scene.setTransform(
        dog,
        &[_]Mat4{
            Mat4.fromTranslate(Vec3.new(-2.0, -0.7, 0))
                .scale(Vec3.set(0.7))
                .mul(Mat4.fromRotation(global_tick * 50, Vec3.up())),
        },
    ) catch unreachable;
    scene.setTransform(
        girl,
        &[_]Mat4{
            Mat4.fromTranslate(Vec3.new(2.0, -1.2, 0))
                .scale(Vec3.set(0.7))
                .mul(Mat4.fromRotation(global_tick * 100, Vec3.up())),
        },
    ) catch unreachable;
    scene.setTransform(
        helmet,
        &[_]Mat4{
            Mat4.fromTranslate(Vec3.new(0.0, 0, 0))
                .scale(Vec3.set(0.7))
                .mul(Mat4.fromRotation(global_tick * 10, Vec3.up())),
        },
    ) catch unreachable;
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
        .enable_vsync = false,
    });
}
