const std = @import("std");
const Camera = @import("Camera.zig");
const Light = @import("Light.zig");
const Material = @import("Material.zig");
const Mesh = @import("Mesh.zig");
const Renderer = @import("Renderer.zig");
const zp = @import("../lib.zig");
const gl = zp.gl;
const alg = zp.alg;
const Mat4 = alg.Mat4;
const Vec2 = alg.Vec2;
const Vec3 = alg.Vec3;
const Self = @This();

const max_point_light_num = 16;
const max_spot_light_num = 16;

pub const Error = error{
    too_many_point_lights,
    too_many_spot_lights,
    renderer_not_active,
};

/// vertex attribute locations
pub const ATTRIB_LOCATION_POS = 0;
pub const ATTRIB_LOCATION_NORMAL = 1;
pub const ATTRIB_LOCATION_TEX = 2;

const vs =
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

const fs =
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
    \\#define NR_POINT_LIGHTS 16
    \\uniform int u_point_light_count;
    \\uniform PointLight u_point_lights[NR_POINT_LIGHTS];
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
    \\#define NR_SPOT_LIGHTS 16
    \\uniform int u_spot_light_count;
    \\uniform SpotLight u_spot_lights[NR_SPOT_LIGHTS];
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
    \\vec3 applyDirectionalLight(DirectionalLight light, vec3 material_diffuse, vec3 material_specular, float shiness)
    \\{
    \\    vec3 light_dir = normalize(-light.direction);
    \\    vec3 view_dir = normalize(u_view_pos - v_pos);
    \\    vec3 ambient_color = ambientColor(light.ambient, material_diffuse);
    \\    vec3 diffuse_color = diffuseColor(light_dir, light.diffuse, v_normal, material_diffuse);
    \\    vec3 specular_color = specularColor(light_dir, light.specular, view_dir,
    \\                                        v_normal, material_specular, shiness);
    \\    vec3 result = ambient_color + diffuse_color + specular_color;
    \\    return result;
    \\}
    \\
    \\vec3 applyPointLight(PointLight light, vec3 material_diffuse, vec3 material_specular, float shiness)
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
    \\    vec3 result = (ambient_color + diffuse_color + specular_color) * attenuation;
    \\    return result;
    \\}
    \\
    \\vec3 applySpotLight(SpotLight light, vec3 material_diffuse, vec3 material_specular, float shiness)
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
    \\
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

/// lighting program
program: gl.ShaderProgram = undefined,

/// various lights
dir_light: Light = undefined,
point_lights: std.ArrayList(Light) = undefined,
spot_lights: std.ArrayList(Light) = undefined,

/// create a Phong lighting renderer
pub fn init(allocator: std.mem.Allocator) Self {
    return .{
        .program = gl.ShaderProgram.init(vs, fs),
        .dir_light = Light.init(
            .{
                .directional = .{
                    .ambient = alg.Vec3.new(0.1, 0.1, 0.1),
                    .diffuse = alg.Vec3.new(0.1, 0.1, 0.1),
                    .specular = alg.Vec3.new(0.1, 0.1, 0.1),
                    .direction = alg.Vec3.one().negate(),
                },
            },
        ),
        .point_lights = std.ArrayList(Light).init(allocator),
        .spot_lights = std.ArrayList(Light).init(allocator),
    };
}

/// create a Phong lighting renderer
pub fn deinit(self: *Self) void {
    self.program.deinit();
    self.point_lights.deinit();
    self.spot_lights.deinit();
}

/// get renderer
pub fn renderer(self: *Self) Renderer {
    return Renderer.init(self, begin, end, render, renderMesh);
}

/// set directional light
pub fn setDirLight(self: *Self, light: Light) void {
    std.debug.assert(light.getType() == .directional);
    self.dir_light = light;
}

/// add point/spot light
pub fn addLight(self: *Self, light: Light) !usize {
    switch (light.getType()) {
        .point => {
            if (self.point_lights.items.len == max_point_light_num)
                return error.too_many_point_lights;
            try self.point_lights.append(light);
            return self.point_lights.items.len - 1;
        },
        .spot => {
            if (self.spot_lights.items.len == max_spot_light_num)
                return error.too_many_spot_lights;
            try self.spot_lights.append(light);
            return self.spot_lights.items.len - 1;
        },
        else => {
            std.debug.panic("invalid light type!", .{});
        },
    }
}

/// clear point lights
pub fn clearPointLights(self: *Self) void {
    self.point_lights.resize(0) catch unreachable;
}

/// clear spot lights
pub fn clearSpotLights(self: *Self) void {
    self.spot_lights.resize(0) catch unreachable;
}

/// begin rendering
fn begin(self: *Self) void {
    // enable program
    self.program.use();

    // directional light
    self.dir_light.apply(&self.program, "u_directional_light");

    // point lights
    var buf = [_]u8{0} ** 64;
    self.program.setUniformByName("u_point_light_count", self.point_lights.items.len);
    for (self.point_lights.items) |*light, i| {
        const name = std.fmt.bufPrintZ(&buf, "u_point_lights[{d}]", .{i}) catch unreachable;
        light.apply(&self.program, name);
    }

    // spot lights
    self.program.setUniformByName("u_spot_light_count", self.spot_lights.items.len);
    for (self.spot_lights.items) |*light, i| {
        const name = std.fmt.bufPrintZ(&buf, "u_spot_lights[{d}]", .{i}) catch unreachable;
        light.apply(&self.program, name);
    }
}

/// end rendering
fn end(self: *Self) void {
    self.program.disuse();
}

/// use material data
fn applyMaterial(self: *Self, material: Material) void {
    const mt = @as(Material.MaterialType, material.data);
    if (mt != .phong) {
        std.debug.panic("material type doesn't match renderer!", .{});
    }

    var buf: [64]u8 = undefined;
    self.program.setUniformByName(
        std.fmt.bufPrintZ(&buf, "u_material.diffuse", .{}) catch unreachable,
        material.data.phong.diffuse_map.tex.getTextureUnit(),
    );
    self.program.setUniformByName(
        std.fmt.bufPrintZ(&buf, "u_material.specular", .{}) catch unreachable,
        material.data.phong.specular_map.tex.getTextureUnit(),
    );
    self.program.setUniformByName(
        std.fmt.bufPrintZ(&buf, "u_material.shiness", .{}) catch unreachable,
        material.data.phong.shiness,
    );
}

/// render geometries
fn render(
    self: *Self,
    vertex_array: gl.VertexArray,
    use_elements: bool,
    primitive: gl.util.PrimitiveType,
    offset: usize,
    count: usize,
    model: Mat4,
    projection: Mat4,
    camera: ?Camera,
    material: ?Material,
    instance_count: ?usize,
) !void {
    if (!self.program.isUsing()) {
        return error.renderer_not_active;
    }

    // set uniforms
    self.program.setUniformByName("u_model", model);
    self.program.setUniformByName("u_normal", model.inv().transpose());
    self.program.setUniformByName("u_project", projection);
    self.program.setUniformByName("u_view", camera.?.getViewMatrix());
    self.program.setUniformByName("u_view_pos", camera.?.position);
    self.applyMaterial(material.?);

    // issue draw call
    vertex_array.use();
    defer vertex_array.disuse();
    if (use_elements) {
        gl.util.drawElements(primitive, offset, count, u32, instance_count);
    } else {
        gl.util.drawBuffer(primitive, offset, count, instance_count);
    }
}

fn renderMesh(
    self: *Self,
    mesh: Mesh,
    model: Mat4,
    projection: Mat4,
    camera: ?Camera,
    material: ?Material,
    instance_count: ?usize,
) !void {
    if (!self.program.isUsing()) {
        return error.renderer_not_active;
    }

    mesh.vertex_array.use();
    defer mesh.vertex_array.disuse();

    // attribute settings
    mesh.vertex_array.setAttribute(Mesh.vbo_positions, ATTRIB_LOCATION_POS, @sizeOf(Vec3), f32, false, 0, 0);
    mesh.vertex_array.setAttribute(Mesh.vbo_positions, ATTRIB_LOCATION_NORMAL, @sizeOf(Vec2), f32, false, 0, 0);
    mesh.vertex_array.setAttribute(Mesh.vbo_positions, ATTRIB_LOCATION_TEX, @sizeOf(Vec2), f32, false, 0, 0);

    // set uniforms
    self.program.setUniformByName("u_model", model);
    self.program.setUniformByName("u_normal", model.inv().transpose());
    self.program.setUniformByName("u_project", projection);
    self.program.setUniformByName("u_view", camera.?.getViewMatrix());
    self.program.setUniformByName("u_view_pos", camera.?.position);
    self.applyMaterial(material.?);

    // issue draw call
    if (mesh.indices.items.len > 0) {
        gl.util.drawElements(.triangles, 0, mesh.indices.items.len, u32, instance_count);
    } else {
        gl.util.drawBuffer(.triangles, 0, mesh.positions.items.len, instance_count);
    }
}
