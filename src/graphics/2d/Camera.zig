const std = @import("std");
const assert = std.debug.assert;
const zp = @import("../../zplay.zig");
const gfx = zp.graphics;
const Viewport = gfx.gpu.Context.Viewport;
const Camera = gfx.Camera;
const alg = zp.deps.alg;
const Vec3 = alg.Vec3;
const Mat4 = alg.Mat4;
const Self = @This();

/// memory allocator
allocator: std.mem.Allocator,

/// internal generic camera
internal_camera: Camera,

/// position of camera's center
pos_x: f32,
pos_y: f32,

/// size of camera
half_width: f32,
half_height: f32,

/// zoom value
zoom: f32,

pub fn init(
    allocator: std.mem.Allocator,
    center_x: f32,
    center_y: f32,
    half_width: f32,
    half_height: f32,
) !*Self {
    assert(center_x > 0 and center_y > 0);
    assert(half_width > 0 and half_height > 0);
    assert(center_x - half_width >= 0);
    assert(center_y - half_height >= 0);
    var camera = try allocator.create(Self);
    camera.* = .{
        .allocator = allocator,
        .internal_camera = Camera.fromPositionAndTarget(
            .{
                .orthographic = .{
                    .left = center_x - half_width,
                    .right = center_x + half_width,
                    .top = center_y - half_height,
                    .bottom = center_y + half_height,
                    .near = -1,
                    .far = 1,
                },
            },
            Vec3.zero(),
            Vec3.zero(),
            null,
        ),
        .pos_x = center_x,
        .pos_y = center_y,
        .half_width = half_width,
        .half_height = half_height,
        .zoom = 1,
    };
    return camera;
}

pub fn fromViewport(allocator: std.mem.Allocator, vp: Viewport) !*Self {
    return try init(
        allocator,
        @intToFloat(f32, vp.w) / 2,
        @intToFloat(f32, vp.h) / 2,
        @intToFloat(f32, vp.w) / 2,
        @intToFloat(f32, vp.h) / 2,
    );
}

pub fn deinit(self: *Self) void {
    self.allocator.destroy(self);
}

pub fn getCamera(self: *Self) *Camera {
    return &self.internal_camera;
}

pub const MoveOption = struct {
    min_x: f32 = 0,
    min_y: f32 = 0,
    max_x: ?f32 = null,
    max_y: ?f32 = null,
};

pub fn move(self: *Self, tr_x: f32, tr_y: f32, opt: MoveOption) void {
    var frustrum = &self.internal_camera.frustrum.orthographic;

    var move_x: f32 = 0;
    if (tr_x > 0) {
        move_x = if (opt.max_x) |mx|
            std.math.min(tr_x, mx - frustrum.right)
        else
            tr_x;
    } else if (tr_x < 0) {
        move_x = std.math.max(
            tr_x,
            opt.min_x - frustrum.left,
        );
    }

    var move_y: f32 = 0;
    if (tr_y > 0) {
        move_y = if (opt.max_y) |my|
            std.math.min(tr_y, my - frustrum.bottom)
        else
            tr_y;
    } else if (tr_y < 0) {
        move_y = std.math.max(
            tr_y,
            opt.min_y - frustrum.top,
        );
    }

    frustrum.left += move_x;
    frustrum.right += move_x;
    frustrum.bottom += move_y;
    frustrum.top += move_y;
    self.pos_x += move_x;
    self.pos_y += move_y;
}

pub fn setZoom(self: *Self, zoom: f32) void {
    assert(zoom > 0);
    var frustrum = &self.internal_camera.frustrum.orthographic;
    self.zoom = zoom;
    frustrum.left = self.pos_x - self.half_width * zoom;
    frustrum.right = self.pos_x + self.half_width * zoom;
    frustrum.top = self.pos_y - self.half_height * zoom;
    frustrum.bottom = self.pos_y + self.half_height * zoom;
    if (frustrum.left < 0) {
        frustrum.right -= frustrum.left;
        frustrum.left = 0;
    }
    if (frustrum.top < 0) {
        frustrum.bottom -= frustrum.top;
        frustrum.top = 0;
    }
    self.pos_x = (frustrum.left + frustrum.right) / 2;
    self.pos_y = (frustrum.bottom + frustrum.top) / 2;
}
