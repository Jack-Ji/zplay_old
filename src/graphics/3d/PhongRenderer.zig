const std = @import("std");
const assert = std.debug.assert;
const light = @import("light.zig");
const zp = @import("../../zplay.zig");
const gfx = zp.graphics;
const drawcall = gfx.gpu.drawcall;
const ShaderProgram = gfx.gpu.ShaderProgram;
const VertexArray = gfx.gpu.VertexArray;
const Renderer = gfx.Renderer;
const Camera = gfx.Camera;
const Mesh = gfx.Mesh;
const Material = gfx.Material;
const alg = zp.deps.alg;
const Mat4 = alg.Mat4;
const Vec2 = alg.Vec2;
const Vec3 = alg.Vec3;
const Self = @This();

const vertex_attribs = [_]u32{
    Renderer.ATTRIB_LOCATION_POS,
    Renderer.ATTRIB_LOCATION_NORMAL,
    Renderer.ATTRIB_LOCATION_TEXTURE1,
};

const shader_head =
    \\#version 330 core
    \\
;

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
    \\out vec3 v_frag_in_light_space;
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
    \\uniform sampler2D u_shadow_map;
    \\float calcShadowValue()
    \\{
    \\    
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

const vs = shader_head ++ vs_body;
const vs_instanced = shader_head ++ "\n#define INSTANCED_DRAW\n" ++ vs_body;
const fs = shader_head ++ fs_body;

const vs_shadow = shader_head ++ "\n#define SHADOW_DRAW\n" ++ vs_body;
const vs_instanced_shadow = shader_head ++ "\n#define INSTANCED_DRAW\n#define SHADOW_DRAW\n" ++ vs_body;
const fs_shadow = shader_head ++ "\n#define SHADOW_DRAW\n" ++ fs_body;

/// status of renderer
status: Renderer.Status = .not_ready,

/// shader programs
program: ShaderProgram = undefined,
program_instanced: ShaderProgram = undefined,

/// renderer features
pub const Option = struct {
    has_shadow: bool = true,
};

/// create a Phong lighting renderer
pub fn init(option: Option) Self {
    var self = Self{};
    if (option.has_shadow) {
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

/// get renderer
pub fn renderer(self: *Self) Renderer {
    return Renderer.init(self, begin, end, getVertexAttribs, render, renderInstanced);
}

/// apply lights to renderer
pub fn applyLights(self: *Self, lights: []light.Light) void {
    var old_status = self.status;

    self.begin(true);
    light.applyLights(self.getProgram(), lights);
    self.end();

    self.begin(false);
    light.applyLights(self.getProgram(), lights);
    self.end();

    // recover renderer's status
    switch (old_status) {
        .ready_to_draw => self.begin(false),
        .ready_to_draw_instanced => self.begin(true),
        else => {},
    }
}

/// begin rendering
fn begin(self: *Self, instanced_draw: bool) void {
    // enable program
    if (instanced_draw) {
        self.program_instanced.use();
        self.status = .ready_to_draw_instanced;
    } else {
        self.program.use();
        self.status = .ready_to_draw;
    }
}

/// end rendering
fn end(self: *Self) void {
    assert(self.status != .not_ready);
    self.getProgram().disuse();
    self.status = .not_ready;
}

/// get supported attributes
fn getVertexAttribs(self: *Self) []const u32 {
    _ = self;
    return &vertex_attribs;
}

// get current using shader program
inline fn getProgram(self: *Self) *ShaderProgram {
    assert(self.status != .not_ready);
    return if (self.status == .ready_to_draw) &self.program else &self.program_instanced;
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
}

/// init common uniform variables
fn initCommonUniformVars(
    self: *Self,
    projection: ?Mat4,
    camera: ?Camera,
    material: ?Material,
) void {
    self.getProgram().setUniformByName("u_project", projection.?);
    self.getProgram().setUniformByName("u_view", camera.?.getViewMatrix());
    self.getProgram().setUniformByName("u_view_pos", camera.?.position);
    self.applyMaterial(material.?);
}

/// render geometries
fn render(
    self: *Self,
    vertex_array: VertexArray,
    use_elements: bool,
    primitive: drawcall.PrimitiveType,
    offset: u32,
    count: u32,
    transform: Mat4,
    projection: ?Mat4,
    camera: ?Camera,
    material: ?Material,
) !void {
    assert(self.status == .ready_to_draw);
    vertex_array.use();
    defer vertex_array.disuse();

    // set uniforms
    self.initCommonUniformVars(projection, camera, material);
    self.getProgram().setUniformByName("u_model", transform);
    self.getProgram().setUniformByName("u_normal", transform.inv().transpose());

    if (use_elements) {
        drawcall.drawElements(primitive, offset, count, u32);
    } else {
        drawcall.drawBuffer(primitive, offset, count);
    }
}

pub fn renderInstanced(
    self: *Self,
    vertex_array: VertexArray,
    use_elements: bool,
    primitive: drawcall.PrimitiveType,
    offset: u32,
    count: u32,
    transforms: Renderer.InstanceTransformArray,
    projection: ?Mat4,
    camera: ?Camera,
    material: ?Material,
    instance_count: u32,
) anyerror!void {
    assert(self.status == .ready_to_draw_instanced);
    vertex_array.use();
    defer vertex_array.disuse();

    // enable instance transforms attribute
    transforms.enableAttributes();

    // set uniforms
    self.initCommonUniformVars(projection, camera, material);

    if (use_elements) {
        drawcall.drawElementsInstanced(
            primitive,
            offset,
            count,
            u32,
            instance_count,
        );
    } else {
        drawcall.drawBufferInstanced(
            primitive,
            offset,
            count,
            instance_count,
        );
    }
}
