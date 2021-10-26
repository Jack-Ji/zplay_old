const std = @import("std");
const gl = @import("gl.zig");
const Self = @This();

const TextureType = enum(c_uint) {
    texture_1d = gl.GL_TEXTURE_1D,
    texture_2d = gl.GL_TEXTURE_2D,
    texture_3d = gl.GL_TEXTURE_3D,
    texture_1d_array = gl.GL_TEXTURE_1D_ARRAY,
    texture_2d_array = gl.GL_TEXTURE_2D_ARRAY,
    texture_rectangle = gl.GL_TEXTURE_RECTANGLE,
    texture_cube_map = gl.GL_TEXTURE_CUBE_MAP,
    texture_buffer = gl.GL_TEXTURE_BUFFER,
    texture_2d_multisample = gl.GL_TEXTURE_2D_MULTISAMPLE,
    texture_2d_multisample_array = gl.GL_TEXTURE_2D_MULTISAMPLE_ARRAY,
};

const UpdateTarget = enum(c_uint) {
    /// 1d
    texture_1d = gl.GL_TEXTURE_1D,
    proxy_texture_1d = gl.GL_PROXY_TEXTURE_1D,

    /// 2d
    texture_2d = gl.GL_TEXTURE_2D,
    proxy_texture_2d = gl.GL_PROXY_TEXTURE_2D,
    texture_1d_array = gl.GL_TEXTURE_1D_ARRAY,
    proxy_texture_1d_array = gl.GL_PROXY_TEXTURE_1D_ARRAY,
    texture_rectangle = gl.GL_TEXTURE_RECTANGLE,
    proxy_texture_rectangle = gl.GL_PROXY_TEXTURE_RECTANGLE,
    texture_cube_map_positive_x = gl.GL_TEXTURE_CUBE_MAP_POSITIVE_X,
    texture_cube_map_negative_x = gl.GL_TEXTURE_CUBE_MAP_NEGATIVE_X,
    texture_cube_map_positive_y = gl.GL_TEXTURE_CUBE_MAP_POSITIVE_Y,
    texture_cube_map_negative_y = gl.GL_TEXTURE_CUBE_MAP_NEGATIVE_Y,
    texture_cube_map_positive_z = gl.GL_TEXTURE_CUBE_MAP_POSITIVE_Z,
    texture_cube_map_negative_z = gl.GL_TEXTURE_CUBE_MAP_NEGATIVE_Z,
    proxy_texture_cube_map = gl.GL_PROXY_TEXTURE_CUBE_MAP,

    /// 3d
    texture_3d = gl.GL_TEXTURE_3D,
    proxy_texture_3d = gl.GL_PROXY_TEXTURE_3D,
    texture_2d_array = gl.GL_TEXTURE_2D_ARRAY,
    proxy_texture_2d_array = gl.GL_PROXY_TEXTURE_2D_ARRAY,
};

const TextureMultisampleTarget = enum(c_uint) {
    /// 2d multisample
    texture_2d_multisample = gl.GL_TEXTURE_2D_MULTISAMPLE,
    proxy_texture_2d_multisample = gl.GL_PROXY_TEXTURE_2D_MULTISAMPLE,

    /// 3d multisample
    texture_2d_multisample_array = gl.GL_TEXTURE_2D_MULTISAMPLE_ARRAY,
    proxy_texture_2d_multisample_array = gl.GL_PROXY_TEXTURE_2D_MULTISAMPLE_ARRAY,
};

const TextureFormat = enum(c_int) {
    red = gl.GL_RED,
    rg = gl.GL_RG,
    rgb = gl.GL_RGB,
    rgba = gl.GL_RGBA,
    depth_component = gl.GL_DEPTH_COMPONENT,
    depth_stencil = gl.GL_DEPTH_STENCIL,
    compressed_red = gl.GL_COMPRESSED_RED,
    compressed_rg = gl.GL_COMPRESSED_RG,
    compressed_rgb = gl.GL_COMPRESSED_RGB,
    compressed_rgba = gl.GL_COMPRESSED_RGBA,
    compressed_srgb = gl.GL_COMPRESSED_SRGB,
    compressed_srgb_alpha = gl.GL_COMPRESSED_SRGB_ALPHA,
};

const ImageFormat = enum(c_uint) {
    red = gl.GL_RED,
    rg = gl.GL_RG,
    rgb = gl.GL_RGB,
    bgr = gl.GL_BGR,
    rgba = gl.GL_RGBA,
    bgra = gl.GL_BGRA,
    depth_component = gl.GL_DEPTH_COMPONENT,
    depth_stencil = gl.GL_DEPTH_STENCIL,
};

const TextureUnit = enum(c_uint) {
    texture0 = gl.GL_TEXTURE0,
    texture1 = gl.GL_TEXTURE1,
    texture2 = gl.GL_TEXTURE2,
    texture3 = gl.GL_TEXTURE3,
    texture4 = gl.GL_TEXTURE4,
    texture5 = gl.GL_TEXTURE5,
    texture6 = gl.GL_TEXTURE6,
    texture7 = gl.GL_TEXTURE7,
    texture8 = gl.GL_TEXTURE8,
    texture9 = gl.GL_TEXTURE9,
    texture10 = gl.GL_TEXTURE10,
    texture11 = gl.GL_TEXTURE11,
    texture12 = gl.GL_TEXTURE12,
    texture13 = gl.GL_TEXTURE13,
    texture14 = gl.GL_TEXTURE14,
    texture15 = gl.GL_TEXTURE15,
    texture16 = gl.GL_TEXTURE16,
    texture17 = gl.GL_TEXTURE17,
    texture18 = gl.GL_TEXTURE18,
    texture19 = gl.GL_TEXTURE19,
    texture20 = gl.GL_TEXTURE20,
    texture21 = gl.GL_TEXTURE21,
    texture22 = gl.GL_TEXTURE22,
    texture23 = gl.GL_TEXTURE23,
    texture24 = gl.GL_TEXTURE24,
    texture25 = gl.GL_TEXTURE25,
    texture26 = gl.GL_TEXTURE26,
    texture27 = gl.GL_TEXTURE27,
    texture28 = gl.GL_TEXTURE28,
    texture29 = gl.GL_TEXTURE29,
    texture30 = gl.GL_TEXTURE30,
    texture31 = gl.GL_TEXTURE31,
};

const WrappingCoord = enum(c_uint) {
    s = gl.GL_TEXTURE_WRAP_S,
    t = gl.GL_TEXTURE_WRAP_T,
    r = gl.GL_TEXTURE_WRAP_R,
};

const WrappingMode = enum(c_int) {
    repeat = gl.GL_REPEAT,
    mirrored_repeat = gl.GL_MIRRORED_REPEAT,
    clamp_to_edge = gl.GL_CLAMP_TO_EDGE,
    clamp_to_border = gl.GL_CLAMP_TO_BORDER,
};

const FilteringSituation = enum(c_uint) {
    minifying = gl.GL_TEXTURE_MIN_FILTER,
    magnifying = gl.GL_TEXTURE_MAG_FILTER,
};

const FilteringMode = enum(c_int) {
    nearest = gl.GL_NEAREST,
    linear = gl.GL_LINEAR,
    nearest_mipmap_nearest = gl.GL_NEAREST_MIPMAP_NEAREST,
    nearest_mipmap_linear = gl.GL_NEAREST_MIPMAP_LINEAR,
    linear_mipmap_nearest = gl.GL_LINEAR_MIPMAP_NEAREST,
    linear_mipmap_linear = gl.GL_LINEAR_MIPMAP_LINEAR,
};

/// texture id
id: gl.GLuint = undefined,

/// texture type
tt: TextureType = undefined,

/// texture unit
tu: TextureUnit = undefined,

pub fn init(tt: TextureType) Self {
    var texture: Self = .{
        .tt = tt,
    };
    gl.genTextures(1, &texture.id);
    gl.checkError();
    return texture;
}

pub fn deinit(self: *Self) void {
    gl.deleteTextures(1, &self.id);
    self.id = undefined;
    self.tt = undefined;
    self.tu = undefined;
    gl.checkError();
}

// activate and bind to given texture unit
pub fn bindToTextureUnit(self: *Self, unit: TextureUnit) void {
    self.tu = unit;
    gl.activeTexture(@enumToInt(self.tu));
    gl.bindTexture(@enumToInt(self.tt), self.id);
    gl.checkError();
}

// get binded texture unit
pub fn getTextureUnit(self: Self) i32 {
    std.debug.assert(self.tu != undefined);
    return @intCast(i32, @enumToInt(self.tu) - gl.GL_TEXTURE0);
}

/// set texture wrapping mode
pub fn setWrapping(self: Self, coord: WrappingCoord, mode: WrappingMode) void {
    std.debug.assert(self.tt == .texture_2d);
    gl.texParameteri(gl.GL_TEXTURE_2D, @enumToInt(coord), @enumToInt(mode));
    gl.checkError();
}

/// set border color, useful when using `WrappingMode.clamp_to_border`
pub fn setBorderColor(self: Self, color: [4]f32) void {
    std.debug.assert(self.tt == .texture_2d);
    gl.texParameterfv(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_BORDER_COLOR, &color);
    gl.checkError();
}

/// set filtering mode
pub fn setFilteringMode(self: Self, situation: FilteringSituation, mode: FilteringMode) void {
    std.debug.assert(self.tt == .texture_2d);
    if (situation == .magnifying and
        (mode == .linear_mipmap_nearest or mode == .linear_mipmap_linear or
        mode == .nearest_mipmap_nearest or mode == .nearest_mipmap_linear))
    {
        std.debug.panic("meaningless filtering parameters!", .{});
    }
    gl.texParameteri(gl.GL_TEXTURE_2D, @enumToInt(situation), @enumToInt(mode));
    gl.checkError();
}

/// update image data
pub fn updateImageData(
    self: Self,
    target: UpdateTarget,
    mipmap_level: i32,
    texture_format: TextureFormat,
    width: usize,
    height: ?usize,
    depth: ?usize,
    image_format: ImageFormat,
    comptime T: type,
    data: []const T,
    gen_mipmap: bool,
) void {
    switch (self.tt) {
        .texture_1d => {
            std.debug.assert(target == .texture_1d or target == .proxy_texture_1d);
            gl.texImage1D(
                @enumToInt(target),
                mipmap_level,
                @enumToInt(texture_format),
                @intCast(c_int, width),
                0,
                @enumToInt(image_format),
                gl.dataType(T),
                data.ptr,
            );
        },
        .texture_2d => {
            std.debug.assert(target == .texture_2d or target == .proxy_texture_2d);
            gl.texImage2D(
                @enumToInt(target),
                mipmap_level,
                @enumToInt(texture_format),
                @intCast(c_int, width),
                @intCast(c_int, height.?),
                0,
                @enumToInt(image_format),
                gl.dataType(T),
                data.ptr,
            );
        },
        .texture_1d_array => {
            std.debug.assert(target == .texture_1d or target == .proxy_texture_1d);
            gl.texImage2D(
                @enumToInt(target),
                mipmap_level,
                @enumToInt(texture_format),
                @intCast(c_int, width),
                @intCast(c_int, height.?),
                0,
                @enumToInt(image_format),
                gl.dataType(T),
                data.ptr,
            );
        },
        .texture_rectangle => {
            std.debug.assert(target == .texture_rectangle or target == .proxy_texture_rectangle);
            gl.texImage2D(
                @enumToInt(target),
                mipmap_level,
                @enumToInt(texture_format),
                @intCast(c_int, width),
                @intCast(c_int, height.?),
                0,
                @enumToInt(image_format),
                gl.dataType(T),
                data.ptr,
            );
        },
        .texture_cube_map => {
            std.debug.assert(target == .texture_cube_map_positive_x or
                target == .texture_cube_map_negative_x or
                target == .texture_cube_map_positive_y or
                target == .texture_cube_map_negative_y or
                target == .texture_cube_map_positive_z or
                target == .texture_cube_map_negative_z or
                target == .proxy_texture_cube_map);
            gl.texImage2D(
                @enumToInt(target),
                mipmap_level,
                @enumToInt(texture_format),
                @intCast(c_int, width),
                @intCast(c_int, height.?),
                0,
                @enumToInt(image_format),
                gl.dataType(T),
                data.ptr,
            );
        },
        .texture_3d => {
            std.debug.assert(target == .texture_3d or target == .proxy_texture_3d);
            gl.texImage3D(
                @enumToInt(target),
                mipmap_level,
                @enumToInt(texture_format),
                @intCast(c_int, width),
                @intCast(c_int, height.?),
                @intCast(c_int, depth.?),
                0,
                @enumToInt(image_format),
                gl.dataType(T),
                data.ptr,
            );
        },
        .texture_2d_array => {
            std.debug.assert(target == .texture_2d_array or target == .proxy_texture_2d_array);
            gl.texImage3D(
                @enumToInt(target),
                mipmap_level,
                @enumToInt(texture_format),
                @intCast(c_int, width),
                @intCast(c_int, height.?),
                @intCast(c_int, depth.?),
                0,
                @enumToInt(image_format),
                gl.dataType(T),
                data.ptr,
            );
        },
        else => {
            std.debug.panic("invalid operation!", .{});
        },
    }
    gl.checkError();

    if (self.tt != .texture_rectangle and gen_mipmap) {
        gl.generateMipmap(@enumToInt(self.tt));
        gl.checkError();
    }
}

/// update multisample data
pub fn updateMultisampleData(
    self: Self,
    target: UpdateTarget,
    samples: usize,
    texture_format: TextureFormat,
    width: usize,
    height: usize,
    depth: ?usize,
    fixed_sample_location: bool,
) void {
    switch (self.tt) {
        .texture_2d_multisample => {
            std.debug.assert(target == .texture_2d_multisample or target == .proxy_texture_2d_multisample);
            gl.texImage2DMultisample(
                @enumToInt(target),
                samples,
                @enumToInt(texture_format),
                width,
                height,
                gl.boolType(fixed_sample_location),
            );
        },
        .texture_2d_multisample_array => {
            std.debug.assert(target == .texture_2d_multisample_array or target == .proxy_texture_2d_multisample_array);
            gl.texImage3DMultisample(
                @enumToInt(target),
                samples,
                @enumToInt(texture_format),
                width,
                height,
                depth.?,
                gl.boolType(fixed_sample_location),
            );
        },
        else => {
            std.debug.panic("invalid operation!", .{});
        },
    }
    gl.checkError();
}

/// update buffer texture data
pub fn updateBufferTexture(
    self: Self,
    texture_format: TextureFormat,
    vbo: gl.Uint,
) void {
    std.debug.assert(self.tt == .texture_buffer);
    gl.texBuffer(gl.GL_TEXTURE_BUFFER, @enumToInt(texture_format), vbo);
    gl.checkError();
}
