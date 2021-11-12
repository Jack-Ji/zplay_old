const std = @import("std");
const Camera = @import("Camera.zig");
const Light = @import("Light.zig");
const Material = @import("Material.zig");
const zp = @import("../lib.zig");
const gl = zp.gl;
const alg = zp.alg;
const Mat4 = alg.Mat4;
const Texture2D = zp.texture.Texture2D;
const Self = @This();

const vs =
    \\#version 330 core
    \\layout (location = 0) in vec3 a_pos;
    \\layout (location = 1) in vec3 a_color;
    \\layout (location = 2) in vec2 a_tex;
    \\
    \\uniform mat4 u_model;
    \\uniform mat4 u_view;
    \\uniform mat4 u_project;
    \\
    \\out vec3 v_pos;
    \\out vec3 v_color;
    \\out vec2 v_tex;
    \\
    \\void main()
    \\{
    \\    gl_Position = u_project * u_view * u_model * vec4(a_pos, 1.0);
    \\    v_pos = vec3(u_model * vec4(a_pos, 1.0));
    \\    v_color = a_color;
    \\    v_tex = a_tex;
    \\}
;

const fs_header =
    \\#version 330 core
    \\out vec4 frag_color;
    \\
    \\in vec3 v_pos;
    \\in vec3 v_color;
    \\in vec2 v_tex;
;

const default_fs_body =
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

/// begin rendering, enable texture unit when possible
pub fn begin(self: *Self, texture: ?Texture2D) void {
    // enable program
    self.program.use();

    if (!self.using_custom_shader) {
        if (texture) |t| {
            self.program.setUniformByName("u_texture", t.tex.getTextureUnit());
            self.program.setUniformByName("u_use_texture", true);
        } else {
            self.program.setUniformByName("u_use_texture", false);
        }
    }
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
    vertex_count: usize,
    model: Mat4,
    projection: Mat4,
    camera: ?Camera,
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

    // issue draw call
    vertex_array.use();
    defer vertex_array.disuse();
    if (use_elements) {
        gl.util.drawElements(primitive, offset, vertex_count);
    } else {
        gl.util.drawBuffer(primitive, offset, vertex_count);
    }
}
