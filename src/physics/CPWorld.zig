const std = @import("std");
const assert = std.debug.assert;
const zp = @import("../zplay.zig");
const gfx = zp.graphics;
const Context = gfx.gpu.Context;
const drawcall = gfx.gpu.drawcall;
const ShaderProgram = gfx.gpu.ShaderProgram;
const VertexArray = gfx.gpu.VertexArray;
const Buffer = gfx.gpu.Buffer;
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

/// timing
fixed_dt: f32,
accumulator: f32,

/// physics world object
space: *cp.Space,

/// objects in the world
objects: std.ArrayList(Object),

/// internal debug rendering
debug: ?*PhysicsDebug = null,

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
    fixed_dt: f32 = 1.0 / 60.0,
    gravity: cp.Vect = cp.vzero,
    dumping: f32 = 0,
    iteration: u32 = 10,
    user_data: cp.DataPointer = null,
    collision_callbacks: []CollisionCallback = &.{},
    prealloc_objects_num: u32 = 100,
    enable_debug_draw: bool = true,
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

    var self = Self{
        .allocator = allocator,
        .fixed_dt = opt.fixed_dt,
        .accumulator = 0,
        .space = space.?,
        .objects = try std.ArrayList(Object).initCapacity(
            allocator,
            opt.prealloc_objects_num,
        ),
    };
    if (opt.enable_debug_draw) {
        self.debug = try PhysicsDebug.init(allocator, 64000);
    }

    return self;
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
    if (self.debug) |dbg| dbg.deinit();
}

fn shapeFree(space: ?*cp.Space, shape: ?*anyopaque, unused: ?*anyopaque) callconv(.C) void {
    _ = unused;
    cp.spaceRemoveShape(space, @ptrCast(?*cp.Shape, shape));
    cp.shapeFree(@ptrCast(?*cp.Shape, shape));
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
    cp.constraintFree(@ptrCast(?*cp.Constraint, constraint));
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
    cp.bodyFree(@ptrCast(?*cp.Body, body));
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
        static: struct {
            position: cp.Vect,
        },
        global_static: u8,
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
            radius: f32 = 1,
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
            points: []cp.Vect,
            transform: cp.Transform = cp.transformIdentity,
            radius: f32 = 0,
            physics: Physics = .{},
        },
    };

    body: BodyProperty = .{.global_static},
    shapes: []const ShapeProperty,
    filter: Filter = .{},
    user_data: ?*anyopaque = null,
};
pub fn addObject(self: *Self, opt: ObjectOption) !u32 {
    assert(opt.shapes.len > 0);

    // create physics body
    var use_global_static = false;
    var body = switch (opt.body) {
        .dynamic => |prop| blk: {
            var bd = cp.bodyNew(0, 0).?;
            cp.bodySetPosition(bd, prop.position);
            cp.bodySetVelocity(bd, prop.velocity);
            cp.bodySetAngularVelocity(bd, prop.angular_velocity);
            break :blk bd;
        },
        .kinematic => |prop| blk: {
            var bd = cp.bodyNewKinematic().?;
            cp.bodySetPosition(bd, prop.position);
            cp.bodySetVelocity(bd, prop.velocity);
            cp.bodySetAngularVelocity(bd, prop.angular_velocity);
            break :blk bd;
        },
        .static => |prop| blk: {
            var bd = cp.bodyNewStatic().?;
            cp.bodySetPosition(bd, prop.position);
            break :blk bd;
        },
        .global_static => blk: {
            var bd = cp.spaceGetStaticBody(self.space).?;
            use_global_static = true;
            break :blk bd;
        },
    };
    if (opt.body != .global_static) {
        _ = cp.spaceAddBody(self.space, body);
    }
    errdefer {
        cp.spaceRemoveBody(self.space, body);
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
                assert(opt.body != .global_static);
                var shape = cp.circleShapeNew(body, prop.radius, prop.offset).?;
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
                ).?;
                initPhysicsOfShape(shape, prop.physics);
                break :blk shape;
            },
        };
        _ = cp.spaceAddShape(self.space, shapes[i]);
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

    return @intCast(u32, self.objects.items.len - 1);
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
pub fn update(self: *Self, delta_tick: f32) void {
    self.accumulator += delta_tick;
    while (self.accumulator > self.fixed_dt) : (self.accumulator -= self.fixed_dt) {
        cp.spaceStep(self.space, self.fixed_dt);
    }
}

/// debug draw
pub fn debugDraw(self: Self, gctx: *Context, camera: ?*Camera) void {
    if (self.debug) |dbg| {
        dbg.clear();
        cp.spaceDebugDraw(self.space, &dbg.space_draw_option);
        dbg.render(gctx, camera);
    }
}

/// debug draw
const PhysicsDebug = struct {
    const draw_alpha = 0.8;

    allocator: std.mem.Allocator,
    max_vertex_num: u32,
    max_index_num: u32,
    vattribs: std.ArrayList(f32),
    vindices: std.ArrayList(u32),
    program: ShaderProgram,
    vertex_array: VertexArray,
    space_draw_option: cp.SpaceDebugDrawOptions,

    fn init(allocator: std.mem.Allocator, max_vertex_num: u32) !*PhysicsDebug {
        var debug = try allocator.create(PhysicsDebug);

        // basic setup
        debug.allocator = allocator;
        debug.max_vertex_num = max_vertex_num;
        debug.max_index_num = max_vertex_num * 4;
        debug.vattribs = std.ArrayList(f32).initCapacity(allocator, 1000) catch unreachable;
        debug.vindices = std.ArrayList(u32).initCapacity(allocator, 1000) catch unreachable;

        // create shader
        debug.program = ShaderProgram.init(
            Renderer.shader_head ++
                \\layout(location = 0) in vec2 a_pos;
                \\layout(location = 1) in vec2 a_uv;
                \\layout(location = 2) in float a_radius;
                \\layout(location = 3) in vec4 a_fill;
                \\layout(location = 4) in vec4 a_outline;
                \\
                \\uniform mat4 u_vp_matrix;
                \\out struct {
                \\    vec2 uv;
                \\    vec4 fill;
                \\    vec4 outline;
                \\} FRAG;
                \\
                \\void main() {
                \\    gl_Position = u_vp_matrix * vec4(a_pos + a_radius * a_uv, 0, 1);
                \\    FRAG.uv = a_uv;
                \\    FRAG.fill = a_fill;
                \\    FRAG.outline = a_outline;
                \\}
            ,
            Renderer.shader_head ++
                \\out vec4 frag_color;
                \\
                \\in struct {
                \\    vec2 uv;
                \\    vec4 fill;
                \\    vec4 outline;
                \\} FRAG;
                \\
                \\void main() {
                \\    float len = length(FRAG.uv);
                \\    float fw = length(fwidth(FRAG.uv));
                \\    float mask = smoothstep(-1, fw - 1, -len);
                \\    float outline = 1 - fw;
                \\    float outline_mask = smoothstep(outline - fw, outline, len);
                \\    vec4 color = FRAG.fill + (FRAG.outline - FRAG.fill * FRAG.outline.a) * outline_mask;
                \\    frag_color = color*mask;
                \\}
            ,
            null,
        );

        // create and init vertex array
        debug.vertex_array = VertexArray.init(allocator, 2);
        debug.vertex_array.vbos[0].allocData(debug.max_vertex_num * 13 * @sizeOf(f32), .dynamic_draw);
        debug.vertex_array.vbos[1].allocData(debug.max_index_num * @sizeOf(u32), .dynamic_draw);
        debug.vertex_array.use();
        debug.vertex_array.setAttribute(0, 0, 2, f32, false, 13 * @sizeOf(f32), 0);
        debug.vertex_array.setAttribute(0, 1, 2, f32, false, 13 * @sizeOf(f32), 2 * @sizeOf(f32));
        debug.vertex_array.setAttribute(0, 2, 1, f32, false, 13 * @sizeOf(f32), 4 * @sizeOf(f32));
        debug.vertex_array.setAttribute(0, 3, 4, f32, false, 13 * @sizeOf(f32), 5 * @sizeOf(f32));
        debug.vertex_array.setAttribute(0, 4, 4, f32, false, 13 * @sizeOf(f32), 9 * @sizeOf(f32));
        Buffer.Target.element_array_buffer.setBinding(
            debug.vertex_array.vbos[1].id,
        );
        debug.vertex_array.disuse();
        Buffer.Target.element_array_buffer.setBinding(0);

        // init chipmunk debug draw option
        debug.space_draw_option = .{
            .drawCircle = drawCircle,
            .drawSegment = drawSegment,
            .drawFatSegment = drawFatSegment,
            .drawPolygon = drawPolygon,
            .drawDot = drawDot,
            .flags = cp.c.CP_SPACE_DEBUG_DRAW_SHAPES | cp.c.CP_SPACE_DEBUG_DRAW_CONSTRAINTS | cp.c.CP_SPACE_DEBUG_DRAW_COLLISION_POINTS,
            .shapeOutlineColor = .{
                .r = @intToFloat(f32, 0xee) / 255.0,
                .g = @intToFloat(f32, 0xe8) / 255.0,
                .b = @intToFloat(f32, 0xd5) / 255.0,
                .a = draw_alpha,
            }, // outline color
            .colorForShape = drawColorForShape,
            .constraintColor = .{ .r = 0, .g = 0.75, .b = 0, .a = draw_alpha }, // constraint color
            .collisionPointColor = .{ .r = 1, .g = 0, .b = 0, .a = draw_alpha }, // collision color
            .data = debug,
        };
        return debug;
    }

    fn deinit(debug: *PhysicsDebug) void {
        debug.vattribs.deinit();
        debug.vindices.deinit();
        debug.program.deinit();
        debug.vertex_array.deinit();
        debug.allocator.destroy(debug);
    }

    fn clear(debug: *PhysicsDebug) void {
        debug.vattribs.clearRetainingCapacity();
        debug.vindices.clearRetainingCapacity();
    }

    fn render(debug: *PhysicsDebug, gctx: *Context, camera: ?*Camera) void {
        if (debug.vindices.items.len == 0) return;

        // upload vertex data
        assert(debug.vattribs.items.len / 13 <= debug.max_vertex_num);
        assert(debug.vindices.items.len <= debug.max_vertex_num * 4);
        debug.vertex_array.vbos[0].updateData(0, f32, debug.vattribs.items);
        debug.vertex_array.vbos[1].updateData(0, u32, debug.vindices.items);

        // send draw command
        debug.program.use();
        defer debug.program.disuse();
        debug.vertex_array.use();
        defer debug.vertex_array.disuse();
        debug.program.setUniformByName("u_vp_matrix", if (camera) |c|
            c.getProjectMatrix()
        else blk: {
            var width: u32 = undefined;
            var height: u32 = undefined;
            gctx.getDrawableSize(&width, &height);
            var mat = Mat4.orthographic(0, @intToFloat(f32, width), @intToFloat(f32, height), 0, -1, 1);
            break :blk mat;
        });
        drawcall.drawElements(.triangles, 0, @intCast(u32, debug.vindices.items.len), u32);
    }

    fn pushVertexes(debug: *PhysicsDebug, vcount: u32, indices: []const u32) []f32 {
        assert((@intCast(u32, debug.vattribs.items.len) + vcount) / 13 <= debug.max_vertex_num);
        assert(@intCast(u32, debug.vindices.items.len) + indices.len <= debug.max_index_num);
        const base = @intCast(u32, debug.vattribs.items.len / 13);
        debug.vattribs.resize(debug.vattribs.items.len + @intCast(usize, vcount) * 13) catch unreachable;
        for (indices) |i| {
            debug.vindices.append(i + base) catch unreachable;
        }
        return debug.vattribs.items[debug.vattribs.items.len - @intCast(usize, vcount) * 13 ..];
    }

    fn setVertexAttrib(
        vs: []f32,
        index: u32,
        pos_x: f32,
        pos_y: f32,
        u: f32,
        v: f32,
        radius: f32,
        fill_color: cp.SpaceDebugColor,
        outline_color: cp.SpaceDebugColor,
    ) void {
        const i = index * 13;
        assert(i + 13 <= @intCast(u32, vs.len));
        vs[i] = pos_x;
        vs[i + 1] = pos_y;
        vs[i + 2] = u;
        vs[i + 3] = v;
        vs[i + 4] = radius;
        vs[i + 5] = fill_color.r;
        vs[i + 6] = fill_color.g;
        vs[i + 7] = fill_color.b;
        vs[i + 8] = fill_color.a;
        vs[i + 9] = outline_color.r;
        vs[i + 10] = outline_color.g;
        vs[i + 11] = outline_color.b;
        vs[i + 12] = outline_color.a;
    }

    fn drawCircle(
        pos: cp.Vect,
        angle: cp.Float,
        radius: cp.Float,
        outline_color: cp.SpaceDebugColor,
        fill_color: cp.SpaceDebugColor,
        data: cp.DataPointer,
    ) callconv(.C) void {
        var debug = @ptrCast(*PhysicsDebug, @alignCast(@alignOf(*PhysicsDebug), data));
        const vs = debug.pushVertexes(4, &[_]u32{ 0, 1, 2, 0, 2, 3 });
        const pos_x = @floatCast(f32, pos.x);
        const pos_y = @floatCast(f32, pos.y);
        const r = @floatCast(f32, radius);
        setVertexAttrib(vs, 0, pos_x, pos_y, -1, -1, r, fill_color, outline_color);
        setVertexAttrib(vs, 1, pos_x, pos_y, -1, 1, r, fill_color, outline_color);
        setVertexAttrib(vs, 2, pos_x, pos_y, 1, 1, r, fill_color, outline_color);
        setVertexAttrib(vs, 3, pos_x, pos_y, 1, -1, r, fill_color, outline_color);

        drawSegment(
            pos,
            cp.vadd(pos, cp.vmult(cp.vforangle(angle), 0.75 * radius)),
            outline_color,
            data,
        );
    }

    fn drawSegment(
        a: cp.Vect,
        b: cp.Vect,
        color: cp.SpaceDebugColor,
        data: cp.DataPointer,
    ) callconv(.C) void {
        drawFatSegment(a, b, 0, color, color, data);
    }

    fn drawFatSegment(
        a: cp.Vect,
        b: cp.Vect,
        radius: cp.Float,
        outline_color: cp.SpaceDebugColor,
        fill_color: cp.SpaceDebugColor,
        data: cp.DataPointer,
    ) callconv(.C) void {
        var debug = @ptrCast(*PhysicsDebug, @alignCast(@alignOf(*PhysicsDebug), data));
        const vs = debug.pushVertexes(8, &[_]u32{ 0, 1, 2, 1, 2, 3, 2, 3, 4, 3, 4, 5, 4, 5, 6, 5, 6, 7 });
        const a_pos_x = @floatCast(f32, a.x);
        const a_pos_y = @floatCast(f32, a.y);
        const b_pos_x = @floatCast(f32, b.x);
        const b_pos_y = @floatCast(f32, b.y);
        const t = cp.vnormalize(cp.vsub(b, a));
        const t_u = @floatCast(f32, t.x);
        const t_v = @floatCast(f32, t.y);
        const r = @floatCast(f32, radius);
        setVertexAttrib(vs, 0, a_pos_x, a_pos_y, -t_u + t_v, -t_u - t_v, r, fill_color, outline_color);
        setVertexAttrib(vs, 1, a_pos_x, a_pos_y, -t_u - t_v, t_u - t_v, r, fill_color, outline_color);
        setVertexAttrib(vs, 2, a_pos_x, a_pos_y, -0 + t_v, -t_u + 0, r, fill_color, outline_color);
        setVertexAttrib(vs, 3, a_pos_x, a_pos_y, -0 - t_v, t_u + 0, r, fill_color, outline_color);
        setVertexAttrib(vs, 4, b_pos_x, b_pos_y, 0 + t_v, -t_u - 0, r, fill_color, outline_color);
        setVertexAttrib(vs, 5, b_pos_x, b_pos_y, 0 - t_v, t_u - 0, r, fill_color, outline_color);
        setVertexAttrib(vs, 6, b_pos_x, b_pos_y, t_u + t_v, -t_u + t_v, r, fill_color, outline_color);
        setVertexAttrib(vs, 7, b_pos_x, b_pos_y, t_u - t_v, t_u + t_v, r, fill_color, outline_color);
    }

    fn drawPolygon(
        count: c_int,
        verts: [*c]const cp.Vect,
        radius: cp.Float,
        outline_color: cp.SpaceDebugColor,
        fill_color: cp.SpaceDebugColor,
        data: cp.DataPointer,
    ) callconv(.C) void {
        _ = count;
        _ = verts;
        _ = radius;
        _ = outline_color;
        _ = fill_color;
        _ = data;
    }

    fn drawDot(
        size: cp.Float,
        pos: cp.Vect,
        color: cp.SpaceDebugColor,
        data: cp.DataPointer,
    ) callconv(.C) void {
        _ = size;
        _ = pos;
        _ = color;
        _ = data;
    }

    fn drawColorForShape(
        shape: ?*cp.Shape,
        data: cp.DataPointer,
    ) callconv(.C) cp.SpaceDebugColor {
        _ = data;
        if (cp.shapeGetSensor(shape) == 1) {
            return .{ .r = 1, .g = 1, .b = 1, .a = 1 };
        } else {
            var body = cp.shapeGetBody(shape);
            if (cp.bodyIsSleeping(body) == 1) {
                return .{
                    .r = @intToFloat(f32, 0x58) / 255.0,
                    .g = @intToFloat(f32, 0x6e) / 255.0,
                    .b = @intToFloat(f32, 0x75) / 255.0,
                    .a = draw_alpha,
                };
            } else {
                return .{
                    .r = 1,
                    .g = 1,
                    .b = 0,
                    .a = draw_alpha,
                };
            }
        }
    }
};
