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
    \\uniform vec4 u_color;
    \\
    \\void main()
    \\{
    \\    frag_color = u_color;
    \\}
;

var shader_program: gl.ShaderProgram = undefined;
var vertex_array: gl.VertexArray = undefined;

const vertices = [_]f32{
    -0.5, -0.5, 0.0,
    0.5,  -0.5, 0.0,
    0.0,  0.5,  0.0,
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
    vertex_array.setAttribute(0, 3, f32, false, 3 * @sizeOf(f32), 0);

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
                else => {},
            }
        },
        .quit_event => ctx.kill(),
        else => {},
    }
}

fn loop(ctx: *zp.Context) void {
    gl.clearColor(0.2, 0.3, 0.3, 1.0);
    gl.clear(gl.GL_COLOR_BUFFER_BIT);

    shader_program.use();
    vertex_array.use();

    // update color and draw triangle
    const color = zlm.Vec4.new(0.2, 0.3 + std.math.absFloat(std.math.sin(ctx.tick)), 0.3, 1);
    shader_program.setUniformByName("u_color", color);
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
        .resizable = true,
    });
}