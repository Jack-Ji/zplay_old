const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const Renderer = @import("Renderer.zig");
const Camera = @import("Camera.zig");
const Material = @import("Material.zig");
const zp = @import("../../zplay.zig");
const drawcall = zp.graphics.common.drawcall;
const VertexArray = zp.graphics.common.VertexArray;
const Buffer = zp.graphics.common.Buffer;
const alg = zp.deps.alg;
const Vec2 = alg.Vec2;
const Vec3 = alg.Vec3;
const Vec4 = alg.Vec4;
const Mat4 = alg.Mat4;
const Self = @This();

pub const vbo_positions = 0;
pub const vbo_normals = 1;
pub const vbo_texcoords = 2;
pub const vbo_colors = 3;
pub const vbo_tangents = 4;
pub const vbo_indices = 5;
pub const vbo_num = 6;

/// vertex array
vertex_array: ?VertexArray = null,

/// primitive type
primitive_type: drawcall.PrimitiveType,

/// vertex attribute
indices: std.ArrayList(u32),
positions: std.ArrayList(Vec3),
normals: ?std.ArrayList(Vec3) = null,
texcoords: ?std.ArrayList(Vec2) = null,
colors: ?std.ArrayList(Vec4) = null,
tangents: ?std.ArrayList(Vec3) = null,
owns_data: bool,

/// allocate and initialize Mesh instance
pub fn init(
    allocator: std.mem.Allocator,
    primitive_type: drawcall.PrimitiveType,
    indices: []const u32,
    positions: []const Vec3,
    normals: ?[]const Vec3,
    texcoords: ?[]const Vec2,
    colors: ?[]const Vec4,
    tangents: ?[]const Vec3,
) !Self {
    var self: Self = .{
        .primitive_type = primitive_type,
        .indices = try std.ArrayList(u32).initCapacity(allocator, indices.len),
        .positions = try std.ArrayList(Vec3).initCapacity(allocator, positions.len),
        .owns_data = true,
    };
    self.indices.appendSliceAssumeCapacity(indices);
    self.positions.appendSliceAssumeCapacity(positions);
    if (normals) |ns| {
        self.normals = try std.ArrayList(Vec3).initCapacity(allocator, ns.len);
        self.normals.?.appendSliceAssumeCapacity(ns);
    }
    if (texcoords) |ts| {
        self.texcoords = try std.ArrayList(Vec2).initCapacity(allocator, ts.len);
        self.texcoords.?.appendSliceAssumeCapacity(ts);
    }
    if (colors) |cs| {
        self.colors = try std.ArrayList(Vec4).initCapacity(allocator, cs.len);
        self.colors.?.appendSliceAssumeCapacity(cs);
    }
    if (tangents) |ts| {
        self.tangents = try std.ArrayList(Vec3).initCapacity(allocator, ts.len);
        self.tangents.?.appendSliceAssumeCapacity(ts);
    }
    return self;
}

/// create Mesh, maybe taking ownership of given arrays
pub fn fromArrays(
    primitive_type: drawcall.PrimitiveType,
    indices: std.ArrayList(u32),
    positions: std.ArrayList(Vec3),
    normals: ?std.ArrayList(Vec3),
    texcoords: ?std.ArrayList(Vec2),
    colors: ?std.ArrayList(Vec4),
    tangents: ?std.ArrayList(Vec3),
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

/// setup vertex array's data
pub fn setup(self: *Self, allocator: std.mem.Allocator) void {
    self.vertex_array = VertexArray.init(allocator, vbo_num);
    self.vertex_array.?.use();
    self.vertex_array.?.vbos[vbo_indices].allocInitData(u32, self.indices.items, .static_draw);
    Buffer.Target.element_array_buffer.setBinding(
        self.vertex_array.?.vbos[vbo_indices].id,
    ); // keep element buffer binded, which is demanded by vao
    self.vertex_array.?.vbos[vbo_positions].allocInitData(Vec3, self.positions.items, .static_draw);
    if (self.normals) |ns| {
        self.vertex_array.?.vbos[vbo_normals].allocInitData(Vec3, ns.items, .static_draw);
    }
    if (self.texcoords) |ts| {
        self.vertex_array.?.vbos[vbo_texcoords].allocInitData(Vec2, ts.items, .static_draw);
    }
    if (self.colors) |cs| {
        self.vertex_array.?.vbos[vbo_colors].allocInitData(Vec4, cs.items, .static_draw);
    }
    if (self.tangents) |ts| {
        self.vertex_array.?.vbos[vbo_tangents].allocInitData(Vec3, ts.items, .static_draw);
    }
    self.vertex_array.?.disuse();
    Buffer.Target.element_array_buffer.setBinding(0);
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

/// draw mesh using renderer
pub fn render(
    self: Self,
    rd: Renderer,
    transform: Mat4,
    projection: Mat4,
    camera: ?Camera,
    material: ?Material,
) !void {
    self.vertex_array.?.use();
    self.enableAttributes(rd.getVertexAttribs());
    self.vertex_array.?.disuse();

    try rd.render(
        self.vertex_array.?,
        true,
        self.primitive_type,
        0,
        @intCast(u32, self.indices.items.len),
        transform,
        projection,
        camera,
        material,
    );
}

/// instanced draw mesh using renderer
pub fn renderInstanced(
    self: Self,
    rd: Renderer,
    transforms: Renderer.InstanceTransformArray,
    projection: Mat4,
    camera: ?Camera,
    material: ?Material,
    instance_count: ?u32,
) !void {
    self.vertex_array.?.use();
    self.enableAttributes(rd.getVertexAttribs());
    self.vertex_array.?.disuse();

    try rd.renderInstanced(
        self.vertex_array.?,
        self.indices != null,
        self.primitive_type,
        0,
        if (self.indices) |ids|
            @intCast(u32, ids.items.len)
        else
            @intCast(u32, self.positions.items.len),
        transforms,
        projection,
        camera,
        material,
        instance_count,
    );
}

/// enable vertex attributes
/// NOTE: VertexArray should have been activated!
fn enableAttributes(self: Self, attrs: []const u32) void {
    for (attrs) |a| {
        switch (a) {
            Renderer.ATTRIB_LOCATION_POS => {
                self.vertex_array.?.setAttribute(vbo_positions, a, 3, f32, false, 0, 0);
            },
            Renderer.ATTRIB_LOCATION_COLOR => {
                if (self.colors != null) {
                    self.vertex_array.?.setAttribute(vbo_colors, a, 4, f32, false, 0, 0);
                }
            },
            Renderer.ATTRIB_LOCATION_NORMAL => {
                if (self.normals != null) {
                    self.vertex_array.?.setAttribute(vbo_normals, a, 3, f32, false, 0, 0);
                }
            },
            Renderer.ATTRIB_LOCATION_TANGENT => {
                if (self.tangents != null) {
                    self.vertex_array.?.setAttribute(vbo_tangents, a, 3, f32, false, 0, 0);
                }
            },
            Renderer.ATTRIB_LOCATION_TEXTURE1 => {
                if (self.texcoords != null) {
                    self.vertex_array.?.setAttribute(vbo_texcoords, a, 2, f32, false, 0, 0);
                }
            },
            Renderer.ATTRIB_LOCATION_TEXTURE2 => {},
            Renderer.ATTRIB_LOCATION_TEXTURE3 => {},
            else => {},
        }
    }
}

// generate a quad
pub fn genQuad(
    allocator: std.mem.Allocator,
    w: f32,
    h: f32,
) !Self {
    const w2 = w / 2;
    const h2 = h / 2;
    const positions: [4]Vec3 = .{
        Vec3.new(-w2, -h2, 0),
        Vec3.new(w2, -h2, 0),
        Vec3.new(w2, h2, 0),
        Vec3.new(-w2, h2, 0),
    };
    const normals: [4]Vec3 = .{
        Vec3.forward(),
        Vec3.forward(),
        Vec3.forward(),
        Vec3.forward(),
    };
    const texcoords: [4]Vec2 = .{
        Vec2.new(0, 0),
        Vec2.new(1, 0),
        Vec2.new(1, 1),
        Vec2.new(0, 1),
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

// generate a cube
pub fn genCube(
    allocator: std.mem.Allocator,
    w: f32,
    d: f32,
    h: f32,
) !Self {
    assert(w > 0 and d > 0 and h > 0);
    const attrib_count = 36;
    var positions = try std.ArrayList(Vec3).initCapacity(
        allocator,
        attrib_count,
    );
    var normals = try std.ArrayList(Vec3).initCapacity(
        allocator,
        attrib_count,
    );
    var texcoords = try std.ArrayList(Vec2).initCapacity(
        allocator,
        attrib_count,
    );
    var indices = try std.ArrayList(u32).initCapacity(
        allocator,
        attrib_count,
    );

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
    positions.appendSliceAssumeCapacity(&.{
        vs[0], vs[1], vs[2], vs[0], vs[2], vs[3], // top
        vs[4], vs[7], vs[6], vs[4], vs[6], vs[5], // bottom
        vs[6], vs[7], vs[3], vs[6], vs[3], vs[2], // left
        vs[4], vs[5], vs[1], vs[4], vs[1], vs[0], // right
        vs[7], vs[4], vs[0], vs[7], vs[0], vs[3], // front
        vs[5], vs[6], vs[2], vs[5], vs[2], vs[1], // back
    });

    const cs: [4]Vec2 = .{
        Vec2.new(0, 0),
        Vec2.new(1, 0),
        Vec2.new(1, 1),
        Vec2.new(0, 1),
    };
    texcoords.appendSliceAssumeCapacity(&.{
        cs[0], cs[1], cs[2], cs[0], cs[2], cs[3], // top
        cs[0], cs[1], cs[2], cs[0], cs[2], cs[3], // bottom
        cs[0], cs[1], cs[2], cs[0], cs[2], cs[3], // left
        cs[0], cs[1], cs[2], cs[0], cs[2], cs[3], // right
        cs[0], cs[1], cs[2], cs[0], cs[2], cs[3], // front
        cs[0], cs[1], cs[2], cs[0], cs[2], cs[3], // back
    });

    const up = Vec3.up();
    const down = Vec3.down();
    const left = Vec3.left();
    const right = Vec3.right();
    const forward = Vec3.forward();
    const back = Vec3.back();
    normals.appendSliceAssumeCapacity(&.{
        up, up, up, up, up, up, // top
        down, down, down, down, down, down, // bottom
        left, left, left, left, left, left, // left
        right, right, right, right, right, right, // right
        forward, forward, forward, forward, forward, forward, // front
        back, back, back, back, back, back, // back
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
    var positions = try std.ArrayList(Vec3).initCapacity(
        allocator,
        attrib_count,
    );
    var normals = try std.ArrayList(Vec3).initCapacity(
        allocator,
        attrib_count,
    );
    var texcoords = try std.ArrayList(Vec2).initCapacity(
        allocator,
        attrib_count,
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
        var xy = radius * math.cos(stack_angle);
        var z = radius * math.sin(stack_angle);

        var j: u32 = 0;
        while (j <= sector_count) : (j += 1) {
            // starting from 0 to 2pi
            var sector_angle = @intToFloat(f32, j) * sector_step;

            // postion
            var x = xy * math.cos(sector_angle);
            var y = xy * math.sin(sector_angle);
            positions.appendAssumeCapacity(Vec3.new(x, y, z));

            // normal
            normals.appendAssumeCapacity(Vec3.new(
                x * radius_inv,
                y * radius_inv,
                z * radius_inv,
            ));

            // tex coords
            var s = @intToFloat(f32, j) / @intToFloat(f32, sector_count);
            var t = @intToFloat(f32, i) / @intToFloat(f32, stack_count);
            texcoords.appendAssumeCapacity(Vec2.new(s, t));
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
    var positions = try std.ArrayList(Vec3).initCapacity(
        allocator,
        attrib_count,
    );
    var normals = try std.ArrayList(Vec3).initCapacity(
        allocator,
        attrib_count,
    );
    var texcoords = try std.ArrayList(Vec2).initCapacity(
        allocator,
        attrib_count,
    );
    var indices = try std.ArrayList(u32).initCapacity(
        allocator,
        (stack_count + 1) * sector_count * 6,
    );
    var sector_step = math.pi * 2.0 / @intToFloat(f32, sector_count);

    // unit circle positions
    var unit_circle = try std.ArrayList(Vec2).initCapacity(
        allocator,
        sector_count + 1,
    );
    defer unit_circle.deinit();
    var i: u32 = 0;
    while (i <= sector_count) : (i += 1) {
        var sector_angle = @intToFloat(f32, i) * sector_step;
        unit_circle.appendAssumeCapacity(Vec2.new(
            math.cos(sector_angle),
            math.sin(sector_angle),
        ));
    }

    // compute normals of side
    var side_normals = try std.ArrayList(Vec3).initCapacity(
        allocator,
        sector_count + 1,
    );
    defer side_normals.deinit();
    var zangle = math.atan2(f32, bottom_radius - top_radius, height);
    i = 0;
    while (i <= sector_count) : (i += 1) {
        var sector_angle = @intToFloat(f32, i) * sector_step;
        side_normals.appendAssumeCapacity(Vec3.new(
            math.cos(zangle) * math.cos(sector_angle),
            math.cos(zangle) * math.sin(sector_angle),
            math.sin(zangle),
        ));
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
            positions.appendAssumeCapacity(Vec3.new(
                unit_circle.items[j].x * radius,
                unit_circle.items[j].y * radius,
                z,
            ));
            normals.appendAssumeCapacity(side_normals.items[j]);
            texcoords.appendAssumeCapacity(Vec2.new(
                @intToFloat(f32, j) / @intToFloat(f32, sector_count),
                t,
            ));
        }
    }

    // bottom
    var bottom_index_offset = @intCast(u32, positions.items.len);
    var z = -height * 0.5;
    positions.appendAssumeCapacity(Vec3.new(0, 0, z));
    normals.appendAssumeCapacity(Vec3.new(0, 0, -1));
    texcoords.appendAssumeCapacity(Vec2.new(0.5, 0.5));
    i = 0;
    while (i <= sector_count) : (i += 1) {
        var x = unit_circle.items[i].x;
        var y = unit_circle.items[i].y;
        positions.appendAssumeCapacity(Vec3.new(x * bottom_radius, y * bottom_radius, z));
        normals.appendAssumeCapacity(Vec3.new(0, 0, -1));
        texcoords.appendAssumeCapacity(Vec2.new(-x * 0.5 + 0.5, -y * 0.5 + 0.5));
    }

    // top
    var top_index_offset = @intCast(u32, positions.items.len);
    z = height * 0.5;
    positions.appendAssumeCapacity(Vec3.new(0, 0, z));
    normals.appendAssumeCapacity(Vec3.new(0, 0, 1));
    texcoords.appendAssumeCapacity(Vec2.new(0.5, 0.5));
    i = 0;
    while (i <= sector_count) : (i += 1) {
        var x = unit_circle.items[i].x;
        var y = unit_circle.items[i].y;
        positions.appendAssumeCapacity(Vec3.new(x * top_radius, y * top_radius, z));
        normals.appendAssumeCapacity(Vec3.new(0, 0, 1));
        texcoords.appendAssumeCapacity(Vec2.new(x * 0.5 + 0.5, y * 0.5 + 0.5));
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
