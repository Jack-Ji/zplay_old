const std = @import("std");
const zp = @import("../../zplay.zig");
const stb_image = zp.deps.stb.image;
const Texture = zp.graphics.common.Texture;
const Self = @This();

pub const Error = error{
    LoadImageError,
};

/// gpu texture
tex: *Texture,

/// size of texture
width: u32 = undefined,
height: u32 = undefined,

/// format of texture
format: Texture.ImageFormat = undefined,

/// init 2d texture from pixel data
pub fn init(
    allocator: std.mem.Allocator,
    pixel_data: []const u8,
    format: Texture.ImageFormat,
    width: u32,
    height: u32,
) !Self {
    var tex = try Texture.init(allocator, .texture_2d);
    tex.updateImageData(
        .texture_2d,
        0,
        .rgb,
        width,
        height,
        null,
        format,
        u8,
        pixel_data,
        true,
    );

    return Self{
        .tex = tex,
        .width = @intCast(u32, width),
        .height = @intCast(u32, height),
        .format = format,
    };
}

pub fn deinit(self: Self) void {
    self.tex.deinit();
}

/// create 2d texture with path to image file
pub fn fromFilePath(allocator: std.mem.Allocator, file_path: []const u8, flip: bool) !Self {
    var width: c_int = undefined;
    var height: c_int = undefined;
    var channels: c_int = undefined;

    stb_image.stbi_set_flip_vertically_on_load(@boolToInt(flip));
    var image_data = stb_image.stbi_load(
        file_path.ptr,
        &width,
        &height,
        &channels,
        0,
    );
    if (image_data == null) {
        return error.LoadImageError;
    }
    defer stb_image.stbi_image_free(image_data);

    return Self.init(
        allocator,
        image_data[0..@intCast(u32, width * height * channels)],
        switch (channels) {
            3 => .rgb,
            4 => .rgba,
            else => std.debug.panic(
                "unsupported image format: path({s}) width({d}) height({d}) channels({d})",
                .{ file_path, width, height, channels },
            ),
        },
        @intCast(u32, width),
        @intCast(u32, height),
    );
}

/// create 2d texture with given file's data buffer
pub fn fromFileData(allocator: std.mem.Allocator, data: []const u8, flip: bool) !Self {
    var width: c_int = undefined;
    var height: c_int = undefined;
    var channels: c_int = undefined;

    stb_image.stbi_set_flip_vertically_on_load(@boolToInt(flip));
    var image_data = stb_image.stbi_load_from_memory(
        data.ptr,
        @intCast(c_int, data.len),
        &width,
        &height,
        &channels,
        0,
    );
    if (image_data == null) {
        return error.LoadImageError;
    }
    defer stb_image.stbi_image_free(image_data);

    return Self.init(
        allocator,
        image_data[0..@intCast(u32, width * height * channels)],
        switch (channels) {
            3 => .rgb,
            4 => .rgba,
            else => std.debug.panic(
                "unsupported image format: width({d}) height({d}) channels({d})",
                .{ width, height, channels },
            ),
        },
        @intCast(u32, width),
        @intCast(u32, height),
    );
}
