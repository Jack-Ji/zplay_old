const std = @import("std");
const zp = @import("zplay");
const gl = zp.deps.gl;
const alg = zp.deps.alg;
const Vec3 = alg.Vec3;
const Mat4 = alg.Mat4;
const gfx = zp.graphics;
const VertexArray = gfx.common.VertexArray;
const Texture2D = gfx.texture.Texture2D;
const Renderer = gfx.Renderer;
const Camera = gfx.Camera;
const Material = gfx.Material;
const SimpleRenderer = gfx.@"3d".SimpleRenderer;

var simple_renderer: SimpleRenderer = undefined;
var vertex_array: VertexArray = undefined;
var material: Material = undefined;

const vertices = [_]f32{
    -0.5, -0.5, 0.0, 1.0, 0.0, 0.0, 1.0,
    0.5,  -0.5, 0.0, 0.0, 1.0, 0.0, 1.0,
    0.0,  0.5,  0.0, 0.0, 0.0, 1.0, 1.0,
};

fn init(ctx: *zp.Context) anyerror!void {
    _ = ctx;
    std.log.info("game init", .{});

    // create renderer
    simple_renderer = SimpleRenderer.init();
    simple_renderer.mix_factor = 1;

    // vertex array
    vertex_array = VertexArray.init(std.testing.allocator, 5);
    vertex_array.use();
    defer vertex_array.disuse();
    vertex_array.vbos[0].allocInitData(f32, &vertices, .static_draw);
    vertex_array.setAttribute(0, Renderer.ATTRIB_LOCATION_POS, 3, f32, false, 7 * @sizeOf(f32), 0);
    vertex_array.setAttribute(0, Renderer.ATTRIB_LOCATION_COLOR, 4, f32, false, 7 * @sizeOf(f32), 3 * @sizeOf(f32));

    // create material
    material = Material.init(.{ .single_texture = try Texture2D.fromPixelData(
        std.testing.allocator,
        &.{
            0,   0,   0,
            0,   255, 0,
            0,   0,   255,
            255, 255, 255,
        },
        3,
        2,
        2,
        .{},
    ) });
    _ = material.allocTextureUnit(0);
}

fn loop(ctx: *zp.Context) void {
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
                        .f1 => ctx.toggleFullscreeen(null),
                        else => {},
                    }
                }
            },
            .quit_event => ctx.kill(),
            else => {},
        }
    }

    ctx.graphics.clear(true, false, false, [_]f32{ 0.2, 0.3, 0.3, 1.0 });

    // update color and draw triangle
    var rd = simple_renderer.renderer();
    rd.begin(false);
    rd.render(
        vertex_array,
        false,
        .triangles,
        0,
        3,
        Mat4.identity(),
        Mat4.identity(),
        null,
        material,
    ) catch unreachable;
    rd.end();
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
