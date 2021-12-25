const std = @import("std");
const assert = std.debug.assert;
const Camera = @import("Camera.zig");
const Material = @import("Material.zig");
const Mesh = @import("Mesh.zig");
const Renderer = @import("Renderer.zig");
const zp = @import("../../zplay.zig");
const drawcall = zp.graphics.common.drawcall;
const ShaderProgram = zp.graphics.common.ShaderProgram;
const VertexArray = zp.graphics.common.VertexArray;
const alg = zp.deps.alg;
const Mat4 = alg.Mat4;
const Vec2 = alg.Vec2;
const Vec3 = alg.Vec3;
const Self = @This();

pub const ATTRIB_LOCATION_POS = 0;
pub const ATTRIB_LOCATION_NORMAL = 1;

const vs =
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

const reflect_fs =
    \\#version 330 core
    \\out vec4 frag_color;
    \\
    \\in vec3 v_pos;
    \\in vec3 v_normal;
    \\
    \\uniform vec3 u_view_pos;
    \\uniform samplerCube u_texture;
    \\
    \\void main()
    \\{
    \\    vec3 view_dir = normalize(v_pos - u_view_pos);
    \\    vec3 reflect_dir = reflect(view_dir, v_normal);
    \\    frag_color = vec4(texture(u_texture, reflect_dir).rgb, 1.0);
    \\}
;

const refract_fs =
    \\#version 330 core
    \\out vec4 frag_color;
    \\
    \\in vec3 v_pos;
    \\in vec3 v_normal;
    \\
    \\uniform vec3 u_view_pos;
    \\uniform samplerCube u_texture;
    \\uniform float u_ratio;
    \\
    \\void main()
    \\{
    \\    vec3 view_dir = normalize(v_pos - u_view_pos);
    \\    vec3 refract_dir = refract(view_dir, v_normal, u_ratio);
    \\    frag_color = vec4(texture(u_texture, refract_dir).rgb, 1.0);
    \\}
;

// environment mapping type
const Type = enum {
    reflect,
    refract,
};

/// lighting program
program: ShaderProgram = undefined,

/// type of mapping
type: Type,

/// create a Phong lighting renderer
pub fn init(t: Type) Self {
    return .{
        .program = ShaderProgram.init(
            vs,
            switch (t) {
                .reflect => reflect_fs,
                .refract => refract_fs,
            },
        ),
        .type = t,
    };
}

/// free resources
pub fn deinit(self: *Self) void {
    self.program.deinit();
}

/// get renderer
pub fn renderer(self: *Self) Renderer {
    return Renderer.init(self, begin, end, render, renderMesh);
}

/// begin rendering
fn begin(self: *Self) void {
    self.program.use();
}

/// end rendering
fn end(self: *Self) void {
    self.program.disuse();
}

/// use material data
fn applyMaterial(self: *Self, material: Material) void {
    switch (self.type) {
        .reflect => {
            assert(material.data == .single_cubemap);
            self.program.setUniformByName(
                "u_texture",
                material.data.single_cubemap.tex.getTextureUnit(),
            );
        },
        .refract => {
            assert(material.data == .refract_mapping);
            self.program.setUniformByName(
                "u_texture",
                material.data.refract_mapping.cubemap.tex.getTextureUnit(),
            );
            self.program.setUniformByName(
                "u_ratio",
                1.0 / material.data.refract_mapping.ratio,
            );
        },
    }
}

/// render geometries
fn render(
    self: *Self,
    vertex_array: VertexArray,
    use_elements: bool,
    primitive: drawcall.PrimitiveType,
    offset: u32,
    count: u32,
    model: Mat4,
    projection: Mat4,
    camera: ?Camera,
    material: ?Material,
    instance_count: ?u32,
) !void {
    if (!self.program.isUsing()) {
        return error.RendererNotActive;
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
        drawcall.drawElements(primitive, offset, count, u32, instance_count);
    } else {
        drawcall.drawBuffer(primitive, offset, count, instance_count);
    }
}

fn renderMesh(
    self: *Self,
    mesh: Mesh,
    model: Mat4,
    projection: Mat4,
    camera: ?Camera,
    material: ?Material,
    instance_count: ?u32,
) !void {
    if (!self.program.isUsing()) {
        return error.RendererNotActive;
    }

    mesh.vertex_array.use();
    defer mesh.vertex_array.disuse();

    // attribute settings
    mesh.vertex_array.setAttribute(Mesh.vbo_positions, ATTRIB_LOCATION_POS, 3, f32, false, 0, 0);
    assert(mesh.normals != null);
    mesh.vertex_array.setAttribute(Mesh.vbo_normals, ATTRIB_LOCATION_NORMAL, 3, f32, false, 0, 0);

    // set uniforms
    self.program.setUniformByName("u_model", model);
    self.program.setUniformByName("u_normal", model.inv().transpose());
    self.program.setUniformByName("u_project", projection);
    self.program.setUniformByName("u_view", camera.?.getViewMatrix());
    self.program.setUniformByName("u_view_pos", camera.?.position);
    self.applyMaterial(material.?);

    // issue draw call
    if (mesh.indices) |ids| {
        drawcall.drawElements(mesh.primitive_type, 0, @intCast(u32, ids.items.len), u32, instance_count);
    } else {
        drawcall.drawBuffer(mesh.primitive_type, 0, @intCast(u32, mesh.positions.items.len), instance_count);
    }
}
