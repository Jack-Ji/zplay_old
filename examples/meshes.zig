const std = @import("std");
const zp = @import("zplay");
const dig = zp.dig;
const gl = zp.gl;
const alg = zp.alg;
const Vec3 = alg.Vec3;
const Vec4 = alg.Vec4;
const SimpleRenderer = zp.@"3d".SimpleRenderer;
const Mesh = zp.@"3d".Mesh;

var simple_renderer: SimpleRenderer = undefined;
var wireframe_mode = false;
var cube1: Mesh = undefined;
var cube2: Mesh = undefined;
var camera = zp.@"3d".Camera.fromPositionAndTarget(
    alg.Vec3.new(0, 0, 6),
    alg.Vec3.zero(),
    null,
);

fn init(ctx: *zp.Context) anyerror!void {
    _ = ctx;

    // simple renderer
    simple_renderer = SimpleRenderer.init();

    // generate meshes
    cube1 = Mesh.genCube(std.testing.allocator, 0.5, 0.5, 0.5, Vec4.new(0, 1, 0, 1));
    cube2 = Mesh.genCube(std.testing.allocator, 0.5, 0.7, 1, Vec4.new(0, 1, 0, 1));

    // enable depth test
    gl.util.toggleCapability(.depth_test, true);

    std.log.info("game init", .{});
}

fn loop(ctx: *zp.Context) void {
    const S = struct {
        var frame: f32 = 0;
        var axis = alg.Vec4.new(1, 1, 1, 0);
        var last_tick: ?f32 = null;
    };
    S.frame += 1;

    while (ctx.pollEvent()) |e| {
        switch (e) {
            .window_event => |we| {
                switch (we.data) {
                    .resized => |size| {
                        gl.viewport(0, 0, size.width, size.height);
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
                            toggleWireframeMode(wireframe_mode);
                        },
                        else => {},
                    }
                }
            },
            .quit_event => ctx.kill(),
            else => {},
        }
    }

    var width: i32 = undefined;
    var height: i32 = undefined;
    ctx.getWindowSize(&width, &height);

    // start drawing
    gl.util.clear(true, true, false, [_]f32{ 0.2, 0.3, 0.3, 1.0 });

    const projection = alg.Mat4.perspective(
        camera.zoom,
        @intToFloat(f32, width) / @intToFloat(f32, height),
        0.1,
        100,
    );
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
            dig.ImGuiCond_Always,
            .{ .x = 1, .y = 0 },
        );
        if (dig.begin(
            "settings",
            null,
            dig.ImGuiWindowFlags_NoMove | dig.ImGuiWindowFlags_NoResize,
        )) {
            if (dig.checkbox("wireframe", &wireframe_mode)) {
                toggleWireframeMode(wireframe_mode);
            }
        }
        dig.end();
    }
    dig.endFrame();
}

fn toggleWireframeMode(status: bool) void {
    if (status) {
        gl.polygonMode(gl.GL_FRONT_AND_BACK, gl.GL_LINE);
    } else {
        gl.polygonMode(gl.GL_FRONT_AND_BACK, gl.GL_FILL);
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
        .enable_dear_imgui = true,
    });
}
