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
    \\uniform sampler2D u_texture;
    \\
    \\void main()
    \\{
    \\    frag_color = texture(u_texture, v_tex);
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

    // texture
    var width: c_int = undefined;
    var height: c_int = undefined;
    var channels: c_int = undefined;
    var image_data = stb_image.stbi_load(
        "assets/wall.jpg",
        &width,
        &height,
        &channels,
        0,
    );
    if (image_data == null) {
        std.debug.panic("load texture failed!", .{});
    }
    defer stb_image.stbi_image_free(image_data);
    std.log.info("image info: width({d}) height({d}) channel({d})", .{ width, height, channels });
    var texture = gl.Texture.init(.texture_2d);
    texture.bindToTextureUnit(.texture_unit_0);
    texture.setWrapping(.s, .repeat);
    texture.setWrapping(.t, .repeat);
    texture.setFilteringMode(.minifying, .linear_mipmap_linear);
    texture.setFilteringMode(.magnifying, .linear);
    texture.updateImageData(
        .texture_2d,
        0,
        .rgb,
        @intCast(usize, width),
        @intCast(usize, height),
        null,
        .rgb,
        u8,
        image_data[0..@intCast(usize, width * height * channels)],
        true,
    );

    // only necessary when not using texture unit 0
    //shader_program.use();
    //shader_program.setUniformByName("u_texture", texture.getTextureUnit());

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

    const mvp = zlm.Mat4.createAngleAxis(
        zlm.Vec3.unitZ,
        std.math.pi / 180.0 * @intToFloat(f32, s.frame),
    ).transpose();
    shader_program.setUniformByName("u_mvp", mvp);
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
