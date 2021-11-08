const std = @import("std");
const zp = @import("zplay");
const gl = zp.gl;
const alg = zp.alg;

const vertex_shader =
    \\#version 330 core
    \\layout (location = 0) in vec3 a_pos;
    \\layout (location = 1) in vec3 a_normal;
    \\
    \\out vec3 v_pos;
    \\out vec3 v_normal;
    \\
    \\uniform mat4 u_model;
    \\uniform mat4 u_normal;
    \\uniform mat4 u_view;
    \\uniform mat4 u_project;
    \\
    \\void main()
    \\{
    \\    gl_Position = u_project * u_view * u_model * vec4(a_pos, 1.0);
    \\    v_pos = vec3(u_model * vec4(a_pos, 1.0));
    \\    v_normal = mat3(u_normal) * a_normal;
    \\}
;

const fragment_shader =
    \\#version 330 core
    \\out vec4 frag_color;
    \\
    \\in vec3 v_pos;
    \\in vec3 v_normal;
    \\
    \\uniform vec3 u_view_pos;
    \\
    \\struct Light {
    \\    vec3 ambient;
    \\    vec3 diffuse;
    \\    vec3 specular;
    \\    vec3 position;
    \\};
    \\uniform Light u_light;
    \\
    \\struct Material {
    \\    vec3 ambient;
    \\    vec3 diffuse;
    \\    vec3 specular;
    \\    float shiness;
    \\};
    \\uniform Material u_material;
    \\
    \\vec3 ambientColor(vec3 light_color,
    \\                  vec3 material_ambient)
    \\{
    \\    return light_color * material_ambient;
    \\}
    \\
    \\vec3 diffuseColor(vec3 light_color,
    \\                  vec3 light_pos,
    \\                  vec3 vertex_pos,
    \\                  vec3 vertex_normal,
    \\                  vec3 material_diffuse)
    \\{
    \\    vec3 norm = normalize(vertex_normal);
    \\    vec3 light_dir = normalize(light_pos - vertex_pos);
    \\    float diff = max(dot(norm, light_dir), 0.0);
    \\    return light_color * (diff * material_diffuse);
    \\}
    \\
    \\vec3 specularColor(vec3 light_color,
    \\                   vec3 light_pos,
    \\                   vec3 view_pos,
    \\                   vec3 vertex_pos,
    \\                   vec3 vertex_normal,
    \\                   vec3 material_specular,
    \\                   float material_shiness)
    \\{
    \\    vec3 norm = normalize(vertex_normal);
    \\    vec3 view_dir = normalize(view_pos - vertex_pos);
    \\    vec3 light_dir = normalize(light_pos - vertex_pos);
    \\    vec3 reflect_dir = reflect(-light_dir, norm);
    \\    float spec = pow(max(dot(view_dir, reflect_dir), 0.0), material_shiness);
    \\    return light_color * (spec * material_specular);
    \\}
    \\
    \\void main()
    \\{
    \\    vec3 ambient_color = ambientColor(u_light.ambient, u_material.ambient);
    \\    vec3 diffuse_color = diffuseColor(u_light.diffuse, u_light.position,
    \\                                      v_pos, v_normal, u_material.diffuse);
    \\    vec3 specular_color = specularColor(u_light.specular, u_light.position, u_view_pos,
    \\                                        v_pos, v_normal, u_material.specular,
    \\                                        u_material.shiness);
    \\
    \\    vec3 result = ambient_color + diffuse_color + specular_color;
    \\    frag_color = vec4(result, 1.0);
    \\}
;

const light_shader =
    \\#version 330 core
    \\out vec4 frag_color;
    \\
    \\uniform vec3 u_color;
    \\
    \\void main()
    \\{
    \\    frag_color = vec4(u_color, 1);
    \\}
;

var normal_shader_program: gl.ShaderProgram = undefined;
var light_shader_program: gl.ShaderProgram = undefined;
var cube_va: gl.VertexArray = undefined;
var camera = zp.util.Camera3D.fromPositionAndTarget(
    alg.Vec3.new(1, 2, 3),
    alg.Vec3.zero(),
    null,
);
var light = zp.util.Light3D.init(
    alg.Vec3.new(1.2, 1, 2),
    alg.Vec3.new(0.2, 0.2, 0.2),
    alg.Vec3.new(0.5, 0.5, 0.5),
    null,
);
var materials = [_]zp.util.Material3D{
    zp.util.Material3D.init(
        alg.Vec3.new(1, 0.5, 0.31),
        alg.Vec3.new(1, 0.5, 0.31),
        alg.Vec3.new(0.5, 0.5, 0.5),
        32,
    ),
    zp.util.Material3D.emerald,
    zp.util.Material3D.jade,
    zp.util.Material3D.obsidian,
    zp.util.Material3D.pearl,
    zp.util.Material3D.ruby,
    zp.util.Material3D.turquoise,
    zp.util.Material3D.brass,
    zp.util.Material3D.bronze,
    zp.util.Material3D.chrome,
    zp.util.Material3D.copper,
    zp.util.Material3D.gold,
    zp.util.Material3D.silver,
};

const vertices = [_]f32{
    -0.5, -0.5, -0.5, 0.0,  0.0,  -1.0,
    0.5,  -0.5, -0.5, 0.0,  0.0,  -1.0,
    0.5,  0.5,  -0.5, 0.0,  0.0,  -1.0,
    0.5,  0.5,  -0.5, 0.0,  0.0,  -1.0,
    -0.5, 0.5,  -0.5, 0.0,  0.0,  -1.0,
    -0.5, -0.5, -0.5, 0.0,  0.0,  -1.0,

    -0.5, -0.5, 0.5,  0.0,  0.0,  1.0,
    0.5,  -0.5, 0.5,  0.0,  0.0,  1.0,
    0.5,  0.5,  0.5,  0.0,  0.0,  1.0,
    0.5,  0.5,  0.5,  0.0,  0.0,  1.0,
    -0.5, 0.5,  0.5,  0.0,  0.0,  1.0,
    -0.5, -0.5, 0.5,  0.0,  0.0,  1.0,

    -0.5, 0.5,  0.5,  -1.0, 0.0,  0.0,
    -0.5, 0.5,  -0.5, -1.0, 0.0,  0.0,
    -0.5, -0.5, -0.5, -1.0, 0.0,  0.0,
    -0.5, -0.5, -0.5, -1.0, 0.0,  0.0,
    -0.5, -0.5, 0.5,  -1.0, 0.0,  0.0,
    -0.5, 0.5,  0.5,  -1.0, 0.0,  0.0,

    0.5,  0.5,  0.5,  1.0,  0.0,  0.0,
    0.5,  0.5,  -0.5, 1.0,  0.0,  0.0,
    0.5,  -0.5, -0.5, 1.0,  0.0,  0.0,
    0.5,  -0.5, -0.5, 1.0,  0.0,  0.0,
    0.5,  -0.5, 0.5,  1.0,  0.0,  0.0,
    0.5,  0.5,  0.5,  1.0,  0.0,  0.0,

    -0.5, -0.5, -0.5, 0.0,  -1.0, 0.0,
    0.5,  -0.5, -0.5, 0.0,  -1.0, 0.0,
    0.5,  -0.5, 0.5,  0.0,  -1.0, 0.0,
    0.5,  -0.5, 0.5,  0.0,  -1.0, 0.0,
    -0.5, -0.5, 0.5,  0.0,  -1.0, 0.0,
    -0.5, -0.5, -0.5, 0.0,  -1.0, 0.0,

    -0.5, 0.5,  -0.5, 0.0,  1.0,  0.0,
    0.5,  0.5,  -0.5, 0.0,  1.0,  0.0,
    0.5,  0.5,  0.5,  0.0,  1.0,  0.0,
    0.5,  0.5,  0.5,  0.0,  1.0,  0.0,
    -0.5, 0.5,  0.5,  0.0,  1.0,  0.0,
    -0.5, 0.5,  -0.5, 0.0,  1.0,  0.0,
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
    cube_va.setAttribute(0, 3, f32, false, 6 * @sizeOf(f32), 0);
    cube_va.setAttribute(1, 3, f32, false, 6 * @sizeOf(f32), 3 * @sizeOf(f32));

    // enable depth test
    gl.util.toggleCapability(.depth_test, true);

    std.log.info("game init", .{});
}

fn loop(ctx: *zp.Context) void {
    const S = struct {
        var current_material: usize = 0;
    };

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
                        .up => {
                            if (S.current_material == 0) {
                                S.current_material = materials.len - 1;
                            } else {
                                S.current_material -= 1;
                            }
                        },
                        .down => {
                            if (S.current_material == materials.len - 1) {
                                S.current_material = 0;
                            } else {
                                S.current_material += 1;
                            }
                        },
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

    // update light color
    var light_color = alg.Vec3.new(
        std.math.sin(ctx.tick * 2.0),
        std.math.sin(ctx.tick * 0.7),
        std.math.sin(ctx.tick * 1.3),
    );
    light.ambient = light_color.scale(0.2);
    light.diffuse = light_color.scale(0.5);

    // start drawing
    gl.util.clear(true, true, false, [_]f32{ 0.2, 0.2, 0.2, 1.0 });

    cube_va.use();
    const projection = alg.Mat4.perspective(
        camera.zoom,
        @intToFloat(f32, width) / @intToFloat(f32, height),
        0.1,
        100,
    );

    normal_shader_program.use();
    var model = alg.Mat4.identity();
    var normal = model.inv().transpose();
    normal_shader_program.setUniformByName("u_model", model);
    normal_shader_program.setUniformByName("u_normal", normal);
    normal_shader_program.setUniformByName("u_view", camera.getViewMatrix());
    normal_shader_program.setUniformByName("u_project", projection);
    normal_shader_program.setUniformByName("u_view_pos", camera.position);
    light.apply(&normal_shader_program, "u_light");
    materials[S.current_material].apply(&normal_shader_program, "u_material");
    gl.util.drawBuffer(.triangles, 0, 36);

    // draw light
    light_shader_program.use();
    light_shader_program.setUniformByName(
        "u_model",
        alg.Mat4.fromScale(alg.Vec3.set(0.2)).translate(light.position),
    );
    light_shader_program.setUniformByName("u_view", camera.getViewMatrix());
    light_shader_program.setUniformByName("u_project", projection);
    light_shader_program.setUniformByName("u_color", light_color);
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
