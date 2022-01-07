const std = @import("std");
const math = std.math;
const zp = @import("../../zplay.zig");
const alg = zp.deps.alg;
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

/// up vector of the world
world_up: Vec3 = undefined,

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
temp_angle: f32 = undefined,

/// i/o state
move_speed: f32 = 2.5,
mouse_sensitivity: f32 = 0.25,
zoom: f32 = 45.0,

/// create a 3d camera using position and target
pub fn fromPositionAndTarget(pos: Vec3, target: Vec3, world_up: ?Vec3) Self {
    var camera: Self = .{};
    camera.world_up = world_up orelse Vec3.up();
    camera.position = pos;
    camera.dir = target.sub(pos).norm();
    camera.right = camera.dir.cross(camera.world_up).norm();
    camera.up = camera.right.cross(camera.dir).norm();

    // calculate euler angles
    var crossdir = Vec3.cross(camera.world_up, camera.up);
    if (Vec3.dot(crossdir, camera.right) < 0) {
        camera.euler.x = -Vec3.getAngle(camera.world_up, camera.up);
    } else {
        camera.euler.x = Vec3.getAngle(camera.world_up, camera.up);
    }
    crossdir = Vec3.cross(camera.right, Vec3.right());
    if (Vec3.dot(crossdir, camera.world_up) < 0) {
        camera.euler.y = -Vec3.getAngle(camera.right, Vec3.right()) - 90;
    } else {
        camera.euler.y = Vec3.getAngle(camera.right, Vec3.right()) - 90;
    }
    camera.euler.z = 0;
    return camera;
}

/// create a 3d camera using position and euler angle (in degrees)
pub fn fromPositionAndEulerAngles(pos: Vec3, pitch: f32, yaw: f32, world_up: ?Vec3) Self {
    var camera: Self = .{};
    camera.world_up = world_up orelse Vec3.up();
    camera.position = pos;
    camera.euler = Vec3.new(pitch, yaw - 90, 0);
    camera.updateVectors();
    return camera;
}

/// get view matrix
pub fn getViewMatrix(self: Self) Mat4 {
    return Mat4.lookAt(self.position, self.position.add(self.dir), self.world_up);
}

/// move camera
pub fn move(self: *Self, direction: MoveDirection, distance: f32) void {
    var movement = switch (direction) {
        .forward => self.dir.scale(distance),
        .backward => self.dir.scale(-distance),
        .left => self.right.scale(-distance),
        .right => self.right.scale(distance),
        .up => self.up.scale(distance),
        .down => self.up.scale(-distance),
    };
    self.position = self.position.add(movement);
}

/// rotate camera (in degrees)
pub fn rotate(self: *Self, pitch: f32, yaw: f32) void {
    self.euler.x += pitch;
    self.euler.y += yaw;
    self.updateVectors();
}

/// update vectors: direction/right/up
fn updateVectors(self: *Self) void {
    self.euler.x = math.clamp(self.euler.x, -89, 89);
    const sin_pitch = math.sin(alg.toRadians(self.euler.x));
    const cos_pitch = math.cos(alg.toRadians(self.euler.x));
    const sin_yaw = math.sin(alg.toRadians(self.euler.y));
    const cos_yaw = math.cos(alg.toRadians(self.euler.y));
    self.dir.x = cos_yaw * cos_pitch;
    self.dir.y = sin_pitch;
    self.dir.z = sin_yaw * cos_pitch;
    self.dir = self.dir.norm();
    self.right = self.dir.cross(self.world_up).norm();
    self.up = self.right.cross(self.dir).norm();
}

/// get position of ray test target
/// NOTE: assuming mouse's coordinate is relative to top-left corner of viewport
pub fn getRayTestTarget(
    self: Self,
    viewport_w: u32,
    viewport_h: u32,
    mouse_x: u32,
    mouse_y: u32,
) Vec3 {
    const far_plane: f32 = 10000.0;
    const tanfov = math.tan(0.5 * alg.toRadians(self.zoom));
    const width = @intToFloat(f32, viewport_w);
    const height = @intToFloat(f32, viewport_h);
    const aspect = width / height;

    const ray_forward = self.dir.scale(far_plane);
    const hor = self.right.scale(2.0 * far_plane * tanfov * aspect);
    const vertical = self.up.scale(2.0 * far_plane * tanfov);

    const ray_to_center = self.position.add(ray_forward);
    const dhor = hor.scale(1.0 / width);
    const dvert = vertical.scale(1.0 / height);

    var ray_to = ray_to_center.sub(hor.scale(0.5)).sub(vertical.scale(0.5));
    ray_to = ray_to.add(dhor.scale(@intToFloat(f32, mouse_x)));
    ray_to = ray_to.add(dvert.scale(@intToFloat(f32, viewport_h - mouse_y)));
    return ray_to;
}
