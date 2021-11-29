const std = @import("std");
pub const api = @import("api.zig");

pub const Error = error{
    data_too_short,
    unknown_format,
    invalid_json,
    invalid_gltf,
    invalid_options,
    file_not_found,
    io_error,
    out_of_memory,
    legacy_gltf,
    invalid_params,
};

fn resultToError(result: api.cgltf_result) Error {
    return switch (result) {
        api.cgltf_result_data_too_short => .data_too_short,
        api.cgltf_result_unknown_format => .unknown_format,
        api.cgltf_result_invalid_json => .invalid_json,
        api.cgltf_result_invalid_gltf => .invalid_gltf,
        api.cgltf_result_invalid_options => .invalid_options,
        api.cgltf_result_file_not_found => .file_not_found,
        api.cgltf_result_io_error => .io_error,
        api.cgltf_result_out_of_memory => .out_of_memory,
        api.cgltf_result_legacy_gltf => .legacy_gltf,
        else => {
            std.debug.panic("unknown error!", .{});
        },
    };
}

/// parse gltf from data bytes, also load buffers if gltf_path is valid
pub fn loadBuffer(data: []const u8, gltf_path: ?[]const u8, options: ?api.cgltf_options) Error!*api.cgltf_data {
    const parse_option = options orelse std.mem.zeroes(api.cgltf_options);
    const out: *api.cgltf_data = undefined;
    const result = api.cgltf_parse(&parse_option, data.ptr, data.len, &out);
    if (result != api.cgltf_result_success) {
        return resultToError(result);
    }
    errdefer free(out);

    if (gltf_path) |path| {
        result = api.cgltf_load_buffers(&parse_option, out, path.ptr);
        if (result != api.cgltf_result_success) {
            return resultToError(result);
        }
    }

    return resultToError(result);
}

/// parse gltf from file, and load buffers (assuming assets are in the same directory)
pub fn loadFile(path: [:0]const u8, options: ?api.cgltf_options) Error!*api.cgltf_data {
    const parse_option = options orelse std.mem.zeroes(api.cgltf_options);
    const out: *api.cgltf_data = undefined;
    const result = api.cgltf_parse_file(&parse_option, path.ptr, &out);
    if (result != api.cgltf_result_success) {
        return resultToError(result);
    }
    errdefer free(out);

    result = api.cgltf_load_buffers(&parse_option, out, path.ptr);
    if (result != api.cgltf_result_success) {
        return resultToError(result);
    }

    return out;
}

/// read data from accessor
pub fn readFromAccessor(accessor: *api.cgltf_accessor, index: ?usize, T: type, out: []T) Error!void {
    const success = switch (T) {
        f32 => api.cgltf_accessor_read_float(
            accessor,
            index,
            out.ptr,
            out.len,
        ),
        c_uint, u32, i32 => api.cgltf_accessor_read_uint(
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
        return error.invalid_params;
    }
}

pub fn free(data: *api.cgltf_data) void {
    api.cgltf_free(data);
}
