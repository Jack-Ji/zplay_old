const std = @import("std");
const zp = @import("zplay");
const gl = zp.gl;
const alg = zp.alg;

const vertex_shader =
    \\#version 330 core
    \\layout (location = 0) in vec3 a_pos;
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
    \\uniform vec3 u_object_color;
    \\uniform vec3 u_light_color;
    \\
    \\void main()
    \\{
    \\    float ambient_strenth = 0.1;
    \\    vec3 ambient_color = ambient_strenth * u_light_color;
    \\
    \\    vec3 result = ambient_color * u_object_color;
    \\    frag_color = vec4(result, 1.0);
    \\}
;

const light_shader =
    \\#version 330 core
    \\out vec4 frag_color;
    \\
    \\void main()
    \\{
    \\    frag_color = vec4(1);
    \\}
;

var normal_shader_program: gl.ShaderProgram = undefined;
var light_shader_program: gl.ShaderProgram = undefined;
var light_pos = alg.Vec3.new(1.2, 1, -2);
var cube_va: gl.VertexArray = undefined;
var camera = zp.Camera3D.fromPositionAndTarget(
    alg.Vec3.new(0, 0, 3),
    alg.Vec3.zero(),
    null,
);

const vertices = [_]f32{
    -0.5, -0.5, -0.5,
    0.5,  -0.5, -0.5,
    0.5,  0.5,  -0.5,
    0.5,  0.5,  -0.5,
    -0.5, 0.5,  -0.5,
    -0.5, -0.5, -0.5,

    -0.5, -0.5, 0.5,
    0.5,  -0.5, 0.5,
    0.5,  0.5,  0.5,
    0.5,  0.5,  0.5,
    -0.5, 0.5,  0.5,
    -0.5, -0.5, 0.5,

    -0.5, 0.5,  0.5,
    -0.5, 0.5,  -0.5,
    -0.5, -0.5, -0.5,
    -0.5, -0.5, -0.5,
    -0.5, -0.5, 0.5,
    -0.5, 0.5,  0.5,

    0.5,  0.5,  0.5,
    0.5,  0.5,  -0.5,
    0.5,  -0.5, -0.5,
    0.5,  -0.5, -0.5,
    0.5,  -0.5, 0.5,
    0.5,  0.5,  0.5,

    -0.5, -0.5, -0.5,
    0.5,  -0.5, -0.5,
    0.5,  -0.5, 0.5,
    0.5,  -0.5, 0.5,
    -0.5, -0.5, 0.5,
    -0.5, -0.5, -0.5,

    -0.5, 0.5,  -0.5,
    0.5,  0.5,  -0.5,
    0.5,  0.5,  0.5,
    0.5,  0.5,  0.5,
    -0.5, 0.5,  0.5,
    -0.5, 0.5,  -0.5,
};

fn init(ctx: *zp.Context) anyerror!void {
    _ = ctx;

    // shader program
    normal_shader_program = gl.ShaderProgram.init(vertex_shader, fragment_shader);
    light_shader_program = gl.ShaderProgram.init(vertex_shader, light_shader);

    // vertex array
    cube_va = gl.VertexArray.init(5);
    cube_va.use();
    defer cube_va.disuse();
    cube_va.bufferData(0, f32, &vertices, .array_buffer, .static_draw);
    cube_va.setAttribute(0, 3, f32, false, 3 * @sizeOf(f32), 0);

    // enable depth test
    ctx.toggleCapability(.depth_test, true);

    std.log.info("game init", .{});
}

fn loop(ctx: *zp.Context) void {
    const S = struct {
        var frame: f32 = 0;
        var axis = alg.Vec4.new(1, 1, 1, 0);
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

    // start drawing
    ctx.clear(true, true, false, [_]f32{ 0, 0, 0, 1.0 });

    cube_va.use();

    normal_shader_program.use();
    const projection = alg.Mat4.perspective(
        45,
        @intToFloat(f32, width) / @intToFloat(f32, height),
        0.1,
        100,
    );
    S.axis = alg.Mat4.fromRotation(1, alg.Vec3.new(-1, 1, -1)).multByVec4(S.axis);
    var model = alg.Mat4.fromRotation(
        S.frame,
        alg.Vec3.new(S.axis.x, S.axis.y, S.axis.z),
    );
    var mvp = projection.mult(camera.getViewMatrix()).mult(model);
    normal_shader_program.setUniformByName("u_mvp", mvp);
    normal_shader_program.setUniformByName("u_object_color", alg.Vec3.new(1, 0.5, 0.31));
    normal_shader_program.setUniformByName("u_light_color", alg.Vec3.new(1, 1, 1));
    ctx.drawBuffer(.triangles, 0, 36);

    // draw light
    light_shader_program.use();
    model = alg.Mat4.fromScale(alg.Vec3.set(0.2)).translate(light_pos);
    mvp = projection.mult(camera.getViewMatrix()).mult(model);
    light_shader_program.setUniformByName("u_mvp", mvp);
    ctx.drawBuffer(.triangles, 0, 36);
}

fn quit(ctx: *zp.Context) void {
    _ = ctx;

    std.log.info("game quit", .{});
}

pub fn main() anyerror!void {
    try zp.run(.{
        .init_fn = init,
        .loop_fn = loop,
        .quit_fn = quit,
        .enable_relative_mouse_mode = true,
    });
}
