const std = @import("std");
const assert = std.debug.assert;
const zp = @import("../../zplay.zig");
const stb_image = zp.deps.stb.image;
const Texture = zp.graphics.common.Texture;
const Self = @This();

pub const Error = error{
    LoadImageError,
};

/// gpu texture
tex: *Texture,

/// format of image
format: Texture.ImageFormat = undefined,

/// init cube texture from pixel data
pub fn init(
    allocator: std.mem.Allocator,
    right_pixel_data: []const u8,
    left_pixel_data: []const u8,
    top_pixel_data: []const u8,
    bottom_pixel_data: []const u8,
    front_pixel_data: []const u8,
    back_pixel_data: []const u8,
    format: Texture.ImageFormat,
    size: u32,
    need_linearization: bool,
) !Self {
    var tex = try Texture.init(allocator, .texture_cube_map);
    const tex_format = switch (format) {
        .rgb => if (need_linearization)
            Texture.TextureFormat.srgb
        else
            Texture.TextureFormat.rgb,
        .rgba => if (need_linearization)
            Texture.TextureFormat.srgba
        else
            Texture.TextureFormat.rgba,
        else => unreachable,
    };
    tex.setWrappingMode(.s, .clamp_to_edge);
    tex.setWrappingMode(.t, .clamp_to_edge);
    tex.setWrappingMode(.r, .clamp_to_edge);
    tex.setFilteringMode(.minifying, .linear);
    tex.setFilteringMode(.magnifying, .linear);
    tex.updateImageData(
        .texture_cube_map_positive_x,
        0,
        tex_format,
        size,
        size,
        null,
        format,
        u8,
        right_pixel_data.ptr,
        false,
    );
    tex.updateImageData(
        .texture_cube_map_negative_x,
        0,
        tex_format,
        size,
        size,
        null,
        format,
        u8,
        left_pixel_data.ptr,
        false,
    );
    tex.updateImageData(
        .texture_cube_map_positive_y,
        0,
        tex_format,
        size,
        size,
        null,
        format,
        u8,
        top_pixel_data.ptr,
        false,
    );
    tex.updateImageData(
        .texture_cube_map_negative_y,
        0,
        tex_format,
        size,
        size,
        null,
        format,
        u8,
        bottom_pixel_data.ptr,
        false,
    );
    tex.updateImageData(
        .texture_cube_map_positive_z,
        0,
        tex_format,
        size,
        size,
        null,
        format,
        u8,
        front_pixel_data.ptr,
        false,
    );
    tex.updateImageData(
        .texture_cube_map_negative_z,
        0,
        tex_format,
        size,
        size,
        null,
        format,
        u8,
        back_pixel_data.ptr,
        false,
    );

    return Self{
        .tex = tex,
        .format = format,
    };
}

pub fn deinit(self: Self) void {
    self.tex.deinit();
}

/// create cubemap with path to image files
pub fn fromFilePath(
    allocator: std.mem.Allocator,
    right_file_path: [:0]const u8,
    left_file_path: [:0]const u8,
    top_file_path: [:0]const u8,
    bottom_file_path: [:0]const u8,
    front_file_path: [:0]const u8,
    back_file_path: [:0]const u8,
    need_linearization: bool,
) !Self {
    var width: c_int = undefined;
    var height: c_int = undefined;
    var channels: c_int = undefined;
    var width1: c_int = undefined;
    var height1: c_int = undefined;
    var channels1: c_int = undefined;

    // right side
    var right_image_data = stb_image.stbi_load(
        right_file_path.ptr,
        &width,
        &height,
        &channels,
        0,
    );
    if (right_image_data == null) {
        return error.LoadImageError;
    }
    assert(width == height);
    defer stb_image.stbi_image_free(right_image_data);

    // left side
    var left_image_data = stb_image.stbi_load(
        left_file_path.ptr,
        &width1,
        &height1,
        &channels1,
        0,
    );
    if (left_image_data == null) {
        return error.LoadImageError;
    }
    assert(width1 == width);
    assert(height1 == height);
    assert(channels1 == channels);
    defer stb_image.stbi_image_free(left_image_data);

    // top side
    var top_image_data = stb_image.stbi_load(
        top_file_path.ptr,
        &width1,
        &height1,
        &channels1,
        0,
    );
    if (top_image_data == null) {
        return error.LoadImageError;
    }
    assert(width1 == width);
    assert(height1 == height);
    assert(channels1 == channels);
    defer stb_image.stbi_image_free(top_image_data);

    // bottom side
    var bottom_image_data = stb_image.stbi_load(
        bottom_file_path.ptr,
        &width1,
        &height1,
        &channels1,
        0,
    );
    if (bottom_image_data == null) {
        return error.LoadImageError;
    }
    assert(width1 == width);
    assert(height1 == height);
    assert(channels1 == channels);
    defer stb_image.stbi_image_free(bottom_image_data);

    // front side
    var front_image_data = stb_image.stbi_load(
        front_file_path.ptr,
        &width1,
        &height1,
        &channels1,
        0,
    );
    if (front_image_data == null) {
        return error.LoadImageError;
    }
    assert(width1 == width);
    assert(height1 == height);
    assert(channels1 == channels);
    defer stb_image.stbi_image_free(front_image_data);

    // back side
    var back_image_data = stb_image.stbi_load(
        back_file_path.ptr,
        &width1,
        &height1,
        &channels1,
        0,
    );
    if (back_image_data == null) {
        return error.LoadImageError;
    }
    assert(width1 == width);
    assert(height1 == height);
    assert(channels1 == channels);
    defer stb_image.stbi_image_free(back_image_data);

    var size = @intCast(u32, width * height * channels);
    return Self.init(
        allocator,
        right_image_data[0..size],
        left_image_data[0..size],
        top_image_data[0..size],
        bottom_image_data[0..size],
        front_image_data[0..size],
        back_image_data[0..size],
        switch (channels) {
            3 => .rgb,
            4 => .rgba,
            else => unreachable,
        },
        @intCast(u32, width),
        need_linearization,
    );
}

/// create cubemap with given files' data buffer
pub fn fromFileData(
    allocator: std.mem.Allocator,
    right_data: []const u8,
    left_data: []const u8,
    top_data: []const u8,
    bottom_data: []const u8,
    front_data: []const u8,
    back_data: []const u8,
) !Self {
    var width: c_int = undefined;
    var height: c_int = undefined;
    var channels: c_int = undefined;
    var width1: c_int = undefined;
    var height1: c_int = undefined;
    var channels1: c_int = undefined;

    // right side
    var right_image_data = stb_image.stbi_load_from_memory(
        right_data.ptr,
        @intCast(c_int, right_data.len),
        &width,
        &height,
        &channels,
        0,
    );
    assert(width == height);
    if (right_image_data == null) {
        return error.LoadImageError;
    }
    defer stb_image.stbi_image_free(right_image_data);

    // left side
    var left_image_data = stb_image.stbi_load_from_memory(
        left_data.ptr,
        @intCast(c_int, left_data.len),
        &width1,
        &height1,
        &channels1,
        0,
    );
    if (left_image_data == null) {
        return error.LoadImageError;
    }
    assert(width1 == width);
    assert(height1 == height);
    assert(channels1 == channels);
    defer stb_image.stbi_image_free(left_image_data);

    // top side
    var top_image_data = stb_image.stbi_load_from_memory(
        top_data.ptr,
        @intCast(c_int, top_data.len),
        &width1,
        &height1,
        &channels1,
        0,
    );
    if (top_image_data == null) {
        return error.LoadImageError;
    }
    assert(width1 == width);
    assert(height1 == height);
    assert(channels1 == channels);
    defer stb_image.stbi_image_free(top_image_data);

    // bottom side
    var bottom_image_data = stb_image.stbi_load_from_memory(
        bottom_data.ptr,
        @intCast(c_int, bottom_data.len),
        &width1,
        &height1,
        &channels1,
        0,
    );
    if (bottom_image_data == null) {
        return error.LoadImageError;
    }
    assert(width1 == width);
    assert(height1 == height);
    assert(channels1 == channels);
    defer stb_image.stbi_image_free(bottom_image_data);

    // front side
    var front_image_data = stb_image.stbi_load_from_memory(
        front_data.ptr,
        @intCast(c_int, front_data.len),
        &width1,
        &height1,
        &channels1,
        0,
    );
    if (front_image_data == null) {
        return error.LoadImageError;
    }
    assert(width1 == width);
    assert(height1 == height);
    assert(channels1 == channels);
    defer stb_image.stbi_image_free(front_image_data);

    // back side
    var back_image_data = stb_image.stbi_load_from_memory(
        back_data.ptr,
        @intCast(c_int, back_data.len),
        &width1,
        &height1,
        &channels1,
        0,
    );
    if (back_image_data == null) {
        return error.LoadImageError;
    }
    assert(width1 == width);
    assert(height1 == height);
    assert(channels1 == channels);
    defer stb_image.stbi_image_free(back_image_data);

    var size = @intCast(u32, width * height * channels);
    return Self.init(
        allocator,
        right_image_data[0..size],
        left_image_data[0..size],
        top_image_data[0..size],
        bottom_image_data[0..size],
        front_image_data[0..size],
        back_image_data[0..size],
        switch (channels) {
            3 => .rgb,
            4 => .rgba,
            else => unreachable,
        },
        @intCast(u32, width),
    );
}
