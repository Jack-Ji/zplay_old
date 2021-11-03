const std = @import("std");
const stb = @import("../lib.zig").stb;
const gl = @import("gl.zig");
const stb_image = stb.image;
const Self = @This();

pub const Error = error{
    LoadImageError,
};

/// opengl texture
tex: gl.Texture = undefined,

/// size of texture
width: usize = undefined,
height: usize = undefined,

/// format of texture
format: gl.Texture.ImageFormat = undefined,

/// create 2d texture with given image file
pub fn init(
    file_path: []const u8,
    texture_unit: ?gl.Texture.TextureUnit,
    flip: bool,
) Error!Self {
    var tex: gl.Texture = undefined;
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

    const format: gl.Texture.ImageFormat = switch (channels) {
        3 => .rgb,
        4 => .rgba,
        else => std.debug.panic(
            "unsupported image format: path({s}) width({d}) height({d}) channels({d})",
            .{ file_path, width, height, channels },
        ),
    };
    tex = gl.Texture.init(.texture_2d);
    tex.bindToTextureUnit(texture_unit orelse .texture_unit_0);
    tex.updateImageData(
        .texture_2d,
        0,
        .rgb,
        @intCast(usize, width),
        @intCast(usize, height),
        null,
        format,
        u8,
        image_data[0..@intCast(usize, width * height * channels)],
        true,
    );

    return Self{
        .tex = tex,
        .width = @intCast(usize, width),
        .height = @intCast(usize, height),
        .format = format,
    };
}
