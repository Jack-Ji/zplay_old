const std = @import("std");
const assert = std.debug.assert;
const zp = @import("zplay.zig");
const Texture = zp.graphics.gpu.Texture;
const stb_image = zp.deps.stb.image;
const alg = zp.deps.alg;
const Vec3 = alg.Vec3;
const Vec4 = alg.Vec4;
const Mat4 = alg.Mat4;

pub const Error = error{
    EncodeTextureFailed,
};

/// dump texture's pixels into png/bmp/tga/jpg file, only 2d texture is supported
pub const TexutureDumpOption = struct {
    format: enum { png, bmp, tga, jpg } = .png,
    png_compress_level: u8 = 8,
    tga_rle_compress: bool = true,
    jpg_quality: u8 = 75, // between 1 and 100
    flip_on_write: bool = true, // flip by default
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
    stb_image.stbi_flip_vertically_on_write(@boolToInt(option.flip_on_write));
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

/// calculate a plane determined by normal vector and point
pub fn getPlane(normal: Vec3, point: Vec3, size: f32) [12]f32 {
    const normal_p = if (normal.x() != 0)
        Vec3.new(
            (-normal.y() - normal.z()) / normal.x(),
            1,
            1,
        ).norm()
    else if (normal.y() != 0)
        Vec3.new(
            1,
            (-normal.x() - normal.z()) / normal.y(),
            1,
        ).norm()
    else if (normal.z() != 0)
        Vec3.new(
            1,
            1,
            (-normal.x() - normal.y()) / normal.z(),
        ).norm()
    else
        unreachable;
    const normal_pp = normal_p.cross(normal).norm();
    const v1 = point.add(normal_p.scale(size / 2));
    const v2 = point.add(normal_pp.scale(size / 2));
    const v3 = point.sub(normal_p.scale(size / 2));
    const v4 = point.sub(normal_pp.scale(size / 2));
    return [12]f32{
        v1.x(), v1.y(), v1.z(),
        v2.x(), v2.y(), v2.z(),
        v3.x(), v3.y(), v3.z(),
        v4.x(), v4.y(), v4.z(),
    };
}
