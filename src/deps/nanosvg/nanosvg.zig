const std = @import("std");
pub const c = @import("c.zig");

pub const SVG = c.NSVGimage;

pub const Unit = enum {
    px,
    pt,
    pc,
    mm,
    cm,
    in,

    const Self = @This();
    pub fn toString(self: Self) [:0]const u8 {
        return switch (self) {
            .px => "px",
            .pt => "pt",
            .pc => "pc",
            .mm => "mm",
            .cm => "cm",
            .in => "in",
        };
    }
};

/// parse svg data from file
pub fn loadFile(filename: [:0]const u8, unit: ?Unit, dpi: ?f32) ?*SVG {
    var u: Unit = unit orelse .px;
    var d: f32 = dpi orelse 96;
    return c.nsvgParseFromFile(filename.ptr, u.toString().ptr, d);
}

/// parse svg data from memory
pub fn loadBuffer(buffer: [:0]const u8, unit: ?Unit, dpi: ?f32) ?*SVG {
    var u: Unit = unit orelse .px;
    var d: f32 = dpi orelse 96;
    return c.nsvgParse(buffer.ptr, u.toString().ptr, d);
}

/// free svg data
pub fn free(data: *SVG) void {
    c.nsvgDelete(data);
}
