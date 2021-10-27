const std = @import("std");
const zp = @import("zplay");
const gl = zp.gl;
const zlm = zp.zlm;
const stb_image = zp.stb.image;

const vertex_shader =
    \\#version 330 core
    \\layout (location = 0) in vec3 a_pos;
    \\layout (location = 1) in vec3 a_color;
    \\layout (location = 2) in vec2 a_tex;
    \\
    \\uniform mat4 u_mvp;
    \\
    \\out vec3 v_color;
    \\out vec2 v_tex;
    \\
    \\void main()
    \\{
    \\    gl_Position = u_mvp * vec4(a_pos, 1.0);
    \\    v_color = a_color;
    \\    v_tex = a_tex;
    \\}
;

const fragment_shader =
    \\#version 330 core
    \\out vec4 frag_color;
    \\
    \\in vec3 v_color;
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
    // positions, colors, texture coords
    0.5, 0.5, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0, // top right
    0.5, -0.5, 0.0, 0.0, 1.0, 0.0, 1.0, 0.0, // bottom right
    -0.5, -0.5, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, // bottom left
    -0.5, 0.5, 0.0, 1.0, 1.0, 0.0, 0.0, 1.0, // top left
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
    vertex_array.setAttribute(0, 3, f32, false, 8 * @sizeOf(f32), 0);
    vertex_array.setAttribute(1, 3, f32, false, 8 * @sizeOf(f32), 3 * @sizeOf(f32));
    vertex_array.setAttribute(2, 2, f32, false, 8 * @sizeOf(f32), 6 * @sizeOf(f32));
    vertex_array.bufferData(1, u32, &indices, .element_array_buffer, .static_draw);

    // load texture
    const texture1 = try zp.texture.createTexture2D("assets/wall.jpg", .texture_unit_0, false);
    const texture2 = try zp.texture.createTexture2D("assets/awesomeface.png", .texture_unit_1, true);

    // only necessary when not using texture unit 0
    shader_program.use();
    shader_program.setUniformByName("u_texture1", texture1.getTextureUnit());
    shader_program.setUniformByName("u_texture2", texture2.getTextureUnit());

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
    _ = ctx;

    const s = struct {
        var frame: u32 = 0;
    };
    s.frame += 1;

    gl.clearColor(0.2, 0.3, 0.3, 1.0);
    gl.clear(gl.GL_COLOR_BUFFER_BIT);

    shader_program.use();
    vertex_array.use();

    shader_program.setUniformByName("u_mvp", zlm.Mat4.identity);
    gl.drawElements(gl.GL_TRIANGLES, 6, gl.GL_UNSIGNED_INT, null);
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
