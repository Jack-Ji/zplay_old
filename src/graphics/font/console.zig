const std = @import("std");
const assert = std.debug.assert;
const Font = @import("Font.zig");
const FontRenderer = @import("FontRenderer.zig");
const zp = @import("../../zplay.zig");
const gfx = zp.graphics;
const Context = gfx.gpu.Context;
const VertexArray = gfx.gpu.VertexArray;
const Renderer = gfx.Renderer;
const Material = gfx.Material;
const Self = @This();

const font_data = @embedFile("clacon2.ttf");

/// font 
var font: ?*Font = null;

/// font-atlas
var atlas: Font.Atlas = undefined;

/// font renderer
var renderer: FontRenderer = undefined;

/// vertex attributes
var vattrib: std.ArrayList(f32) = undefined;

/// vertex array
var vertex_array: VertexArray = undefined;

/// material
var material: Material = undefined;

/// renderer's input 
var render_data: Renderer.Input = undefined;

/// maximum number of texts to be rendered
const max_text_num = 1000;

/// init module
pub fn init(allocator: std.mem.Allocator, size: u32) void {
    font = Font.fromTrueTypeData(allocator, font_data) catch unreachable;
    atlas = font.?.createAtlas(
        size,
        &[_][2]u32{
            .{ 0x0020, 0x00FF }, // Basic Latin + Latin Supplement
            .{ 0x2500, 0x25FF }, // Special marks (block, line, triangle etc)
            .{ 0x2801, 0x28FF }, // Braille
            .{ 0x16A0, 0x16F0 }, // Runic
        },
        4096,
    ) catch unreachable;
    renderer = FontRenderer.init();
    vattrib = std.ArrayList(f32).initCapacity(allocator, 1000) catch unreachable;
    vertex_array = VertexArray.init(std.testing.allocator, 1);
    vertex_array.vbos[0].allocData(max_text_num * 48 * @sizeOf(f32), .dynamic_draw);
    FontRenderer.setupVertexArray(vertex_array);
    material = Material.init(.{ .single_texture = atlas.tex });
    render_data = Renderer.Input.init(
        std.testing.allocator,
        &[_]Renderer.Input.VertexData{
            .{
                .element_draw = false,
                .vertex_array = vertex_array,
                .count = 0,
                .material = &material,
            },
        },
        null,
        null,
        null,
    ) catch unreachable;
}

pub fn clear() void {
    assert(font != null);
    vattrib.clearRetainingCapacity();
}

/// add draw data, return metrics of text
pub const DrawOption = struct {
    xpos: f32 = 0,
    ypos: f32 = 0,
    ypos_type: Font.Atlas.YPosType = .top,
    color: [3]f32 = .{ 0, 0, 0 },
};
pub const DrawRect = struct {
    xpos: f32,
    ypos: f32,
    width: f32,
    height: f32,
    next_xpos: f32,
    next_line_ypos: f32,
};
pub fn drawText(text: []const u8, opt: DrawOption) !DrawRect {
    assert(font != null);
    assert(vattrib.items.len / 48 <= max_text_num - text.len);
    var next_xpos = try atlas.appendDrawDataFromUTF8String(
        text,
        opt.xpos,
        opt.ypos,
        opt.ypos_type,
        opt.color,
        &vattrib,
    );
    const attribs = vattrib.items[vattrib.items.len - 48 ..];
    return DrawRect{
        .xpos = attribs[0],
        .ypos = attribs[1],
        .width = attribs[16] - attribs[0],
        .height = attribs[17] - attribs[1],
        .next_xpos = next_xpos,
        .next_line_ypos = atlas.getVPosOfNextLine(opt.ypos),
    };
}

/// send batched data to gpu, issue draw command
pub fn submitAndRender(ctx: *Context) void {
    assert(font != null);
    if (vattrib.items.len == 0) return;
    vertex_array.vbos[0].updateData(0, f32, vattrib.items);
    render_data.vds.?.items[0].count =
        @intCast(u32, vattrib.items.len) / FontRenderer.float_num_of_vertex_attrib;
    renderer.draw(ctx, render_data) catch unreachable;
}
