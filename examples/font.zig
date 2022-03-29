const std = @import("std");
const zp = @import("zplay");
const gl = zp.deps.gl;
const alg = zp.deps.alg;
const Vec3 = alg.Vec3;
const Mat4 = alg.Mat4;
const gfx = zp.graphics;
const Texture = gfx.gpu.Texture;
const VertexArray = gfx.gpu.VertexArray;
const Renderer = gfx.Renderer;
const Camera = gfx.Camera;
const Material = gfx.Material;
const Font = gfx.Font;
const FontRenderer = gfx.@"2d".FontRenderer;

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

    var width: u32 = undefined;
    var height: u32 = undefined;
    ctx.graphics.getDrawableSize(&width, &height);

    // create font atlas
    var font = try Font.init(std.testing.allocator, "assets/msyh.ttf");
    defer font.deinit();
    font_atlas1 = try font.createAtlas(64, &Font.CodepointRanges.chineseCommon, null);
    font_atlas2 = try font.createAtlas(30, &Font.CodepointRanges.chineseCommon, null);

    // create renderer
    font_renderer = FontRenderer.init();

    // vertex array
    var vpos = std.ArrayList(f32).init(std.testing.allocator);
    var tcoords = std.ArrayList(f32).init(std.testing.allocator);
    defer vpos.deinit();
    defer tcoords.deinit();
    _ = try font_atlas1.appendDrawDataFromUTF8String(
        "你好！ABCDEFGHIJKL abcdefghijkl",
        0,
        0,
        &vpos,
        &tcoords,
        .top,
    );
    _ = try font_atlas1.appendDrawDataFromUTF8String(
        "你好！ABCDEFGHIJKL abcdefghijkl",
        0,
        @intToFloat(f32, height),
        &vpos,
        &tcoords,
        .bottom,
    );
    const vcount1 = @intCast(u32, vpos.items.len);
    vertex_array1 = VertexArray.init(std.testing.allocator, 2);
    vertex_array1.use();
    defer vertex_array1.disuse();
    vertex_array1.vbos[0].allocInitData(f32, vpos.items, .static_draw);
    vertex_array1.vbos[1].allocInitData(f32, tcoords.items, .static_draw);
    vertex_array1.setAttribute(0, 0, 3, f32, false, 0, 0);
    vertex_array1.setAttribute(1, 1, 2, f32, false, 0, 0);

    vpos.clearRetainingCapacity();
    tcoords.clearRetainingCapacity();
    _ = try font_atlas2.appendDrawDataFromUTF8String(
        "第一行",
        0,
        200,
        &vpos,
        &tcoords,
        .baseline,
    );
    _ = try font_atlas2.appendDrawDataFromUTF8String(
        "第二行",
        0,
        font_atlas2.getVPosOfNextLine(200),
        &vpos,
        &tcoords,
        .baseline,
    );
    const vcount2 = @intCast(u32, vpos.items.len);
    vertex_array2 = VertexArray.init(std.testing.allocator, 2);
    vertex_array2.use();
    defer vertex_array2.disuse();
    vertex_array2.vbos[0].allocInitData(f32, vpos.items, .static_draw);
    vertex_array2.vbos[1].allocInitData(f32, tcoords.items, .static_draw);
    vertex_array2.setAttribute(0, 0, 3, f32, false, 0, 0);
    vertex_array2.setAttribute(1, 1, 2, f32, false, 0, 0);

    // create material
    material1 = Material.init(.{
        .font = .{
            .color = [_]f32{ 1, 1, 0 },
            .atlas = font_atlas1.tex,
        },
    });
    material2 = Material.init(.{
        .font = .{
            .color = [_]f32{ 1, 1, 0 },
            .atlas = font_atlas2.tex,
        },
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

    ctx.graphics.toggleCapability(.blend, true);
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
    font_renderer.draw(&ctx.graphics, render_data) catch unreachable;
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
