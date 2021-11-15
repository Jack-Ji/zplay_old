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

/// fragment coloring method
pub const ColorSource = union(enum) {
    texture: Texture2D,
    color: Vec3,
};

const vs =
    \\#version 330 core
    \\layout (location = 0) in vec3 a_pos;
    \\layout (location = 1) in vec2 a_tex;
    \\
    \\uniform mat4 u_model;
    \\uniform mat4 u_view;
    \\uniform mat4 u_project;
    \\
    \\out vec3 v_pos;
    \\out vec2 v_tex;
    \\
    \\void main()
    \\{
    \\    gl_Position = u_project * u_view * u_model * vec4(a_pos, 1.0);
    \\    v_pos = vec3(u_model * vec4(a_pos, 1.0));
    \\    v_tex = a_tex;
    \\}
;

const fs_header =
    \\#version 330 core
    \\out vec4 frag_color;
    \\
    \\in vec3 v_pos;
    \\in vec2 v_tex;
    \\
    \\
;

const default_fs_body =
    \\uniform bool u_use_texture;
    \\uniform sampler2D u_texture;
    \\uniform vec3 u_color;
    \\
    \\void main()
    \\{
    \\    if (u_use_texture) {
    \\        frag_color = texture(u_texture, v_tex);
    \\    } else {
    \\        frag_color = vec4(u_color, 1);
    \\    }
    \\}
;

/// lighting program
program: gl.ShaderProgram = undefined,

/// whether using custom shader
using_custom_shader: bool = undefined,

/// create a simple renderer
pub fn init(custom_fs: ?[:0]const u8) Self {
    const allocator = std.heap.raw_c_allocator;
    var fsource: [:0]u8 = undefined;
    if (custom_fs) |fs| {
        fsource = std.fmt.allocPrintZ(
            allocator,
            "{s}{s}",
            .{ fs_header, fs },
        ) catch unreachable;
    } else {
        fsource = std.fmt.allocPrintZ(
            allocator,
            "{s}{s}",
            .{ fs_header, default_fs_body },
        ) catch unreachable;
    }
    defer allocator.free(fsource);

    return .{
        .program = gl.ShaderProgram.init(vs, fsource),
        .using_custom_shader = if (custom_fs != null) true else false,
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
    color_src: ?ColorSource,
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
    if (!self.using_custom_shader) {
        switch (color_src.?) {
            .texture => |t| {
                self.program.setUniformByName("u_use_texture", true);
                self.program.setUniformByName("u_texture", t.tex.getTextureUnit());
            },
            .color => |c| {
                self.program.setUniformByName("u_use_texture", false);
                self.program.setUniformByName("u_color", c);
            },
        }
    } else if (color_src != null) {
        std.debug.panic("probably meanless paramter!", .{});
    }

    // issue draw call
    vertex_array.use();
    defer vertex_array.disuse();
    if (use_elements) {
        gl.util.drawElements(primitive, offset, count);
    } else {
        gl.util.drawBuffer(primitive, offset, count);
    }
}

/// render a mesh 
pub fn renderMesh(
    self: *Self,
    mesh: Mesh,
    model: Mat4,
    projection: Mat4,
    camera: Camera,
    color_src: ?ColorSource,
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
        color_src,
    );
}
