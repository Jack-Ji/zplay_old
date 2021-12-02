const std = @import("std");
const zp = @import("zplay");
const gl = zp.gl;
const alg = zp.alg;
const Vec3 = alg.Vec3;
const Mat4 = alg.Mat4;
const Camera = zp.@"3d".Camera;
const Light = zp.@"3d".Light;
const Material = zp.@"3d".Material;
const SimpleRenderer = zp.@"3d".SimpleRenderer;
const PhongRenderer = zp.@"3d".PhongRenderer;

var simple_renderer: SimpleRenderer = undefined;
var phong_renderer: PhongRenderer = undefined;
var regular_cube_va: gl.VertexArray = undefined;
var lighting_cube_va: gl.VertexArray = undefined;
var material_for_simple: Material = undefined;
var material_for_phong: Material = undefined;
var camera = Camera.fromPositionAndTarget(
    Vec3.new(1, 2, 3),
    Vec3.zero(),
    null,
);

// position, normal, texture coord
const vertices = [_]f32{
    -0.5, -0.5, -0.5, 0.0,  0.0,  -1.0, 0.0, 0.0,
    0.5,  -0.5, -0.5, 0.0,  0.0,  -1.0, 1.0, 0.0,
    0.5,  0.5,  -0.5, 0.0,  0.0,  -1.0, 1.0, 1.0,
    0.5,  0.5,  -0.5, 0.0,  0.0,  -1.0, 1.0, 1.0,
    -0.5, 0.5,  -0.5, 0.0,  0.0,  -1.0, 0.0, 1.0,
    -0.5, -0.5, -0.5, 0.0,  0.0,  -1.0, 0.0, 0.0,

    -0.5, -0.5, 0.5,  0.0,  0.0,  1.0,  0.0, 0.0,
    0.5,  -0.5, 0.5,  0.0,  0.0,  1.0,  1.0, 0.0,
    0.5,  0.5,  0.5,  0.0,  0.0,  1.0,  1.0, 1.0,
    0.5,  0.5,  0.5,  0.0,  0.0,  1.0,  1.0, 1.0,
    -0.5, 0.5,  0.5,  0.0,  0.0,  1.0,  0.0, 1.0,
    -0.5, -0.5, 0.5,  0.0,  0.0,  1.0,  0.0, 0.0,

    -0.5, 0.5,  0.5,  -1.0, 0.0,  0.0,  1.0, 0.0,
    -0.5, 0.5,  -0.5, -1.0, 0.0,  0.0,  1.0, 1.0,
    -0.5, -0.5, -0.5, -1.0, 0.0,  0.0,  0.0, 1.0,
    -0.5, -0.5, -0.5, -1.0, 0.0,  0.0,  0.0, 1.0,
    -0.5, -0.5, 0.5,  -1.0, 0.0,  0.0,  0.0, 0.0,
    -0.5, 0.5,  0.5,  -1.0, 0.0,  0.0,  1.0, 0.0,

    0.5,  0.5,  0.5,  1.0,  0.0,  0.0,  1.0, 0.0,
    0.5,  0.5,  -0.5, 1.0,  0.0,  0.0,  1.0, 1.0,
    0.5,  -0.5, -0.5, 1.0,  0.0,  0.0,  0.0, 1.0,
    0.5,  -0.5, -0.5, 1.0,  0.0,  0.0,  0.0, 1.0,
    0.5,  -0.5, 0.5,  1.0,  0.0,  0.0,  0.0, 0.0,
    0.5,  0.5,  0.5,  1.0,  0.0,  0.0,  1.0, 0.0,

    -0.5, -0.5, -0.5, 0.0,  -1.0, 0.0,  0.0, 1.0,
    0.5,  -0.5, -0.5, 0.0,  -1.0, 0.0,  1.0, 1.0,
    0.5,  -0.5, 0.5,  0.0,  -1.0, 0.0,  1.0, 0.0,
    0.5,  -0.5, 0.5,  0.0,  -1.0, 0.0,  1.0, 0.0,
    -0.5, -0.5, 0.5,  0.0,  -1.0, 0.0,  0.0, 0.0,
    -0.5, -0.5, -0.5, 0.0,  -1.0, 0.0,  0.0, 1.0,

    -0.5, 0.5,  -0.5, 0.0,  1.0,  0.0,  0.0, 1.0,
    0.5,  0.5,  -0.5, 0.0,  1.0,  0.0,  1.0, 1.0,
    0.5,  0.5,  0.5,  0.0,  1.0,  0.0,  1.0, 0.0,
    0.5,  0.5,  0.5,  0.0,  1.0,  0.0,  1.0, 0.0,
    -0.5, 0.5,  0.5,  0.0,  1.0,  0.0,  0.0, 0.0,
    -0.5, 0.5,  -0.5, 0.0,  1.0,  0.0,  0.0, 1.0,
};

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
    _ = ctx;

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

    // vertex array for regular scene
    regular_cube_va = gl.VertexArray.init(5);
    regular_cube_va.use();
    regular_cube_va.bufferData(0, f32, &vertices, .array_buffer, .static_draw);
    regular_cube_va.setAttribute(
        0,
        SimpleRenderer.ATTRIB_LOCATION_POS,
        3,
        f32,
        false,
        8 * @sizeOf(f32),
        0,
    );
    regular_cube_va.disuse();

    // vertex array for lighting scene
    lighting_cube_va = gl.VertexArray.init(5);
    lighting_cube_va.use();
    lighting_cube_va.bufferData(0, f32, &vertices, .array_buffer, .static_draw);
    lighting_cube_va.setAttribute(
        0,
        PhongRenderer.ATTRIB_LOCATION_POS,
        3,
        f32,
        false,
        8 * @sizeOf(f32),
        0,
    );
    lighting_cube_va.setAttribute(
        0,
        PhongRenderer.ATTRIB_LOCATION_NORMAL,
        3,
        f32,
        false,
        8 * @sizeOf(f32),
        3 * @sizeOf(f32),
    );
    lighting_cube_va.setAttribute(
        0,
        PhongRenderer.ATTRIB_LOCATION_TEX,
        2,
        f32,
        false,
        8 * @sizeOf(f32),
        6 * @sizeOf(f32),
    );
    lighting_cube_va.disuse();

    // material init
    var diffuse_texture = try zp.texture.Texture2D.fromFilePath("assets/container2.png", null, false);
    var specular_texture = try zp.texture.Texture2D.fromFilePath("assets/container2_specular.png", .texture_unit_1, false);
    material_for_phong = Material.init(.{
        .phong = .{
            .diffuse_map = diffuse_texture,
            .specular_map = specular_texture,
            .shiness = 32,
        },
    });
    material_for_simple = Material.init(.{
        .single_color = Vec3.one(),
    });

    // enable depth test
    gl.util.toggleCapability(.depth_test, true);

    std.log.info("game init", .{});
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

    var width: i32 = undefined;
    var height: i32 = undefined;
    ctx.getSize(&width, &height);

    // clear frame
    gl.util.clear(true, true, false, [_]f32{ 0.2, 0.2, 0.2, 1.0 });

    // lighting scene
    const projection = Mat4.perspective(
        camera.zoom,
        @intToFloat(f32, width) / @intToFloat(f32, height),
        0.1,
        100,
    );
    var renderer = &phong_renderer.renderer;
    renderer.begin();
    for (cube_positions) |pos, i| {
        const model = Mat4.fromRotation(
            20 * @intToFloat(f32, i),
            Vec3.new(1, 0.3, 0.5),
        ).translate(pos);
        renderer.render(
            lighting_cube_va,
            false,
            .triangles,
            0,
            36,
            model,
            projection,
            camera,
            material_for_phong,
        ) catch unreachable;
    }
    renderer.end();

    // draw lights
    renderer = &simple_renderer.renderer;
    renderer.begin();
    for (phong_renderer.point_lights.items) |light| {
        const model = Mat4.fromScale(Vec3.set(0.1)).translate(light.getPosition().?);
        renderer.render(
            regular_cube_va,
            false,
            .triangles,
            0,
            36,
            model,
            projection,
            camera,
            material_for_simple,
        ) catch unreachable;
    }
    for (phong_renderer.spot_lights.items) |light| {
        const model = Mat4.fromScale(Vec3.set(0.1)).translate(light.getPosition().?);
        renderer.render(
            regular_cube_va,
            false,
            .triangles,
            0,
            36,
            model,
            projection,
            camera,
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
