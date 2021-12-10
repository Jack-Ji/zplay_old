const std = @import("std");
const zp = @import("zplay");
const dig = zp.dig;
const gl = zp.gl;
const alg = zp.alg;
const Vec3 = alg.Vec3;
const Vec4 = alg.Vec4;
const Mat4 = alg.Mat4;
const SimpleRenderer = zp.@"3d".SimpleRenderer;
const Model = zp.@"3d".Model;

var simple_renderer: SimpleRenderer = undefined;
var wireframe_mode = false;
var dog: Model = undefined;
var girl: Model = undefined;
var camera = zp.@"3d".Camera.fromPositionAndTarget(
    alg.Vec3.new(0, 0, 3),
    alg.Vec3.zero(),
    null,
);

fn init(ctx: *zp.Context) anyerror!void {
    _ = ctx;
    std.log.info("game init", .{});

    // create renderer
    simple_renderer = SimpleRenderer.init();

    // load model
    dog = Model.fromGLTF(std.testing.allocator, "assets/dog.gltf");
    girl = Model.fromGLTF(std.testing.allocator, "assets/girl.glb");

    // enable depth test
    gl.util.toggleCapability(.depth_test, true);
}

fn loop(ctx: *zp.Context) void {
    const S = struct {
        var frame: f32 = 0;
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

    var renderer = simple_renderer.renderer();
    renderer.begin();
    dog.render(
        renderer,
        Mat4.fromTranslate(Vec3.new(-1.0, -0.7, 0))
            .scale(Vec3.set(0.7))
            .mult(Mat4.fromRotation(S.frame, Vec3.up())),
        projection,
        camera,
        null,
    ) catch unreachable;
    girl.render(
        renderer,
        Mat4.fromTranslate(Vec3.new(1.0, -1.2, 0))
            .scale(Vec3.set(0.7))
            .mult(Mat4.fromRotation(S.frame, Vec3.up())),
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
            dig.ImGuiWindowFlags_NoMove | dig.ImGuiWindowFlags_NoResize | dig.ImGuiWindowFlags_AlwaysAutoResize,
        )) {
            var buf: [32]u8 = undefined;
            dig.text(std.fmt.bufPrintZ(&buf, "FPS: {d:.2}", .{dig.getIO().*.Framerate}) catch unreachable);
            dig.text(
                "Total Vertices: %d",
                blk: {
                    var num: u32 = 0;
                    for (dog.meshes.items) |m| {
                        num += @intCast(u32, m.positions.items.len);
                    }
                    break :blk num;
                },
            );
            dig.separator();
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
