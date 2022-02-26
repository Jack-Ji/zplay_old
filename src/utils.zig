const std = @import("std");
const assert = std.debug.assert;
const zp = @import("zplay.zig");
const Texture = zp.graphics.gpu.Texture;
const stb_image = zp.deps.stb.image;

pub const Error = error{
    EncodeTextureFailed,
};

/// dump texture's pixels into png/bmp/tga/jpg file, only 2d texture is supported
pub const TexutureDumpOption = struct {
    format: enum { png, bmp, tga, jpg } = .png,
    png_compress_level: u8 = 8,
    tga_rle_compress: bool = true,
    jpg_quality: u8 = 75, // between 1 and 100
};
pub fn dumpTexture(
    allocator: std.mem.Allocator,
    tex: *Texture,
    path: [:0]const u8,
    option: TexutureDumpOption,
) !void {
    assert(tex.type == .texture_2d);
    assert(tex.format == .rgb or tex.format == .rgba);
    assert(tex.width > 0 and tex.height.? > 0);
    var buf = try allocator.alloc(u8, tex.width * tex.height.? * tex.format.getChannels());
    defer allocator.free(buf);

    // read pixels
    tex.getPixels(u8, buf);

    // encode file
    var result: c_int = undefined;
    switch (option.format) {
        .png => {
            stb_image.stbi_write_png_compression_level =
                @intCast(c_int, option.png_compress_level);
            result = stb_image.stbi_write_png(
                path,
                @intCast(c_int, tex.width),
                @intCast(c_int, tex.height.?),
                @intCast(c_int, tex.format.getChannels()),
                buf.ptr,
                @intCast(c_int, tex.width * tex.format.getChannels()),
            );
        },
        .bmp => {
            result = stb_image.stbi_write_bmp(
                path,
                @intCast(c_int, tex.width),
                @intCast(c_int, tex.height.?),
                @intCast(c_int, tex.format.getChannels()),
                buf.ptr,
            );
        },
        .tga => {
            stb_image.stbi_write_tga_with_rle =
                if (option.tga_rle_compress) 1 else 0;
            result = stb_image.stbi_write_tga(
                path,
                @intCast(c_int, tex.width),
                @intCast(c_int, tex.height.?),
                @intCast(c_int, tex.format.getChannels()),
                buf.ptr,
            );
        },
        .jpg => {
            result = stb_image.stbi_write_jpg(
                path,
                @intCast(c_int, tex.width),
                @intCast(c_int, tex.height.?),
                @intCast(c_int, tex.format.getChannels()),
                buf.ptr,
                @intCast(c_int, @intCast(c_int, std.math.clamp(option.jpg_quality, 1, 100))),
            );
        },
    }
    if (result == 0) {
        return error.EncodeTextureFailed;
    }
}
