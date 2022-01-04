const std = @import("std");
const zp = @import("zplay");
const dig = zp.deps.dig;
const alg = zp.deps.alg;
const bt = zp.deps.bt;
const Vec3 = alg.Vec3;
const Vec4 = alg.Vec4;
const Mat4 = alg.Mat4;
const Texture2D = zp.graphics.texture.Texture2D;
const Renderer = zp.graphics.@"3d".Renderer;
const PhongRenderer = zp.graphics.@"3d".PhongRenderer;
const Light = zp.graphics.@"3d".Light;
const Model = zp.graphics.@"3d".Model;
const Material = zp.graphics.@"3d".Material;
const Camera = zp.graphics.@"3d".Camera;

var rd: Renderer = undefined;
var phong_renderer: PhongRenderer = undefined;
var wireframe_mode = false;
var room_texture: Texture2D = undefined;
var room: Model = undefined;
var scene1: Scene = undefined;
var frame_mt: Material = undefined;
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
    rd = phong_renderer.renderer();

    // load models
    room_texture = Texture2D.fromPixelData(
        std.testing.allocator,
        &.{ 128, 128, 128, 255 },
        1,
        1,
        .{},
    ) catch unreachable;
    room = try Model.fromGLTF(
        std.testing.allocator,
        "assets/world.gltf",
        false,
        room_texture,
    );
    var frame_texture = Texture2D.fromPixelData(
        std.testing.allocator,
        &.{ 0, 0, 0, 255 },
        1,
        1,
        .{},
    ) catch unreachable;
    frame_mt = Material.init(.{
        .phong = .{
            .diffuse_map = frame_texture,
            .specular_map = frame_texture,
            .shiness = 0,
        },
    });
    scene1 = try loadScene();

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

    // render room
    const projection = alg.Mat4.perspective(
        camera.zoom,
        @intToFloat(f32, width) / @intToFloat(f32, height),
        0.1,
        1000,
    );
    rd.begin();
    room.render(
        rd,
        Mat4.identity(),
        projection,
        camera,
        null,
        null,
    ) catch unreachable;
    {
        ctx.graphics.setPolygonMode(.line);
        defer ctx.graphics.setPolygonMode(.fill);
        for (scene1.items) |obj| {
            obj.model.render(
                rd,
                Mat4.fromScale(Vec3.set(1.001)).translate(obj.position),
                projection,
                camera,
                frame_mt,
                null,
            ) catch unreachable;
        }
    }
    if (!wireframe_mode) {
        for (scene1.items) |obj| {
            obj.model.render(
                rd,
                Mat4.fromTranslate(obj.position),
                projection,
                camera,
                null,
                null,
            ) catch unreachable;
        }
    }
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
            _ = dig.checkbox("wireframe", &wireframe_mode);
        }
        dig.end();
    }
    dig.endFrame();
}

const Object = struct {
    model: Model,
    position: Vec3,
    //rigid_body: bt.Body,
};
const Scene = std.ArrayList(Object);

fn loadScene() !Scene {
    var scene = Scene.init(std.testing.allocator);

    try scene.append(.{
        .model = try Model.fromGLTF(std.testing.allocator, "assets/capsule.gltf", false, null),
        .position = Vec3.new(-20, 5, -2),
    });
    try scene.append(.{
        .model = try Model.fromGLTF(std.testing.allocator, "assets/cylinder.gltf", false, null),
        .position = Vec3.new(-15, 5, -2),
    });
    try scene.append(.{
        .model = try Model.fromGLTF(std.testing.allocator, "assets/cube.gltf", false, null),
        .position = Vec3.new(-10, 5, -2),
    });
    try scene.append(.{
        .model = try Model.fromGLTF(std.testing.allocator, "assets/cone.gltf", false, null),
        .position = Vec3.new(-5, 5, -2),
    });
    try scene.append(.{
        .model = try Model.fromGLTF(std.testing.allocator, "assets/sphere.gltf", false, null),
        .position = Vec3.new(5, 5, -2),
    });

    // allocate texture units
    var unit: i32 = 0;
    for (room.materials.items) |m| {
        unit = m.allocTextureUnit(unit);
    }
    unit = frame_mt.allocTextureUnit(unit);
    for (scene.items) |obj| {
        for (obj.model.materials.items) |m| {
            unit = m.allocTextureUnit(unit);
        }
    }

    return scene;
}

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
