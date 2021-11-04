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
var fov: f32 = 45;
var camera = zp.util.Camera3D.fromPositionAndTarget(
    alg.Vec3.new(0, 0, 3),
    alg.Vec3.zero(),
    null,
);

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
    const texture1 = try zp.util.Texture2D.init("assets/wall.jpg", .texture_unit_0, false);
    const texture2 = try zp.util.Texture2D.init("assets/awesomeface.png", .texture_unit_1, true);

    // only necessary when not using texture unit 0
    shader_program.use();
    defer shader_program.disuse();
    shader_program.setUniformByName("u_texture1", texture1.tex.getTextureUnit());
    shader_program.setUniformByName("u_texture2", texture2.tex.getTextureUnit());

    // enable depth test
    gl.util.toggleCapability(.depth_test, true);

    std.log.info("game init", .{});
}

fn loop(ctx: *zp.Context) void {
    const S = struct {
        var frame: f32 = 0;
        var axis = alg.Vec4.new(1, 1, 1, 0);
        var last_tick: ?f32 = null;
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
                        .m => ctx.toggleRelativeMouseMode(null),
                        .v => ctx.toggleVsyncMode(null),
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
                    .wheel => |scroll| {
                        fov -= @intToFloat(f32, scroll.scroll_y);
                        if (fov < 1) {
                            fov = 1;
                        }
                        if (fov > 45) {
                            fov = 45;
                        }
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
    gl.util.clear(true, true, false, [_]f32{ 0.2, 0.3, 0.3, 1.0 });

    shader_program.use();
    vertex_array.use();

    const projection = alg.Mat4.perspective(
        fov,
        @intToFloat(f32, width) / @intToFloat(f32, height),
        0.1,
        100,
    );
    S.axis = alg.Mat4.fromRotation(1, alg.Vec3.new(-1, 1, -1)).multByVec4(S.axis);
    const model = alg.Mat4.fromRotation(
        S.frame,
        alg.Vec3.new(S.axis.x, S.axis.y, S.axis.z),
    );
    const mvp = projection.mult(camera.getViewMatrix()).mult(model);
    shader_program.setUniformByName("u_mvp", mvp);

    gl.util.drawBuffer(.triangles, 0, 36);
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
