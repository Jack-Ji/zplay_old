const std = @import("std");
const assert = std.debug.assert;
const Model = @import("Model");
const SimpleRenderer = @import("SimpleRenderer.zig");
const zp = @import("../../zplay.zig");
const gfx = zp.graphics;
const VertexArray = gfx.gpu.VertexArray;
const Texture = gfx.gpu.Texture;
const Renderer = gfx.Renderer;
const Camera = gfx.Camera;
const Material = gfx.Material;
const bt = zp.deps.bt;
const alg = zp.deps.alg;
const Vec2 = alg.Vec2;
const Vec3 = alg.Vec3;
const Vec4 = alg.Vec4;
const Mat4 = alg.Mat4;
const Quat = alg.Quat;
const Self = @This();

const Object = struct {
    model: Model,
    body: bt.Body,
    size: Vec3 = undefined,
};

const default_linear_damping: f32 = 0.1;
const default_angular_damping: f32 = 0.1;
const default_world_friction: f32 = 0.15;

// physics world object
world: bt.World,

// objects in the world
objects: std.ArrayList(Object),

// internal debug info rendering
//physics_debug: *PhysicsDebug,

// scene update option
pub const Option = struct {
    rd: Renderer,
};

// init a empty scene
pub fn init(allocator: std.mem.Allocator) !Self {
    return Self{
        .world = bt.worldCreate(),
        .objects = std.ArrayList(Object).init(allocator),
        //.physics_debug = try allocator.create(PhysicsDebug),
    };
}

/// update world
pub fn update(option: Option) void {
    _ = option;
}
