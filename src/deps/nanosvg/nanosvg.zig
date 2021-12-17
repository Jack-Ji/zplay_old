const std = @import("std");
pub const c = @import("c.zig");

pub const SVG = struct {
    image: *c.NSVGimage,
    nshape: u32 = 0,
    nstroke: u32 = 0,
    nfill: u32 = 0,
    npath: u32 = 0,

    const Self = @This();
    pub fn init(data: *c.NSVGimage) Self {
        var self = Self{ .image = data };
        var shape = data.shapes;
        while (shape != null) : (shape = shape.*.next) {
            if ((shape.*.flags & c.NSVG_FLAGS_VISIBLE) == 0) {
                continue;
            }
            self.nshape += 1;
            if (shape.*.fill.type > 0) {
                self.nfill += 1;
            }
            if (shape.*.stroke.type > 0) {
                self.nstroke += 1;
            }
            var path = shape.*.paths;
            while (path != null) : (path = path.*.next) {
                self.npath += 1;
            }
        }
        return self;
    }
};

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
pub fn loadFile(filename: [:0]const u8, unit: ?Unit, dpi: ?f32) ?SVG {
    var u: Unit = unit orelse .px;
    var d: f32 = dpi orelse 96;
    var image = c.nsvgParseFromFile(filename.ptr, u.toString().ptr, d);
    if (image == null) return null;
    return SVG.init(image);
}

/// parse svg data from memory
pub fn loadBuffer(buffer: [:0]const u8, unit: ?Unit, dpi: ?f32) ?SVG {
    var u: Unit = unit orelse .px;
    var d: f32 = dpi orelse 96;
    var image = c.nsvgParse(buffer.ptr, u.toString().ptr, d);
    if (image == null) return null;
    return SVG.init(image);
}

/// free svg data
pub fn free(data: SVG) void {
    c.nsvgDelete(data.image);
}
