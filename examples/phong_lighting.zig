const std = @import("std");
const zp = @import("zplay");
const gl = zp.gl;
const alg = zp.alg;

const vertex_shader =
    \\#version 330 core
    \\layout (location = 0) in vec3 a_pos;
    \\layout (location = 1) in vec3 a_normal;
    \\layout (location = 2) in vec2 a_tex;
    \\
    \\out vec3 v_pos;
    \\out vec3 v_normal;
    \\out vec2 v_tex;
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
    \\    v_tex = a_tex;
    \\}
;

const fragment_shader =
    \\#version 330 core
    \\out vec4 frag_color;
    \\
    \\in vec3 v_pos;
    \\in vec3 v_normal;
    \\in vec2 v_tex;
    \\
    \\uniform vec3 u_view_pos;
    \\
    \\struct DirectionalLight {
    \\    vec3 ambient;
    \\    vec3 diffuse;
    \\    vec3 specular;
    \\    vec3 direction;
    \\};
    \\uniform DirectionalLight u_directional_light;
    \\
    \\struct PointLight {
    \\    vec3 ambient;
    \\    vec3 diffuse;
    \\    vec3 specular;
    \\    vec3 position;
    \\    float constant;
    \\    float linear;
    \\    float quadratic;
    \\};
    \\uniform PointLight u_point_light;
    \\
    \\struct SpotLight {
    \\    vec3 ambient;
    \\    vec3 diffuse;
    \\    vec3 specular;
    \\    vec3 position;
    \\    vec3 direction;
    \\    float constant;
    \\    float linear;
    \\    float quadratic;
    \\    float cutoff;
    \\    float outer_cutoff;
    \\};
    \\uniform SpotLight u_spot_light;
    \\
    \\struct Material {
    \\    sampler2D diffuse;
    \\    sampler2D specular;
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
    \\vec3 diffuseColor(vec3 light_dir,
    \\                  vec3 light_color,
    \\                  vec3 vertex_normal,
    \\                  vec3 material_diffuse)
    \\{
    \\    vec3 norm = normalize(vertex_normal);
    \\    float diff = max(dot(norm, light_dir), 0.0);
    \\    return light_color * (diff * material_diffuse);
    \\}
    \\
    \\vec3 specularColor(vec3 light_dir,
    \\                   vec3 light_color,
    \\                   vec3 view_dir,
    \\                   vec3 vertex_normal,
    \\                   vec3 material_specular,
    \\                   float material_shiness)
    \\{
    \\    vec3 norm = normalize(vertex_normal);
    \\    vec3 reflect_dir = reflect(-light_dir, norm);
    \\    float spec = pow(max(dot(view_dir, reflect_dir), 0.0), material_shiness);
    \\    return light_color * (spec * material_specular);
    \\}
    \\
    \\vec3 applyDirectionalLight(DirectionalLight light)
    \\{
    \\    vec3 light_dir = -light.direction;
    \\    vec3 view_dir = normalize(u_view_pos - v_pos);
    \\    vec3 material_diffuse = vec3(texture(u_material.diffuse, v_tex));
    \\    vec3 material_specular = vec3(texture(u_material.specular, v_tex));
    \\
    \\    vec3 ambient_color = ambientColor(light.ambient, material_diffuse);
    \\    vec3 diffuse_color = diffuseColor(light_dir, light.diffuse, v_normal, material_diffuse);
    \\    vec3 specular_color = specularColor(light_dir, light.specular, view_dir,
    \\                                        v_normal, material_specular, u_material.shiness);
    \\    vec3 result = ambient_color + diffuse_color + specular_color;
    \\    return result;
    \\}
    \\
    \\vec3 applyPointLight(PointLight light)
    \\{
    \\    vec3 light_dir = normalize(light.position - v_pos);
    \\    vec3 view_dir = normalize(u_view_pos - v_pos);
    \\    vec3 material_diffuse = vec3(texture(u_material.diffuse, v_tex));
    \\    vec3 material_specular = vec3(texture(u_material.specular, v_tex));
    \\    float distance = length(light.position - v_pos);
    \\    float attenuation = 1.0 / (light.constant + light.linear * distance +
    \\              light.quadratic * distance * distance);
    \\
    \\    vec3 ambient_color = ambientColor(light.ambient, material_diffuse);
    \\    vec3 diffuse_color = diffuseColor(light_dir, light.diffuse, v_normal, material_diffuse);
    \\    vec3 specular_color = specularColor(light_dir, light.specular, view_dir,
    \\                                        v_normal, material_specular, u_material.shiness);
    \\    vec3 result = (ambient_color + diffuse_color + specular_color) * attenuation;
    \\    return result;
    \\}
    \\
    \\vec3 applySpotLight(SpotLight light)
    \\{
    \\    vec3 light_dir = normalize(light.position - v_pos);
    \\    vec3 view_dir = normalize(u_view_pos - v_pos);
    \\    vec3 material_diffuse = vec3(texture(u_material.diffuse, v_tex));
    \\    vec3 material_specular = vec3(texture(u_material.specular, v_tex));
    \\    float distance = length(light.position - v_pos);
    \\    float attenuation = 1.0 / (light.constant + light.linear * distance +
    \\              light.quadratic * distance * distance);
    \\    float theta = dot(light_dir, normalize(-light.direction));
    \\    float epsilon = light.cutoff - light.outer_cutoff;
    \\    float intensity = clamp((theta - light.outer_cutoff) / epsilon, 0.0, 1.0);
    \\
    \\    vec3 ambient_color = ambientColor(light.ambient, material_diffuse);
    \\    vec3 diffuse_color = diffuseColor(light_dir, light.diffuse, v_normal, material_diffuse);
    \\    vec3 specular_color = specularColor(light_dir, light.specular, view_dir,
    \\                                        v_normal, material_specular, u_material.shiness);
    \\    vec3 result = ambient_color + (diffuse_color + specular_color) * intensity;
    \\
    \\    return result * attenuation;
    \\}
    \\
    \\void main()
    \\{
    \\    //vec3 result = applyDirectionalLight(u_directional_light);
    \\    //vec3 result = applyPointLight(u_point_light);
    \\    vec3 result = applySpotLight(u_spot_light);
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
    .{
        .spot = .{
            .ambient = alg.Vec3.new(0.2, 0.2, 0.2),
            .diffuse = alg.Vec3.new(0.5, 0.5, 0.5),
            .position = alg.Vec3.new(1.2, 1, 2),
            .direction = alg.Vec3.new(1.2, 1, 2).negate(),
            .linear = 0.09,
            .quadratic = 0.032,
            .cutoff = std.math.cos(alg.toRadians(@as(f32, 12.5))),
            .outer_cutoff = std.math.cos(alg.toRadians(@as(f32, 17.5))),
        },
    },
);
var material: zp.util.Material3D = undefined;

// position, normal, texture coord
const vertices = [_]f32{
    -0.5, -0.5, -0.5, 0.0,  0.0,  -1.0, 0.0, 0.0,
    0.5,  -0.5, -0.5, 0.0,  0.0,  -1.0, 1.0, 0.0,
    0.5,  0.5,  -0.5, 0.0,  0.0,  -1.0, 1.0, 1.0,
    0.5,  0.5,  -0.5, 0.0,  0.0,  -1.0, 1.0, 1.0,
    -0.5, 0.5,  -0.5, 0.0,  0.0,  -1.0, 0.0, 1.0,
    -0.5, -0.5, -0.5, 0.0,  0.0,  -1.0, 0.0, 0.0,

    -0.5, -0.5, 0.5,  0.0,  0.0,  1.0,  0.0, 0.0,
    0.5,  -0.5, 0.5,  0.0,  0.0,  1.0,  1.0, 0.0,
    0.5,  0.5,  0.5,  0.0,  0.0,  1.0,  1.0, 1.0,
    0.5,  0.5,  0.5,  0.0,  0.0,  1.0,  1.0, 1.0,
    -0.5, 0.5,  0.5,  0.0,  0.0,  1.0,  0.0, 1.0,
    -0.5, -0.5, 0.5,  0.0,  0.0,  1.0,  0.0, 0.0,

    -0.5, 0.5,  0.5,  -1.0, 0.0,  0.0,  1.0, 0.0,
    -0.5, 0.5,  -0.5, -1.0, 0.0,  0.0,  1.0, 1.0,
    -0.5, -0.5, -0.5, -1.0, 0.0,  0.0,  0.0, 1.0,
    -0.5, -0.5, -0.5, -1.0, 0.0,  0.0,  0.0, 1.0,
    -0.5, -0.5, 0.5,  -1.0, 0.0,  0.0,  0.0, 0.0,
    -0.5, 0.5,  0.5,  -1.0, 0.0,  0.0,  1.0, 0.0,

    0.5,  0.5,  0.5,  1.0,  0.0,  0.0,  1.0, 0.0,
    0.5,  0.5,  -0.5, 1.0,  0.0,  0.0,  1.0, 1.0,
    0.5,  -0.5, -0.5, 1.0,  0.0,  0.0,  0.0, 1.0,
    0.5,  -0.5, -0.5, 1.0,  0.0,  0.0,  0.0, 1.0,
    0.5,  -0.5, 0.5,  1.0,  0.0,  0.0,  0.0, 0.0,
    0.5,  0.5,  0.5,  1.0,  0.0,  0.0,  1.0, 0.0,

    -0.5, -0.5, -0.5, 0.0,  -1.0, 0.0,  0.0, 1.0,
    0.5,  -0.5, -0.5, 0.0,  -1.0, 0.0,  1.0, 1.0,
    0.5,  -0.5, 0.5,  0.0,  -1.0, 0.0,  1.0, 0.0,
    0.5,  -0.5, 0.5,  0.0,  -1.0, 0.0,  1.0, 0.0,
    -0.5, -0.5, 0.5,  0.0,  -1.0, 0.0,  0.0, 0.0,
    -0.5, -0.5, -0.5, 0.0,  -1.0, 0.0,  0.0, 1.0,

    -0.5, 0.5,  -0.5, 0.0,  1.0,  0.0,  0.0, 1.0,
    0.5,  0.5,  -0.5, 0.0,  1.0,  0.0,  1.0, 1.0,
    0.5,  0.5,  0.5,  0.0,  1.0,  0.0,  1.0, 0.0,
    0.5,  0.5,  0.5,  0.0,  1.0,  0.0,  1.0, 0.0,
    -0.5, 0.5,  0.5,  0.0,  1.0,  0.0,  0.0, 0.0,
    -0.5, 0.5,  -0.5, 0.0,  1.0,  0.0,  0.0, 1.0,
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
    normal_shader_program = gl.ShaderProgram.init(vertex_shader, fragment_shader);
    light_shader_program = gl.ShaderProgram.init(vertex_shader, light_shader);

    // vertex array
    cube_va = gl.VertexArray.init(5);
    cube_va.use();
    defer cube_va.disuse();
    cube_va.bufferData(0, f32, &vertices, .array_buffer, .static_draw);
    cube_va.setAttribute(0, 3, f32, false, 8 * @sizeOf(f32), 0);
    cube_va.setAttribute(1, 3, f32, false, 8 * @sizeOf(f32), 3 * @sizeOf(f32));
    cube_va.setAttribute(2, 2, f32, false, 8 * @sizeOf(f32), 6 * @sizeOf(f32));

    // material init
    var diffuse_texture = try zp.util.Texture2D.init("assets/container2.png", null, false);
    var specular_texture = try zp.util.Texture2D.init("assets/container2_specular.png", .texture_unit_1, false);
    material = zp.util.Material3D.init(
        diffuse_texture,
        specular_texture,
        32,
    );

    // enable depth test
    gl.util.toggleCapability(.depth_test, true);

    std.log.info("game init", .{});
}

fn loop(ctx: *zp.Context) void {
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
    var light_color = alg.Vec3.one();
    //var light_color = alg.Vec3.new(
    //    std.math.sin(ctx.tick * 2.0),
    //    std.math.sin(ctx.tick * 0.7),
    //    std.math.sin(ctx.tick * 1.3),
    //);
    light.updateColors(light_color.scale(0.2), light_color.scale(0.5), null);

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
    normal_shader_program.setUniformByName("u_view", camera.getViewMatrix());
    normal_shader_program.setUniformByName("u_project", projection);
    normal_shader_program.setUniformByName("u_view_pos", camera.position);
    light.apply(&normal_shader_program, "u_spot_light");
    material.apply(&normal_shader_program, "u_material");
    for (cube_positions) |pos, i| {
        const model = alg.Mat4.fromRotation(
            20 * @intToFloat(f32, i),
            alg.Vec3.new(1, 0.3, 0.5),
        ).translate(pos);
        const normal = model.inv().transpose();
        normal_shader_program.setUniformByName("u_model", model);
        normal_shader_program.setUniformByName("u_normal", normal);
        gl.util.drawBuffer(.triangles, 0, 36);
    }

    // draw light
    if (light.getPosition()) |pos| {
        light_shader_program.use();
        light_shader_program.setUniformByName(
            "u_model",
            alg.Mat4.fromScale(alg.Vec3.set(0.2)).translate(pos),
        );
        light_shader_program.setUniformByName("u_view", camera.getViewMatrix());
        light_shader_program.setUniformByName("u_project", projection);
        light_shader_program.setUniformByName("u_color", light_color);
        gl.util.drawBuffer(.triangles, 0, 36);
    }
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
