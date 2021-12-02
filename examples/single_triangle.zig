const std = @import("std");
const zp = @import("zplay");
const gl = zp.gl;
const alg = zp.alg;
const Vec3 = alg.Vec3;
const Mat4 = alg.Mat4;
const Camera = zp.@"3d".Camera;
const Material = zp.@"3d".Material;
const Renderer = zp.@"3d".Renderer;
const SimpleRenderer = zp.@"3d".SimpleRenderer;

var renderer: *Renderer = undefined;
var simple_renderer: SimpleRenderer = undefined;
var vertex_array: gl.VertexArray = undefined;

const vertices = [_]f32{
    -0.5, -0.5, 0.0, 1.0, 0.0, 0.0,
    0.5,  -0.5, 0.0, 0.0, 1.0, 0.0,
    0.0,  0.5,  0.0, 0.0, 0.0, 1.0,
};

fn init(ctx: *zp.Context) anyerror!void {
    _ = ctx;

    // create renderer
    simple_renderer = SimpleRenderer.init();
    renderer = &simple_renderer.renderer;

    // vertex array
    vertex_array = gl.VertexArray.init(5);
    vertex_array.use();
    defer vertex_array.disuse();
    vertex_array.bufferData(0, f32, &vertices, .array_buffer, .static_draw);
    vertex_array.setAttribute(0, SimpleRenderer.ATTRIB_LOCATION_POS, 3, f32, false, 6 * @sizeOf(f32), 0);
    vertex_array.setAttribute(0, SimpleRenderer.ATTRIB_LOCATION_COLOR, 3, f32, false, 6 * @sizeOf(f32), 3 * @sizeOf(f32));

    std.log.info("game init", .{});
}

fn loop(ctx: *zp.Context) void {
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
                if (key.trigger_type == .down) {
                    return;
                }
                switch (key.scan_code) {
                    .escape => ctx.kill(),
                    .f1 => ctx.toggleFullscreeen(null),
                    else => {},
                }
            },
            .quit_event => ctx.kill(),
            else => {},
        }
    }

    gl.util.clear(true, false, false, [_]f32{ 0.2, 0.3, 0.3, 1.0 });

    // update color and draw triangle
    renderer.begin();
    renderer.render(
        vertex_array,
        false,
        .triangles,
        0,
        3,
        Mat4.identity(),
        Mat4.identity(),
        null,
        null,
    ) catch unreachable;
    renderer.end();
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
        .enable_resizable = true,
    });
}
