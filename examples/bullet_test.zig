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

var phong_renderer: PhongRenderer = undefined;
var wireframe_mode = false;
var scene: Scene = undefined;
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
    phong_renderer = PhongRenderer.init(std.testing.allocator);
    phong_renderer.setDirLight(Light.init(.{
        .directional = .{
            .ambient = Vec3.new(0.8, 0.8, 0.8),
            .diffuse = Vec3.new(0.5, 0.5, 0.3),
            .specular = Vec3.new(0.1, 0.1, 0.1),
            .direction = Vec3.new(-1, -1, 0),
        },
    }));

    // create scene
    scene = try Scene.init(std.testing.allocator, ctx);

    // toggle depth test
    ctx.graphics.toggleCapability(.depth_test, true);
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
    rd.begin();
    scene.update(ctx, rd) catch unreachable;
    rd.end();

    // settings
    dig.beginFrame();
    {
        dig.setNextWindowPos(
            .{ .x = @intToFloat(f32, width) - 10, .y = 50 },
            .{
                .cond = dig.c.ImGuiCond_Once,
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
    projection: Mat4,
    physics_debug: *PhysicsDebug,

    fn init(allocator: std.mem.Allocator, ctx: *zp.Context) !Scene {
        var width: u32 = undefined;
        var height: u32 = undefined;
        ctx.graphics.getDrawableSize(ctx.window, &width, &height);

        var self = Scene{
            .world = bt.worldCreate(),
            .objs = std.ArrayList(Object).init(allocator),
            .projection = alg.Mat4.perspective(
                camera.zoom,
                @intToFloat(f32, width) / @intToFloat(f32, height),
                0.1,
                1000,
            ),
            .physics_debug = try std.testing.allocator.create(PhysicsDebug),
        };
        bt.worldSetGravity(self.world, &Vec3.new(0.0, -10.0, 0.0).toArray());

        // physics debug draw
        self.physics_debug.* = PhysicsDebug.init(std.testing.allocator);
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
                    &.{ 128, 128, 128, 255 },
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
            @intCast(i32, room.model.meshes.items[0].indices.?.items.len / 3),
            room.model.meshes.items[0].indices.?.items.ptr,
            3 * @sizeOf(u32),
            @intCast(i32, room.model.meshes.items[0].positions.items.len),
            room.model.meshes.items[0].positions.items.ptr,
            @sizeOf(Vec3),
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

        return self;
    }

    fn addBodyToWorld(self: *Scene, obj: *Object, mass: f32, shape: bt.Shape, position: Vec3) !void {
        const shape_type = bt.shapeGetType(shape);
        const mesh_size = switch (shape_type) {
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

        obj.size = mesh_size;
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
        // update physical world
        _ = bt.worldStepSimulation(self.world, ctx.delta_tick, 1, 1.0 / 60.0);

        // render objects
        for (self.objs.items) |obj| {
            var tr: bt.Transform = undefined;
            bt.bodyGetGraphicsWorldTransform(obj.body, &tr);

            try obj.model.render(
                rd,
                bt.convertTransformToMat4(tr).mult(Mat4.fromScale(obj.size)),
                self.projection,
                camera,
                null,
                null,
            );
        }

        // render physical debug
        bt.worldDebugDraw(self.world);
        self.physics_debug.render(self.projection);
    }
};

const PhysicsDebug = struct {
    positions: std.ArrayList(Vec3),
    colors: std.ArrayList(Vec4),
    vertex_array: VertexArray,
    simple_renderer: SimpleRenderer,

    fn init(allocator: std.mem.Allocator) PhysicsDebug {
        var debug = PhysicsDebug{
            .positions = std.ArrayList(Vec3).init(allocator),
            .colors = std.ArrayList(Vec4).init(allocator),
            .vertex_array = VertexArray.init(2),
            .simple_renderer = SimpleRenderer.init(),
        };

        debug.vertex_array.use();
        defer debug.vertex_array.disuse();
        debug.vertex_array.setAttribute(
            0,
            SimpleRenderer.ATTRIB_LOCATION_POS,
            3,
            f32,
            false,
            0,
            0,
        );
        debug.vertex_array.setAttribute(
            1,
            SimpleRenderer.ATTRIB_LOCATION_COLOR,
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

        debug.vertex_array.bufferData(0, Vec3, debug.positions.items, .array_buffer, .stream_draw);
        debug.vertex_array.bufferData(1, Vec4, debug.colors.items, .array_buffer, .stream_draw);

        var rd = debug.simple_renderer.renderer();
        rd.begin();
        defer rd.end();

        rd.render(
            debug.vertex_array,
            false,
            .lines,
            0,
            @intCast(u32, debug.positions.items.len),
            Mat4.identity(),
            projection,
            camera,
            null,
            null,
        ) catch unreachable;

        debug.positions.resize(0) catch unreachable;
        debug.colors.resize(0) catch unreachable;
    }

    fn drawLine1(debug: *PhysicsDebug, p0: Vec3, p1: Vec3, color: Vec4) void {
        debug.positions.appendSlice(&.{ p0, p1 }) catch unreachable;
        debug.colors.appendSlice(&.{ color, color }) catch unreachable;
    }

    fn drawLine2(debug: *PhysicsDebug, p0: Vec3, p1: Vec3, color0: Vec4, color1: Vec4) void {
        debug.positions.appendSlice(&.{ p0, p1 }) catch unreachable;
        debug.colors.appendSlice(&.{ color0, color1 }) catch unreachable;
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
    });
}
