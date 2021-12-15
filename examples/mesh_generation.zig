const std = @import("std");
const zp = @import("zplay");
const SimpleRenderer = zp.graphics.@"3d".SimpleRenderer;
const Mesh = zp.graphics.@"3d".Mesh;
const Camera = zp.graphics.@"3d".Camera;
const dig = zp.deps.dig;
const alg = zp.deps.alg;
const Vec3 = alg.Vec3;
const Vec4 = alg.Vec4;

var simple_renderer: SimpleRenderer = undefined;
var wireframe_mode = false;
var perspective_mode = true;
var cube1: Mesh = undefined;
var cube2: Mesh = undefined;
var camera = Camera.fromPositionAndTarget(
    alg.Vec3.new(0, 0, 6),
    alg.Vec3.zero(),
    null,
);

fn init(ctx: *zp.Context) anyerror!void {
    std.log.info("game init", .{});

    // init imgui
    try dig.init(ctx.window);

    // simple renderer
    simple_renderer = SimpleRenderer.init();

    // generate meshes
    cube1 = Mesh.genCube(std.testing.allocator, 0.5, 0.5, 0.5, Vec4.new(0, 1, 0, 1));
    cube2 = Mesh.genCube(std.testing.allocator, 0.5, 0.7, 2, Vec4.new(0, 1, 0, 1));

    // enable depth test
    ctx.graphics.toggleCapability(.depth_test, true);
}

fn loop(ctx: *zp.Context) void {
    const S = struct {
        var frame: f32 = 0;
        var axis = alg.Vec4.new(1, 1, 1, 0);
        var last_tick: ?f32 = null;
    };
    S.frame += 1;

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
    ctx.getWindowSize(&width, &height);

    // start drawing
    ctx.graphics.clear(true, true, false, [_]f32{ 0.2, 0.3, 0.3, 1.0 });

    var projection: alg.Mat4 = undefined;
    if (perspective_mode) {
        projection = alg.Mat4.perspective(
            camera.zoom,
            @intToFloat(f32, width) / @intToFloat(f32, height),
            0.1,
            100,
        );
    } else {
        projection = alg.Mat4.orthographic(
            -3,
            3,
            -3,
            3,
            0,
            100,
        );
    }
    S.axis = alg.Mat4.fromRotation(1, alg.Vec3.new(-1, 1, -1)).multByVec4(S.axis);
    const model = alg.Mat4.fromRotation(
        S.frame,
        alg.Vec3.new(S.axis.x, S.axis.y, S.axis.z),
    );

    var renderer = simple_renderer.renderer();
    renderer.begin();
    {
        renderer.renderMesh(
            cube1,
            model.translate(Vec3.new(-2.0, 1.2, 0)),
            projection,
            camera,
            null,
            null,
        ) catch unreachable;

        renderer.renderMesh(
            cube2,
            model.translate(Vec3.new(-0.5, 1.2, 0)),
            projection,
            camera,
            null,
            null,
        ) catch unreachable;
    }
    renderer.end();

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
            if (dig.checkbox("wireframe", &wireframe_mode)) {
                ctx.graphics.setPolygonMode(if (wireframe_mode) .line else .fill);
            }
            _ = dig.checkbox("perspective", &perspective_mode);
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
        .enable_highres_depth = false,
    });
}
