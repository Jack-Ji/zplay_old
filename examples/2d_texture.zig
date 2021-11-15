const std = @import("std");
const zp = @import("zplay");
const gl = zp.gl;
const alg = zp.alg;
const Mat4 = alg.Mat4;
const SimpleRenderer = zp.@"3d".SimpleRenderer;
const Texture2D = zp.texture.Texture2D;

const fragment_shader =
    \\uniform sampler2D u_texture1;
    \\uniform sampler2D u_texture2;
    \\
    \\void main()
    \\{
    \\    frag_color = mix(texture(u_texture1, v_tex), texture(u_texture2, v_tex), 0.3);
    \\}
;

var simple_renderer: SimpleRenderer = undefined;
var vertex_array: gl.VertexArray = undefined;
var texture1: Texture2D = undefined;
var texture2: Texture2D = undefined;
var wireframe_mode = false;

const vertices = [_]f32{
    // positions, texture coords
    0.5, 0.5, 0.0, 1.0, 1.0, // top right
    0.5, -0.5, 0.0, 1.0, 0.0, // bottom right
    -0.5, -0.5, 0.0, 0.0, 0.0, // bottom left
    -0.5, 0.5, 0.0, 0.0, 1.0, // top left
};

const indices = [_]u16{
    0, 1, 3, // 1st triangle
    1, 2, 3, // 2nd triangle
};

fn init(ctx: *zp.Context) anyerror!void {
    _ = ctx;

    // simple renderer
    simple_renderer = SimpleRenderer.init(fragment_shader);

    // vertex array
    vertex_array = gl.VertexArray.init(5);
    vertex_array.use();
    defer vertex_array.disuse();
    vertex_array.bufferData(0, f32, &vertices, .array_buffer, .static_draw);
    vertex_array.setAttribute(0, 0, 3, f32, false, 5 * @sizeOf(f32), 0);
    vertex_array.setAttribute(0, 1, 2, f32, false, 5 * @sizeOf(f32), 3 * @sizeOf(f32));
    vertex_array.bufferData(1, u16, &indices, .element_array_buffer, .static_draw);

    // load texture
    texture1 = try zp.texture.Texture2D.init("assets/wall.jpg", null, false);
    texture2 = try zp.texture.Texture2D.init("assets/awesomeface.png", .texture_unit_1, false);

    std.log.info("game init", .{});
}

fn loop(ctx: *zp.Context) void {
    const S = struct {
        var frame: f32 = 0;
    };
    S.frame += 1;

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

    // start drawing
    gl.util.clear(true, false, false, [_]f32{ 0.2, 0.3, 0.3, 1.0 });

    const model = alg.Mat4.fromTranslate(alg.Vec3.new(0.5, 0.5, 0)).rotate(S.frame, alg.Vec3.forward());
    simple_renderer.begin();
    simple_renderer.program.setUniformByName("u_texture1", texture1.tex.getTextureUnit());
    simple_renderer.program.setUniformByName("u_texture2", texture2.tex.getTextureUnit());
    simple_renderer.render(
        vertex_array,
        true,
        .triangles,
        0,
        6,
        model,
        Mat4.identity(),
        null,
        null,
    ) catch unreachable;
    simple_renderer.end();
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
        .enable_resizable = true,
    });
}
