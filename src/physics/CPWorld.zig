const std = @import("std");
const assert = std.debug.assert;
const zp = @import("../zplay.zig");
const gfx = zp.graphics;
const Context = gfx.gpu.Context;
const VertexArray = gfx.gpu.VertexArray;
const Renderer = gfx.Renderer;
const Camera = gfx.Camera;
const alg = zp.deps.alg;
const cp = zp.deps.cp;
const Vec2 = alg.Vec2;
const Vec3 = alg.Vec3;
const Vec4 = alg.Vec4;
const Mat4 = alg.Mat4;
const Quat = alg.Quat;
const Self = @This();

pub const Error = error{
    OutOfMemory,
};

pub const Filter = struct {
    group: usize = 0,
    categories: u32 = ~@as(u32, 0),
    mask: u32 = ~@as(u32, 0),
};

pub const Object = struct {
    /// object's physics body, null means using global static
    body: ?*cp.Body,

    /// object's shape
    shapes: []*cp.Shape,

    /// filter info
    filter: Filter,
};

/// memory allocator
allocator: std.mem.Allocator,

/// physics world object
space: *cp.Space,

/// objects in the world
objects: std.ArrayList(Object),

/// init chipmunk world
pub const CollisionCallback = struct {
    type_a: ?cp.CollisionType = null,
    type_b: ?cp.CollisionType = null,
    begin_func: cp.CollisionBeginFunc = null,
    pre_solve_func: cp.CollisionPreSolveFunc = null,
    post_solve_func: cp.CollisionPostSolveFunc = null,
    separate_func: cp.CollisionSeparateFunc = null,
    user_data: cp.DataPointer = null,
};
pub const InitOption = struct {
    gravity: cp.Vect = .{ .x = 0, .y = 10 },
    dumping: f32 = 0,
    iteration: u32 = 10,
    user_data: cp.DataPointer = null,
    collision_callbacks: []CollisionCallback = &.{},
    prealloc_objects_num: u32 = 100,
};
pub fn init(allocator: std.mem.Allocator, opt: InitOption) !Self {
    var space = cp.spaceNew();
    if (space == null) return error.OutOfMemory;

    cp.spaceSetGravity(space, opt.gravity);
    cp.spaceSetDamping(space, opt.dumping);
    cp.spaceSetIterations(space, @intCast(c_int, opt.iteration));
    cp.spaceSetUserData(space, opt.user_data);
    for (opt.collision_callbacks) |cb| {
        var handler: *cp.CollisionHandler = undefined;
        if (cb.type_a != null and cb.type_b != null) {
            handler = cp.spaceAddCollisionHandler(space, cb.type_a.?, cb.type_b.?);
        } else if (cb.type_a != null) {
            handler = cp.spaceAddWildcardHandler(space, cb.type_a.?);
        } else {
            handler = cp.spaceAddDefaultCollisionHandler(space);
        }
        handler.beginFunc = cb.begin_func;
        handler.preSolveFunc = cb.pre_solve_func;
        handler.postSolveFunc = cb.post_solve_func;
        handler.separateFunc = cb.separate_func;
        handler.userData = cb.user_data;
    }

    return Self{
        .allocator = allocator,
        .space = space.?,
        .objects = try std.ArrayList(Object).initCapacity(
            allocator,
            opt.prealloc_objects_num,
        ),
    };
}

pub fn deinit(self: Self) void {
    cp.spaceEachShape(self.space, postShapeFree, self.space);
    cp.spaceEachConstraint(self.space, postConstraintFree, self.space);
    cp.spaceEachBody(self.space, postBodyFree, self.space);
    cp.spaceFree(self.space);
    for (self.objects.items) |o| {
        self.allocator.free(o.shapes);
    }
    self.objects.deinit();
}

fn shapeFree(space: ?*cp.Space, shape: ?*anyopaque, unused: ?*anyopaque) callconv(.C) void {
    _ = unused;
    cp.spaceRemoveShape(space, @ptrCast(?*cp.Shape, shape));
    cp.shapeFree(shape);
}

fn postShapeFree(shape: ?*cp.Shape, user_data: ?*anyopaque) callconv(.C) void {
    _ = cp.spaceAddPostStepCallback(
        @ptrCast(?*cp.Space, user_data),
        shapeFree,
        shape,
        null,
    );
}

fn constraintFree(space: ?*cp.Space, constraint: ?*anyopaque, unused: ?*anyopaque) callconv(.C) void {
    _ = unused;
    cp.spaceRemoveConstraint(space, @ptrCast(?*cp.Constraint, constraint));
    cp.constraintFree(constraint);
}

fn postConstraintFree(constraint: ?*cp.Constraint, user_data: ?*anyopaque) callconv(.C) void {
    _ = cp.spaceAddPostStepCallback(
        @ptrCast(?*cp.Space, user_data),
        constraintFree,
        constraint,
        null,
    );
}

fn bodyFree(space: ?*cp.Space, body: ?*anyopaque, unused: ?*anyopaque) callconv(.C) void {
    _ = unused;
    cp.spaceRemoveBody(space, @ptrCast(?*cp.Body, body));
    cp.bodyFree(body);
}

fn postBodyFree(body: ?*cp.Body, user_data: ?*anyopaque) callconv(.C) void {
    _ = cp.spaceAddPostStepCallback(
        @ptrCast(?*cp.Space, user_data),
        bodyFree,
        body,
        null,
    );
}

/// add object to world
pub const ObjectOption = struct {
    pub const BodyProperty = union(enum) {
        dynamic: struct {
            position: cp.Vect,
            velocity: cp.Vect = cp.vzero,
            angular_velocity: f32 = 0,
        },
        kinematic: struct {
            position: cp.Vect,
            velocity: cp.Vect = cp.vzero,
            angular_velocity: f32 = 0,
        },
        static: ?struct {
            position: cp.Vect,
        },
    };
    pub const ShapeProperty = union(enum) {
        pub const Weight = union(enum) {
            mass: f32,
            density: f32,
        };
        pub const Physics = struct {
            weight: Weight = .{ .mass = 0 },
            elasticity: f32 = 0,
            friction: f32 = 0.7,
            is_sensor: bool = false,
        };

        segment: struct {
            a: cp.Vect,
            b: cp.Vect,
            radius: f32 = 0,
            physics: Physics = .{},
        },
        box: struct {
            left: f32,
            right: f32,
            top: f32,
            bottom: f32,
            radius: f32 = 0,
            physics: Physics = .{},
        },
        circle: struct {
            radius: f32,
            offset: cp.Vect = cp.vzero,
            physics: Physics = .{},
        },
        polygon: struct {
            points: []cp.Vert,
            transform: cp.Transform = cp.transformIdentity,
            radius: f32 = 0,
            physics: Physics = .{},
        },
    };

    body: BodyProperty,
    shapes: ShapeProperty,
    filter: Filter = .{},
    user_data: ?*anyopaque = null,
};
pub fn addObject(self: Self, opt: ObjectOption) !u32 {
    assert(opt.shapes.len > 0);

    // create physics body
    var use_global_static = false;
    var body: *cp.Body = switch (opt.body) {
        .dynamic => |prop| blk: {
            var bd: *cp.Body = cp.bodyNew(0, 0).?;
            cp.bodySetPosition(bd, prop.position);
            cp.bodySetVelocity(bd, prop.velocity);
            cp.bodySetAngularVelocity(bd, prop.angular_velocity);
            break :blk bd.?;
        },
        .kinematic => |prop| blk: {
            var bd: *cp.Body = cp.bodyNewKinematic(0, 0).?;
            cp.bodySetPosition(bd, prop.position);
            cp.bodySetVelocity(bd, prop.velocity);
            cp.bodySetAngularVelocity(bd, prop.angular_velocity);
            break :blk bd.?;
        },
        .static => |prop| blk: {
            var bd: *cp.Body = undefined;
            if (prop == null) {
                bd = cp.spaceGetStaticBody(self.space);
                use_global_static = true;
            } else {
                bd = cp.bodyNewStatic(self.space).?;
                cp.bodySetPosition(bd, prop.position);
            }
            break :blk bd.?;
        },
    };
    if (!use_global_static) _ = cp.spaceAddBody(self.space, body);
    errdefer {
        cp.spaceRemoveBody(body);
        cp.bodyFree(body);
    }

    // create shapes
    var shapes = try self.allocator.alloc(*cp.Shape, opt.shapes.len);
    for (opt.shapes) |s, i| {
        shapes[i] = switch (s) {
            .segment => |prop| blk: {
                var shape = cp.segmentShapeNew(body, prop.a, prop.b, prop.radius).?;
                initPhysicsOfShape(shape, prop.physics);
                break :blk shape;
            },
            .box => |prop| blk: {
                var shape = cp.boxShapeNew2(body, .{
                    .l = prop.left,
                    .b = prop.bottom,
                    .r = prop.right,
                    .t = prop.top,
                }, prop.radius).?;
                initPhysicsOfShape(shape, prop.physics);
                break :blk shape;
            },
            .circle => |prop| blk: {
                var shape = cp.circleShapeNew(body, prop.radius, prop.offset);
                initPhysicsOfShape(shape, prop.physics);
                break :blk shape;
            },
            .polygon => |prop| blk: {
                var shape = cp.polyShapeNew(
                    body,
                    @intCast(c_int, prop.points.len),
                    prop.points.ptr,
                    prop.transform,
                    prop.radius,
                );
                initPhysicsOfShape(shape, prop.physics);
                break :blk shape;
            },
        };
        cp.shapeSetFilter(shapes[i], .{
            .group = @intCast(usize, opt.filter.group),
            .categories = @intCast(c_uint, opt.filter.categories),
            .mask = @intCast(c_uint, opt.filter.mask),
        });
    }
    errdefer {
        for (shapes) |s| {
            cp.spaceRemoveShape(self.space, s);
            cp.shapeFree(s);
        }
        self.allocator.free(shapes);
    }

    // append to object array
    try self.objects.append(.{
        .body = if (use_global_static) null else body,
        .shapes = shapes,
        .filter = opt.filter,
    });

    // set user data of body/shapes, equal to
    // index/id of object by default.
    var ud = opt.user_data orelse @intToPtr(
        *allowzero anyopaque,
        self.objects.items.len - 1,
    );
    if (!use_global_static) {
        cp.bodySetUserData(body, ud);
    }
    for (shapes) |s| {
        cp.shapeSetUserData(s, ud);
    }

    return self.objects.items.len - 1;
}

fn initPhysicsOfShape(shape: *cp.Shape, phy: ObjectOption.ShapeProperty.Physics) void {
    switch (phy.weight) {
        .mass => |m| cp.shapeSetMass(shape, m),
        .density => |d| cp.shapeSetDensity(shape, d),
    }
    cp.shapeSetElasticity(shape, phy.elasticity);
    cp.shapeSetFriction(shape, phy.friction);
    cp.shapeSetSensor(shape, @as(u8, @boolToInt(phy.is_sensor)));
}

/// update world
pub fn update(self: Self, delta_tick: f32) void {
    cp.spaceStep(self.space, delta_tick);
}

/// debug draw
pub fn debugDraw(self: Self) void {
    _ = self;
}
