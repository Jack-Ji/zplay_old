const std = @import("std");
const math = std.math;
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
pub const vbo_tangents = 4;
pub const vbo_indices = 5;
pub const vbo_num = 6;

/// vertex array
/// each vertex has multiple properties (see VertexAttribute)
vertex_array: gl.VertexArray = undefined,

/// primitive type
primitive_type: gl.util.PrimitiveType = undefined,

/// vertex attribute
positions: std.ArrayList(Vec3) = undefined,
normals: ?std.ArrayList(Vec3) = null,
texcoords: ?std.ArrayList(Vec2) = null,
colors: ?std.ArrayList(Vec4) = null,
tangents: ?std.ArrayList(Vec4) = null,
indices: ?std.ArrayList(u32) = null,
owns_data: bool = undefined,

/// allocate and initialize Mesh instance
pub fn init(
    allocator: std.mem.Allocator,
    primitive_type: gl.util.PrimitiveType,
    positions: []const Vec3,
    indices: ?[]const u32,
    normals: ?[]const Vec3,
    texcoords: ?[]const Vec2,
    colors: ?[]const Vec4,
    tangents: ?[]const Vec4,
) Self {
    var self: Self = .{
        .primitive_type = primitive_type,
        .vertex_array = gl.VertexArray.init(vbo_num),
        .positions = std.ArrayList(Vec3).initCapacity(allocator, positions.len) catch unreachable,
        .owns_data = true,
    };
    self.positions.appendSliceAssumeCapacity(positions);
    if (indices) |ids| {
        self.indices = std.ArrayList(u32).initCapacity(allocator, ids.len) catch unreachable;
        self.indices.?.appendSliceAssumeCapacity(ids);
    }
    if (normals) |ns| {
        self.normals = std.ArrayList(Vec3).initCapacity(allocator, ns.len) catch unreachable;
        self.normals.?.appendSliceAssumeCapacity(ns);
    }
    if (texcoords) |ts| {
        self.texcoords = std.ArrayList(Vec2).initCapacity(allocator, ts.len) catch unreachable;
        self.texcoords.?.appendSliceAssumeCapacity(ts);
    }
    if (colors) |cs| {
        self.colors = std.ArrayList(Vec4).initCapacity(allocator, cs.len) catch unreachable;
        self.colors.?.appendSliceAssumeCapacity(cs);
    }
    if (tangents) |ts| {
        self.tangents = std.ArrayList(Vec4).initCapacity(allocator, ts.len) catch unreachable;
        self.tangents.?.appendSliceAssumeCapacity(ts);
    }
    self.setup();
    return self;
}

/// create Mesh, maybe taking ownership of given arrays
pub fn fromArrayLists(
    primitive_type: gl.util.PrimitiveType,
    positions: std.ArrayList(Vec3),
    indices: ?std.ArrayList(u32),
    normals: ?std.ArrayList(Vec3),
    texcoords: ?std.ArrayList(Vec2),
    colors: ?std.ArrayList(Vec4),
    tangents: ?std.ArrayList(Vec4),
    take_ownership: bool,
) Self {
    var mesh: Self = .{
        .primitive_type = primitive_type,
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
    if (self.indices) |ids| {
        self.vertex_array.bufferData(vbo_indices, u32, ids.items, .element_array_buffer, .static_draw);
    }
    if (self.normals) |ns| {
        self.vertex_array.bufferData(vbo_normals, Vec3, ns.items, .array_buffer, .static_draw);
    }
    if (self.texcoords) |ts| {
        self.vertex_array.bufferData(vbo_texcoords, Vec2, ts.items, .array_buffer, .static_draw);
    }
    if (self.colors) |cs| {
        self.vertex_array.bufferData(vbo_colors, Vec4, cs.items, .array_buffer, .static_draw);
    }
    if (self.tangents) |ts| {
        self.vertex_array.bufferData(vbo_tangents, Vec4, ts.items, .array_buffer, .static_draw);
    }
}

/// free resources
pub fn deinit(self: *Self) void {
    self.vertex_array.deinit();
    if (self.owns_data) {
        self.positions.deinit();
        if (self.indices) |ids| ids.deinit();
        if (self.normals) |ns| ns.deinit();
        if (self.texcoords) |ts| ts.deinit();
        if (self.colors) |cs| cs.deinit();
        if (self.tangents) |ts| ts.deinit();
    }
}

// generate a cube
pub fn genCube(
    allocator: std.mem.Allocator,
    w: f32,
    d: f32,
    h: f32,
    color: ?Vec4,
) Self {
    const w2 = w / 2;
    const d2 = d / 2;
    const h2 = h / 2;
    const vs: [8]Vec3 = .{
        Vec3.new(w2, h2, d2),
        Vec3.new(w2, h2, -d2),
        Vec3.new(-w2, h2, -d2),
        Vec3.new(-w2, h2, d2),
        Vec3.new(w2, -h2, d2),
        Vec3.new(w2, -h2, -d2),
        Vec3.new(-w2, -h2, -d2),
        Vec3.new(-w2, -h2, d2),
    };
    const positions: [36]Vec3 = .{
        vs[0], vs[1], vs[2], vs[0], vs[2], vs[3], // top
        vs[4], vs[6], vs[5], vs[4], vs[7], vs[6], // bottom
        vs[3], vs[6], vs[7], vs[3], vs[2], vs[6], // left
        vs[0], vs[5], vs[1], vs[0], vs[4], vs[5], // right
        vs[0], vs[3], vs[7], vs[0], vs[7], vs[4], // front
        vs[1], vs[6], vs[2], vs[1], vs[5], vs[6], // back
    };

    const up = Vec3.up();
    const down = Vec3.down();
    const left = Vec3.left();
    const right = Vec3.right();
    const forward = Vec3.forward();
    const back = Vec3.back();
    const normals: [36]Vec3 = .{
        up, up, up, up, up, up, // top
        down, down, down, down, down, down, // bottom
        left, left, left, left, left, left, // left
        right, right, right, right, right, right, // right
        forward, forward, forward, forward, forward, forward, // front
        back, back, back, back, back, back, // back
    };

    return init(
        allocator,
        .triangles,
        &positions,
        null,
        &normals,
        null,
        if (color) |c|
            &[36]Vec4{
                c, c, c, c, c, c, c, c, c, c, c, c,
                c, c, c, c, c, c, c, c, c, c, c, c,
                c, c, c, c, c, c, c, c, c, c, c, c,
            }
        else
            null,
        null,
    );
}
