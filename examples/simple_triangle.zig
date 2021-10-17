const std = @import("std");
const zp = @import("zplay");
const gl = zp.gl;

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

var shader_program: zp.ShaderProgram = undefined;
var vao: gl.GLuint = undefined;

const vertices = [_]f32{
    -0.5, -0.5, 0.0,
    0.5,  -0.5, 0.0,
    0.0,  0.5,  0.0,
};

fn init(ctx: *zp.Context) anyerror!void {
    _ = ctx;

    // shader program
    shader_program = zp.ShaderProgram.init(vertex_shader, fragment_shader);

    // vertex array object
    gl.genVertexArrays(1, &vao);
    gl.bindVertexArray(vao);
    defer gl.bindVertexArray(0);

    // vertex buffer object
    var vbo: gl.GLuint = undefined;
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
    var w: i32 = undefined;
    var h: i32 = undefined;
    ctx.getSize(&w, &h);
    gl.viewport(0, 0, w, h);

    gl.clearColor(0.2, 0.3, 0.3, 1.0);
    gl.clear(gl.GL_COLOR_BUFFER_BIT);

    gl.useProgram(shader_program.id);
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
