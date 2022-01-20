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
const Buffer = zp.graphics.common.Buffer;
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
pub const ATTRIB_LOCATION_TRANSFORM = 3;

const vs =
    \\#version 330 core
    \\layout (location = 0) in vec3 a_pos;
    \\layout (location = 1) in vec2 a_tex;
    \\layout (location = 2) in vec4 a_color;
    \\
    \\uniform mat4 u_model = mat4(1.0);
    \\uniform mat4 u_view = mat4(1.0);
    \\uniform mat4 u_project = mat4(1.0);
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

const vs_instanced =
    \\#version 330 core
    \\layout (location = 0) in vec3 a_pos;
    \\layout (location = 1) in vec2 a_tex;
    \\layout (location = 2) in vec4 a_color;
    \\layout (location = 3) in mat4 a_transform;
    \\
    \\uniform mat4 u_view = mat4(1.0);
    \\uniform mat4 u_project = mat4(1.0);
    \\
    \\out vec3 v_pos;
    \\out vec2 v_tex;
    \\out vec4 v_color;
    \\
    \\void main()
    \\{
    \\    gl_Position = u_project * u_view * a_transform * vec4(a_pos, 1.0);
    \\    v_pos = vec3(a_transform * vec4(a_pos, 1.0));
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

/// status of renderer
status: Renderer.Status = .not_ready,

/// shader programs
program: ShaderProgram,
program_instanced: ShaderProgram,

/// buffer object for instanced transform matrices
vbo_instanced: *Buffer,

/// number of instanced transform matrices
count_instanced: u32 = 0,

/// set factor used to mix texture and vertex's colors
mix_factor: f32 = 0,

/// create a simple renderer
pub fn init(allocator: std.mem.Allocator) Self {
    return .{
        .program = ShaderProgram.init(vs, fs, null),
        .program_instanced = ShaderProgram.init(vs_instanced, fs, null),
        .vbo_instanced = Buffer.init(allocator),
    };
}

/// free resources
pub fn deinit(self: *Self) void {
    self.program.deinit();
    self.vbo_instanced.deinit();
}

/// get renderer
pub fn renderer(self: *Self) Renderer {
    return Renderer.init(self, begin, end, updateInstanceTransforms, render, renderMesh);
}

/// begin rendering
fn begin(self: *Self, instanced_draw: bool) void {
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
    self.program.disuse();
    self.status = .not_ready;
}

/// update instanced transforms
fn updateInstanceTransforms(self: *Self, va: VertexArray, transforms: []Mat4) !void {
    assert(self.status == .ready_to_draw_instanced);
    va.use();
    defer va.disuse();

    var total_size: u32 = @intCast(u32, @sizeOf(Mat4) * transforms.len);
    if (self.vbo_instanced.size < total_size) {
        self.vbo_instanced.allocData(total_size, .array_buffer, .static_draw);
    }
    self.vbo_instanced.updateData(0, Mat4, transforms, .array_buffer);
    self.count_instanced = @intCast(u32, transforms.len);

    // set/enable attribute for instance transform matrix
    self.vbo_instanced.setAttribute(ATTRIB_LOCATION_TRANSFORM, 4, f32, false, @sizeOf(Mat4), 0, 1);
    self.vbo_instanced.setAttribute(ATTRIB_LOCATION_TRANSFORM + 1, 4, f32, false, @sizeOf(Mat4), 4 * @sizeOf(f32), 1);
    self.vbo_instanced.setAttribute(ATTRIB_LOCATION_TRANSFORM + 2, 4, f32, false, @sizeOf(Mat4), 8 * @sizeOf(f32), 1);
    self.vbo_instanced.setAttribute(ATTRIB_LOCATION_TRANSFORM + 3, 4, f32, false, @sizeOf(Mat4), 12 * @sizeOf(f32), 1);
}

// get current using shader program
fn getProgram(self: Self) ShaderProgram {
    assert(self.status != .not_ready);
    return if (self.status == .ready_to_draw) self.program else self.program_instanced;
}

/// use material data
fn applyMaterial(self: *Self, material: Material) void {
    switch (material.data) {
        .phong => |m| {
            self.getProgram().setUniformByName("u_texture", m.diffuse_map.tex.getTextureUnit());
        },
        .single_texture => |t| {
            self.getProgram().setUniformByName("u_texture", t.tex.getTextureUnit());
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
    transforms: ?[]Mat4,
    projection: ?Mat4,
    camera: ?Camera,
    material: ?Material,
    instance_count: ?u32,
) !void {
    assert(self.status != .not_ready);

    // set uniforms
    if (projection) |proj| {
        self.getProgram().setUniformByName("u_project", proj);
    }
    if (camera) |c| {
        self.getProgram().setUniformByName("u_view", c.getViewMatrix());
    } else {
        self.getProgram().setUniformByName("u_view", Mat4.identity());
    }
    self.getProgram().setUniformByName("u_mix_factor", self.mix_factor);
    if (material) |mr| {
        self.applyMaterial(mr);
    }

    // issue draw call
    vertex_array.use();
    defer vertex_array.disuse();
    if (self.status == .ready_to_draw) {
        for (transforms.?) |tr| {
            self.getProgram().setUniformByName("u_model", tr);
            if (use_elements) {
                drawcall.drawElements(primitive, offset, count, u32);
            } else {
                drawcall.drawBuffer(primitive, offset, count);
            }
        }
    } else {
        assert(instance_count.? <= self.count_instanced);
        if (use_elements) {
            drawcall.drawElementsInstanced(primitive, offset, count, u32, instance_count.?);
        } else {
            drawcall.drawBufferInstanced(primitive, offset, count, instance_count.?);
        }
    }
}

fn renderMesh(
    self: *Self,
    mesh: Mesh,
    transforms: ?[]Mat4,
    projection: ?Mat4,
    camera: ?Camera,
    material: ?Material,
    instance_count: ?u32,
) !void {
    assert(self.status != .not_ready);
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
    if (projection) |proj| {
        self.getProgram().setUniformByName("u_project", proj);
    }
    if (camera) |c| {
        self.getProgram().setUniformByName("u_view", c.getViewMatrix());
    } else {
        self.getProgram().setUniformByName("u_view", Mat4.identity());
    }
    self.getProgram().setUniformByName("u_mix_factor", self.mix_factor);
    if (material) |mr| {
        self.applyMaterial(mr);
    }

    // issue draw call
    if (self.status == .ready_to_draw) {
        for (transforms.?) |tr| {
            self.getProgram().setUniformByName("u_model", tr);
            if (mesh.indices) |ids| {
                drawcall.drawElements(mesh.primitive_type, 0, @intCast(u32, ids.items.len), u32);
            } else {
                drawcall.drawBuffer(mesh.primitive_type, 0, @intCast(u32, mesh.positions.items.len));
            }
        }
    } else {
        assert(instance_count.? <= self.count_instanced);
        if (mesh.indices) |ids| {
            drawcall.drawElementsInstanced(mesh.primitive_type, 0, @intCast(u32, ids.items.len), u32, instance_count.?);
        } else {
            drawcall.drawBufferInstanced(mesh.primitive_type, 0, @intCast(u32, mesh.positions.items.len), instance_count.?);
        }
    }
}
