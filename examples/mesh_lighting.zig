const std = @import("std");
const zp = @import("zplay");
const gl = zp.gl;
const alg = zp.alg;
const Vec2 = alg.Vec2;
const Vec3 = alg.Vec3;
const Vec4 = alg.Vec4;
const Mat4 = alg.Mat4;
const SimpleRenderer = zp.@"3d".SimpleRenderer;
const PhongRenderer = zp.@"3d".PhongRenderer;
const Light = zp.@"3d".Light;
const Material = zp.@"3d".Material;
const Mesh = zp.@"3d".Mesh;

var simple_renderer: SimpleRenderer = undefined;
var phong_renderer: PhongRenderer = undefined;
var mesh_for_simple: Mesh = undefined;
var mesh_for_phong: Mesh = undefined;
var material_for_simple: Material = undefined;
var material_for_phong: Material = undefined;
var camera = zp.@"3d".Camera.fromPositionAndTarget(
    Vec3.new(1, 2, 3),
    Vec3.zero(),
    null,
);

// normal, position, texture coord
const vertices = [_]f32{
    0.0,  0.0,  -1.0, -0.5, -0.5, -0.5, 0.0, 0.0,
    0.0,  0.0,  -1.0, 0.5,  -0.5, -0.5, 1.0, 0.0,
    0.0,  0.0,  -1.0, 0.5,  0.5,  -0.5, 1.0, 1.0,
    0.0,  0.0,  -1.0, 0.5,  0.5,  -0.5, 1.0, 1.0,
    0.0,  0.0,  -1.0, -0.5, 0.5,  -0.5, 0.0, 1.0,
    0.0,  0.0,  -1.0, -0.5, -0.5, -0.5, 0.0, 0.0,

    0.0,  0.0,  1.0,  -0.5, -0.5, 0.5,  0.0, 0.0,
    0.0,  0.0,  1.0,  0.5,  -0.5, 0.5,  1.0, 0.0,
    0.0,  0.0,  1.0,  0.5,  0.5,  0.5,  1.0, 1.0,
    0.0,  0.0,  1.0,  0.5,  0.5,  0.5,  1.0, 1.0,
    0.0,  0.0,  1.0,  -0.5, 0.5,  0.5,  0.0, 1.0,
    0.0,  0.0,  1.0,  -0.5, -0.5, 0.5,  0.0, 0.0,

    -1.0, 0.0,  0.0,  -0.5, 0.5,  0.5,  1.0, 0.0,
    -1.0, 0.0,  0.0,  -0.5, 0.5,  -0.5, 1.0, 1.0,
    -1.0, 0.0,  0.0,  -0.5, -0.5, -0.5, 0.0, 1.0,
    -1.0, 0.0,  0.0,  -0.5, -0.5, -0.5, 0.0, 1.0,
    -1.0, 0.0,  0.0,  -0.5, -0.5, 0.5,  0.0, 0.0,
    -1.0, 0.0,  0.0,  -0.5, 0.5,  0.5,  1.0, 0.0,

    1.0,  0.0,  0.0,  0.5,  0.5,  0.5,  1.0, 0.0,
    1.0,  0.0,  0.0,  0.5,  0.5,  -0.5, 1.0, 1.0,
    1.0,  0.0,  0.0,  0.5,  -0.5, -0.5, 0.0, 1.0,
    1.0,  0.0,  0.0,  0.5,  -0.5, -0.5, 0.0, 1.0,
    1.0,  0.0,  0.0,  0.5,  -0.5, 0.5,  0.0, 0.0,
    1.0,  0.0,  0.0,  0.5,  0.5,  0.5,  1.0, 0.0,

    0.0,  -1.0, 0.0,  -0.5, -0.5, -0.5, 0.0, 1.0,
    0.0,  -1.0, 0.0,  0.5,  -0.5, -0.5, 1.0, 1.0,
    0.0,  -1.0, 0.0,  0.5,  -0.5, 0.5,  1.0, 0.0,
    0.0,  -1.0, 0.0,  0.5,  -0.5, 0.5,  1.0, 0.0,
    0.0,  -1.0, 0.0,  -0.5, -0.5, 0.5,  0.0, 0.0,
    0.0,  -1.0, 0.0,  -0.5, -0.5, -0.5, 0.0, 1.0,

    0.0,  1.0,  0.0,  -0.5, 0.5,  -0.5, 0.0, 1.0,
    0.0,  1.0,  0.0,  0.5,  0.5,  -0.5, 1.0, 1.0,
    0.0,  1.0,  0.0,  0.5,  0.5,  0.5,  1.0, 0.0,
    0.0,  1.0,  0.0,  0.5,  0.5,  0.5,  1.0, 0.0,
    0.0,  1.0,  0.0,  -0.5, 0.5,  0.5,  0.0, 0.0,
    0.0,  1.0,  0.0,  -0.5, 0.5,  -0.5, 0.0, 1.0,
};

const indices = [_]u32{
    0,  1,  2,  3,  4,  5,  6,  7,  8,  9,  10, 11, 12, 13, 14,
    15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29,
    30, 31, 32, 33, 34, 35,
};

fn init(ctx: *zp.Context) anyerror!void {
    _ = ctx;

    // create renderer
    simple_renderer = SimpleRenderer.init();
    phong_renderer = PhongRenderer.init(std.testing.allocator);
    _ = try phong_renderer.addLight(Light.init(.{
        .point = .{
            .ambient = Vec3.new(0.2, 0.2, 0.2),
            .diffuse = Vec3.new(0.5, 0.5, 0.5),
            .position = Vec3.new(1.2, 1, -2),
            .linear = 0.09,
            .quadratic = 0.032,
        },
    }));

    // create mesh for simple renderer
    mesh_for_simple = Mesh.init(
        std.testing.allocator,
        &vertices,
        &indices,
        .{ .normal, .position, .texture_coord, null },
    );
    mesh_for_simple.relateLocation(SimpleRenderer.ATTRIB_LOCATION_POS, .position);
    mesh_for_simple.relateLocation(SimpleRenderer.ATTRIB_LOCATION_TEX, .texture_coord);

    // create mesh for phong renderer
    mesh_for_phong = Mesh.init(
        std.testing.allocator,
        &vertices,
        &indices,
        .{ .normal, .position, .texture_coord, null },
    );
    mesh_for_phong.relateLocation(PhongRenderer.ATTRIB_LOCATION_POS, .position);
    mesh_for_phong.relateLocation(PhongRenderer.ATTRIB_LOCATION_NORMAL, .normal);
    mesh_for_phong.relateLocation(PhongRenderer.ATTRIB_LOCATION_TEX, .texture_coord);

    // create material for simple renderer
    material_for_simple = Material.init(.{
        .single_color = Vec3.one(),
    });

    // create material for phong renderer
    var diffuse_texture = try zp.texture.Texture2D.fromFilePath("assets/container2.png", null, false);
    var specular_texture = try zp.texture.Texture2D.fromFilePath("assets/container2_specular.png", .texture_unit_1, false);
    material_for_phong = Material.init(.{
        .phong = .{
            .diffuse_map = diffuse_texture,
            .specular_map = specular_texture,
            .shiness = 32,
        },
    });

    // enable depth test
    gl.util.toggleCapability(.depth_test, true);

    std.log.info("game init", .{});
}

fn loop(ctx: *zp.Context) void {
    const S = struct {
        var frame: f32 = 0;
        var axis = Vec4.new(1, 1, 1, 0);
        var last_tick: ?f32 = null;
    };
    S.frame += 1;

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
                        gl.viewport(0, 0, size.width, size.height);
                    },
                    else => {},
                }
            },
            .keyboard_event => |key| {
                if (key.trigger_type == .up) {
                    switch (key.scan_code) {
                        .escape => ctx.kill(),
                        .f1 => ctx.toggleFullscreeen(null),
                        .m => ctx.toggleRelativeMouseMode(null),
                        .v => ctx.toggleVsyncMode(null),
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
                    .wheel => |scroll| {
                        camera.zoom -= @intToFloat(f32, scroll.scroll_y);
                        if (camera.zoom < 1) {
                            camera.zoom = 1;
                        }
                        if (camera.zoom > 45) {
                            camera.zoom = 45;
                        }
                    },
                    else => {},
                }
            },
            .quit_event => ctx.kill(),
            else => {},
        }
    }

    var width: i32 = undefined;
    var height: i32 = undefined;
    ctx.getSize(&width, &height);

    // start drawing
    gl.util.clear(true, true, false, [_]f32{ 0.2, 0.3, 0.3, 1.0 });

    const projection = Mat4.perspective(
        camera.zoom,
        @intToFloat(f32, width) / @intToFloat(f32, height),
        0.1,
        100,
    );
    S.axis = Mat4.fromRotation(1, Vec3.new(-1, 1, -1)).multByVec4(S.axis);

    var renderer = &phong_renderer.renderer;
    renderer.begin();
    var model = Mat4.fromRotation(
        S.frame,
        Vec3.new(S.axis.x, S.axis.y, S.axis.z),
    );
    renderer.renderMesh(
        mesh_for_phong,
        model,
        projection,
        camera,
        material_for_phong,
        null,
    ) catch unreachable;
    renderer.end();

    renderer = &simple_renderer.renderer;
    renderer.begin();
    for (phong_renderer.point_lights.items) |light| {
        model = Mat4.fromScale(Vec3.set(0.1)).translate(light.getPosition().?);
        renderer.renderMesh(
            mesh_for_simple,
            model,
            projection,
            camera,
            material_for_simple,
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
