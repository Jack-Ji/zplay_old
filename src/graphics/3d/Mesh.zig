const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const zp = @import("../../zplay.zig");
const Renderer = zp.graphics.Renderer;
const Material = zp.graphics.Material;
const drawcall = zp.graphics.gpu.drawcall;
const VertexArray = zp.graphics.gpu.VertexArray;
const Buffer = zp.graphics.gpu.Buffer;
const alg = zp.deps.alg;
const Mat4 = alg.Mat4;
const Self = @This();

pub const vbo_positions = 0;
pub const vbo_normals = 1;
pub const vbo_texcoords = 2;
pub const vbo_colors = 3;
pub const vbo_tangents = 4;
pub const vbo_indices = 5;
pub const vbo_num = 6;

/// renderer's vertex attribute locations
/// NOTE: renderer's vertex shader should follow this
/// convention if its purpose is rendering 3d Mesh/Model objects.
pub const AttribLocation = enum(c_uint) {
    position = 0,
    color = 1,
    normal = 2,
    tangent = 3,
    texture1 = 4,
    texture2 = 5,
    texture3 = 6,
    instance_transform = 10,
};

/// vertex array
vertex_array: ?VertexArray = null,

/// primitive type
primitive_type: drawcall.PrimitiveType,

/// vertex attribute
indices: std.ArrayList(u32), // 1 u32
positions: std.ArrayList(f32), // 3 float
normals: ?std.ArrayList(f32) = null, // 3 float
texcoords: ?std.ArrayList(f32) = null, // 2 float
colors: ?std.ArrayList(f32) = null, // 4 float
tangents: ?std.ArrayList(f32) = null, // 4 float
owns_data: bool,

/// allocate and initialize Mesh instance
pub fn init(
    allocator: std.mem.Allocator,
    primitive_type: drawcall.PrimitiveType,
    indices: []const u32,
    positions: []const f32,
    normals: ?[]const f32,
    texcoords: ?[]const f32,
    colors: ?[]const f32,
    tangents: ?[]const f32,
) !Self {
    var self: Self = .{
        .primitive_type = primitive_type,
        .indices = try std.ArrayList(u32).initCapacity(allocator, indices.len),
        .positions = try std.ArrayList(f32).initCapacity(allocator, positions.len),
        .owns_data = true,
    };
    self.indices.appendSliceAssumeCapacity(indices);
    self.positions.appendSliceAssumeCapacity(positions);
    if (normals) |ns| {
        self.normals = try std.ArrayList(f32).initCapacity(allocator, ns.len);
        self.normals.?.appendSliceAssumeCapacity(ns);
    }
    if (texcoords) |ts| {
        self.texcoords = try std.ArrayList(f32).initCapacity(allocator, ts.len);
        self.texcoords.?.appendSliceAssumeCapacity(ts);
    }
    if (colors) |cs| {
        self.colors = try std.ArrayList(f32).initCapacity(allocator, cs.len);
        self.colors.?.appendSliceAssumeCapacity(cs);
    }
    if (tangents) |ts| {
        self.tangents = try std.ArrayList(f32).initCapacity(allocator, ts.len);
        self.tangents.?.appendSliceAssumeCapacity(ts);
    }
    return self;
}

/// create Mesh, maybe taking ownership of given arrays
pub fn fromArrays(
    primitive_type: drawcall.PrimitiveType,
    indices: std.ArrayList(u32),
    positions: std.ArrayList(f32),
    normals: ?std.ArrayList(f32),
    texcoords: ?std.ArrayList(f32),
    colors: ?std.ArrayList(f32),
    tangents: ?std.ArrayList(f32),
    take_ownership: bool,
) Self {
    var mesh: Self = .{
        .primitive_type = primitive_type,
        .indices = indices,
        .positions = positions,
        .normals = normals,
        .texcoords = texcoords,
        .colors = colors,
        .tangents = tangents,
        .owns_data = take_ownership,
    };
    return mesh;
}

/// free resources
pub fn deinit(self: Self) void {
    if (self.vertex_array) |va| {
        va.deinit();
    }
    if (self.owns_data) {
        self.indices.deinit();
        self.positions.deinit();
        if (self.normals) |ns| ns.deinit();
        if (self.texcoords) |ts| ts.deinit();
        if (self.colors) |cs| cs.deinit();
        if (self.tangents) |ts| ts.deinit();
    }
}

/// setup vertex attribtes for rendering
pub fn setup(self: *Self, allocator: std.mem.Allocator) void {
    self.vertex_array = VertexArray.init(allocator, vbo_num);
    self.vertex_array.?.use();
    self.vertex_array.?.vbos[vbo_indices].allocInitData(u32, self.indices.items, .static_draw);
    Buffer.Target.element_array_buffer.setBinding(
        self.vertex_array.?.vbos[vbo_indices].id,
    ); // keep element buffer binded, which is demanded by vao
    self.vertex_array.?.vbos[vbo_positions].allocInitData(f32, self.positions.items, .static_draw);
    self.vertex_array.?.setAttribute(vbo_positions, @enumToInt(AttribLocation.position), 3, f32, false, 0, 0);
    if (self.normals) |ns| {
        self.vertex_array.?.vbos[vbo_normals].allocInitData(f32, ns.items, .static_draw);
        self.vertex_array.?.setAttribute(vbo_normals, @enumToInt(AttribLocation.normal), 3, f32, false, 0, 0);
    }
    if (self.texcoords) |ts| {
        self.vertex_array.?.vbos[vbo_texcoords].allocInitData(f32, ts.items, .static_draw);
        self.vertex_array.?.setAttribute(vbo_texcoords, @enumToInt(AttribLocation.texture1), 2, f32, false, 0, 0);
    }
    if (self.colors) |cs| {
        self.vertex_array.?.vbos[vbo_colors].allocInitData(f32, cs.items, .static_draw);
        self.vertex_array.?.setAttribute(vbo_colors, @enumToInt(AttribLocation.color), 4, f32, false, 0, 0);
    }
    if (self.tangents) |ts| {
        self.vertex_array.?.vbos[vbo_tangents].allocInitData(f32, ts.items, .static_draw);
        self.vertex_array.?.setAttribute(vbo_tangents, @enumToInt(AttribLocation.tangent), 4, f32, false, 0, 0);
    }
    self.vertex_array.?.disuse();
    Buffer.Target.element_array_buffer.setBinding(0);
}

/// get vertex data
pub fn getVertexData(
    self: Self,
    material: ?*Material,
    transform: ?Renderer.LocalTransform,
) Renderer.Input.VertexData {
    var vd = Renderer.Input.VertexData{
        .vertex_array = self.vertex_array.?,
        .primitive = self.primitive_type,
        .count = @intCast(u32, self.indices.items.len),
        .material = material,
    };
    if (transform) |tr| {
        vd.transform = tr;
    }
    return vd;
}

// generate a quad
pub fn genQuad(
    allocator: std.mem.Allocator,
    w: f32,
    h: f32,
) !Self {
    const w2 = w / 2;
    const h2 = h / 2;
    const positions: [12]f32 = .{
        -w2, -h2, 0,
        w2,  -h2, 0,
        w2,  h2,  0,
        -w2, h2,  0,
    };
    const normals: [12]f32 = .{
        0, 0, 1,
        0, 0, 1,
        0, 0, 1,
        0, 0, 1,
    };
    const texcoords: [8]f32 = .{
        0, 0,
        1, 0,
        1, 1,
        0, 1,
    };
    const indices: [6]u32 = .{
        0, 1, 2, 0, 2, 3,
    };

    var mesh = try init(
        allocator,
        .triangles,
        &indices,
        &positions,
        &normals,
        &texcoords,
        null,
        null,
    );
    mesh.setup(allocator);
    return mesh;
}

// generate a plane surface
pub fn genPlane(
    allocator: std.mem.Allocator,
    w: f32,
    h: f32,
    sector_count: u32,
    stack_count: u32,
) !Self {
    assert(w > 0 and h > 0 and sector_count > 0 and stack_count > 0);
    const attrib_count = (sector_count + 1) * (stack_count + 1);
    var positions = try std.ArrayList(f32).initCapacity(
        allocator,
        attrib_count * 3,
    );
    var normals = try std.ArrayList(f32).initCapacity(
        allocator,
        attrib_count * 3,
    );
    var texcoords = try std.ArrayList(f32).initCapacity(
        allocator,
        attrib_count * 2,
    );
    var indices = try std.ArrayList(u32).initCapacity(
        allocator,
        sector_count * stack_count * 6,
    );
    var sector_step = w / @intToFloat(f32, sector_count);
    var stack_step = h / @intToFloat(f32, stack_count);

    // vertex atributes
    const start_x = -w / 2;
    const start_y = -h / 2;
    var i: u32 = 0;
    while (i <= sector_count) : (i += 1) {
        var xpos = start_x + sector_step * @intToFloat(f32, i);

        var j: u32 = 0;
        while (j <= stack_count) : (j += 1) {
            positions.appendSliceAssumeCapacity(&.{
                xpos,
                start_y + stack_step * @intToFloat(f32, j),
                0,
            });
            normals.appendSliceAssumeCapacity(&.{ 0, 0, 1 });
            texcoords.appendSliceAssumeCapacity(&.{
                @intToFloat(f32, i),
                @intToFloat(f32, j),
            });
        }
    }

    // vertex indices
    i = 0;
    while (i < sector_count) : (i += 1) {
        var j: u32 = 0;
        while (j < stack_count) : (j += 1) {
            var idx_bl = (stack_count + 1) * i + j; // index of bottom-left
            var idx_br = (stack_count + 1) * (i + 1) + j; // index of bottom-right
            var idx_tl = idx_bl + 1; // index of top-left
            var idx_tr = idx_br + 1; // index of top-right
            indices.appendSliceAssumeCapacity(&.{ idx_bl, idx_br, idx_tl });
            indices.appendSliceAssumeCapacity(&.{ idx_tl, idx_br, idx_tr });
        }
    }

    var mesh = fromArrays(
        .triangles,
        indices,
        positions,
        normals,
        texcoords,
        null,
        null,
        true,
    );
    mesh.setup(allocator);
    return mesh;
}

// generate a circle
pub fn genCircle(
    allocator: std.mem.Allocator,
    r: f32,
    sector_count: u32,
) !Self {
    assert(r > 0 and sector_count > 0);
    const attrib_count = sector_count + 2;
    var positions = try std.ArrayList(f32).initCapacity(
        allocator,
        attrib_count * 3,
    );
    var normals = try std.ArrayList(f32).initCapacity(
        allocator,
        attrib_count * 3,
    );
    var texcoords = try std.ArrayList(f32).initCapacity(
        allocator,
        attrib_count * 2,
    );
    var indices = try std.ArrayList(u32).initCapacity(
        allocator,
        sector_count * 3,
    );
    var sector_step = math.pi * 2.0 / @intToFloat(f32, sector_count);

    // vertex atributes
    positions.appendSliceAssumeCapacity(&.{ 0, 0, 0 });
    normals.appendSliceAssumeCapacity(&.{ 0, 0, 1 });
    texcoords.appendSliceAssumeCapacity(&.{ 0.5, 0.5 });
    var i: u32 = 0;
    while (i <= sector_count) : (i += 1) {
        var sector_angle = @intToFloat(f32, i) * sector_step;
        const cos = @cos(sector_angle);
        const sin = @sin(sector_angle);
        positions.appendSliceAssumeCapacity(&.{ cos * r, sin * r, 0 });
        normals.appendSliceAssumeCapacity(&.{ 0, 0, 1 });
        texcoords.appendSliceAssumeCapacity(&.{ cos * 0.5 + 0.5, sin * 0.5 + 0.5 });
    }

    // vertex indices
    i = 0;
    while (i < sector_count) : (i += 1) {
        indices.appendSliceAssumeCapacity(&.{ 0, i + 1, i + 2 });
    }

    var mesh = fromArrays(
        .triangles,
        indices,
        positions,
        normals,
        texcoords,
        null,
        null,
        true,
    );
    mesh.setup(allocator);
    return mesh;
}

// generate a cube
pub fn genCube(
    allocator: std.mem.Allocator,
    w: f32,
    d: f32,
    h: f32,
) !Self {
    assert(w > 0 and d > 0 and h > 0);
    const attrib_count = 36;
    var positions = try std.ArrayList(f32).initCapacity(
        allocator,
        attrib_count * 3,
    );
    var normals = try std.ArrayList(f32).initCapacity(
        allocator,
        attrib_count * 3,
    );
    var texcoords = try std.ArrayList(f32).initCapacity(
        allocator,
        attrib_count * 2,
    );
    var indices = try std.ArrayList(u32).initCapacity(
        allocator,
        attrib_count,
    );

    const w2 = w / 2;
    const d2 = d / 2;
    const h2 = h / 2;
    const vs: [8][3]f32 = .{
        .{ w2, h2, d2 },
        .{ w2, h2, -d2 },
        .{ -w2, h2, -d2 },
        .{ -w2, h2, d2 },
        .{ w2, -h2, d2 },
        .{ w2, -h2, -d2 },
        .{ -w2, -h2, -d2 },
        .{ -w2, -h2, d2 },
    };
    positions.appendSliceAssumeCapacity(&.{
        vs[0][0], vs[0][1], vs[0][2], vs[1][0], vs[1][1], vs[1][2], vs[2][0], vs[2][1], vs[2][2], vs[0][0], vs[0][1], vs[0][2], vs[2][0], vs[2][1], vs[2][2], vs[3][0], vs[3][1], vs[3][2], // top
        vs[4][0], vs[4][1], vs[4][2], vs[7][0], vs[7][1], vs[7][2], vs[6][0], vs[6][1], vs[6][2], vs[4][0], vs[4][1], vs[4][2], vs[6][0], vs[6][1], vs[6][2], vs[5][0], vs[5][1], vs[5][2], // bottom
        vs[6][0], vs[6][1], vs[6][2], vs[7][0], vs[7][1], vs[7][2], vs[3][0], vs[3][1], vs[3][2], vs[6][0], vs[6][1], vs[6][2], vs[3][0], vs[3][1], vs[3][2], vs[2][0], vs[2][1], vs[2][2], // left
        vs[4][0], vs[4][1], vs[4][2], vs[5][0], vs[5][1], vs[5][2], vs[1][0], vs[1][1], vs[1][2], vs[4][0], vs[4][1], vs[4][2], vs[1][0], vs[1][1], vs[1][2], vs[0][0], vs[0][1], vs[0][2], // right
        vs[7][0], vs[7][1], vs[7][2], vs[4][0], vs[4][1], vs[4][2], vs[0][0], vs[0][1], vs[0][2], vs[7][0], vs[7][1], vs[7][2], vs[0][0], vs[0][1], vs[0][2], vs[3][0], vs[3][1], vs[3][2], // front
        vs[5][0], vs[5][1], vs[5][2], vs[6][0], vs[6][1], vs[6][2], vs[2][0], vs[2][1], vs[2][2], vs[5][0], vs[5][1], vs[5][2], vs[2][0], vs[2][1], vs[2][2], vs[1][0], vs[1][1], vs[1][2], // back
    });

    const cs: [4][2]f32 = .{
        .{ 0, 0 },
        .{ 1, 0 },
        .{ 1, 1 },
        .{ 0, 1 },
    };
    texcoords.appendSliceAssumeCapacity(&.{
        cs[0][0], cs[0][1], cs[1][0], cs[1][1], cs[2][0], cs[2][1], cs[0][0], cs[0][1], cs[2][0], cs[2][1], cs[3][0], cs[3][1], // top
        cs[0][0], cs[0][1], cs[1][0], cs[1][1], cs[2][0], cs[2][1], cs[0][0], cs[0][1], cs[2][0], cs[2][1], cs[3][0], cs[3][1], // bottom
        cs[0][0], cs[0][1], cs[1][0], cs[1][1], cs[2][0], cs[2][1], cs[0][0], cs[0][1], cs[2][0], cs[2][1], cs[3][0], cs[3][1], // left
        cs[0][0], cs[0][1], cs[1][0], cs[1][1], cs[2][0], cs[2][1], cs[0][0], cs[0][1], cs[2][0], cs[2][1], cs[3][0], cs[3][1], // right
        cs[0][0], cs[0][1], cs[1][0], cs[1][1], cs[2][0], cs[2][1], cs[0][0], cs[0][1], cs[2][0], cs[2][1], cs[3][0], cs[3][1], // front
        cs[0][0], cs[0][1], cs[1][0], cs[1][1], cs[2][0], cs[2][1], cs[0][0], cs[0][1], cs[2][0], cs[2][1], cs[3][0], cs[3][1], // back
    });

    normals.appendSliceAssumeCapacity(&.{
        0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, // top
        0, -1, 0, 0, -1, 0, 0, -1, 0, 0, -1, 0, 0, -1, 0, 0, -1, 0, // bottom
        -1, 0, 0, -1, 0, 0, -1, 0, 0, -1, 0, 0, -1, 0, 0, -1, 0, 0, // left
        1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, // right
        0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, // front
        0, 0, -1, 0, 0, -1, 0, 0, -1, 0, 0, -1, 0, 0, -1, 0, 0, -1, // back
    });

    var i: u32 = 0;
    while (i < attrib_count) : (i += 1) {
        indices.appendAssumeCapacity(i);
    }

    var mesh = fromArrays(
        .triangles,
        indices,
        positions,
        normals,
        texcoords,
        null,
        null,
        true,
    );
    mesh.setup(allocator);
    return mesh;
}

// generate a sphere
pub fn genSphere(
    allocator: std.mem.Allocator,
    radius: f32,
    sector_count: u32,
    stack_count: u32,
) !Self {
    assert(radius > 0 and sector_count > 0 and stack_count > 0);
    const attrib_count = (stack_count + 1) * (sector_count + 1);
    var positions = try std.ArrayList(f32).initCapacity(
        allocator,
        attrib_count * 3,
    );
    var normals = try std.ArrayList(f32).initCapacity(
        allocator,
        attrib_count * 3,
    );
    var texcoords = try std.ArrayList(f32).initCapacity(
        allocator,
        attrib_count * 2,
    );
    var indices = try std.ArrayList(u32).initCapacity(
        allocator,
        (stack_count - 1) * sector_count * 6,
    );
    var sector_step = math.pi * 2.0 / @intToFloat(f32, sector_count);
    var stack_step = math.pi / @intToFloat(f32, stack_count);
    var radius_inv = 1.0 / radius;

    // generate vertex attributes
    var i: u32 = 0;
    while (i <= stack_count) : (i += 1) {
        // starting from pi/2 to -pi/2
        var stack_angle = math.pi / 2.0 - @intToFloat(f32, i) * stack_step;
        var xy = radius * @cos(stack_angle);
        var z = radius * @sin(stack_angle);

        var j: u32 = 0;
        while (j <= sector_count) : (j += 1) {
            // starting from 0 to 2pi
            var sector_angle = @intToFloat(f32, j) * sector_step;

            // postion
            var x = xy * @cos(sector_angle);
            var y = xy * @sin(sector_angle);
            positions.appendSliceAssumeCapacity(&.{ x, y, z });

            // normal
            normals.appendSliceAssumeCapacity(&.{
                x * radius_inv,
                y * radius_inv,
                z * radius_inv,
            });

            // tex coords
            var s = @intToFloat(f32, j) / @intToFloat(f32, sector_count);
            var t = @intToFloat(f32, i) / @intToFloat(f32, stack_count);
            texcoords.appendSliceAssumeCapacity(&.{ s, t });
        }
    }

    // generate vertex indices
    // k1--k1+1
    // |  / |
    // | /  |
    // k2--k2+1
    i = 0;
    while (i < stack_count) : (i += 1) {
        var k1 = i * (sector_count + 1); // beginning of current stack
        var k2 = k1 + sector_count + 1; // beginning of next stack
        var j: u32 = 0;
        while (j < sector_count) : ({
            j += 1;
            k1 += 1;
            k2 += 1;
        }) {
            // 2 triangles per sector excluding first and last stacks
            // k1 => k2 => k1+1
            if (i != 0) {
                indices.appendSliceAssumeCapacity(&.{ k1, k2, k1 + 1 });
            }

            // k1+1 => k2 => k2+1
            if (i != (stack_count - 1)) {
                indices.appendSliceAssumeCapacity(&.{ k1 + 1, k2, k2 + 1 });
            }
        }
    }

    var mesh = fromArrays(
        .triangles,
        indices,
        positions,
        normals,
        texcoords,
        null,
        null,
        true,
    );
    mesh.setup(allocator);
    return mesh;
}

// generate a cylinder
pub fn genCylinder(
    allocator: std.mem.Allocator,
    height: f32,
    bottom_radius: f32,
    top_radius: f32,
    stack_count: u32,
    sector_count: u32,
) !Self {
    assert(height > 0 and
        (bottom_radius > 0 or top_radius > 0) and
        sector_count > 0 and stack_count > 0);
    const attrib_count = (stack_count + 3) * (sector_count + 1) + 2;
    var positions = try std.ArrayList(f32).initCapacity(
        allocator,
        attrib_count * 3,
    );
    var normals = try std.ArrayList(f32).initCapacity(
        allocator,
        attrib_count * 3,
    );
    var texcoords = try std.ArrayList(f32).initCapacity(
        allocator,
        attrib_count * 2,
    );
    var indices = try std.ArrayList(u32).initCapacity(
        allocator,
        (stack_count + 1) * sector_count * 6,
    );
    var sector_step = math.pi * 2.0 / @intToFloat(f32, sector_count);

    // unit circle positions
    var unit_circle = try std.ArrayList(f32).initCapacity(
        allocator,
        (sector_count + 1) * 2,
    );
    defer unit_circle.deinit();
    var i: u32 = 0;
    while (i <= sector_count) : (i += 1) {
        var sector_angle = @intToFloat(f32, i) * sector_step;
        unit_circle.appendSliceAssumeCapacity(&.{
            @cos(sector_angle),
            @sin(sector_angle),
        });
    }

    // compute normals of side
    var side_normals = try std.ArrayList(f32).initCapacity(
        allocator,
        (sector_count + 1) * 3,
    );
    defer side_normals.deinit();
    var zangle = math.atan2(f32, bottom_radius - top_radius, height);
    i = 0;
    while (i <= sector_count) : (i += 1) {
        var sector_angle = @intToFloat(f32, i) * sector_step;
        side_normals.appendSliceAssumeCapacity(&.{
            @cos(zangle) * @cos(sector_angle),
            @cos(zangle) * @sin(sector_angle),
            @sin(zangle),
        });
    }

    // sides
    i = 0;
    while (i <= stack_count) : (i += 1) {
        var step = @intToFloat(f32, i) / @intToFloat(f32, stack_count);
        var z = -(height * 0.5) + step * height;
        var radius = bottom_radius + step * (top_radius - bottom_radius);
        var t = 1.0 - step;

        var j: u32 = 0;
        while (j <= sector_count) : (j += 1) {
            positions.appendSliceAssumeCapacity(&.{
                unit_circle.items[j * 2] * radius,
                unit_circle.items[j * 2 + 1] * radius,
                z,
            });
            normals.appendSliceAssumeCapacity(side_normals.items[j * 3 .. (j + 1) * 3]);
            texcoords.appendSliceAssumeCapacity(&.{
                @intToFloat(f32, j) / @intToFloat(f32, sector_count),
                t,
            });
        }
    }

    // bottom
    var bottom_index_offset = @intCast(u32, positions.items.len / 3);
    var z = -height * 0.5;
    positions.appendSliceAssumeCapacity(&.{ 0, 0, z });
    normals.appendSliceAssumeCapacity(&.{ 0, 0, -1 });
    texcoords.appendSliceAssumeCapacity(&.{ 0.5, 0.5 });
    i = 0;
    while (i <= sector_count) : (i += 1) {
        var x = unit_circle.items[i * 2];
        var y = unit_circle.items[i * 2 + 1];
        positions.appendSliceAssumeCapacity(&.{ x * bottom_radius, y * bottom_radius, z });
        normals.appendSliceAssumeCapacity(&.{ 0, 0, -1 });
        texcoords.appendSliceAssumeCapacity(&.{ -x * 0.5 + 0.5, -y * 0.5 + 0.5 });
    }

    // top
    var top_index_offset = @intCast(u32, positions.items.len / 3);
    z = height * 0.5;
    positions.appendSliceAssumeCapacity(&.{ 0, 0, z });
    normals.appendSliceAssumeCapacity(&.{ 0, 0, 1 });
    texcoords.appendSliceAssumeCapacity(&.{ 0.5, 0.5 });
    i = 0;
    while (i <= sector_count) : (i += 1) {
        var x = unit_circle.items[i * 2];
        var y = unit_circle.items[i * 2 + 1];
        positions.appendSliceAssumeCapacity(&.{ x * top_radius, y * top_radius, z });
        normals.appendSliceAssumeCapacity(&.{ 0, 0, 1 });
        texcoords.appendSliceAssumeCapacity(&.{ x * 0.5 + 0.5, y * 0.5 + 0.5 });
    }

    // indices
    i = 0;
    while (i < stack_count) : (i += 1) {
        var k1 = i * (sector_count + 1);
        var k2 = k1 + sector_count + 1;
        var j: u32 = 0;
        while (j < sector_count) : ({
            j += 1;
            k1 += 1;
            k2 += 1;
        }) {
            indices.appendSliceAssumeCapacity(&.{ k1, k1 + 1, k2 });
            indices.appendSliceAssumeCapacity(&.{ k2, k1 + 1, k2 + 1 });
        }
    }
    i = 0;
    while (i < sector_count) : (i += 1) {
        indices.appendSliceAssumeCapacity(&.{
            bottom_index_offset,
            bottom_index_offset + i + 2,
            bottom_index_offset + i + 1,
        });
        indices.appendSliceAssumeCapacity(&.{
            top_index_offset,
            top_index_offset + i + 1,
            top_index_offset + i + 2,
        });
    }

    var mesh = fromArrays(
        .triangles,
        indices,
        positions,
        normals,
        texcoords,
        null,
        null,
        true,
    );
    mesh.setup(allocator);
    return mesh;
}
