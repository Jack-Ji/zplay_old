const std = @import("std");
const zp = @import("zplay");
const SimpleRenderer = zp.graphics.@"3d".SimpleRenderer;
const Camera = zp.graphics.@"3d".Camera;
const Model = zp.graphics.@"3d".Model;
const dig = zp.deps.dig;
const alg = zp.deps.alg;
const Vec2 = alg.Vec2;
const Vec3 = alg.Vec3;
const Vec4 = alg.Vec4;
const Mat4 = alg.Mat4;

var simple_renderer: SimpleRenderer = undefined;
var wireframe_mode = false;
var merge_meshes = true;
var vsync_mode = false;
var dog: Model = undefined;
var girl: Model = undefined;
var helmet: Model = undefined;
var total_vertices: u32 = undefined;
var total_meshes: u32 = undefined;
var camera = Camera.fromPositionAndTarget(
    Vec3.new(0, 0, 3),
    Vec3.zero(),
    null,
);

fn init(ctx: *zp.Context) anyerror!void {
    std.log.info("game init", .{});

    // init imgui
    try dig.init(ctx.window);

    // create renderer
    simple_renderer = SimpleRenderer.init();

    // load scene
    loadScene();

    // enable depth test
    ctx.graphics.toggleCapability(.depth_test, true);
}

fn loop(ctx: *zp.Context) void {
    while (ctx.pollEvent()) |e| {
        if (e == .mouse_event and dig.getIO().*.WantCaptureMouse) {
            _ = dig.processEvent(e);
            continue;
        }
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
                        .m => ctx.toggleRelativeMouseMode(null),
                        .f => {
                            if (wireframe_mode) {
                                wireframe_mode = false;
                            } else {
                                wireframe_mode = true;
                            }
                            ctx.graphics.setPolygonMode(if (wireframe_mode) .line else .fill);
                        },
                        else => {},
                    }
                }
            },
            .mouse_event => |me| {
                switch (me.data) {
                    .wheel => |scroll| {
                        camera.zoom -= @intToFloat(f32, scroll.scroll_y);
                        if (camera.zoom < 1) {
                            camera.zoom = 1;
                        }
                        if (camera.zoom > 45) {
                            camera.zoom = 45;
                        }
                    },
                    else => {},
                }
            },
            .quit_event => ctx.kill(),
            else => {},
        }
    }

    var width: u32 = undefined;
    var height: u32 = undefined;
    ctx.getWindowSize(&width, &height);

    // start drawing
    ctx.graphics.clear(true, true, false, [_]f32{ 0.2, 0.3, 0.3, 1.0 });

    const projection = Mat4.perspective(
        camera.zoom,
        @intToFloat(f32, width) / @intToFloat(f32, height),
        0.1,
        100,
    );

    var renderer = simple_renderer.renderer();
    renderer.begin();
    dog.render(
        renderer,
        Mat4.fromTranslate(Vec3.new(-2.0, -0.7, 0))
            .scale(Vec3.set(0.7))
            .mult(Mat4.fromRotation(ctx.tick * 50, Vec3.up())),
        projection,
        camera,
        null,
    ) catch unreachable;
    girl.render(
        renderer,
        Mat4.fromTranslate(Vec3.new(2.0, -1.2, 0))
            .scale(Vec3.set(0.7))
            .mult(Mat4.fromRotation(ctx.tick * 100, Vec3.up())),
        projection,
        camera,
        null,
    ) catch unreachable;
    helmet.render(
        renderer,
        Mat4.fromTranslate(Vec3.new(0.0, 0, 0))
            .scale(Vec3.set(0.7))
            .mult(Mat4.fromRotation(ctx.tick * 10, Vec3.up())),
        projection,
        camera,
        null,
    ) catch unreachable;
    renderer.end();

    // settings
    dig.beginFrame();
    {
        dig.setNextWindowPos(
            .{ .x = @intToFloat(f32, width) - 30, .y = 50 },
            dig.ImGuiCond_Always,
            .{ .x = 1, .y = 0 },
        );
        if (dig.begin(
            "control",
            null,
            dig.ImGuiWindowFlags_NoMove |
                dig.ImGuiWindowFlags_NoResize |
                dig.ImGuiWindowFlags_AlwaysAutoResize,
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
            if (dig.checkbox("merge meshes", &merge_meshes)) {
                loadScene();
            }
        }
        dig.end();

        const S = struct {
            const MAX_SIZE = 20000;
            var data = std.ArrayList(Vec2).init(std.testing.allocator);
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
                S.data.append(Vec2.new(ctx.tick, mpf)) catch unreachable;
            } else {
                S.data.items[S.offset] = Vec2.new(ctx.tick, mpf);
                S.offset = (S.offset + 1) % S.MAX_SIZE;
            }
            S.interval = 0;
            S.count = 0;
        }
        const plot = dig.ext.plot;
        if (dig.begin("monitor", null, 0)) {
            _ = dig.sliderFloat("History", &S.history, 1, 30, "%.1f s", 0);
            plot.setNextPlotLimitsX(ctx.tick - S.history, ctx.tick, dig.ImGuiCond_Always);
            plot.setNextPlotLimitsY(0, 0.02, dig.ImGuiCond_Once, plot.ImPlotYAxis_1);
            if (plot.beginPlot(
                "milliseconds per frame",
                null,
                null,
                .{ .x = -1, .y = 200 },
                0,
                plot.ImPlotAxisFlags_NoTickLabels,
                0,
                plot.ImPlotAxisFlags_NoGridLines,
                plot.ImPlotAxisFlags_NoGridLines,
                null,
                null,
            )) {
                if (S.data.items.len > 0) {
                    plot.plotLine_FloatPtrFloatPtr(
                        "line",
                        &S.data.items[0].x,
                        &S.data.items[0].y,
                        @intCast(c_int, S.data.items.len),
                        @intCast(c_int, S.offset),
                        @intCast(c_int, @sizeOf(Vec2)),
                    );
                }
                plot.endPlot();
            }
        }
        dig.end();
    }
    dig.endFrame();
}

fn loadScene() void {
    const S = struct {
        var loaded = false;
    };
    if (S.loaded) {
        dog.deinit();
        girl.deinit();
        helmet.deinit();
    }

    // load models
    total_vertices = 0;
    total_meshes = 0;
    dog = Model.fromGLTF(std.testing.allocator, "assets/dog.gltf", merge_meshes) catch unreachable;
    girl = Model.fromGLTF(std.testing.allocator, "assets/girl.glb", merge_meshes) catch unreachable;
    helmet = Model.fromGLTF(std.testing.allocator, "assets/SciFiHelmet/SciFiHelmet.gltf", merge_meshes) catch unreachable;
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

    // allocate texture units
    var unit: i32 = 0;
    for (dog.materials.items) |m| {
        unit = m.allocTextureUnit(unit);
    }
    for (girl.materials.items) |m| {
        unit = m.allocTextureUnit(unit);
    }
    for (helmet.materials.items) |m| {
        unit = m.allocTextureUnit(unit);
    }
    S.loaded = true;
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
        .enable_maximized = true,
        .enable_vsync = false,
    });
}
