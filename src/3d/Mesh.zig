const std = @import("std");
const sdl = @import("sdl");
const zp = @import("../lib.zig");
const gl = zp.gl;
const Texture2D = zp.texture.Texture2D;
const alg = zp.alg;
const Vec2 = alg.Vec2;
const Vec3 = alg.Vec3;
const Vec4 = alg.Vec4;
const Self = @This();

pub const vbo_positions = 0;
pub const vbo_normals = 1;
pub const vbo_texcoords = 2;
pub const vbo_colors = 3;
pub const vbo_indices = 4;
pub const vbo_tangents = 5;
pub const vbo_num = 6;

/// vertex array
/// each vertex has multiple properties (see VertexAttribute)
vertex_array: gl.VertexArray = undefined,

/// vertex attribute
positions: std.ArrayList(Vec3) = undefined,
normals: std.ArrayList(Vec3) = undefined,
texcoords: std.ArrayList(Vec2) = undefined,
colors: std.ArrayList(Vec4) = undefined,
tangents: std.ArrayList(Vec4) = undefined,
indices: std.ArrayList(u32) = undefined,
owns_data: bool = false,

/// allocate and initialize Mesh instance
pub fn init(
    allocator: std.mem.Allocator,
    positions: []const Vec3,
    normals: []const Vec3,
    texcoords: []const Vec2,
    colors: []const Vec4,
    tangents: []const Vec4,
    indices: []const u32,
) Self {
    var self: Self = .{
        .vertex_array = gl.VertexArray.init(vbo_num),
        .positions = std.ArrayList(Vec3).initCapacity(allocator, positions.len) catch unreachable,
        .normals = std.ArrayList(Vec3).initCapacity(allocator, normals.len) catch unreachable,
        .texcoords = std.ArrayList(Vec2).initCapacity(allocator, texcoords.len) catch unreachable,
        .colors = std.ArrayList(Vec4).initCapacity(allocator, colors.len) catch unreachable,
        .tangents = std.ArrayList(Vec4).initCapacity(allocator, tangents.len) catch unreachable,
        .indices = std.ArrayList(Vec4).initCapacity(allocator, indices.len) catch unreachable,
        .owns_data = true,
    };
    self.positions.appendSlice(positions) catch unreachable;
    self.normals.appendSlice(normals) catch unreachable;
    self.texcoords.appendSlice(texcoords) catch unreachable;
    self.colors.appendSlice(colors) catch unreachable;
    self.tangents.appendSlice(tangents) catch unreachable;
    self.indices.appendSlice(indices) catch unreachable;
    self.setup();
    return self;
}

/// create Mesh, maybe taking ownership of given arrays
pub fn fromArrayLists(
    positions: std.ArrayList(Vec3),
    normals: std.ArrayList(Vec3),
    texcoords: std.ArrayList(Vec2),
    colors: std.ArrayList(Vec4),
    indices: std.ArrayList(u32),
    tangents: std.ArrayList(Vec4),
    take_ownership: bool,
) Self {
    var mesh: Self = .{
        .vertex_array = gl.VertexArray.init(vbo_num),
        .positions = positions,
        .normals = normals,
        .texcoords = texcoords,
        .colors = colors,
        .tangents = tangents,
        .indices = indices,
        .owns_data = take_ownership,
    };
    mesh.setup();
    return mesh;
}

/// initialize vertex array's data
fn setup(self: *Self) void {
    self.vertex_array.use();
    defer self.vertex_array.disuse();

    self.vertex_array.bufferData(vbo_positions, Vec3, self.positions.items, .array_buffer, .static_draw);
    self.vertex_array.bufferData(vbo_normals, Vec3, self.normals.items, .array_buffer, .static_draw);
    self.vertex_array.bufferData(vbo_texcoords, Vec2, self.texcoords.items, .array_buffer, .static_draw);
    self.vertex_array.bufferData(vbo_colors, Vec4, self.colors.items, .array_buffer, .static_draw);
    self.vertex_array.bufferData(vbo_colors, Vec4, self.tangents.items, .array_buffer, .static_draw);
    self.vertex_array.bufferData(vbo_indices, u32, self.indices.items, .element_array_buffer, .static_draw);
}

/// free resources
pub fn deinit(self: *Self) void {
    self.vertex_array.deinit();
    if (self.owns_data) {
        self.positions.deinit();
        self.normals.deinit();
        self.texcoords.deinit();
        self.colors.deinit();
        self.tangents.deinit();
        self.indices.deinit();
    }
}
