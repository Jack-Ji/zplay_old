const std = @import("std");
const assert = std.debug.assert;
const Camera = @import("Camera.zig");
const Light = @import("Light.zig");
const Material = @import("Material.zig");
const Mesh = @import("Mesh.zig");
const Renderer = @import("Renderer.zig");
const zp = @import("../../zplay.zig");
const drawcall = zp.graphics.common.drawcall;
const ShaderProgram = zp.graphics.common.ShaderProgram;
const VertexArray = zp.graphics.common.VertexArray;
const alg = zp.deps.alg;
const Vec2 = alg.Vec2;
const Vec3 = alg.Vec3;
const Vec4 = alg.Vec4;
const Mat4 = alg.Mat4;
const Self = @This();

/// vertex attribute locations
pub const ATTRIB_LOCATION_POS = 0;
pub const ATTRIB_LOCATION_TEX = 1;
pub const ATTRIB_LOCATION_COLOR = 2;

const vs =
    \\#version 330 core
    \\layout (location = 0) in vec3 a_pos;
    \\layout (location = 1) in vec2 a_tex;
    \\layout (location = 2) in vec4 a_color;
    \\
    \\uniform mat4 u_model;
    \\uniform mat4 u_view;
    \\uniform mat4 u_project;
    \\
    \\out vec3 v_pos;
    \\out vec2 v_tex;
    \\out vec4 v_color;
    \\
    \\void main()
    \\{
    \\    gl_Position = u_project * u_view * u_model * vec4(a_pos, 1.0);
    \\    v_pos = vec3(u_model * vec4(a_pos, 1.0));
    \\    v_tex = a_tex;
    \\    v_color = a_color;
    \\}
;

const fs =
    \\#version 330 core
    \\out vec4 frag_color;
    \\
    \\in vec3 v_pos;
    \\in vec2 v_tex;
    \\in vec4 v_color;
    \\
    \\uniform sampler2D u_texture;
    \\uniform float u_mix_factor;
    \\
    \\void main()
    \\{
    \\    frag_color = mix(texture(u_texture, v_tex), v_color, u_mix_factor);
    \\}
;

/// lighting program
program: ShaderProgram = undefined,

/// set factor used to mix texture and vertex's colors
mix_factor: f32 = 0,

/// create a simple renderer
pub fn init() Self {
    return .{
        .program = ShaderProgram.init(vs, fs),
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
    switch (material.data) {
        .phong => |m| {
            self.program.setUniformByName("u_texture", m.diffuse_map.tex.getTextureUnit());
        },
        .single_texture => |t| {
            self.program.setUniformByName("u_texture", t.tex.getTextureUnit());
        },
        else => {
            std.debug.panic("unsupported material type", .{});
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
    self.program.setUniformByName("u_project", projection);
    if (camera) |c| {
        self.program.setUniformByName("u_view", c.getViewMatrix());
    } else {
        self.program.setUniformByName("u_view", Mat4.identity());
    }
    self.program.setUniformByName("u_mix_factor", self.mix_factor);
    if (material) |mr| {
        self.applyMaterial(mr);
    }

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
    if (mesh.texcoords != null) {
        mesh.vertex_array.setAttribute(Mesh.vbo_texcoords, ATTRIB_LOCATION_TEX, 2, f32, false, 0, 0);
    }
    if (mesh.colors != null) {
        mesh.vertex_array.setAttribute(Mesh.vbo_colors, ATTRIB_LOCATION_COLOR, 4, f32, false, 0, 0);
    }

    // set uniforms
    self.program.setUniformByName("u_model", model);
    self.program.setUniformByName("u_project", projection);
    if (camera) |c| {
        self.program.setUniformByName("u_view", c.getViewMatrix());
    } else {
        self.program.setUniformByName("u_view", Mat4.identity());
    }
    self.program.setUniformByName("u_mix_factor", self.mix_factor);
    if (material) |mr| {
        self.applyMaterial(mr);
    }

    // issue draw call
    if (mesh.indices) |ids| {
        drawcall.drawElements(mesh.primitive_type, 0, @intCast(u32, ids.items.len), u32, instance_count);
    } else {
        drawcall.drawBuffer(mesh.primitive_type, 0, @intCast(u32, mesh.positions.items.len), instance_count);
    }
}
