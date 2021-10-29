const std = @import("std");
const zp = @import("zplay");
const gl = zp.gl;
const alg = zp.alg;

const vertex_shader =
    \\#version 330 core
    \\layout (location = 0) in vec3 a_pos;
    \\layout (location = 1) in vec2 a_tex;
    \\
    \\uniform mat4 u_mvp;
    \\
    \\out vec2 v_tex;
    \\
    \\void main()
    \\{
    \\    gl_Position = u_mvp * vec4(a_pos, 1.0);
    \\    v_tex = a_tex;
    \\}
;

const fragment_shader =
    \\#version 330 core
    \\out vec4 frag_color;
    \\
    \\in vec2 v_tex;
    \\
    \\uniform sampler2D u_texture1;
    \\uniform sampler2D u_texture2;
    \\
    \\void main()
    \\{
    \\    frag_color = mix(texture(u_texture1, v_tex), texture(u_texture2, v_tex), 0.2);
    \\}
;

var shader_program: gl.ShaderProgram = undefined;
var vertex_array: gl.VertexArray = undefined;
var wireframe_mode = false;

const vertices = [_]f32{
    // positions, texture coords
    -0.5, -0.5, -0.5, 0.0, 0.0,
    0.5,  -0.5, -0.5, 1.0, 0.0,
    0.5,  0.5,  -0.5, 1.0, 1.0,
    0.5,  0.5,  -0.5, 1.0, 1.0,
    -0.5, 0.5,  -0.5, 0.0, 1.0,
    -0.5, -0.5, -0.5, 0.0, 0.0,

    -0.5, -0.5, 0.5,  0.0, 0.0,
    0.5,  -0.5, 0.5,  1.0, 0.0,
    0.5,  0.5,  0.5,  1.0, 1.0,
    0.5,  0.5,  0.5,  1.0, 1.0,
    -0.5, 0.5,  0.5,  0.0, 1.0,
    -0.5, -0.5, 0.5,  0.0, 0.0,

    -0.5, 0.5,  0.5,  1.0, 0.0,
    -0.5, 0.5,  -0.5, 1.0, 1.0,
    -0.5, -0.5, -0.5, 0.0, 1.0,
    -0.5, -0.5, -0.5, 0.0, 1.0,
    -0.5, -0.5, 0.5,  0.0, 0.0,
    -0.5, 0.5,  0.5,  1.0, 0.0,

    0.5,  0.5,  0.5,  1.0, 0.0,
    0.5,  0.5,  -0.5, 1.0, 1.0,
    0.5,  -0.5, -0.5, 0.0, 1.0,
    0.5,  -0.5, -0.5, 0.0, 1.0,
    0.5,  -0.5, 0.5,  0.0, 0.0,
    0.5,  0.5,  0.5,  1.0, 0.0,

    -0.5, -0.5, -0.5, 0.0, 1.0,
    0.5,  -0.5, -0.5, 1.0, 1.0,
    0.5,  -0.5, 0.5,  1.0, 0.0,
    0.5,  -0.5, 0.5,  1.0, 0.0,
    -0.5, -0.5, 0.5,  0.0, 0.0,
    -0.5, -0.5, -0.5, 0.0, 1.0,

    -0.5, 0.5,  -0.5, 0.0, 1.0,
    0.5,  0.5,  -0.5, 1.0, 1.0,
    0.5,  0.5,  0.5,  1.0, 0.0,
    0.5,  0.5,  0.5,  1.0, 0.0,
    -0.5, 0.5,  0.5,  0.0, 0.0,
    -0.5, 0.5,  -0.5, 0.0, 1.0,
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

    // shader program
    shader_program = gl.ShaderProgram.init(vertex_shader, fragment_shader);

    // vertex array
    vertex_array = gl.VertexArray.init(5);
    vertex_array.use();
    defer vertex_array.disuse();
    vertex_array.bufferData(0, f32, &vertices, .array_buffer, .static_draw);
    vertex_array.setAttribute(0, 3, f32, false, 5 * @sizeOf(f32), 0);
    vertex_array.setAttribute(1, 2, f32, false, 5 * @sizeOf(f32), 3 * @sizeOf(f32));

    // load texture
    const texture1 = try zp.Texture2D.init("assets/wall.jpg", .texture_unit_0, false);
    const texture2 = try zp.Texture2D.init("assets/awesomeface.png", .texture_unit_1, true);

    // only necessary when not using texture unit 0
    shader_program.use();
    defer shader_program.disuse();
    shader_program.setUniformByName("u_texture1", texture1.tex.getTextureUnit());
    shader_program.setUniformByName("u_texture2", texture2.tex.getTextureUnit());

    // enable depth test
    gl.enable(gl.GL_DEPTH_TEST);

    std.log.info("game init", .{});
}

fn event(ctx: *zp.Context, e: zp.Event) void {
    _ = ctx;

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
            if (key.trigger_type == .down) {
                return;
            }
            switch (key.scan_code) {
                .escape => ctx.kill(),
                .f1 => ctx.toggleFullscreeen(),
                .w => {
                    if (wireframe_mode) {
                        wireframe_mode = false;
                        gl.polygonMode(gl.GL_FRONT_AND_BACK, gl.GL_FILL);
                    } else {
                        wireframe_mode = true;
                        gl.polygonMode(gl.GL_FRONT_AND_BACK, gl.GL_LINE);
                    }
                },
                else => {},
            }
        },
        .quit_event => ctx.kill(),
        else => {},
    }
}

fn loop(ctx: *zp.Context) void {
    var width: i32 = undefined;
    var height: i32 = undefined;
    ctx.getSize(&width, &height);

    const S = struct {
        var frame: f32 = 0;
    };
    S.frame += 1;

    gl.clearColor(0.2, 0.3, 0.3, 1.0);
    gl.clear(gl.GL_COLOR_BUFFER_BIT | gl.GL_DEPTH_BUFFER_BIT);

    shader_program.use();
    vertex_array.use();

    const view = alg.Mat4.lookAt(
        alg.Vec3.new(0, 0, 3),
        alg.Vec3.zero(),
        alg.Vec3.up(),
    );
    const projection = alg.Mat4.perspective(
        45,
        @intToFloat(f32, width) / @intToFloat(f32, height),
        0.1,
        100,
    );
    for (cube_positions) |pos, i| {
        const model = alg.Mat4.fromRotation(
            20 * @intToFloat(f32, i) + S.frame,
            alg.Vec3.new(1, 0.3, 0.5),
        ).translate(pos);
        shader_program.setUniformByName("u_mvp", projection.mult(view).mult(model));
        gl.drawArrays(gl.GL_TRIANGLES, 0, 36);
    }
}

fn quit(ctx: *zp.Context) void {
    _ = ctx;

    std.log.info("game quit", .{});
}

pub fn main() anyerror!void {
    try zp.run(.{
        .init_fn = init,
        .event_fn = event,
        .loop_fn = loop,
        .quit_fn = quit,
        .resizable = true,
    });
}
