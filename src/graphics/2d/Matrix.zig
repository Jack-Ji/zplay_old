//! 2x3 matrix specially made for 2d games

const std = @import("std");
const math = std.math;
const zp = @import("../../zplay.zig");
const alg = zp.deps.alg;
const Self = @This();

/// use column-major style
/// | values[0] values[2] values[4] |
/// | values[1] values[3] values[5] |
values: [6]f32,

/// do nothing
pub fn identity() Self {
    return Self{
        1, 0, 0, 1, 0, 0,
    };
}

/// scale along x/y axis
pub fn scale(self: Self, sx: f32, sy: f32) Self {
    var result = self;
    result.values[0] *= sx;
    result.values[3] *= sy;
    return result;
}

/// rotate around zero point (positive means counter-clock)
pub fn rotate(self: Self, degree: f32) Self {
    var rad = alg.toRadians(degree);
    var result = self;
    result.values[0] *= math.cos(rad);
    result.values[1] = math.sin(rad);
    result.values[2] = -math.sin(rad);
    result.values[3] *= math.cos(rad);
    return result;
}

/// move by (dx, dy)
pub fn translate(self: Self, dx: f32, dy: f32) Self {
    var result = self;
    result.values[4] += dx;
    result.values[5] += dy;
    return result;
}
