const std = @import("std");
const alg = @import("lib.zig").alg;
const Vec3 = alg.Vec3;
const Mat4 = alg.Mat4;
const Self = @This();

const MoveDirection = enum {
    forward,
    backward,
    left,
    right,
    up,
    down,
};

/// position of camera
position: Vec3 = undefined,

/// direction of camera
dir: Vec3 = undefined,

/// up of camera
up: Vec3 = undefined,

/// right of camera
right: Vec3 = undefined,

/// euler angle of camera
euler: Vec3 = undefined,

/// create a 3d camera using position and target
pub fn fromPositionAndTarget(pos: Vec3, target: Vec3, world_up: ?Vec3) Self {
    var camera: Self = undefined;
    camera.position = pos;
    camera.dir = target.sub(pos).norm();
    camera.right = camera.dir.cross(world_up orelse Vec3.up()).norm();
    camera.up = camera.right.cross(camera.dir).norm();
    camera.euler = camera.getViewMatrix().extractRotation();
    return camera;
}

/// create a 3d camera using position and euler angle (in degrees)
pub fn fromPositionAndEulerAngles(pos: Vec3, pitch: f32, yaw: f32, world_up: ?Vec3) Self {
    var camera: Self = undefined;
    camera.position = pos;
    camera.up = world_up orelse Vec3.up();
    camera.euler = Vec3.new(pitch, yaw, 0);
    camera._updateVectors();
    return camera;
}

/// get view matrix
pub fn getViewMatrix(self: Self) Mat4 {
    return Mat4.lookAt(self.position, self.position.add(self.dir), self.up);
}

/// move camera
pub fn move(self: *Self, direction: MoveDirection, distance: f32) void {
    var movement = switch (direction) {
        .forward => self.dir.scale(distance),
        .backward => Vec3.zero().sub(self.dir).scale(distance),
        .left => Vec3.zero().sub(self.right).scale(distance),
        .right => self.right.scale(distance),
        .up => self.up.scale(distance),
        .down => Vec3.zero().sub(self.up).scale(distance),
    };
    self.position = self.position.add(movement);
}

/// rotate camera (in degrees)
pub fn rotate(self: *Self, pitch: f32, yaw: f32) void {
    self.euler.x += pitch;
    self.euler.y += yaw;
    self._updateVectors();
}

/// update vectors: direction/right/up
fn _updateVectors(self: *Self) void {
    if (self.euler.x > 89) {
        self.euler.x = 89;
    } else if (self.euler.x < -89) {
        self.euler.x = -89;
    }
    const sin_pitch = std.math.sin(alg.toRadians(self.euler.x));
    const cos_pitch = std.math.cos(alg.toRadians(self.euler.y));
    const sin_yaw = std.math.sin(alg.toRadians(self.euler.y));
    const cos_yaw = std.math.cos(alg.toRadians(self.euler.y));
    self.dir.x = cos_yaw * cos_pitch;
    self.dir.y = sin_pitch;
    self.dir.z = sin_yaw * cos_pitch;
    self.right = self.dir.cross(self.up).norm();
    self.up = self.right.cross(self.dir).norm();
}
