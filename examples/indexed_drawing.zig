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

var shader_program: gl.ShaderProgram = undefined;
var vertex_array: gl.VertexArray = undefined;
var wireframe_mode = false;

const vertices = [_]f32{
    0.5, 0.5, 0.0, // top right
    0.5, -0.5, 0.0, // bottom right
    -0.5, -0.5, 0.0, // bottom left
    -0.5, 0.5, 0.0, // top left
};
const indices = [_]u32{
    0, 1, 3, // 1st triangle
    1, 2, 3, // 2nd triangle
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
    vertex_array.bufferData(1, u32, &indices, .element_array_buffer, .static_draw);

    std.log.info("game init", .{});
}

fn loop(ctx: *zp.Context) void {
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
                if (key.trigger_type == .down) {
                    return;
                }
                switch (key.scan_code) {
                    .escape => ctx.kill(),
                    .f1 => ctx.toggleFullscreeen(null),
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

    gl.util.clear(true, false, false, [_]f32{ 0.2, 0.3, 0.3, 1.0 });
    shader_program.use();
    vertex_array.use();
    gl.util.drawElements(.triangles, 0, 6);
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
        .enable_resizable = true,
    });
}
