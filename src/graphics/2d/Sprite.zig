const std = @import("std");
const Self = @This();

pub const Point = struct {
    x: f32,
    y: f32,
};

pub const Rectangle = struct {
    topleft: Point,
    width: f32,
    height: f32,
};

area: Rectangle,
uv: Rectangle,

pub fn init() Self {
    return .{};
}
