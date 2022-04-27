const std = @import("std");
const assert = std.debug.assert;
const zp = @import("../zplay.zig");
const gfx = zp.graphics;
const Context = gfx.gpu.Context;
const VertexArray = gfx.gpu.VertexArray;
const Renderer = gfx.Renderer;
const Camera = gfx.Camera;
const SimpleRenderer = gfx.@"3d".SimpleRenderer;
const Mesh = gfx.@"3d".Mesh;
const Model = gfx.@"3d".Model;
const bt = zp.deps.bt;
const alg = zp.deps.alg;
const Vec2 = alg.Vec2;
const Vec3 = alg.Vec3;
const Vec4 = alg.Vec4;
const Mat4 = alg.Mat4;
const Quat = alg.Quat;
const Self = @This();

const Object = struct {
    shape: bt.Shape,
    body: bt.Body,
    size: Vec3,
};

/// physics world object
world: bt.World,

/// objects in the world
objects: std.ArrayList(Object),

/// internal debug rendering
debug: ?*PhysicsDebug = null,

/// create physics world
pub fn init(allocator: std.mem.Allocator, gravity: ?f32) !Self {
    var self = Self{
        .world = bt.worldCreate(),
        .objects = try std.ArrayList(Object).initCapacity(allocator, 10),
    };
    if (gravity) |g| {
        bt.worldSetGravity(self.world, &Vec3.new(0.0, g, 0.0).toArray());
    }
    return self;
}

/// destroy physics world
pub fn deinit(self: *Self) void {
    for (self.objects.items) |o| {
        bt.worldRemoveBody(self.world, o.body);
        if (bt.shapeGetType(o.shape) == bt.c.CBT_SHAPE_TYPE_TRIANGLE_MESH) {
            bt.shapeTriMeshDestroy(o.shape);
        } else {
            bt.shapeDestroy(o.shape);
        }
        bt.bodyDestroy(o.body);
    }
    self.objects.deinit();
    bt.worldDestroy(self.world);
    if (self.debug) |dbg| dbg.deinit();
}

/// enable physics debug rendering
pub fn enableDebugDraw(self: *Self, allocator: std.mem.Allocator) !void {
    self.debug = try PhysicsDebug.init(allocator, 128000);
    bt.worldDebugSetCallbacks(self.world, &.{
        .drawLine1 = PhysicsDebug.drawLine1Callback,
        .drawLine2 = PhysicsDebug.drawLine2Callback,
        .drawContactPoint = PhysicsDebug.drawContactPointCallback,
        .reportErrorWarning = PhysicsDebug.reportErrorWarningCallback,
        .user_data = self.debug.?,
    });
}

/// get world's gravity
pub fn getGravity(self: Self) Vec3 {
    var gravity: [3]f32 = undefined;
    bt.worldGetGravity(self.world, &gravity);
    return Vec3.fromSlice(&gravity);
}

/// set world's gravity
pub fn setGravity(self: Self, gravity: f32) void {
    bt.worldSetGravity(self.world, &Vec3.new(0.0, gravity, 0.0).toArray());
}

/// add object, return object id
pub const ShapeParam = struct {
    shape: union(enum) {
        predefined_shape: bt.Shape,
        triangle_mesh: Mesh,
    },
    transform: Mat4 = Mat4.identity(),
};
pub const PhysicsParam = struct {
    mass: f32 = 0,
    friction: ?f32 = null,
    linear_damping: f32 = 0.1,
    angular_damping: f32 = 0.1,
};
pub fn addObject(
    self: *Self,
    position: Vec3,
    shapes: []ShapeParam,
    physics_param: PhysicsParam,
) !u32 {
    assert(shapes.len > 0);
    var body: bt.Body = bt.bodyAllocate();
    assert(body != null);
    errdefer bt.bodyDestroy(body);

    // create shapes
    var shape: bt.Shape = undefined;
    if (shapes.len > 1) {
        shape = bt.shapeAllocate(bt.c.CBT_SHAPE_TYPE_COMPOUND);
        bt.shapeCompoundCreate(shape, true, @intCast(c_int, shapes.len));
        var sub_shape: bt.Shape = undefined;
        for (shapes) |s| {
            sub_shape = if (s.shape == .predefined_shape)
                s.shape.predefined_shape
            else blk: {
                assert(physics_param.mass == 0);
                break :blk createTriangleMeshShape(s.shape.triangle_mesh);
            };
            bt.shapeCompoundAddChild(
                shape,
                @ptrCast([*c]const [3]f32, s.transform.getData()),
                sub_shape,
            );
        }
    } else {
        shape = if (shapes[0].shape == .predefined_shape)
            shapes[0].shape.predefined_shape
        else blk: {
            assert(physics_param.mass == 0);
            break :blk createTriangleMeshShape(shapes[0].shape.triangle_mesh);
        };
    }
    errdefer bt.shapeDestroy(shape);

    // get size of shape
    const shape_type = bt.shapeGetType(shape);
    const size = switch (shape_type) {
        bt.c.CBT_SHAPE_TYPE_BOX => blk: {
            var half_extents: bt.Vector3 = undefined;
            bt.shapeBoxGetHalfExtentsWithoutMargin(shape, &half_extents);
            break :blk Vec3.fromSlice(&half_extents);
        },
        bt.c.CBT_SHAPE_TYPE_SPHERE => blk: {
            break :blk Vec3.set(bt.shapeSphereGetRadius(shape));
        },
        bt.c.CBT_SHAPE_TYPE_CONE => blk: {
            assert(bt.shapeConeGetUpAxis(shape) == bt.c.CBT_LINEAR_AXIS_Y);
            const radius = bt.shapeConeGetRadius(shape);
            const height = bt.shapeConeGetHeight(shape);
            break :blk Vec3.new(radius, 0.5 * height, radius);
        },
        bt.c.CBT_SHAPE_TYPE_CYLINDER => blk: {
            var half_extents: bt.Vector3 = undefined;
            assert(bt.shapeCylinderGetUpAxis(shape) == bt.c.CBT_LINEAR_AXIS_Y);
            bt.shapeCylinderGetHalfExtentsWithoutMargin(shape, &half_extents);
            break :blk Vec3.fromSlice(&half_extents);
        },
        bt.c.CBT_SHAPE_TYPE_CAPSULE => blk: {
            assert(bt.shapeCapsuleGetUpAxis(shape) == bt.c.CBT_LINEAR_AXIS_Y);
            const radius = bt.shapeCapsuleGetRadius(shape);
            const half_height = bt.shapeCapsuleGetHalfHeight(shape);
            break :blk Vec3.new(radius, half_height, radius);
        },
        bt.c.CBT_SHAPE_TYPE_TRIANGLE_MESH => Vec3.set(1),
        bt.c.CBT_SHAPE_TYPE_COMPOUND => Vec3.set(1),
        else => blk: {
            assert(false);
            break :blk Vec3.set(1);
        },
    };

    try self.objects.append(.{
        .shape = shape,
        .body = body,
        .size = size,
    });
    bt.bodyCreate(
        body,
        physics_param.mass,
        &bt.convertMat4ToTransform(Mat4.fromTranslate(position)),
        shape,
    );
    if (physics_param.friction) |f| bt.bodySetFriction(body, f);
    bt.bodySetUserIndex(body, 0, @intCast(i32, self.objects.items.len - 1));
    bt.bodySetDamping(body, physics_param.linear_damping, physics_param.angular_damping);
    bt.bodySetActivationState(body, bt.c.CBT_DISABLE_DEACTIVATION);
    bt.worldAddBody(self.world, body);
    return @intCast(u32, self.objects.items.len - 1);
}

/// add object with loaded Model, return object id
pub fn addObjectWithModel(
    self: *Self,
    allocator: std.mem.Allocator,
    position: Vec3,
    model: *Model,
    shape: ?bt.Shape,
    physics_param: PhysicsParam,
) !u32 {
    var shapes = try std.ArrayList(ShapeParam)
        .initCapacity(allocator, model.meshes.items.len);
    defer shapes.deinit();
    if (shape) |s| {
        // predefined collision shape, high performance
        shapes.appendAssumeCapacity(.{
            .shape = .{ .predefined_shape = s },
        });
    } else {
        // use mesh as collision shape, consume more cpu
        for (model.meshes.items) |m, i| {
            shapes.appendAssumeCapacity(.{
                .shape = .{ .triangle_mesh = m },
                .transform = model.transforms.items[i],
            });
        }
    }
    return self.addObject(position, shapes.items, physics_param);
}

fn createTriangleMeshShape(mesh: Mesh) bt.Shape {
    assert(mesh.primitive_type == .triangles);
    var shape = bt.shapeAllocate(bt.c.CBT_SHAPE_TYPE_TRIANGLE_MESH);
    bt.shapeTriMeshCreateBegin(shape);
    bt.shapeTriMeshAddIndexVertexArray(
        shape,
        @intCast(i32, mesh.indices.items.len / 3),
        mesh.indices.items.ptr,
        3 * @sizeOf(u32),
        @intCast(i32, mesh.positions.items.len / 3),
        mesh.positions.items.ptr,
        @sizeOf(f32) * 3,
    );
    bt.shapeTriMeshCreateEnd(shape);
    return shape;
}

/// remove object, memory will be leaved as it is
pub fn removeObject(self: Self, id: u32) void {
    const obj = self.objects.items[id];
    bt.worldRemoveBody(self.world, obj.body);
}

/// clear all object
pub fn removeAllObjects(self: *Self) void {
    for (self.objects.items) |o| {
        bt.shapeDestroy(self.world, o.shape);
        bt.worldRemoveBody(self.world, o.body);
        bt.bodyDestroy(o.body);
    }
    self.objects.resize(0) catch unreachable;
}

/// get object's transformation matrix in physics world
pub fn getTransformation(self: Self, id: u32) Mat4 {
    var tr: bt.Transform = undefined;
    const obj = self.objects.items[id];
    bt.bodyGetGraphicsWorldTransform(obj.body, &tr);
    return bt.convertTransformToMat4(tr).mul(Mat4.fromScale(obj.size));
}

/// set object's friction
pub fn setFriction(self: Self, id: u32, friction: f32) f32 {
    const obj = self.objects.items[id];
    return bt.bodySetFriction(obj.body, friction);
}

/// get object's friction
pub fn getFriction(self: Self, id: u32) f32 {
    const obj = self.objects.items[id];
    return bt.bodyGetFriction(obj.body);
}

/// ray-test for intersected object
pub fn getRayTestResult(self: Self, from: Vec3, to: Vec3) ?u32 {
    var result: bt.RayCastResult = undefined;
    var hit = bt.rayTestClosest(
        self.world,
        &from.toArray(),
        &to.toArray(),
        bt.c.CBT_COLLISION_FILTER_DEFAULT,
        bt.c.CBT_COLLISION_FILTER_ALL,
        bt.c.CBT_RAYCAST_FLAG_USE_USE_GJK_CONVEX_TEST,
        &result,
    );
    return if (hit and result.body != null)
        @intCast(u32, bt.bodyGetUserIndex(result.body, 0))
    else
        null;
}

/// update world
pub const UpdateOption = struct {
    delta_time: f32 = 0, // passed time
};
pub fn update(self: Self, option: UpdateOption) void {
    _ = bt.worldStepSimulation(self.world, option.delta_time, 1, 1.0 / 60.0);
}

/// draw debug lines
pub fn debugDraw(self: Self, ctx: *Context, camera: *Camera, line_width: f32) void {
    if (self.debug) |dbg| {
        dbg.clear();
        for (self.objects.items) |obj| {
            var linear_velocity: bt.Vector3 = undefined;
            var angular_velocity: bt.Vector3 = undefined;
            var position: bt.Vector3 = undefined;
            bt.bodyGetLinearVelocity(obj.body, &linear_velocity);
            bt.bodyGetAngularVelocity(obj.body, &angular_velocity);
            bt.bodyGetCenterOfMassPosition(obj.body, &position);
            const p1_linear = Vec3.fromSlice(&position).add(Vec3.fromSlice(&linear_velocity));
            const p1_angular = Vec3.fromSlice(&position).add(Vec3.fromSlice(&angular_velocity));
            const color_linear = bt.Vector3{ 1.0, 0.0, 1.0 };
            const color_angular = bt.Vector3{ 0.0, 1.0, 1.0 };
            bt.worldDebugDrawLine1(self.world, &position, &p1_linear.toArray(), &color_linear);
            bt.worldDebugDrawLine1(self.world, &position, &p1_angular.toArray(), &color_angular);
        }
        bt.worldDebugDraw(self.world);
        dbg.render(ctx, camera, line_width);
    }
}

/// debug draw
const PhysicsDebug = struct {
    allocator: std.mem.Allocator,
    max_vertex_num: u32,
    vertex_array: VertexArray,
    render_data: Renderer.Input,
    positions: std.ArrayList(f32),
    colors: std.ArrayList(f32),
    renderer: SimpleRenderer,

    fn init(allocator: std.mem.Allocator, max_vertex_num: u32) !*PhysicsDebug {
        var debug = try allocator.create(PhysicsDebug);
        debug.allocator = allocator;
        debug.max_vertex_num = max_vertex_num;
        debug.vertex_array = VertexArray.init(allocator, 2);
        debug.vertex_array.vbos[0].allocData(max_vertex_num * @sizeOf(Vec3), .dynamic_draw);
        debug.vertex_array.vbos[1].allocData(max_vertex_num * @sizeOf(Vec4), .dynamic_draw);
        debug.render_data = try Renderer.Input.init(
            allocator,
            &[_]Renderer.Input.VertexData{
                .{
                    .element_draw = false,
                    .vertex_array = debug.vertex_array,
                    .primitive = .lines,
                    .count = 0,
                },
            },
            null,
            null,
            null,
        );
        debug.positions = try std.ArrayList(f32).initCapacity(allocator, 10);
        debug.colors = try std.ArrayList(f32).initCapacity(allocator, 10);
        debug.renderer = SimpleRenderer.init(.{ .mix_factor = 1.0 });

        debug.vertex_array.use();
        defer debug.vertex_array.disuse();
        debug.vertex_array.setAttribute(
            0,
            @enumToInt(Mesh.AttribLocation.position),
            3,
            f32,
            false,
            0,
            0,
        );
        debug.vertex_array.setAttribute(
            1,
            @enumToInt(Mesh.AttribLocation.color),
            4,
            f32,
            false,
            0,
            0,
        );
        return debug;
    }

    fn deinit(debug: *PhysicsDebug) void {
        debug.renderer.deinit();
        debug.positions.deinit();
        debug.colors.deinit();
        debug.render_data.deinit();
        debug.vertex_array.deinit();
        debug.allocator.destroy(debug);
    }

    fn clear(debug: *PhysicsDebug) void {
        debug.positions.clearRetainingCapacity();
        debug.colors.clearRetainingCapacity();
    }

    fn render(debug: *PhysicsDebug, ctx: *Context, camera: *Camera, line_width: f32) void {
        if (debug.positions.items.len == 0) return;

        // upload vertex data
        assert(debug.positions.items.len <= debug.max_vertex_num);
        debug.vertex_array.vbos[0].updateData(0, f32, debug.positions.items);
        debug.vertex_array.vbos[1].updateData(0, f32, debug.colors.items);
        debug.render_data.camera = camera;
        debug.render_data.vds.?.items[0].count =
            @intCast(u32, debug.positions.items.len / 3);

        var old_line_width = ctx.line_width;
        ctx.setLineWidth(line_width);
        var old_depth_test_status = ctx.isCapabilityEnabled(.depth_test);
        ctx.toggleCapability(.depth_test, false);
        var old_stencil_test_status = ctx.isCapabilityEnabled(.stencil_test);
        ctx.toggleCapability(.stencil_test, false);

        defer {
            debug.clear();
            ctx.setLineWidth(old_line_width);
            ctx.toggleCapability(.depth_test, old_depth_test_status);
            ctx.toggleCapability(.stencil_test, old_stencil_test_status);
        }

        // render the lines
        debug.renderer.draw(ctx, debug.render_data) catch unreachable;
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
