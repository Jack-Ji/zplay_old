const std = @import("std");
const zp = @import("zplay");
const gl = zp.gl;
const zlm = zp.zlm;

const vertex_shader =
    \\#version 330 core
    \\layout (location = 0) in vec3 a_pos;
    \\
    \\void main()
    \\{
    \\    gl_Position = vec4(a_pos, 1.0);
    \\}
;

const fragment_shader =
    \\#version 330 core
    \\out vec4 frag_color;
    \\
    \\void main()
    \\{
    \\    frag_color = vec4(1.0f, 0.5f, 0.2f, 1.0f);
    \\}
;

var shader_program: gl.GLuint = undefined;
var vao: gl.GLuint = undefined;
var vbo: gl.GLuint = undefined;

const vertices = [_]f32{
    -0.5, -0.5, 0.0,
    0.5,  -0.5, 0.0,
    0.0,  0.5,  0.0,
};

fn init(ctx: *zp.Context) anyerror!void {
    _ = ctx;

    var success: gl.GLint = undefined;
    var shader_log: [512]gl.GLchar = undefined;
    var log_size: gl.GLsizei = undefined;

    // vertex shader
    var vshader = gl.createShader(gl.GL_VERTEX_SHADER);
    defer gl.deleteShader(vshader);
    gl.shaderSource(vshader, 1, @ptrCast([*c]const [*c]const gl.GLchar, &vertex_shader), null);
    gl.compileShader(vshader);
    gl.getShaderiv(vshader, gl.GL_COMPILE_STATUS, &success);
    if (success == 0) {
        gl.getShaderInfoLog(vshader, 512, &log_size, &shader_log);
        std.debug.panic("compile vertex shader failed: {s}", .{shader_log[0..@intCast(usize, log_size)]});
    }

    // fragment shader
    var fshader = gl.createShader(gl.GL_FRAGMENT_SHADER);
    defer gl.deleteShader(fshader);
    gl.shaderSource(fshader, 1, @ptrCast([*c]const [*c]const gl.GLchar, &fragment_shader), null);
    gl.compileShader(fshader);
    gl.getShaderiv(fshader, gl.GL_COMPILE_STATUS, &success);
    if (success == 0) {
        gl.getShaderInfoLog(fshader, 512, &log_size, &shader_log);
        std.debug.panic("compile fragment shader failed: {s}", .{shader_log[0..@intCast(usize, log_size)]});
    }

    // link program
    shader_program = gl.createProgram();
    gl.attachShader(shader_program, vshader);
    gl.attachShader(shader_program, fshader);
    gl.linkProgram(shader_program);
    gl.getProgramiv(shader_program, gl.GL_LINK_STATUS, &success);
    if (success == 0) {
        gl.getProgramInfoLog(shader_program, 512, &log_size, &shader_log);
        std.debug.panic("link shader program failed: {s}", .{shader_log[0..@intCast(usize, log_size)]});
    }

    // vertex array object
    gl.genVertexArrays(1, &vao);
    gl.bindVertexArray(vao);
    defer gl.bindVertexArray(0);

    // vertex buffer
    gl.genBuffers(1, &vbo);
    gl.bindBuffer(gl.GL_ARRAY_BUFFER, vbo);
    gl.bufferData(gl.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(vertices)), &vertices, gl.GL_STATIC_DRAW);

    // vertex attribute
    gl.vertexAttribPointer(0, 3, gl.GL_FLOAT, gl.GL_FALSE, 3 * @sizeOf(f32), null);
    gl.enableVertexAttribArray(0);

    std.log.info("game init", .{});
}

fn event(ctx: *zp.Context, e: zp.Event) void {
    _ = ctx;

    switch (e) {
        .keyboard_event => |key| {
            if (key.trigger_type == .down) {
                return;
            }
            switch (key.scan_code) {
                .escape => ctx.kill(),
                .f1 => ctx.toggleFullscreeen(),
                else => {},
            }
        },
        .mouse_event => {},
        .gamepad_event => {},
        .quit_event => ctx.kill(),
    }
}

fn loop(ctx: *zp.Context) void {
    _ = ctx;

    gl.clearColor(0.2, 0.3, 0.3, 1.0);
    gl.clear(gl.GL_COLOR_BUFFER_BIT);

    gl.useProgram(shader_program);
    gl.bindVertexArray(vao);
    gl.drawArrays(gl.GL_TRIANGLES, 0, 3);
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
    });
}
