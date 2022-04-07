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

/// position of sprite
pos: Point,

/// size of sprite
width: f32,
height: f32,

/// tex-coords of sprite
uv0: Point,
uv1: Point,

/// scale of width/height
scale_w: f32 = 1.0,
scale_h: f32 = 1.0,

/// rotation around anchor-point (center by default)
rotate_degree: f32 = 0,

/// anchor-point of sprite, around which rotation and translation is calculated
anchor_point: Point = .{ .x = 0, .y = 0 },

/// reference to sprite-sheet
sheet: *SpriteSheet,

pub fn appendDrawData(self: Self, color: [4]f32, depth: f32, va: *std.ArrayList(f32), tr: *std.ArrayList(Mat4)) !void {
    assert(self.anchor_point.x >= 0 and self.anchor_point.x <= 1);
    assert(self.anchor_point.y >= 0 and self.anchor_point.y <= 1);
    try va.appendSlice(&.{
        -self.anchor_point.x,    -self.anchor_point.y,    depth, color[0], color[1], color[2], color[3], self.uv0.x, self.uv0.y,
        -self.anchor_point.x,    1 - self.anchor_point.y, depth, color[0], color[1], color[2], color[3], self.uv0.x, self.uv1.y,
        1 - self.anchor_point.x, 1 - self.anchor_point.y, depth, color[0], color[1], color[2], color[3], self.uv1.x, self.uv1.y,
        -self.anchor_point.x,    -self.anchor_point.y,    depth, color[0], color[1], color[2], color[3], self.uv0.x, self.uv0.y,
        1 - self.anchor_point.x, 1 - self.anchor_point.y, depth, color[0], color[1], color[2], color[3], self.uv1.x, self.uv1.y,
        1 - self.anchor_point.x, -self.anchor_point.y,    depth, color[0], color[1], color[2], color[3], self.uv1.x, self.uv0.y,
    });
    const mat = Mat4.fromScale(Vec3.new(self.width * self.scale_w, self.height * self.scale_h, 1))
        .rotate(self.rotate_degree, Vec3.back())
        .translate(Vec3.new(self.pos.x, self.pos.y, 0));
    try tr.appendSlice(
        &.{ mat, mat, mat, mat, mat, mat },
    );
}

pub fn setAnchorPoint(self: *Self, anchor: Point) void {
    self.anchor_point = anchor;
}

pub fn moveTo(self: *Self, pos: Point) void {
    self.pos = pos;
}

pub fn moveBy(self: *Self, pos_rel: Point) void {
    self.pos.x += pos_rel.x;
    self.pos.y += pos_rel.y;
}

pub fn rotate(self: *Self, degree: f32) void {
    self.rotate_degree = degree;
}

pub fn scale(self: *Self, scale_w: f32, scale_h: f32) void {
    self.scale_w = scale_w;
    self.scale_h = scale_h;
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
