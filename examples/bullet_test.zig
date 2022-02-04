const std = @import("std");
const assert = std.debug.assert;
const zp = @import("zplay");
const dig = zp.deps.dig;
const alg = zp.deps.alg;
const bt = zp.deps.bt;
const Vec3 = alg.Vec3;
const Vec4 = alg.Vec4;
const Mat4 = alg.Mat4;
const VertexArray = zp.graphics.common.VertexArray;
const Texture2D = zp.graphics.texture.Texture2D;
const Renderer = zp.graphics.@"3d".Renderer;
const SimpleRenderer = zp.graphics.@"3d".SimpleRenderer;
const PhongRenderer = zp.graphics.@"3d".PhongRenderer;
const Light = zp.graphics.@"3d".Light;
const Model = zp.graphics.@"3d".Model;
const Material = zp.graphics.@"3d".Material;
const Camera = zp.graphics.@"3d".Camera;

var simple_renderer: SimpleRenderer = undefined;
var phong_renderer: PhongRenderer = undefined;
var color_material: Material = undefined;
var wireframe_mode = false;
var scene: Scene = undefined;
var enable_msaa = false;
var camera = Camera.fromPositionAndTarget(
    Vec3.new(5, 10, 25),
    Vec3.new(-4, 8, 0),
    null,
);

fn init(ctx: *zp.Context) anyerror!void {
    std.log.info("game init", .{});

    // init imgui
    try dig.init(ctx.window);

    // create renderer
    simple_renderer = SimpleRenderer.init();
    phong_renderer = PhongRenderer.init(std.testing.allocator);
    phong_renderer.setDirLight(Light.init(.{
        .directional = .{
            .ambient = Vec3.new(0.8, 0.8, 0.8),
            .diffuse = Vec3.new(0.5, 0.5, 0.3),
            .specular = Vec3.new(0.1, 0.1, 0.1),
            .direction = Vec3.new(-1, -1, 0),
        },
    }));

    // init color_material
    color_material = Material.init(.{
        .single_texture = try Texture2D.fromPixelData(
            std.testing.allocator,
            &.{ 0, 255, 0 },
            3,
            1,
            1,
            .{},
        ),
    });

    // create scene
    scene = try Scene.init(std.testing.allocator, ctx);

    // graphics init
    ctx.graphics.toggleCapability(.depth_test, true);
    ctx.graphics.toggleCapability(.stencil_test, true);
    ctx.graphics.toggleCapability(.multisample, enable_msaa);
}

fn loop(ctx: *zp.Context) void {
    // camera movement
    const distance = ctx.delta_tick * camera.move_speed;
    if (ctx.isKeyPressed(.w)) {
        camera.move(.forward, distance);
    }
    if (ctx.isKeyPressed(.s)) {
        camera.move(.backward, distance);
    }
    if (ctx.isKeyPressed(.a)) {
        camera.move(.left, distance);
    }
    if (ctx.isKeyPressed(.d)) {
        camera.move(.right, distance);
    }
    if (ctx.isKeyPressed(.left)) {
        camera.rotate(0, -1);
    }
    if (ctx.isKeyPressed(.right)) {
        camera.rotate(0, 1);
    }
    if (ctx.isKeyPressed(.up)) {
        camera.rotate(1, 0);
    }
    if (ctx.isKeyPressed(.down)) {
        camera.rotate(-1, 0);
    }

    while (ctx.pollEvent()) |e| {
        switch (e) {
            .window_event => |we| {
                switch (we.data) {
                    .resized => |size| {
                        ctx.graphics.setViewport(0, 0, size.width, size.height);
                    },
                    else => {},
                }
            },
            .keyboard_event => |key| {
                if (key.trigger_type == .up) {
                    switch (key.scan_code) {
                        .escape => ctx.kill(),
                        .f1 => ctx.toggleFullscreeen(null),
                        else => {},
                    }
                }
            },
            .quit_event => ctx.kill(),
            else => {},
        }
    }

    var width: u32 = undefined;
    var height: u32 = undefined;
    ctx.graphics.getDrawableSize(ctx.window, &width, &height);
    ctx.graphics.clear(true, true, true, [_]f32{ 0.2, 0.3, 0.3, 1.0 });

    // render world
    var rd = phong_renderer.renderer();
    rd.begin(false);
    scene.update(ctx, rd) catch unreachable;
    rd.end();

    // settings
    dig.beginFrame();
    {
        dig.setNextWindowPos(
            .{ .x = @intToFloat(f32, width) - 10, .y = 50 },
            .{
                .cond = dig.c.ImGuiCond_Always,
                .pivot = .{ .x = 1, .y = 0 },
            },
        );
        if (dig.begin(
            "settings",
            null,
            dig.c.ImGuiWindowFlags_NoResize |
                dig.c.ImGuiWindowFlags_AlwaysAutoResize,
        )) {
            if (dig.checkbox("wireframe", &wireframe_mode)) {
                ctx.graphics.setPolygonMode(if (wireframe_mode) .line else .fill);
            }
            if (dig.checkbox("msaa", &enable_msaa)) {
                ctx.graphics.toggleCapability(.multisample, enable_msaa);
            }
        }
        dig.end();
    }
    dig.endFrame();
}

const Scene = struct {
    const Object = struct {
        model: Model,
        body: bt.Body,
        size: Vec3 = undefined,
    };
    const default_linear_damping: f32 = 0.1;
    const default_angular_damping: f32 = 0.1;
    const default_world_friction: f32 = 0.15;

    world: bt.World,
    objs: std.ArrayList(Object),
    physics_debug: *PhysicsDebug,

    fn init(allocator: std.mem.Allocator, ctx: *zp.Context) !Scene {
        var width: u32 = undefined;
        var height: u32 = undefined;
        ctx.graphics.getDrawableSize(ctx.window, &width, &height);

        var self = Scene{
            .world = bt.worldCreate(),
            .objs = std.ArrayList(Object).init(allocator),
            .physics_debug = try allocator.create(PhysicsDebug),
        };
        bt.worldSetGravity(self.world, &Vec3.new(0.0, -10.0, 0.0).toArray());

        // physics debug draw
        self.physics_debug.* = PhysicsDebug.init(allocator);
        bt.worldDebugSetCallbacks(self.world, &.{
            .drawLine1 = PhysicsDebug.drawLine1Callback,
            .drawLine2 = PhysicsDebug.drawLine2Callback,
            .drawContactPoint = PhysicsDebug.drawContactPointCallback,
            .reportErrorWarning = PhysicsDebug.reportErrorWarningCallback,
            .user_data = self.physics_debug,
        });

        // init/add objects
        var room = Object{
            .model = try Model.fromGLTF(
                allocator,
                "assets/world.gltf",
                false,
                try Texture2D.fromPixelData(
                    allocator,
                    &.{ 128, 128, 128 },
                    3,
                    1,
                    1,
                    .{},
                ),
            ),
            .body = bt.bodyAllocate(),
        };
        var shape = bt.shapeAllocate(bt.c.CBT_SHAPE_TYPE_TRIANGLE_MESH);
        bt.shapeTriMeshCreateBegin(shape);
        bt.shapeTriMeshAddIndexVertexArray(
            shape,
            @intCast(i32, room.model.meshes.items[0].indices.items.len / 3),
            room.model.meshes.items[0].indices.items.ptr,
            3 * @sizeOf(u32),
            @intCast(i32, room.model.meshes.items[0].positions.items.len / 3),
            room.model.meshes.items[0].positions.items.ptr,
            @sizeOf(f32) * 3,
        );
        bt.shapeTriMeshCreateEnd(shape);
        try self.addBodyToWorld(&room, 0, shape, Vec3.zero());
        bt.bodySetFriction(room.body, default_world_friction);

        var capsule = Object{
            .model = try Model.fromGLTF(
                allocator,
                "assets/capsule.gltf",
                false,
                null,
            ),
            .body = bt.bodyAllocate(),
        };
        shape = bt.shapeAllocate(bt.c.CBT_SHAPE_TYPE_CAPSULE);
        bt.shapeCapsuleCreate(shape, 1, 2, bt.c.CBT_LINEAR_AXIS_Y);
        try self.addBodyToWorld(&capsule, 30, shape, Vec3.new(-5, 12, -2));

        var cylinder = Object{
            .model = try Model.fromGLTF(
                allocator,
                "assets/cylinder.gltf",
                false,
                null,
            ),
            .body = bt.bodyAllocate(),
        };
        shape = bt.shapeAllocate(bt.c.CBT_SHAPE_TYPE_CYLINDER);
        bt.shapeCylinderCreate(shape, &Vec3.new(1.5, 2.0, 1.5).toArray(), bt.c.CBT_LINEAR_AXIS_Y);
        try self.addBodyToWorld(&cylinder, 60, shape, Vec3.new(-5, 10, -2));

        var cube = Object{
            .model = try Model.fromGLTF(
                allocator,
                "assets/cube.gltf",
                false,
                null,
            ),
            .body = bt.bodyAllocate(),
        };
        shape = bt.shapeAllocate(bt.c.CBT_SHAPE_TYPE_BOX);
        bt.shapeBoxCreate(shape, &Vec3.new(0.5, 1.0, 2.0).toArray());
        try self.addBodyToWorld(&cube, 50, shape, Vec3.new(-5, 8, -2));

        var cone = Object{
            .model = try Model.fromGLTF(
                allocator,
                "assets/cone.gltf",
                false,
                null,
            ),
            .body = bt.bodyAllocate(),
        };
        shape = bt.shapeAllocate(bt.c.CBT_SHAPE_TYPE_CONE);
        bt.shapeConeCreate(shape, 1.0, 2.0, bt.c.CBT_LINEAR_AXIS_Y);
        try self.addBodyToWorld(&cone, 15, shape, Vec3.new(-5, 5, -2));

        var sphere = Object{
            .model = try Model.fromGLTF(
                allocator,
                "assets/sphere.gltf",
                false,
                null,
            ),
            .body = bt.bodyAllocate(),
        };
        shape = bt.shapeAllocate(bt.c.CBT_SHAPE_TYPE_SPHERE);
        bt.shapeSphereCreate(shape, 1.5);
        try self.addBodyToWorld(&sphere, 25, shape, Vec3.new(-5, 3, -2));

        // allocate texture units
        var unit: i32 = 0;
        for (self.objs.items) |obj| {
            for (obj.model.materials.items) |m| {
                unit = m.allocTextureUnit(unit);
            }
        }
        _ = color_material.allocTextureUnit(unit);

        return self;
    }

    fn addBodyToWorld(self: *Scene, obj: *Object, mass: f32, shape: bt.Shape, position: Vec3) !void {
        const shape_type = bt.shapeGetType(shape);
        obj.size = switch (shape_type) {
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
                assert(radius == 1.0 and height == 2.0);
                break :blk Vec3.new(radius, 0.5 * height, radius);
            },
            bt.c.CBT_SHAPE_TYPE_CYLINDER => blk: {
                var half_extents: bt.Vector3 = undefined;
                assert(bt.shapeCylinderGetUpAxis(shape) == bt.c.CBT_LINEAR_AXIS_Y);
                bt.shapeCylinderGetHalfExtentsWithoutMargin(shape, &half_extents);
                assert(half_extents[0] == half_extents[2]);
                break :blk Vec3.fromSlice(&half_extents);
            },
            bt.c.CBT_SHAPE_TYPE_CAPSULE => blk: {
                assert(bt.shapeCapsuleGetUpAxis(shape) == bt.c.CBT_LINEAR_AXIS_Y);
                const radius = bt.shapeCapsuleGetRadius(shape);
                const half_height = bt.shapeCapsuleGetHalfHeight(shape);
                assert(radius == 1.0 and half_height == 1.0);
                break :blk Vec3.new(radius, half_height, radius);
            },
            bt.c.CBT_SHAPE_TYPE_TRIANGLE_MESH => Vec3.set(1),
            bt.c.CBT_SHAPE_TYPE_COMPOUND => Vec3.set(1),
            else => blk: {
                assert(false);
                break :blk Vec3.set(1);
            },
        };
        try self.objs.append(obj.*);
        bt.bodyCreate(
            obj.body,
            mass,
            &bt.convertMat4ToTransform(Mat4.fromTranslate(position)),
            shape,
        );

        bt.bodySetUserIndex(obj.body, 0, @intCast(i32, self.objs.items.len - 1));
        bt.bodySetDamping(obj.body, default_linear_damping, default_angular_damping);
        bt.bodySetActivationState(obj.body, bt.c.CBT_DISABLE_DEACTIVATION);
        bt.worldAddBody(self.world, obj.body);
    }

    fn update(self: Scene, ctx: *zp.Context, rd: Renderer) !void {
        var width: u32 = undefined;
        var height: u32 = undefined;
        ctx.graphics.getDrawableSize(ctx.window, &width, &height);
        const mouse_state = ctx.getMouseState();

        // calc projection matrix
        const projection = Mat4.perspective(
            camera.zoom,
            @intToFloat(f32, width) / @intToFloat(f32, height),
            0.1,
            1000,
        );

        // update physical world
        _ = bt.worldStepSimulation(self.world, ctx.delta_tick, 1, 1.0 / 60.0);

        // get selected object
        var result: bt.RayCastResult = undefined;
        var ray_target = camera.getRayTestTarget(
            width,
            height,
            @intCast(u32, mouse_state.x),
            @intCast(u32, mouse_state.y),
        );
        var hit_idx: u32 = undefined;
        var hit = bt.rayTestClosest(
            self.world,
            &camera.position.toArray(),
            &ray_target.toArray(),
            bt.c.CBT_COLLISION_FILTER_DEFAULT,
            bt.c.CBT_COLLISION_FILTER_ALL,
            bt.c.CBT_RAYCAST_FLAG_USE_USE_GJK_CONVEX_TEST,
            &result,
        );
        if (hit and result.body != null) {
            hit_idx = @intCast(u32, bt.bodyGetUserIndex(result.body, 0));
            if (hit_idx == 0) hit = false;
        }

        // render objects
        for (self.objs.items) |obj, idx| {
            // draw debug lines
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

            // draw object, highlight selected object
            var tr: bt.Transform = undefined;
            bt.bodyGetGraphicsWorldTransform(obj.body, &tr);
            if (hit and hit_idx == idx) {
                ctx.graphics.setStencilOption(.{
                    .test_func = .always,
                    .test_ref = 1,
                    .action_dppass = .replace,
                });
            }
            try obj.model.render(
                rd,
                bt.convertTransformToMat4(tr).mult(Mat4.fromScale(obj.size)),
                projection,
                camera,
                null,
            );
            if (hit and hit_idx == idx) {
                ctx.graphics.setStencilOption(.{
                    .test_func = .not_equal,
                    .test_ref = 1,
                });
                simple_renderer.renderer().begin(false);
                defer rd.begin(false);
                try obj.model.render(
                    simple_renderer.renderer(),
                    bt.convertTransformToMat4(tr)
                        .mult(Mat4.fromScale(Vec3.set(1.05)))
                        .mult(Mat4.fromScale(obj.size)),
                    projection,
                    camera,
                    color_material,
                );
            }
        }

        // render physical debug
        bt.worldDebugDraw(self.world);
        var old_line_width = ctx.graphics.line_width;
        ctx.graphics.setLineWidth(5);
        self.physics_debug.render(projection);
        ctx.graphics.setLineWidth(old_line_width);
    }
};

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
            .simple_renderer = SimpleRenderer.init(),
        };
        debug.simple_renderer.mix_factor = 1.0;
        debug.vertex_array.vbos[0].allocData(100 * @sizeOf(Vec3), .stream_draw);
        debug.vertex_array.vbos[1].allocData(100 * @sizeOf(Vec4), .stream_draw);

        debug.vertex_array.use();
        defer debug.vertex_array.disuse();
        debug.vertex_array.setAttribute(
            0,
            Renderer.ATTRIB_LOCATION_POS,
            3,
            f32,
            false,
            0,
            0,
        );
        debug.vertex_array.setAttribute(
            1,
            Renderer.ATTRIB_LOCATION_COLOR,
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

    fn render(debug: *PhysicsDebug, projection: Mat4) void {
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

fn quit(ctx: *zp.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
}

pub fn main() anyerror!void {
    try zp.run(.{
        .initFn = init,
        .loopFn = loop,
        .quitFn = quit,
        .enable_maximized = true,
        .enable_msaa = true,
    });
}
