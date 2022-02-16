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
physics_debug: *PhysicsDebug,

// scene update option
pub const Option = struct {
    rd: Renderer,
};

// init a empty scene
pub fn init(allocator: std.mem.Allocator) !Self {
    return Self{
        .world = bt.worldCreate(),
        .objects = std.ArrayList(Object).init(allocator),
        .physics_debug = try allocator.create(PhysicsDebug),
    };
}

/// update world
pub fn update(option: Option) void {
    _ = option;
}

const PhysicsDebug = struct {
    positions: std.ArrayList(f32),
    colors: std.ArrayList(f32),
    vertex_array: VertexArray,
    simple_renderer: SimpleRenderer,

    fn init(allocator: std.mem.Allocator) PhysicsDebug {
        var debug = PhysicsDebug{
            .positions = std.ArrayList(f32).init(allocator),
            .colors = std.ArrayList(f32).init(allocator),
            .vertex_array = VertexArray.init(allocator, 2),
            .simple_renderer = SimpleRenderer.init(.{}),
        };
        debug.simple_renderer.mix_factor = 1.0;
        debug.vertex_array.vbos[0].allocData(100 * @sizeOf(Vec3), .stream_draw);
        debug.vertex_array.vbos[1].allocData(100 * @sizeOf(Vec4), .stream_draw);

        debug.vertex_array.use();
        defer debug.vertex_array.disuse();
        debug.vertex_array.setAttribute(
            0,
            @enumToInt(Renderer.AttribLocation.position),
            3,
            f32,
            false,
            0,
            0,
        );
        debug.vertex_array.setAttribute(
            1,
            @enumToInt(Renderer.AttribLocation.color),
            4,
            f32,
            false,
            0,
            0,
        );
        return debug;
    }

    fn deinit(debug: *PhysicsDebug) void {
        debug.positions.deinit();
        debug.colors.deinit();
        debug.vertex_array.deinit();
        debug.simple_renderer.deinit();
        debug.* = undefined;
    }

    fn render(debug: *PhysicsDebug, camera: Camera, projection: Mat4) void {
        if (debug.positions.items.len == 0) return;

        debug.vertex_array.vbos[0].updateData(0, f32, debug.positions.items);
        debug.vertex_array.vbos[1].updateData(0, f32, debug.colors.items);

        var rd = debug.simple_renderer.renderer();
        rd.begin(false);
        defer rd.end();

        rd.render(
            debug.vertex_array,
            false,
            .lines,
            0,
            @intCast(u32, debug.positions.items.len / 3),
            Mat4.identity(),
            projection,
            camera,
            null,
        ) catch unreachable;

        debug.positions.resize(0) catch unreachable;
        debug.colors.resize(0) catch unreachable;
    }

    fn drawLine1(debug: *PhysicsDebug, p0: Vec3, p1: Vec3, color: Vec4) void {
        debug.positions.appendSlice(&p0.toArray()) catch unreachable;
        debug.positions.appendSlice(&p1.toArray()) catch unreachable;
        debug.colors.appendSlice(&color.toArray()) catch unreachable;
        debug.colors.appendSlice(&color.toArray()) catch unreachable;
    }

    fn drawLine2(debug: *PhysicsDebug, p0: Vec3, p1: Vec3, color0: Vec4, color1: Vec4) void {
        debug.positions.appendSlice(&p0.toArray()) catch unreachable;
        debug.positions.appendSlice(&p1.toArray()) catch unreachable;
        debug.colors.appendSlice(&color0.toArray()) catch unreachable;
        debug.colors.appendSlice(&color1.toArray()) catch unreachable;
    }

    fn drawContactPoint(debug: *PhysicsDebug, point: Vec3, normal: Vec3, distance: f32, color: Vec4) void {
        debug.drawLine1(point, point.add(normal.scale(distance)), color);
        debug.drawLine1(point, point.add(normal.scale(0.01)), Vec4.zero());
    }

    fn drawLine1Callback(p0: [*c]const f32, p1: [*c]const f32, color: [*c]const f32, user: ?*anyopaque) callconv(.C) void {
        const ptr = @ptrCast(*PhysicsDebug, @alignCast(@alignOf(PhysicsDebug), user.?));
        ptr.drawLine1(
            Vec3.new(p0[0], p0[1], p0[2]),
            Vec3.new(p1[0], p1[1], p1[2]),
            Vec4.new(color[0], color[1], color[2], 1.0),
        );
    }

    fn drawLine2Callback(
        p0: [*c]const f32,
        p1: [*c]const f32,
        color0: [*c]const f32,
        color1: [*c]const f32,
        user: ?*anyopaque,
    ) callconv(.C) void {
        const ptr = @ptrCast(*PhysicsDebug, @alignCast(@alignOf(PhysicsDebug), user.?));
        ptr.drawLine2(
            Vec3.new(p0[0], p0[1], p0[2]),
            Vec3.new(p1[0], p1[1], p1[2]),
            Vec4.new(color0[0], color0[1], color0[2], 1),
            Vec4.new(color1[0], color1[1], color1[2], 1),
        );
    }

    fn drawContactPointCallback(
        point: [*c]const f32,
        normal: [*c]const f32,
        distance: f32,
        _: c_int,
        color: [*c]const f32,
        user: ?*anyopaque,
    ) callconv(.C) void {
        const ptr = @ptrCast(*PhysicsDebug, @alignCast(@alignOf(PhysicsDebug), user.?));
        ptr.drawContactPoint(
            Vec3.new(point[0], point[1], point[2]),
            Vec3.new(normal[0], normal[1], normal[2]),
            distance,
            Vec4.new(color[0], color[1], color[2], 1.0),
        );
    }

    fn reportErrorWarningCallback(str: [*c]const u8, _: ?*anyopaque) callconv(.C) void {
        std.log.info("{s}", .{str});
    }
};
