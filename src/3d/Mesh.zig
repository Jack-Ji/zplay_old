const std = @import("std");
const sdl = @import("sdl");
const Material = @import("Material.zig");
const zp = @import("../lib.zig");
const gl = zp.gl;
const Texture2D = zp.texture.Texture2D;
const alg = zp.alg;
const Vec2 = alg.Vec2;
const Vec3 = alg.Vec3;
const Self = @This();

const vbo_idx = 0;
const ebo_idx = 1;

/// vertex array (including vbo/ebo)
vertex_array: gl.VertexArray = undefined,

/// vertices, each has 3 properties: position, normal, texture coord
vertices: std.ArrayList(f32) = undefined,
vertex_indices: std.ArrayList(u16) = undefined,
owns_data: bool = false,

/// material
material: Material = undefined,

/// allocate and initialize Mesh instance
pub fn init(
    allocator: *std.mem.Allocator,
    vertices: []const f32,
    indices: []const u16,
    material: Material,
) Self {
    var mesh: Self = .{
        .vertex_array = gl.VertexArray.init(2),
        .vertices = std.ArrayList(f32).init(allocator),
        .vertex_indices = std.ArrayList(u16).init(allocator),
        .owns_data = true,
        .material = material,
    };
    mesh.vertices.appendSlice(vertices) catch unreachable;
    mesh.vertex_indices.appendSlice(indices) catch unreachable;
    mesh.setup();
    return mesh;
}

/// create Mesh, maybe taking ownership of given arrays
pub fn fromArrayLists(
    vertices: std.ArrayList(f32),
    indices: std.ArrayList(u16),
    material: Material,
    take_ownership: bool,
) Self {
    var mesh: Self = .{
        .vertex_array = gl.VertexArray.init(2),
        .vertices = vertices,
        .vertex_indices = indices,
        .owns_data = take_ownership,
        .material = material,
    };
    mesh.setup();
    return mesh;
}

/// initialize vertex array's data
fn setup(self: *Self) void {
    self.vertex_array.use();
    defer self.vertex_array.disuse();

    // vertex buffer
    self.vertex_array.bufferData(
        vbo_idx,
        f32,
        self.vertices.items,
        .array_buffer,
        .static_draw,
    );

    // postion attribute
    self.vertex_array.setAttribute(vbo_idx, 0, 3, f32, false, 8 * @sizeOf(f32), 0);

    // normal attribute
    self.vertex_array.setAttribute(vbo_idx, 1, 3, f32, false, 8 * @sizeOf(f32), 3 * @sizeOf(f32));

    // texture coordinate attribute
    self.vertex_array.setAttribute(vbo_idx, 2, 2, f32, false, 8 * @sizeOf(f32), 6 * @sizeOf(f32));

    // elment array buffer
    self.vertex_array.bufferData(
        ebo_idx,
        u16,
        self.vertex_indices.items,
        .element_array_buffer,
        .static_draw,
    );
}

/// free resources
pub fn deinit(self: *Self) void {
    self.vertex_array.deinit();
    if (self.owns_data) {
        self.vertices.deinit();
        self.vertex_indices.deinit();
    }
}
