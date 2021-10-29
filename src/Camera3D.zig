const std = @import("std");
const sdl = @import("sdl");
const Context = @import("lib.zig").Context;
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

/// i/o state
last_tick: ?f32 = null,
move_speed: f32 = 2.5,
mouse_sensitivity: f32 = 0.25,
last_mouse_state: sdl.MouseState = undefined,

/// create a 3d camera using position and target
pub fn fromPositionAndTarget(pos: Vec3, target: Vec3, world_up: ?Vec3) Self {
    var camera: Self = .{};
    camera.world_up = world_up orelse Vec3.up();
    camera.position = pos;
    camera.dir = target.sub(pos).norm();
    camera.right = camera.dir.cross(camera.world_up).norm();
    camera.up = camera.right.cross(camera.dir).norm();
    camera.euler = camera.getViewMatrix().extractRotation();
    camera.euler.y -= 90;
    return camera;
}

/// create a 3d camera using position and euler angle (in degrees)
pub fn fromPositionAndEulerAngles(pos: Vec3, pitch: f32, yaw: f32, world_up: ?Vec3) Self {
    var camera: Self = .{};
    camera.world_up = world_up orelse Vec3.up();
    camera.position = pos;
    camera.euler = Vec3.new(pitch, yaw - 90, 0);
    camera._updateVectors();
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
    const cos_pitch = std.math.cos(alg.toRadians(self.euler.x));
    const sin_yaw = std.math.sin(alg.toRadians(self.euler.y));
    const cos_yaw = std.math.cos(alg.toRadians(self.euler.y));
    self.dir.x = cos_yaw * cos_pitch;
    self.dir.y = sin_pitch;
    self.dir.z = sin_yaw * cos_pitch;
    self.dir = self.dir.norm();
    self.right = self.dir.cross(self.world_up).norm();
    self.up = self.right.cross(self.dir).norm();
}

/// update camera according to keyboard/mouse state
pub fn updateInContext(self: *Self, ctx: *Context) void {
    if (self.last_tick == null) {
        self.last_tick = ctx.tick;
        self.last_mouse_state = ctx.getMouseState();
        return;
    }

    // keyboard WSAD movement
    const delta_tick = ctx.tick - self.last_tick.?;
    self.last_tick = ctx.tick;
    const distance = delta_tick * self.move_speed;
    if (ctx.isKeyPressed(.w)) {
        self.move(.forward, distance);
    }
    if (ctx.isKeyPressed(.s)) {
        self.move(.backward, distance);
    }
    if (ctx.isKeyPressed(.a)) {
        self.move(.left, distance);
    }
    if (ctx.isKeyPressed(.d)) {
        self.move(.right, distance);
    }

    // mouse rotation
    const state = ctx.getMouseState();
    const xoffset = @intToFloat(f32, state.x - self.last_mouse_state.x);
    const yoffset = @intToFloat(f32, self.last_mouse_state.y - state.y);
    self.last_mouse_state = state;
    self.rotate(self.mouse_sensitivity * yoffset, self.mouse_sensitivity * xoffset);
}
