const std = @import("std");
const assert = std.debug.assert;
const SpriteSheet = @import("SpriteSheet.zig");
const zp = @import("../../zplay.zig");
const Mat4 = zp.deps.alg.Mat4;
const Vec3 = zp.deps.alg.Vec3;
const Self = @This();

pub const Point = struct {
    x: f32,
    y: f32,
};

/// size of sprite
width: f32,
height: f32,

/// tex-coords of sprite
uv0: Point,
uv1: Point,

/// reference to sprite-sheet
sheet: *SpriteSheet,

/// sprite's drawing params
pub const DrawOption = struct {
    /// position of sprite
    pos: Point,

    /// tint color
    color: [4]f32 = [_]f32{ 1, 1, 1, 1 },

    /// scale of width/height
    scale_w: f32 = 1.0,
    scale_h: f32 = 1.0,

    /// rotation around anchor-point (center by default)
    rotate_degree: f32 = 0,

    /// anchor-point of sprite, around which rotation and translation is calculated
    anchor_point: Point = .{ .x = 0, .y = 0 },
};

/// add vertex data
pub fn appendDrawData(
    self: Self,
    va: *std.ArrayList(f32),
    tr: *std.ArrayList(Mat4),
    opt: DrawOption,
) !void {
    assert(opt.color[0] >= 0 and opt.color[0] <= 1);
    assert(opt.color[1] >= 0 and opt.color[1] <= 1);
    assert(opt.color[2] >= 0 and opt.color[2] <= 1);
    assert(opt.color[3] >= 0 and opt.color[3] <= 1);
    assert(opt.scale_w >= 0 and opt.scale_h >= 0);
    assert(opt.anchor_point.x >= 0 and opt.anchor_point.x <= 1);
    assert(opt.anchor_point.y >= 0 and opt.anchor_point.y <= 1);
    try va.appendSlice(&.{
        -opt.anchor_point.x,    -opt.anchor_point.y,    opt.color[0], opt.color[1], opt.color[2], opt.color[3], self.uv0.x, self.uv0.y,
        -opt.anchor_point.x,    1 - opt.anchor_point.y, opt.color[0], opt.color[1], opt.color[2], opt.color[3], self.uv0.x, self.uv1.y,
        1 - opt.anchor_point.x, 1 - opt.anchor_point.y, opt.color[0], opt.color[1], opt.color[2], opt.color[3], self.uv1.x, self.uv1.y,
        -opt.anchor_point.x,    -opt.anchor_point.y,    opt.color[0], opt.color[1], opt.color[2], opt.color[3], self.uv0.x, self.uv0.y,
        1 - opt.anchor_point.x, 1 - opt.anchor_point.y, opt.color[0], opt.color[1], opt.color[2], opt.color[3], self.uv1.x, self.uv1.y,
        1 - opt.anchor_point.x, -opt.anchor_point.y,    opt.color[0], opt.color[1], opt.color[2], opt.color[3], self.uv1.x, self.uv0.y,
    });
    const mat = Mat4.fromScale(Vec3.new(self.width * opt.scale_w, self.height * opt.scale_h, 1))
        .rotate(opt.rotate_degree, Vec3.forward())
        .translate(Vec3.new(opt.pos.x, opt.pos.y, 0));
    try tr.appendSlice(
        &.{ mat, mat, mat, mat, mat, mat },
    );
}

pub fn flipH(self: *Self) void {
    const old_uv0 = self.uv0;
    const old_uv1 = self.uv1;
    self.uv0.x = old_uv1.x;
    self.uv1.x = old_uv0.x;
}

pub fn flipV(self: *Self) void {
    const old_uv0 = self.uv0;
    const old_uv1 = self.uv1;
    self.uv0.y = old_uv1.y;
    self.uv1.y = old_uv0.y;
}
