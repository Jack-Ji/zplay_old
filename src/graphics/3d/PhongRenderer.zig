const std = @import("std");
const assert = std.debug.assert;
const light = @import("light.zig");
const zp = @import("../../zplay.zig");
const gfx = zp.graphics;
const drawcall = gfx.gpu.drawcall;
const ShaderProgram = gfx.gpu.ShaderProgram;
const Renderer = gfx.Renderer;
const Material = gfx.Material;
const alg = zp.deps.alg;
const Mat4 = alg.Mat4;
const Vec2 = alg.Vec2;
const Vec3 = alg.Vec3;
const Self = @This();

const vs_body = light.ShaderDefinitions ++
    \\layout (location = 0) in vec3 a_pos;
    \\layout (location = 2) in vec3 a_normal;
    \\layout (location = 4) in vec2 a_tex1;
    \\layout (location = 10) in mat4 a_transform;
    \\
    \\out vec3 v_pos;
    \\out vec3 v_normal;
    \\out vec2 v_tex;
    \\
    \\#ifdef SHADOW_DRAW
    \\out vec4 v_frag_in_light_space;
    \\#endif
    \\
    \\uniform mat4 u_model = mat4(1.0);
    \\uniform mat4 u_normal = mat4(1.0);
    \\uniform mat4 u_view = mat4(1.0);
    \\uniform mat4 u_project = mat4(1.0);
    \\
    \\void main()
    \\{
    \\#ifdef INSTANCED_DRAW
    \\    v_pos = vec3(a_transform * vec4(a_pos, 1.0));
    \\    v_normal = mat3(transpose(inverse(a_transform))) * a_normal;
    \\#else
    \\    v_pos = vec3(u_model * vec4(a_pos, 1.0));
    \\    v_normal = mat3(u_normal) * a_normal;
    \\#endif
    \\    gl_Position = u_project * u_view * vec4(v_pos, 1.0);
    \\    v_tex = a_tex1;
    \\#ifdef SHADOW_DRAW
    \\    v_frag_in_light_space = u_directional_light.space_matrix * vec4(v_pos, 1.0);
    \\#endif
    \\}
;

const fs_body = light.ShaderDefinitions ++
    \\out vec4 frag_color;
    \\in vec3 v_pos;
    \\in vec3 v_normal;
    \\in vec2 v_tex;
    \\
    \\uniform vec3 u_view_pos;
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
    \\    vec3 halfway_dir = normalize(light_dir + view_dir);
    \\    float spec = pow(max(dot(norm, halfway_dir), 0.0), material_shiness);
    \\    return light_color * (spec * material_specular);
    \\}
    \\
    \\#ifdef SHADOW_DRAW
    \\in vec4 v_frag_in_light_space;
    \\uniform sampler2D u_shadow_map;
    \\float calcShadowValue(vec3 light_dir, vec3 vertex_normal)
    \\{
    \\    vec3 proj_coords = v_frag_in_light_space.xyz / v_frag_in_light_space.w;
    \\    proj_coords = proj_coords * 0.5 + 0.5;
    \\    float current_depth = proj_coords.z;
    \\    float shadow = 0;
    \\    if (current_depth <= 1.0) {
    \\        float bias = max(0.05 * (1.0 - dot(light_dir, vertex_normal)), 0.005);
    \\        vec2 texture_size = 1.0 / textureSize(u_shadow_map, 0);
    \\
    \\        // PCF - percentage-closer filtering
    \\        for (int x = -1; x <= 1; ++x) {
    \\            for (int y = -1; y <= 1; ++y) {
    \\                float closest_depth = texture(u_shadow_map, proj_coords.xy + vec2(x, y) * texture_size).r;
    \\                shadow += current_depth - bias > closest_depth ? 1.0 : 0.0;
    \\            }
    \\        }
    \\        shadow /= 9.0;
    \\    }
    \\    return shadow;
    \\}
    \\#endif
    \\
    \\vec3 applyDirectionalLight(DirectionalLight light,
    \\                           vec3 material_diffuse,
    \\                           vec3 material_specular,
    \\                           float shiness)
    \\{
    \\    vec3 light_dir = normalize(-light.direction);
    \\    vec3 view_dir = normalize(u_view_pos - v_pos);
    \\    vec3 ambient_color = ambientColor(light.ambient, material_diffuse);
    \\    vec3 diffuse_color = diffuseColor(light_dir, light.diffuse, v_normal, material_diffuse);
    \\    vec3 specular_color = specularColor(light_dir, light.specular, view_dir,
    \\                                        v_normal, material_specular, shiness);
    \\#ifdef SHADOW_DRAW
    \\    float shadow = calcShadowValue(light_dir, v_normal);
    \\    vec3 result = ambient_color + (1.0 - shadow) * (diffuse_color + specular_color);
    \\#else
    \\    vec3 result = ambient_color + diffuse_color + specular_color;
    \\#endif
    \\    return result;
    \\}
    \\
    \\vec3 applyPointLight(PointLight light,
    \\                     vec3 material_diffuse,
    \\                     vec3 material_specular,
    \\                     float shiness)
    \\{
    \\    vec3 light_dir = normalize(light.position - v_pos);
    \\    vec3 view_dir = normalize(u_view_pos - v_pos);
    \\    float distance = length(light.position - v_pos);
    \\    float attenuation = 1.0 / (light.constant + light.linear * distance +
    \\              light.quadratic * distance * distance);
    \\
    \\    vec3 ambient_color = ambientColor(light.ambient, material_diffuse);
    \\    vec3 diffuse_color = diffuseColor(light_dir, light.diffuse, v_normal, material_diffuse);
    \\    vec3 specular_color = specularColor(light_dir, light.specular, view_dir,
    \\                                        v_normal, material_specular, shiness);
    \\    vec3 result = ambient_color + diffuse_color + specular_color;
    \\    return result * attenuation;
    \\}
    \\
    \\vec3 applySpotLight(SpotLight light,
    \\                    vec3 material_diffuse,
    \\                    vec3 material_specular,
    \\                    float shiness)
    \\{
    \\    vec3 light_dir = normalize(light.position - v_pos);
    \\    vec3 view_dir = normalize(u_view_pos - v_pos);
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
    \\                                        v_normal, material_specular, shiness);
    \\    vec3 result = ambient_color + (diffuse_color + specular_color) * intensity;
    \\    return result * attenuation;
    \\}
    \\
    \\void main()
    \\{
    \\    vec3 material_diffuse = vec3(texture(u_material.diffuse, v_tex));
    \\    vec3 material_specular = vec3(texture(u_material.specular, v_tex));
    \\    float shiness = u_material.shiness;
    \\    vec3 result = applyDirectionalLight(u_directional_light, material_diffuse, material_specular, shiness);
    \\    for (int i = 0; i < u_point_light_count; i++) {
    \\      result += applyPointLight(u_point_lights[i], material_diffuse, material_specular, shiness);
    \\    }
    \\    for (int i = 0; i < u_spot_light_count; i++) {
    \\      result += applySpotLight(u_spot_lights[i], material_diffuse, material_specular, shiness);
    \\    }
    \\    frag_color = vec4(result, 1.0);
    \\}
;

const vs = Renderer.shader_head ++ vs_body;
const vs_instanced = Renderer.shader_head ++ "\n#define INSTANCED_DRAW\n" ++ vs_body;
const fs = Renderer.shader_head ++ fs_body;

const vs_shadow = Renderer.shader_head ++ "\n#define SHADOW_DRAW\n" ++ vs_body;
const vs_instanced_shadow = Renderer.shader_head ++ "\n#define INSTANCED_DRAW\n#define SHADOW_DRAW\n" ++ vs_body;
const fs_shadow = Renderer.shader_head ++ "\n#define SHADOW_DRAW\n" ++ fs_body;

/// shader programs
program: ShaderProgram = undefined,
program_instanced: ShaderProgram = undefined,

/// rendering options
has_shadow: bool = undefined,

/// renderer features
pub const Option = struct {
    has_shadow: bool = false,
};

/// create a Phong lighting renderer
pub fn init(option: Option) Self {
    var self = Self{};
    self.has_shadow = option.has_shadow;
    if (self.has_shadow) {
        self.program = ShaderProgram.init(vs_shadow, fs_shadow, null);
        self.program_instanced = ShaderProgram.init(vs_instanced_shadow, fs_shadow, null);
    } else {
        self.program = ShaderProgram.init(vs, fs, null);
        self.program_instanced = ShaderProgram.init(vs_instanced, fs, null);
    }
    return self;
}

/// free resources
pub fn deinit(self: *Self) void {
    self.program.deinit();
    self.program_instanced.deinit();
}

/// get renderer instance
pub fn renderer(self: *Self) Renderer {
    return Renderer.init(self, draw);
}

/// get light renderer instance
pub fn lightRenderer(self: *Self) light.Renderer {
    return light.Renderer.init(self, applyLights);
}

/// apply lights to renderer
pub fn applyLights(self: *Self, lights: []light.Light) void {
    self.program.use();
    light.applyLights(&self.program, lights);
    self.program.disuse();

    self.program_instanced.use();
    light.applyLights(&self.program_instanced, lights);
    self.program_instanced.disuse();
}

/// use material data
fn applyMaterial(self: *Self, material: Material) void {
    assert(material.data == .phong);
    var buf: [64]u8 = undefined;
    self.getProgram().setUniformByName(
        std.fmt.bufPrintZ(&buf, "u_material.diffuse", .{}) catch unreachable,
        material.data.phong.diffuse_map.getTextureUnit(),
    );
    self.getProgram().setUniformByName(
        std.fmt.bufPrintZ(&buf, "u_material.specular", .{}) catch unreachable,
        material.data.phong.specular_map.getTextureUnit(),
    );
    self.getProgram().setUniformByName(
        std.fmt.bufPrintZ(&buf, "u_material.shiness", .{}) catch unreachable,
        material.data.phong.shiness,
    );
    if (self.has_shadow) {
        self.getProgram().setUniformByName(
            "u_shadow_map",
            material.data.phong.shadow_map.?.getTextureUnit(),
        );
    }
}

/// generic rendering implementation
pub fn draw(self: *Self, input: Renderer.Input) anyerror!void {
    assert(input.vds.?.items.len > 0);
    var is_instanced_drawing = input.vds.?.items[0].transform == .instanced;
    var prog = if (is_instanced_drawing) &self.program_instanced else &self.program;
    prog.use();
    defer prog.disuse();

    // set uniforms
    prog.setUniformByName("u_project", input.projection.?);
    prog.setUniformByName("u_view", input.camera.?.getViewMatrix());
    prog.setUniformByName("u_view_pos", input.camera.?.position);

    // render vertex data one by one
    var current_material: *Material = undefined;
    for (input.vds.?.items) |vd| {
        vd.vertex_array.use();
        defer vd.vertex_array.disuse();

        // apply material
        var mr: *Material = input.material orelse vd.material.?;
        if (mr != current_material) {
            assert(mr.data == .phong);
            var buf: [64]u8 = undefined;
            prog.setUniformByName(
                std.fmt.bufPrintZ(&buf, "u_material.diffuse", .{}) catch unreachable,
                mr.data.phong.diffuse_map.getTextureUnit(),
            );
            prog.setUniformByName(
                std.fmt.bufPrintZ(&buf, "u_material.specular", .{}) catch unreachable,
                mr.data.phong.specular_map.getTextureUnit(),
            );
            prog.setUniformByName(
                std.fmt.bufPrintZ(&buf, "u_material.shiness", .{}) catch unreachable,
                mr.data.phong.shiness,
            );
            if (self.has_shadow) {
                prog.setUniformByName(
                    "u_shadow_map",
                    mr.data.phong.shadow_map.?.getTextureUnit(),
                );
            }
        }

        // send draw command
        if (is_instanced_drawing) {
            vd.transform.instanced.enableAttributes();
            if (vd.element_draw) {
                drawcall.drawElementsInstanced(
                    vd.primitive,
                    vd.offset,
                    vd.count,
                    u32,
                    vd.transform.instanced.count,
                );
            } else {
                drawcall.drawBufferInstanced(
                    vd.primitive,
                    vd.offset,
                    vd.count,
                    vd.transform.instanced.count,
                );
            }
        } else {
            prog.setUniformByName("u_model", vd.transform.single);
            prog.setUniformByName("u_normal", vd.transform.single.inv().transpose());
            if (vd.element_draw) {
                drawcall.drawElements(vd.primitive, vd.offset, vd.count, u32);
            } else {
                drawcall.drawBuffer(vd.primitive, vd.offset, vd.count);
            }
        }
    }
}
