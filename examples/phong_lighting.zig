const std = @import("std");
const zp = @import("zplay");
const Camera = zp.graphics.@"3d".Camera;
const Light = zp.graphics.@"3d".Light;
const Mesh = zp.graphics.@"3d".Mesh;
const Material = zp.graphics.@"3d".Material;
const Texture2D = zp.graphics.texture.Texture2D;
const SimpleRenderer = zp.graphics.@"3d".SimpleRenderer;
const PhongRenderer = zp.graphics.@"3d".PhongRenderer;
const alg = zp.deps.alg;
const Vec2 = alg.Vec2;
const Vec3 = alg.Vec3;
const Vec4 = alg.Vec4;
const Mat4 = alg.Mat4;

var simple_renderer: SimpleRenderer = undefined;
var phong_renderer: PhongRenderer = undefined;
var cube: Mesh = undefined;
var phong_material: Material = undefined;
var camera = Camera.fromPositionAndTarget(
    Vec3.new(1, 2, 3),
    Vec3.zero(),
    null,
);

const cube_positions = [_]Vec3{
    Vec3.new(0.0, 0.0, 0.0),
    Vec3.new(2.0, 5.0, -15.0),
    Vec3.new(-1.5, -2.2, -2.5),
    Vec3.new(-3.8, -2.0, -12.3),
    Vec3.new(2.4, -0.4, -3.5),
    Vec3.new(-1.7, 3.0, -7.5),
    Vec3.new(1.3, -2.0, -2.5),
    Vec3.new(1.5, 2.0, -2.5),
    Vec3.new(1.5, 0.2, -1.5),
    Vec3.new(-1.3, 1.0, -1.5),
};

fn init(ctx: *zp.Context) anyerror!void {
    std.log.info("game init", .{});

    // simple renderer
    simple_renderer = SimpleRenderer.init();

    // phong renderer
    phong_renderer = PhongRenderer.init(std.testing.allocator);
    phong_renderer.setDirLight(Light.init(.{
        .directional = .{
            .ambient = Vec3.new(0.1, 0.1, 0.1),
            .diffuse = Vec3.new(0.1, 0.1, 0.1),
            .specular = Vec3.new(0.1, 0.1, 0.1),
            .direction = Vec3.down(),
        },
    }));
    _ = try phong_renderer.addLight(Light.init(.{
        .point = .{
            .ambient = Vec3.new(0.2, 0.2, 0.2),
            .diffuse = Vec3.new(0.5, 0.5, 0.5),
            .position = Vec3.new(1.2, 1, -2),
            .linear = 0.09,
            .quadratic = 0.032,
        },
    }));
    _ = try phong_renderer.addLight(Light.init(.{
        .spot = .{
            .ambient = Vec3.new(0.2, 0.2, 0.2),
            .diffuse = Vec3.new(0.8, 0.1, 0.1),
            .position = Vec3.new(1.2, 1, 2),
            .direction = Vec3.new(1.2, 1, 2).negate(),
            .linear = 0.09,
            .quadratic = 0.032,
            .cutoff = 12.5,
            .outer_cutoff = 14.5,
        },
    }));

    // generate a cube
    cube = try Mesh.genCube(std.testing.allocator, 1, 1, 1, Vec4.one());

    // material init
    var diffuse_texture = try Texture2D.fromFilePath(std.testing.allocator, "assets/container2.png", false);
    var specular_texture = try Texture2D.fromFilePath(std.testing.allocator, "assets/container2_specular.png", false);
    phong_material = Material.init(.{
        .phong = .{
            .diffuse_map = diffuse_texture,
            .specular_map = specular_texture,
            .shiness = 32,
        },
    });
    _ = phong_material.allocTextureUnit(0);

    // enable depth test
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
            .mouse_event => |me| {
                switch (me.data) {
                    .motion => |motion| {
                        // camera rotation
                        camera.rotate(
                            camera.mouse_sensitivity * @intToFloat(f32, -motion.yrel),
                            camera.mouse_sensitivity * @intToFloat(f32, motion.xrel),
                        );
                    },
                    else => {},
                }
            },
            .quit_event => ctx.kill(),
            else => {},
        }
    }

    var width: u32 = undefined;
    var height: u32 = undefined;
    ctx.getWindowSize(&width, &height);

    // clear frame
    ctx.graphics.clear(true, true, false, [_]f32{ 0.2, 0.2, 0.2, 1.0 });

    // lighting scene
    const projection = Mat4.perspective(
        camera.zoom,
        @intToFloat(f32, width) / @intToFloat(f32, height),
        0.1,
        100,
    );
    var renderer = phong_renderer.renderer();
    renderer.begin();
    for (cube_positions) |pos, i| {
        const model = Mat4.fromRotation(
            20 * @intToFloat(f32, i),
            Vec3.new(1, 0.3, 0.5),
        ).translate(pos);
        renderer.renderMesh(
            cube,
            model,
            projection,
            camera,
            phong_material,
            null,
        ) catch unreachable;
    }
    renderer.end();

    // draw lights
    renderer = simple_renderer.renderer();
    renderer.begin();
    for (phong_renderer.point_lights.items) |light| {
        const model = Mat4.fromScale(Vec3.set(0.1)).translate(light.getPosition().?);
        renderer.renderMesh(
            cube,
            model,
            projection,
            camera,
            null,
            null,
        ) catch unreachable;
    }
    for (phong_renderer.spot_lights.items) |light| {
        const model = Mat4.fromScale(Vec3.set(0.1)).translate(light.getPosition().?);
        renderer.renderMesh(
            cube,
            model,
            projection,
            camera,
            null,
            null,
        ) catch unreachable;
    }
    renderer.end();
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
        .enable_relative_mouse_mode = true,
    });
}
