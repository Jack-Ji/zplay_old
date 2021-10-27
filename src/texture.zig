const std = @import("std");
const stb = @import("stb/stb.zig");
const gl = @import("gl/gl.zig");
const stb_image = stb.image;

pub const Error = error{
    LoadImageError,
};

/// create 2d texture from given image file
pub fn createTexture2D(
    file_path: []const u8,
    texture_unit: ?gl.Texture.TextureUnit,
    flip: bool,
) Error!gl.Texture {
    var texture: gl.Texture = undefined;
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

    texture = gl.Texture.init(.texture_2d);
    texture.bindToTextureUnit(texture_unit orelse .texture_unit_0);
    texture.updateImageData(
        .texture_2d,
        0,
        .rgb,
        @intCast(usize, width),
        @intCast(usize, height),
        null,
        switch (channels) {
            3 => .rgb,
            4 => .rgba,
            else => std.debug.panic(
                "unsupported image format: path({s}) width({d}) height({d}) channels({d})",
                .{ file_path, width, height, channels },
            ),
        },
        u8,
        image_data[0..@intCast(usize, width * height * channels)],
        true,
    );

    return texture;
}
