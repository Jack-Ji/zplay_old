const std = @import("std");
const zp = @import("zplay");
const alg = zp.deps.alg;
const Vec3 = alg.Vec3;
const Mat4 = alg.Mat4;
const gfx = zp.graphics;
const Texture = gfx.gpu.Texture;
const VertexArray = gfx.gpu.VertexArray;
const Renderer = gfx.Renderer;
const Camera = gfx.Camera;
const Material = gfx.Material;
const Mesh = gfx.@"3d".Mesh;
const SimpleRenderer = gfx.@"3d".SimpleRenderer;

var simple_renderer: SimpleRenderer = undefined;
var render_data: Renderer.Input = undefined;
var camera: Camera = undefined;
var vertex_array: VertexArray = undefined;
var material: Material = undefined;

fn init(ctx: *zp.Context) anyerror!void {
    _ = ctx;
    std.log.info("game init", .{});

    // create renderer
    simple_renderer = SimpleRenderer.init(.{ .mix_factor = 1.0 });
    camera = Camera.fromPositionAndTarget(
        .{
            .orthographic = .{
                .left = -1,
                .right = 1,
                .bottom = -1,
                .top = 1,
                .near = -1,
                .far = 1,
            },
        },
        Vec3.zero(),
        Vec3.back(),
        null,
    );

    // vertex array
    const vertices = [_]f32{
        -0.5, -0.5, 0.0, 1.0, 0.0, 0.0, 1.0,
        0.5,  -0.5, 0.0, 0.0, 1.0, 0.0, 1.0,
        0.0,  0.5,  0.0, 0.0, 0.0, 1.0, 1.0,
    };
    vertex_array = VertexArray.init(std.testing.allocator, 5);
    vertex_array.use();
    defer vertex_array.disuse();
    vertex_array.vbos[0].allocInitData(f32, &vertices, .static_draw);
    vertex_array.setAttribute(0, @enumToInt(Mesh.AttribLocation.position), 3, f32, false, 7 * @sizeOf(f32), 0);
    vertex_array.setAttribute(0, @enumToInt(Mesh.AttribLocation.color), 4, f32, false, 7 * @sizeOf(f32), 3 * @sizeOf(f32));

    // create material
    material = Material.init(.{
        .single_texture = try Texture.init2DFromPixels(
            std.testing.allocator,
            &.{
                0,   0,   0,
                0,   255, 0,
                0,   0,   255,
                255, 255, 255,
            },
            .rgb,
            2,
            2,
            .{},
        ),
    });

    // compose renderer's input
    render_data = try Renderer.Input.init(
        std.testing.allocator,
        &[_]Renderer.Input.VertexData{.{
            .element_draw = false,
            .vertex_array = vertex_array,
            .count = 3,
            .material = &material,
        }},
        &camera,
        null,
        null,
    );
}

fn loop(ctx: *zp.Context) void {
    while (ctx.pollEvent()) |e| {
        switch (e) {
            .window_event => |we| {
                switch (we.data) {
                    .resized => {
                        var size = ctx.graphics.getDrawableSize();
                        ctx.graphics.setViewport(.{ .w = size.w, .h = size.h });
                    },
                    else => {},
                }
            },
            .keyboard_event => |key| {
                if (key.trigger_type == .up) {
                    switch (key.scan_code) {
                        .escape => ctx.kill(),
                        else => {},
                    }
                }
            },
            .quit_event => ctx.kill(),
            else => {},
        }
    }

    ctx.graphics.clear(true, false, false, [_]f32{ 0.3, 0.3, 0.3, 1.0 });
    render_data.vds.?.items[0].transform = .{
        .single = Mat4.fromRotation(@floatCast(f32, ctx.tick), Vec3.up()),
    };
    simple_renderer.draw(&ctx.graphics, render_data) catch unreachable;
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
