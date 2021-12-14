const std = @import("std");
const zp = @import("../../zplay.zig");
const gl = zp.deps.gl;
const Self = @This();

pub const Error = error{
    TextureUnitUsed,
};

pub const TextureType = enum(c_uint) {
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

pub const UpdateTarget = enum(c_uint) {
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

pub const TextureMultisampleTarget = enum(c_uint) {
    /// 2d multisample
    texture_2d_multisample = gl.GL_TEXTURE_2D_MULTISAMPLE,
    proxy_texture_2d_multisample = gl.GL_PROXY_TEXTURE_2D_MULTISAMPLE,

    /// 3d multisample
    texture_2d_multisample_array = gl.GL_TEXTURE_2D_MULTISAMPLE_ARRAY,
    proxy_texture_2d_multisample_array = gl.GL_PROXY_TEXTURE_2D_MULTISAMPLE_ARRAY,
};

pub const TextureFormat = enum(c_int) {
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

pub const ImageFormat = enum(c_uint) {
    red = gl.GL_RED,
    rg = gl.GL_RG,
    rgb = gl.GL_RGB,
    bgr = gl.GL_BGR,
    rgba = gl.GL_RGBA,
    bgra = gl.GL_BGRA,
    depth_component = gl.GL_DEPTH_COMPONENT,
    depth_stencil = gl.GL_DEPTH_STENCIL,

    pub fn getChannels(self: @This()) u32 {
        return switch (self) {
            .red => 1,
            .rg => 2,
            .rgb => 3,
            .bgr => 3,
            .rgba => 4,
            .bgra => 4,
            else => {
                std.debug.panic("not image format!", .{});
            },
        };
    }
};

pub const TextureUnit = enum(c_uint) {
    texture_unit_0 = gl.GL_TEXTURE0,
    texture_unit_1 = gl.GL_TEXTURE1,
    texture_unit_2 = gl.GL_TEXTURE2,
    texture_unit_3 = gl.GL_TEXTURE3,
    texture_unit_4 = gl.GL_TEXTURE4,
    texture_unit_5 = gl.GL_TEXTURE5,
    texture_unit_6 = gl.GL_TEXTURE6,
    texture_unit_7 = gl.GL_TEXTURE7,
    texture_unit_8 = gl.GL_TEXTURE8,
    texture_unit_9 = gl.GL_TEXTURE9,
    texture_unit_10 = gl.GL_TEXTURE10,
    texture_unit_11 = gl.GL_TEXTURE11,
    texture_unit_12 = gl.GL_TEXTURE12,
    texture_unit_13 = gl.GL_TEXTURE13,
    texture_unit_14 = gl.GL_TEXTURE14,
    texture_unit_15 = gl.GL_TEXTURE15,
    texture_unit_16 = gl.GL_TEXTURE16,
    texture_unit_17 = gl.GL_TEXTURE17,
    texture_unit_18 = gl.GL_TEXTURE18,
    texture_unit_19 = gl.GL_TEXTURE19,
    texture_unit_20 = gl.GL_TEXTURE20,
    texture_unit_21 = gl.GL_TEXTURE21,
    texture_unit_22 = gl.GL_TEXTURE22,
    texture_unit_23 = gl.GL_TEXTURE23,
    texture_unit_24 = gl.GL_TEXTURE24,
    texture_unit_25 = gl.GL_TEXTURE25,
    texture_unit_26 = gl.GL_TEXTURE26,
    texture_unit_27 = gl.GL_TEXTURE27,
    texture_unit_28 = gl.GL_TEXTURE28,
    texture_unit_29 = gl.GL_TEXTURE29,
    texture_unit_30 = gl.GL_TEXTURE30,
    texture_unit_31 = gl.GL_TEXTURE31,

    pub fn fromInt(int: i32) @This() {
        return @intToEnum(@This(), int + gl.GL_TEXTURE0);
    }

    pub fn toInt(self: @This()) i32 {
        return @intCast(i32, @enumToInt(self) - gl.GL_TEXTURE0);
    }

    // mark where texture unit is allocated to
    var alloc_map = std.EnumArray(@This(), ?*Self).initFill(null);
    fn allocUnit(unit: @This(), tex: *Self) void {
        if (alloc_map.get(unit)) |t| {
            if (tex == t) return;
            t.tu = null; // detach unit from old texture
        }
        alloc_map.set(unit, tex);
    }
    fn freeUnit(unit: @This()) void {
        if (alloc_map.get(unit)) |t| {
            t.tu = null; // detach unit from old texture
            alloc_map.set(unit, null);
        }
    }
};

pub const WrappingCoord = enum(c_uint) {
    s = gl.GL_TEXTURE_WRAP_S,
    t = gl.GL_TEXTURE_WRAP_T,
    r = gl.GL_TEXTURE_WRAP_R,
};

pub const WrappingMode = enum(c_int) {
    repeat = gl.GL_REPEAT,
    mirrored_repeat = gl.GL_MIRRORED_REPEAT,
    clamp_to_edge = gl.GL_CLAMP_TO_EDGE,
    clamp_to_border = gl.GL_CLAMP_TO_BORDER,
};

pub const FilteringSituation = enum(c_uint) {
    minifying = gl.GL_TEXTURE_MIN_FILTER,
    magnifying = gl.GL_TEXTURE_MAG_FILTER,
};

pub const FilteringMode = enum(c_int) {
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
tu: ?TextureUnit = undefined,

pub fn init(tt: TextureType) Self {
    var texture: Self = .{
        .tt = tt,
    };
    gl.genTextures(1, &texture.id);
    gl.util.checkError();
    return texture;
}

pub fn deinit(self: Self) void {
    if (self.tu) |u| {
        TextureUnit.freeUnit(u);
    }
    gl.deleteTextures(1, &self.id);
    gl.util.checkError();
}

/// activate and bind to given texture unit
/// NOTE: because a texture unit can be stolen anytime
/// by other textures, we just blindly bind them everytime. 
/// Maybe we need to look out for performance issue.
pub fn bindToTextureUnit(self: *Self, unit: TextureUnit) void {
    self.tu = unit;
    TextureUnit.allocUnit(unit, self);
    gl.activeTexture(@enumToInt(self.tu.?));
    gl.bindTexture(@enumToInt(self.tt), self.id);
    gl.util.checkError();
}

/// get binded texture unit
pub fn getTextureUnit(self: Self) i32 {
    return @intCast(i32, @enumToInt(self.tu.?) - gl.GL_TEXTURE0);
}

/// set texture wrapping mode
pub fn setWrapping(self: Self, coord: WrappingCoord, mode: WrappingMode) void {
    std.debug.assert(self.tt == .texture_2d);
    gl.texParameteri(gl.GL_TEXTURE_2D, @enumToInt(coord), @enumToInt(mode));
    gl.util.checkError();
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
    width: u32,
    height: ?u32,
    depth: ?u32,
    image_format: ImageFormat,
    comptime T: type,
    data: []const T,
    gen_mipmap: bool,
) void {
    gl.bindTexture(@enumToInt(self.tt), self.id);
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
                gl.util.dataType(T),
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
                gl.util.dataType(T),
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
                gl.util.dataType(T),
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
                gl.util.dataType(T),
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
                gl.util.dataType(T),
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
                gl.util.dataType(T),
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
                gl.util.dataType(T),
                data.ptr,
            );
        },
        else => {
            std.debug.panic("invalid operation!", .{});
        },
    }
    gl.util.checkError();

    if (self.tt != .texture_rectangle and gen_mipmap) {
        gl.generateMipmap(@enumToInt(self.tt));
        gl.util.checkError();
    }
}

/// update multisample data
pub fn updateMultisampleData(
    self: Self,
    target: UpdateTarget,
    samples: u32,
    texture_format: TextureFormat,
    width: u32,
    height: u32,
    depth: ?u32,
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
                gl.util.boolType(fixed_sample_location),
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
                gl.util.boolType(fixed_sample_location),
            );
        },
        else => {
            std.debug.panic("invalid operation!", .{});
        },
    }
    gl.util.checkError();
}

/// update buffer texture data
pub fn updateBufferTexture(
    self: Self,
    texture_format: TextureFormat,
    vbo: gl.Uint,
) void {
    std.debug.assert(self.tt == .texture_buffer);
    gl.texBuffer(gl.GL_TEXTURE_BUFFER, @enumToInt(texture_format), vbo);
    gl.util.checkError();
}
