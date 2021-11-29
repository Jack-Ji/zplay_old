const std = @import("std");
const Camera = @import("Camera.zig");
const Light = @import("Light.zig");
const Material = @import("Material.zig");
const Mesh = @import("Mesh.zig");
const zp = @import("../lib.zig");
const gl = zp.gl;
const alg = zp.alg;
const Vec3 = alg.Vec3;
const Mat4 = alg.Mat4;
const Texture2D = zp.texture.Texture2D;
const Self = @This();

/// vertex attribute locations
pub const ATTRIB_LOCATION_POS = 0;
pub const ATTRIB_LOCATION_TEX = 1;
pub const ATTRIB_LOCATION_COLOR = 2;

const vs =
    \\#version 330 core
    \\layout (location = 0) in vec3 a_pos;
    \\layout (location = 1) in vec2 a_tex;
    \\layout (location = 2) in vec3 a_color;
    \\
    \\uniform mat4 u_model;
    \\uniform mat4 u_view;
    \\uniform mat4 u_project;
    \\
    \\out vec3 v_pos;
    \\out vec2 v_tex;
    \\out vec3 v_color;
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
    \\in vec3 v_color;
    \\
    \\uniform bool u_use_texture;
    \\uniform sampler2D u_texture;
    \\
    \\void main()
    \\{
    \\    if (u_use_texture) {
    \\        frag_color = texture(u_texture, v_tex);
    \\    } else {
    \\        frag_color = vec4(v_color, 1);
    \\    }
    \\}
;

/// lighting program
program: gl.ShaderProgram = undefined,

/// create a simple renderer
pub fn init() Self {
    return .{
        .program = gl.ShaderProgram.init(vs, fs),
    };
}

/// create a simple renderer
pub fn deinit(self: *Self) void {
    self.program.deinit();
}

/// begin rendering
pub fn begin(self: *Self) void {
    self.program.use();
}

/// end rendering
pub fn end(self: Self) void {
    self.program.disuse();
}

/// render geometries
pub fn render(
    self: *Self,
    vertex_array: gl.VertexArray,
    use_elements: bool,
    primitive: gl.util.PrimitiveType,
    offset: usize,
    count: usize,
    model: Mat4,
    projection: Mat4,
    camera: ?Camera,
    texture: ?Texture2D,
) !void {
    if (!self.program.isUsing()) {
        return error.renderer_not_active;
    }

    // set uniforms
    self.program.setUniformByName("u_model", model);
    self.program.setUniformByName("u_project", projection);
    if (camera) |c| {
        self.program.setUniformByName("u_view", c.getViewMatrix());
    } else {
        self.program.setUniformByName("u_view", Mat4.identity());
    }
    if (texture) |t| {
        self.program.setUniformByName("u_use_texture", true);
        self.program.setUniformByName("u_texture", t.tex.getTextureUnit());
    } else {
        self.program.setUniformByName("u_use_texture", false);
    }

    // issue draw call
    vertex_array.use();
    defer vertex_array.disuse();
    if (use_elements) {
        gl.util.drawElements(primitive, offset, count, null);
    } else {
        gl.util.drawBuffer(primitive, offset, count, null);
    }
}

/// render a mesh 
pub fn renderMesh(
    self: *Self,
    mesh: Mesh,
    model: Mat4,
    projection: Mat4,
    camera: Camera,
    texture: ?Texture2D,
) !void {
    try self.render(
        mesh.vertex_array,
        true,
        .triangles,
        0,
        mesh.vertex_indices.items.len,
        model,
        projection,
        camera,
        texture,
    );
}
