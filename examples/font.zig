const std = @import("std");
const zp = @import("zplay");
const alg = zp.deps.alg;
const Vec3 = alg.Vec3;
const Mat4 = alg.Mat4;
const gfx = zp.graphics;
const VertexArray = gfx.gpu.VertexArray;
const Renderer = gfx.Renderer;
const Material = gfx.Material;
const Font = gfx.font.Font;
const FontRenderer = gfx.font.FontRenderer;

var font_atlas1: Font.Atlas = undefined;
var font_atlas2: Font.Atlas = undefined;
var font_renderer: FontRenderer = undefined;
var render_data: Renderer.Input = undefined;
var vertex_array1: VertexArray = undefined;
var vertex_array2: VertexArray = undefined;
var material1: Material = undefined;
var material2: Material = undefined;

fn init(ctx: *zp.Context) anyerror!void {
    _ = ctx;
    std.log.info("game init", .{});

    const size = ctx.graphics.getDrawableSize();

    // create font atlas
    var font = try Font.init(std.testing.allocator, "assets/msyh.ttf");
    defer font.deinit();
    font_atlas1 = try font.createAtlas(64, &Font.CodepointRanges.chineseCommon, null);
    font_atlas2 = try font.createAtlas(30, &Font.CodepointRanges.chineseCommon, null);

    // create renderer
    font_renderer = FontRenderer.init();

    // vertex array
    var vattrib = std.ArrayList(f32).init(std.testing.allocator);
    defer vattrib.deinit();
    _ = try font_atlas1.appendDrawDataFromUTF8String(
        "你好！ABCDEFGHIJKL abcdefghijkl",
        0,
        0,
        .top,
        [3]f32{ 1, 1, 0 },
        &vattrib,
    );
    _ = try font_atlas1.appendDrawDataFromUTF8String(
        "你好！ABCDEFGHIJKL abcdefghijkl",
        0,
        @intToFloat(f32, size.h),
        .bottom,
        [3]f32{ 1, 1, 0 },
        &vattrib,
    );
    const vcount1 = @intCast(u32, vattrib.items.len) / FontRenderer.float_num_of_vertex_attrib;
    vertex_array1 = VertexArray.init(std.testing.allocator, 1);
    FontRenderer.setupVertexArray(vertex_array1);
    vertex_array1.vbos[0].allocInitData(f32, vattrib.items, .static_draw);

    vattrib.clearRetainingCapacity();
    var xpos = try font_atlas2.appendDrawDataFromUTF8String(
        "第一行",
        0,
        200,
        .baseline,
        [3]f32{ 1, 0, 0 },
        &vattrib,
    );
    _ = try font_atlas2.appendDrawDataFromUTF8String(
        "接着第一行",
        xpos,
        200,
        .baseline,
        [3]f32{ 0, 1, 0 },
        &vattrib,
    );
    _ = try font_atlas2.appendDrawDataFromUTF8String(
        "第二行",
        0,
        font_atlas2.getVPosOfNextLine(200),
        .baseline,
        [3]f32{ 1, 0, 0 },
        &vattrib,
    );
    const vcount2 = @intCast(u32, vattrib.items.len) / FontRenderer.float_num_of_vertex_attrib;
    vertex_array2 = VertexArray.init(std.testing.allocator, 1);
    FontRenderer.setupVertexArray(vertex_array2);
    vertex_array2.vbos[0].allocInitData(f32, vattrib.items, .static_draw);

    // create material
    material1 = Material.init(.{
        .single_texture = font_atlas1.tex,
    });
    material2 = Material.init(.{
        .single_texture = font_atlas2.tex,
    });

    // compose renderer's input
    render_data = try Renderer.Input.init(
        std.testing.allocator,
        &[_]Renderer.Input.VertexData{
            .{
                .element_draw = false,
                .vertex_array = vertex_array1,
                .count = vcount1,
                .material = &material1,
            },
            .{
                .element_draw = false,
                .vertex_array = vertex_array2,
                .count = vcount2,
                .material = &material2,
            },
        },
        null,
        null,
        null,
    );
}

fn loop(ctx: *zp.Context) void {
    while (ctx.pollEvent()) |e| {
        switch (e) {
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

    ctx.graphics.clear(true, true, false, [_]f32{ 0.2, 0.3, 0.3, 1.0 });
    font_renderer.draw(&ctx.graphics, render_data) catch unreachable;

    _ = ctx.drawText(
        "FPS: {d:.1}  CPU time: {d:.3} ms",
        .{ ctx.fps, ctx.average_cpu_time },
        .{ .color = .{ 1, 1, 1 } },
    );
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
        .enable_console = true,
    });
}
