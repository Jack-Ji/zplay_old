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

/// advanced texture creation options
pub const Option = struct {
    s_wrap: Texture.WrappingMode = .repeat,
    t_wrap: Texture.WrappingMode = .repeat,
    mag_filer: Texture.FilteringMode = .linear,
    min_filer: Texture.FilteringMode = .linear,
    gen_mipmap: bool = false,
    border_color: ?[4]f32 = null,
};

/// init 2d texture from pixel data
pub fn init(
    allocator: std.mem.Allocator,
    pixel_data: ?[]const u8,
    format: Texture.ImageFormat,
    width: u32,
    height: u32,
    option: Option,
) !Self {
    var tex = try Texture.init(allocator, .texture_2d);
    tex.setWrappingMode(.s, option.s_wrap);
    tex.setWrappingMode(.t, option.t_wrap);
    tex.setFilteringMode(.minifying, option.min_filer);
    tex.setFilteringMode(.magnifying, option.mag_filer);
    if (option.border_color) |c| {
        tex.setBorderColor(c);
    }
    tex.updateImageData(
        .texture_2d,
        0,
        switch (format) {
            .rgb => .rgb,
            .rgba => .rgba,
            else => unreachable,
        },
        width,
        height,
        null,
        format,
        u8,
        if (pixel_data) |data| data.ptr else null,
        option.gen_mipmap,
    );

    return Self{
        .tex = tex,
        .format = format,
    };
}

pub fn deinit(self: Self) void {
    self.tex.deinit();
}

/// create 2d texture with path to image file
pub fn fromFilePath(
    allocator: std.mem.Allocator,
    file_path: [:0]const u8,
    flip: bool,
    option: Option,
) !Self {
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
        option,
    );
}

/// create 2d texture with given file's data buffer
pub fn fromFileData(allocator: std.mem.Allocator, data: []const u8, flip: bool, option: Option) !Self {
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
        option,
    );
}

/// create 2d texture with pixel data (r8g8b8a8)
pub fn fromPixelData(allocator: std.mem.Allocator, data: []const u8, width: u32, height: u32, option: Option) !Self {
    assert(data.len == width * height * 4);
    return Self.init(
        allocator,
        data,
        .rgba,
        width,
        height,
        option,
    );
}
