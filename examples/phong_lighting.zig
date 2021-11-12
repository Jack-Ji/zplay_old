const std = @import("std");
const zp = @import("zplay");
const gl = zp.gl;
const alg = zp.alg;
const PhongRenderer = zp.@"3d".PhongRenderer;
const Camera = zp.@"3d".Camera;
const Light = zp.@"3d".Light;
const Material = zp.@"3d".Material;

const vertex_shader =
    \\#version 330 core
    \\layout (location = 0) in vec3 a_pos;
    \\
    \\out vec3 vertex_color;
    \\
    \\uniform mat4 u_mvp;
    \\
    \\void main()
    \\{
    \\    gl_Position = u_mvp * vec4(a_pos, 1.0);
    \\}
;

const fragment_shader =
    \\#version 330 core
    \\out vec4 frag_color;
    \\
    \\void main()
    \\{
    \\    frag_color = vec4(1.0);
    \\}
;

var phong_renderer: PhongRenderer = undefined;
var shader_program: gl.ShaderProgram = undefined;
var cube_va: gl.VertexArray = undefined;
var material: Material = undefined;
var camera = Camera.fromPositionAndTarget(
    alg.Vec3.new(1, 2, 3),
    alg.Vec3.zero(),
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

const cube_positions = [_]alg.Vec3{
    alg.Vec3.new(0.0, 0.0, 0.0),
    alg.Vec3.new(2.0, 5.0, -15.0),
    alg.Vec3.new(-1.5, -2.2, -2.5),
    alg.Vec3.new(-3.8, -2.0, -12.3),
    alg.Vec3.new(2.4, -0.4, -3.5),
    alg.Vec3.new(-1.7, 3.0, -7.5),
    alg.Vec3.new(1.3, -2.0, -2.5),
    alg.Vec3.new(1.5, 2.0, -2.5),
    alg.Vec3.new(1.5, 0.2, -1.5),
    alg.Vec3.new(-1.3, 1.0, -1.5),
};

fn init(ctx: *zp.Context) anyerror!void {
    _ = ctx;

    // phong renderer
    phong_renderer = PhongRenderer.init(std.testing.allocator);
    phong_renderer.setDirLight(Light.init(.{
        .directional = .{
            .ambient = alg.Vec3.new(0.1, 0.1, 0.1),
            .diffuse = alg.Vec3.new(0.1, 0.1, 0.1),
            .specular = alg.Vec3.new(0.1, 0.1, 0.1),
            .direction = alg.Vec3.down(),
        },
    }));
    _ = try phong_renderer.addLight(Light.init(.{
        .point = .{
            .ambient = alg.Vec3.new(0.2, 0.2, 0.2),
            .diffuse = alg.Vec3.new(0.5, 0.5, 0.5),
            .position = alg.Vec3.new(1.2, 1, -2),
            .linear = 0.09,
            .quadratic = 0.032,
        },
    }));
    _ = try phong_renderer.addLight(Light.init(.{
        .spot = .{
            .ambient = alg.Vec3.new(0.2, 0.2, 0.2),
            .diffuse = alg.Vec3.new(0.8, 0.1, 0.1),
            .position = alg.Vec3.new(1.2, 1, 2),
            .direction = alg.Vec3.new(1.2, 1, 2).negate(),
            .linear = 0.09,
            .quadratic = 0.032,
            .cutoff = 12.5,
            .outer_cutoff = 14.5,
        },
    }));

    // shader program
    shader_program = gl.ShaderProgram.init(vertex_shader, fragment_shader);

    // vertex array
    cube_va = gl.VertexArray.init(5);
    cube_va.use();
    defer cube_va.disuse();
    cube_va.bufferData(0, f32, &vertices, .array_buffer, .static_draw);
    cube_va.setAttribute(0, 0, 3, f32, false, 8 * @sizeOf(f32), 0);
    cube_va.setAttribute(0, 1, 3, f32, false, 8 * @sizeOf(f32), 3 * @sizeOf(f32));
    cube_va.setAttribute(0, 2, 2, f32, false, 8 * @sizeOf(f32), 6 * @sizeOf(f32));

    // material init
    var diffuse_texture = try zp.texture.Texture2D.init("assets/container2.png", null, false);
    var specular_texture = try zp.texture.Texture2D.init("assets/container2_specular.png", .texture_unit_1, false);
    material = Material.init(
        diffuse_texture,
        specular_texture,
        32,
    );

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
    const projection = alg.Mat4.perspective(
        camera.zoom,
        @intToFloat(f32, width) / @intToFloat(f32, height),
        0.1,
        100,
    );
    phong_renderer.begin();
    for (cube_positions) |pos, i| {
        const model = alg.Mat4.fromRotation(
            20 * @intToFloat(f32, i),
            alg.Vec3.new(1, 0.3, 0.5),
        ).translate(pos);
        phong_renderer.render(cube_va, .triangles, 0, 36, model, projection, camera, material) catch unreachable;
    }
    phong_renderer.end();

    // draw lights
    shader_program.use();
    defer shader_program.disuse();
    cube_va.use();
    const view = camera.getViewMatrix();
    for (phong_renderer.point_lights.items) |light| {
        const model = alg.Mat4.fromScale(alg.Vec3.set(0.1)).translate(light.getPosition().?);
        shader_program.setUniformByName("u_mvp", projection.mult(view).mult(model));
        gl.util.drawBuffer(.triangles, 0, 36);
    }
    for (phong_renderer.spot_lights.items) |light| {
        const model = alg.Mat4.fromScale(alg.Vec3.set(0.1)).translate(light.getPosition().?);
        shader_program.setUniformByName("u_mvp", projection.mult(view).mult(model));
        gl.util.drawBuffer(.triangles, 0, 36);
    }
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
