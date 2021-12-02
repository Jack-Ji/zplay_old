const std = @import("std");
const sdl = @import("sdl");
const zp = @import("../lib.zig");
const gl = zp.gl;
const Texture2D = zp.texture.Texture2D;
const alg = zp.alg;
const Vec2 = alg.Vec2;
const Vec3 = alg.Vec3;
const Self = @This();

const vbo_idx = 0;
const ebo_idx = 1;

/// vertex attribute type
pub const VertexAttribute = enum(usize) {
    /// 3 float
    position = 0,

    /// 3 float
    normal = 1,

    /// 2 float
    texture_coord = 2,

    /// 4 float
    color = 3,
};
const MAX_ATTRIB_NUM = 4;

/// vertex array (including vbo/ebo)
/// each vertex has multiple properties (see VertexAttribute)
vertex_array: gl.VertexArray = undefined,

/// vertices' attributes
vertex_data: std.ArrayList(f32) = undefined,
vertex_indices: std.ArrayList(u32) = undefined,
vertex_num: usize = undefined,
attribute_types: [MAX_ATTRIB_NUM]?VertexAttribute = .{null} ** MAX_ATTRIB_NUM,
attribute_sizes: [MAX_ATTRIB_NUM]usize = .{0} ** MAX_ATTRIB_NUM,
attribute_offsets: [MAX_ATTRIB_NUM]usize = .{0} ** MAX_ATTRIB_NUM,
attribute_indices: [MAX_ATTRIB_NUM]?usize = .{null} ** MAX_ATTRIB_NUM,
attribute_total_size: usize = 0,
attribute_num: usize = undefined,
owns_data: bool = false,

/// allocate and initialize Mesh instance
pub fn init(
    allocator: *std.mem.Allocator,
    vertices: []const f32,
    indices: []const u32,
    types: [MAX_ATTRIB_NUM]?VertexAttribute,
) Self {
    var mesh: Self = .{
        .vertex_array = gl.VertexArray.init(2),
        .vertex_data = std.ArrayList(f32).init(allocator),
        .vertex_indices = std.ArrayList(u32).init(allocator),
        .attribute_types = types,
        .owns_data = true,
    };
    mesh.vertex_data.appendSlice(vertices) catch unreachable;
    mesh.vertex_indices.appendSlice(indices) catch unreachable;
    mesh.setup();
    return mesh;
}

/// create Mesh, maybe taking ownership of given arrays
pub fn fromArrayLists(
    vertices: std.ArrayList(f32),
    indices: std.ArrayList(u32),
    types: [MAX_ATTRIB_NUM]?VertexAttribute,
    take_ownership: bool,
) Self {
    var mesh: Self = .{
        .vertex_array = gl.VertexArray.init(2),
        .vertex_data = vertices,
        .vertex_indices = indices,
        .attribute_types = types,
        .owns_data = take_ownership,
    };
    mesh.setup();
    return mesh;
}

/// initialize vertex array's data
fn setup(self: *Self) void {
    self.vertex_array.use();
    defer self.vertex_array.disuse();

    // determine number/size of attributes
    self.attribute_num = for (self.attribute_types) |t, i| {
        if (t == null) {
            break i;
        }
        self.attribute_sizes[i] = switch (t.?) {
            .position => 3,
            .normal => 3,
            .texture_coord => 2,
            .color => 4,
        };
        if (i > 0) {
            self.attribute_offsets[i] = self.attribute_offsets[i - 1] + self.attribute_sizes[i - 1];
        }
        self.attribute_indices[@enumToInt(t.?)] = i;
        self.attribute_total_size += self.attribute_sizes[i];
    } else MAX_ATTRIB_NUM;

    // hard check vertex data
    self.vertex_num = self.vertex_data.items.len / self.attribute_total_size;
    if ((self.vertex_data.items.len % self.attribute_total_size) != 0) {
        std.debug.panic("invalid parameter!", .{});
    }

    // vertex buffer
    self.vertex_array.bufferData(
        vbo_idx,
        f32,
        self.vertex_data.items,
        .array_buffer,
        .static_draw,
    );

    // elment array buffer
    self.vertex_array.bufferData(
        ebo_idx,
        u32,
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

/// relate attribute's location to buffer data
pub fn relateLocation(self: Self, location: gl.GLuint, attribute_type: VertexAttribute) void {
    self.vertex_array.use();
    defer self.vertex_array.disuse();

    var idx = self.attribute_indices[@enumToInt(attribute_type)].?;
    self.vertex_array.setAttribute(
        vbo_idx,
        location,
        @intCast(u32, self.attribute_sizes[idx]),
        f32,
        false,
        self.attribute_total_size * @sizeOf(f32),
        @intCast(u32, self.attribute_offsets[idx] * @sizeOf(f32)),
    );
}
