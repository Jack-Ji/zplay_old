const std = @import("std");
const assert = std.debug.assert;
const zp = @import("../../zplay.zig");
const drawcall = zp.graphics.gpu.drawcall;

pub const c = @import("c.zig");
pub const Data = c.cgltf_data;
pub const Scene = c.cgltf_scene;
pub const Node = c.cgltf_node;
pub const Mesh = c.cgltf_mesh;
pub const Primitive = c.cgltf_primitive;
pub const Material = c.cgltf_material;
pub const Image = c.cgltf_image;

pub const Error = error{
    DataTooShort,
    UnknownFormat,
    InvalidJson,
    InvalidGLTF,
    InvalidOptions,
    FileNotFound,
    IoError,
    OutOfMemory,
    LegacyGLTF,
    InvalidParams,
};

fn resultToError(result: c.cgltf_result) Error {
    return switch (result) {
        c.cgltf_result_data_too_short => error.DataTooShort,
        c.cgltf_result_unknown_format => error.UnknownFormat,
        c.cgltf_result_invalid_json => error.InvalidJson,
        c.cgltf_result_invalid_gltf => error.InvalidGLTF,
        c.cgltf_result_invalid_options => error.InvalidOptions,
        c.cgltf_result_file_not_found => error.FileNotFound,
        c.cgltf_result_io_error => error.IoError,
        c.cgltf_result_out_of_memory => error.OutOfMemory,
        c.cgltf_result_legacy_gltf => error.LegacyGLTF,
        else => {
            std.debug.panic("unknown error!", .{});
        },
    };
}

/// parse gltf from data bytes, also load buffers if gltf_path is valid
pub fn loadBuffer(data: []const u8, gltf_path: ?[]const u8, options: ?c.cgltf_options) Error!*Data {
    const parse_option = options orelse std.mem.zeroes(c.cgltf_options);
    var out: *Data = undefined;
    var result = c.cgltf_parse(
        &parse_option,
        data.ptr,
        data.len,
        @ptrCast([*c][*c]Data, &out),
    );
    if (result != c.cgltf_result_success) {
        return resultToError(result);
    }
    errdefer free(out);

    if (gltf_path) |path| {
        result = c.cgltf_load_buffers(&parse_option, out, path.ptr);
        if (result != c.cgltf_result_success) {
            return resultToError(result);
        }
    }
    return out;
}

/// parse gltf from file, and load buffers (assuming assets are in the same directory)
pub fn loadFile(filename: [:0]const u8, options: ?c.cgltf_options) Error!*Data {
    const parse_option = options orelse std.mem.zeroes(c.cgltf_options);
    var out: *Data = undefined;
    var result = c.cgltf_parse_file(
        &parse_option,
        filename.ptr,
        @ptrCast([*c][*c]Data, &out),
    );
    if (result != c.cgltf_result_success) {
        return resultToError(result);
    }
    errdefer free(out);

    result = c.cgltf_load_buffers(&parse_option, out, filename.ptr);
    if (result != c.cgltf_result_success) {
        return resultToError(result);
    }
    return out;
}

/// read data from accessor
pub fn readFromAccessor(accessor: *c.cgltf_accessor, index: ?u32, T: type, out: []T) Error!void {
    const success = switch (T) {
        f32 => c.cgltf_accessor_read_float(
            accessor,
            index,
            out.ptr,
            out.len,
        ),
        c_uint, u32, i32 => c.cgltf_accessor_read_uint(
            accessor,
            index,
            @ptrCast(*c_uint, out.ptr),
            out.len,
        ),
        else => {
            std.debug.panic("invalid element type", .{});
        },
    };

    if (!success) {
        return error.InvalidParams;
    }
}

pub fn free(data: *Data) void {
    c.cgltf_free(data);
}

pub fn appendMeshPrimitiveByIndex(
    data: *Data,
    mesh_index: u32,
    prim_index: u32,
    indices: *std.ArrayList(u32),
    positions: *std.ArrayList(f32),
    normals: ?*std.ArrayList(f32),
    texcoords0: ?*std.ArrayList(f32),
    tangents: ?*std.ArrayList(f32),
) void {
    assert(mesh_index < data.meshes_count);
    assert(prim_index < data.meshes[mesh_index].primitives_count);
    appendMeshPrimitive(
        &data.meshes[mesh_index].primitives[prim_index],
        indices,
        positions,
        normals,
        texcoords0,
        tangents,
    );
}

pub fn appendMeshPrimitive(
    primitive: *const Primitive,
    indices: *std.ArrayList(u32),
    positions: *std.ArrayList(f32),
    normals: ?*std.ArrayList(f32),
    texcoords0: ?*std.ArrayList(f32),
    tangents: ?*std.ArrayList(f32),
) void {
    const num_vertices: u32 = @intCast(u32, primitive.attributes[0].data.*.count);
    const num_indices: u32 = @intCast(u32, primitive.indices.*.count);

    // Indices.
    {
        indices.ensureTotalCapacity(indices.items.len + num_indices) catch unreachable;

        const accessor = primitive.indices;

        assert(accessor.*.buffer_view != null);
        assert(accessor.*.stride == accessor.*.buffer_view.*.stride or accessor.*.buffer_view.*.stride == 0);
        assert((accessor.*.stride * accessor.*.count) == accessor.*.buffer_view.*.size);
        assert(accessor.*.buffer_view.*.buffer.*.data != null);

        const data_addr = @alignCast(4, @ptrCast([*]const u8, accessor.*.buffer_view.*.buffer.*.data) +
            accessor.*.offset + accessor.*.buffer_view.*.offset);

        if (accessor.*.stride == 1) {
            assert(accessor.*.component_type == c.cgltf_component_type_r_8u);
            const src = @ptrCast([*]const u8, data_addr);
            const offset = @intCast(u8, positions.items.len / 3);
            var i: u32 = 0;
            while (i < num_indices) : (i += 1) {
                indices.appendAssumeCapacity(src[i] + offset);
            }
        } else if (accessor.*.stride == 2) {
            assert(accessor.*.component_type == c.cgltf_component_type_r_16u);
            const src = @ptrCast([*]const u16, data_addr);
            const offset = @intCast(u16, positions.items.len / 3);
            var i: u32 = 0;
            while (i < num_indices) : (i += 1) {
                indices.appendAssumeCapacity(src[i] + offset);
            }
        } else if (accessor.*.stride == 4) {
            assert(accessor.*.component_type == c.cgltf_component_type_r_32u);
            const src = @ptrCast([*]const u32, data_addr);
            const offset = @intCast(u32, positions.items.len / 3);
            var i: u32 = 0;
            while (i < num_indices) : (i += 1) {
                indices.appendAssumeCapacity(src[i] + offset);
            }
        } else {
            unreachable;
        }
    }

    // Attributes.
    {
        positions.resize(positions.items.len + num_vertices * 3) catch unreachable;
        if (normals != null) normals.?.resize(normals.?.items.len + num_vertices * 3) catch unreachable;
        if (texcoords0 != null) texcoords0.?.resize(texcoords0.?.items.len + num_vertices * 2) catch unreachable;
        if (tangents != null) tangents.?.resize(tangents.?.items.len + num_vertices * 4) catch unreachable;

        const num_attribs: u32 = @intCast(u32, primitive.attributes_count);

        var attrib_index: u32 = 0;
        while (attrib_index < num_attribs) : (attrib_index += 1) {
            const attrib = &primitive.attributes[attrib_index];
            const accessor = attrib.data;

            assert(accessor.*.buffer_view != null);
            assert(accessor.*.stride == accessor.*.buffer_view.*.stride or accessor.*.buffer_view.*.stride == 0);
            assert((accessor.*.stride * accessor.*.count) == accessor.*.buffer_view.*.size);
            assert(accessor.*.buffer_view.*.buffer.*.data != null);

            const data_addr = @ptrCast([*]const u8, accessor.*.buffer_view.*.buffer.*.data) +
                accessor.*.offset + accessor.*.buffer_view.*.offset;

            if (attrib.*.type == c.cgltf_attribute_type_position) {
                assert(accessor.*.type == c.cgltf_type_vec3);
                assert(accessor.*.component_type == c.cgltf_component_type_r_32f);
                @memcpy(
                    @ptrCast([*]u8, &positions.items[positions.items.len - num_vertices * 3]),
                    data_addr,
                    accessor.*.count * accessor.*.stride,
                );
            } else if (attrib.*.type == c.cgltf_attribute_type_normal and normals != null) {
                assert(accessor.*.type == c.cgltf_type_vec3);
                assert(accessor.*.component_type == c.cgltf_component_type_r_32f);
                @memcpy(
                    @ptrCast([*]u8, &normals.?.items[normals.?.items.len - num_vertices * 3]),
                    data_addr,
                    accessor.*.count * accessor.*.stride,
                );
            } else if (attrib.*.type == c.cgltf_attribute_type_texcoord and texcoords0 != null) {
                assert(accessor.*.type == c.cgltf_type_vec2);
                assert(accessor.*.component_type == c.cgltf_component_type_r_32f);
                @memcpy(
                    @ptrCast([*]u8, &texcoords0.?.items[texcoords0.?.items.len - num_vertices * 2]),
                    data_addr,
                    accessor.*.count * accessor.*.stride,
                );
            } else if (attrib.*.type == c.cgltf_attribute_type_tangent and tangents != null) {
                assert(accessor.*.type == c.cgltf_type_vec4);
                assert(accessor.*.component_type == c.cgltf_component_type_r_32f);
                @memcpy(
                    @ptrCast([*]u8, &tangents.?.items[tangents.?.items.len - num_vertices * 4]),
                    data_addr,
                    accessor.*.count * accessor.*.stride,
                );
            }
        }
    }
}

pub fn getPrimitiveType(primitive: *Primitive) drawcall.PrimitiveType {
    return switch (primitive.type) {
        c.cgltf_primitive_type_points => .points,
        c.cgltf_primitive_type_lines => .lines,
        c.cgltf_primitive_type_line_loop => .line_loop,
        c.cgltf_primitive_type_line_strip => .line_strip,
        c.cgltf_primitive_type_triangles => .triangles,
        c.cgltf_primitive_type_triangle_strip => .triangle_strip,
        c.cgltf_primitive_type_triangle_fan => .triangle_fan,
        else => unreachable,
    };
}
