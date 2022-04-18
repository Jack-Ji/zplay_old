const std = @import("std");
const assert = std.debug.assert;
const panic = std.debug.panic;
const zp = @import("../../zplay.zig");
const gl = zp.deps.gl;
const stb_image = zp.deps.stb.image;
const Self = @This();

pub const Error = error{
    LoadImageError,
    TextureUnitUsed,
    EncodeTextureFailed,
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

pub const MultisampleTarget = enum(c_uint) {
    /// 2d multisample
    texture_2d_multisample = gl.GL_TEXTURE_2D_MULTISAMPLE,
    proxy_texture_2d_multisample = gl.GL_PROXY_TEXTURE_2D_MULTISAMPLE,

    /// 3d multisample
    texture_2d_multisample_array = gl.GL_TEXTURE_2D_MULTISAMPLE_ARRAY,
    proxy_texture_2d_multisample_array = gl.GL_PROXY_TEXTURE_2D_MULTISAMPLE_ARRAY,
};

pub const TextureFormat = enum(c_uint) {
    red = gl.GL_RED,
    blue = gl.GL_BLUE,
    green = gl.GL_GREEN,
    alpha = gl.GL_ALPHA,
    rg = gl.GL_RG,
    rgb = gl.GL_RGB,
    rgb_f16 = gl.GL_RGB16F,
    rgb_f32 = gl.GL_RGB32F,
    rgba = gl.GL_RGBA,
    rgba_f16 = gl.GL_RGBA16F,
    rgba_f32 = gl.GL_RGBA32F,
    srgb = gl.GL_SRGB,
    srgba = gl.GL_SRGB_ALPHA,
    depth_component = gl.GL_DEPTH_COMPONENT,
    depth_stencil = gl.GL_DEPTH_STENCIL,
    compressed_red = gl.GL_COMPRESSED_RED,
    compressed_rg = gl.GL_COMPRESSED_RG,
    compressed_rgb = gl.GL_COMPRESSED_RGB,
    compressed_rgba = gl.GL_COMPRESSED_RGBA,
    compressed_srgb = gl.GL_COMPRESSED_SRGB,
    compressed_srgb_alpha = gl.GL_COMPRESSED_SRGB_ALPHA,

    pub fn getChannels(self: @This()) u32 {
        return switch (self) {
            .red, .blue, .green, .alpha => 1,
            .rg => 2,
            .rgb, .rgb_f16, .rgb_f32 => 3,
            .rgba, .rgba_f16, .rgba_f32 => 4,
            .srgb => 3,
            .srgba => 4,
            .depth_component => 1,
            .depth_stencil => 1,
            .compressed_red => 1,
            .compressed_rg => 2,
            .compressed_rgb => 3,
            .compressed_rgba => 4,
            .compressed_srgb => 3,
            .compressed_srgb_alpha => 4,
        };
    }
};

pub const PixelFormat = enum(c_uint) {
    red = gl.GL_RED,
    blue = gl.GL_BLUE,
    green = gl.GL_GREEN,
    alpha = gl.GL_ALPHA,
    rg = gl.GL_RG,
    rgb = gl.GL_RGB,
    bgr = gl.GL_BGR,
    rgba = gl.GL_RGBA,
    bgra = gl.GL_BGRA,
    depth_component = gl.GL_DEPTH_COMPONENT,
    depth_stencil = gl.GL_DEPTH_STENCIL,

    pub fn getChannels(self: @This()) u32 {
        return switch (self) {
            .red, .blue, .green, .alpha => 1,
            .rg => 2,
            .rgb => 3,
            .bgr => 3,
            .rgba => 4,
            .bgra => 4,
            else => unreachable,
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

    const Unit = @This();

    pub fn fromInt(int: i32) Unit {
        return @intToEnum(Unit, int + gl.GL_TEXTURE0);
    }

    pub fn toInt(self: Unit) i32 {
        return @intCast(i32, @enumToInt(self) - gl.GL_TEXTURE0);
    }

    // mark where texture unit is allocated to
    var alloc_map = std.EnumArray(Unit, ?*Self).initFill(null);
    fn alloc(unit: Unit, tex: *Self) void {
        if (alloc_map.get(unit)) |t| {
            if (tex == t) return;
            t.unit = null; // detach unit from old texture
        }
        tex.unit = unit;
        alloc_map.set(unit, tex);
    }
    fn free(unit: Unit) void {
        if (alloc_map.get(unit)) |t| {
            t.unit = null; // detach unit from old texture
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

/// allocator
allocator: std.mem.Allocator,

/// texture id
id: gl.GLuint = undefined,

/// texture type
type: TextureType,

/// texture unit
unit: ?TextureUnit = null,

/// internal format
format: TextureFormat = undefined,

/// size of texture
width: u32 = undefined,
height: ?u32 = null,
depth: ?u32 = null,

pub fn init(allocator: std.mem.Allocator, _type: TextureType) !*Self {
    const self = try allocator.create(Self);
    self.allocator = allocator;
    self.type = _type;
    gl.genTextures(1, &self.id);
    gl.util.checkError();
    return self;
}

pub fn deinit(self: *Self) void {
    if (self.unit) |u| {
        TextureUnit.free(u);
    }
    gl.deleteTextures(1, &self.id);
    gl.util.checkError();
    self.allocator.destroy(self);
}

/// advanced texture creation options
pub const Option = struct {
    s_wrap: WrappingMode = .repeat,
    t_wrap: WrappingMode = .repeat,
    mag_filer: FilteringMode = .linear,
    min_filer: FilteringMode = .linear,
    gen_mipmap: bool = false,
    border_color: ?[4]f32 = null,
    need_linearization: bool = false,
};

/// create 2d texture with given size and pixels (could be null)
pub fn init2DFromPixels(
    allocator: std.mem.Allocator,
    pixel_data: ?[]const u8,
    format: PixelFormat,
    width: u32,
    height: u32,
    option: Option,
) !*Self {
    assert(width > 0 and height > 0);
    if (pixel_data) |data| {
        assert(data.len == width * height * format.getChannels());
    }
    var tex = try init(allocator, .texture_2d);
    tex.setWrappingMode(.s, option.s_wrap);
    tex.setWrappingMode(.t, option.t_wrap);
    tex.setFilteringMode(.minifying, option.min_filer);
    tex.setFilteringMode(.magnifying, option.mag_filer);
    if (option.border_color) |c| {
        tex.setBorderColor(c);
    }
    const tex_format = switch (format) {
        .rgb => if (option.need_linearization)
            TextureFormat.srgb
        else
            TextureFormat.rgb,
        .rgba => if (option.need_linearization)
            TextureFormat.srgba
        else
            TextureFormat.rgba,
        else => unreachable,
    };
    tex.updateImageData(
        .texture_2d,
        0,
        tex_format,
        width,
        height,
        null,
        format,
        u8,
        if (pixel_data) |data| data.ptr else null,
        option.gen_mipmap,
    );

    return tex;
}

/// create 2d texture with path to image file
pub fn init2DFromFilePath(
    allocator: std.mem.Allocator,
    file_path: []const u8,
    flip: bool,
    option: Option,
) !*Self {
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

    return init2DFromPixels(
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

/// create 2d texture with image file's data buffer
pub fn init2DFromFileData(
    allocator: std.mem.Allocator,
    data: []const u8,
    flip: bool,
    option: Option,
) !*Self {
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

    return init2DFromPixels(
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

/// create cube texture from pixel data
pub fn initCubeFromPixels(
    allocator: std.mem.Allocator,
    right_pixel_data: []const u8,
    left_pixel_data: []const u8,
    top_pixel_data: []const u8,
    bottom_pixel_data: []const u8,
    front_pixel_data: []const u8,
    back_pixel_data: []const u8,
    format: PixelFormat,
    size: u32,
    need_linearization: bool,
) !*Self {
    assert(right_pixel_data.len == size * size * format.getChannels());
    assert(left_pixel_data.len == size * size * format.getChannels());
    assert(top_pixel_data.len == size * size * format.getChannels());
    assert(bottom_pixel_data.len == size * size * format.getChannels());
    assert(front_pixel_data.len == size * size * format.getChannels());
    assert(back_pixel_data.len == size * size * format.getChannels());
    var tex = try init(allocator, .texture_cube_map);
    const tex_format = switch (format) {
        .rgb => if (need_linearization)
            TextureFormat.srgb
        else
            TextureFormat.rgb,
        .rgba => if (need_linearization)
            TextureFormat.srgba
        else
            TextureFormat.rgba,
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

    return tex;
}

/// create cube texture with path to image files
pub fn initCubeFromFilePaths(
    allocator: std.mem.Allocator,
    right_file_path: []const u8,
    left_file_path: []const u8,
    top_file_path: []const u8,
    bottom_file_path: []const u8,
    front_file_path: []const u8,
    back_file_path: []const u8,
    need_linearization: bool,
) !*Self {
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
    return initCubeFromPixels(
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

/// create cube texture with given files' data buffer
pub fn initCubeFromFileData(
    allocator: std.mem.Allocator,
    right_data: []const u8,
    left_data: []const u8,
    top_data: []const u8,
    bottom_data: []const u8,
    front_data: []const u8,
    back_data: []const u8,
) !*Self {
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
    return initCubeFromPixels(
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

/// save texture into encoded format (png/bmp/tga/jpg) on disk
pub const SaveOption = struct {
    format: enum { png, bmp, tga, jpg } = .png,
    png_compress_level: u8 = 8,
    tga_rle_compress: bool = true,
    jpg_quality: u8 = 75, // between 1 and 100
    flip_on_write: bool = true, // flip by default
};
pub fn saveToFile(
    self: Self,
    allocator: std.mem.Allocator,
    path: [:0]const u8,
    option: SaveOption,
) !void {
    assert(self.type == .texture_2d);
    assert(self.format == .rgb or self.format == .rgba);
    assert(self.width > 0 and self.height.? > 0);
    var buf = try allocator.alloc(u8, self.width * self.height.? * self.format.getChannels());
    defer allocator.free(buf);

    // read pixels
    self.getPixels(u8, buf);

    // encode file
    var result: c_int = undefined;
    stb_image.stbi_flip_vertically_on_write(@boolToInt(option.flip_on_write));
    switch (option.format) {
        .png => {
            stb_image.stbi_write_png_compression_level =
                @intCast(c_int, option.png_compress_level);
            result = stb_image.stbi_write_png(
                path,
                @intCast(c_int, self.width),
                @intCast(c_int, self.height.?),
                @intCast(c_int, self.format.getChannels()),
                buf.ptr,
                @intCast(c_int, self.width * self.format.getChannels()),
            );
        },
        .bmp => {
            result = stb_image.stbi_write_bmp(
                path,
                @intCast(c_int, self.width),
                @intCast(c_int, self.height.?),
                @intCast(c_int, self.format.getChannels()),
                buf.ptr,
            );
        },
        .tga => {
            stb_image.stbi_write_tga_with_rle =
                if (option.tga_rle_compress) 1 else 0;
            result = stb_image.stbi_write_tga(
                path,
                @intCast(c_int, self.width),
                @intCast(c_int, self.height.?),
                @intCast(c_int, self.format.getChannels()),
                buf.ptr,
            );
        },
        .jpg => {
            result = stb_image.stbi_write_jpg(
                path,
                @intCast(c_int, self.width),
                @intCast(c_int, self.height.?),
                @intCast(c_int, self.format.getChannels()),
                buf.ptr,
                @intCast(c_int, @intCast(c_int, std.math.clamp(option.jpg_quality, 1, 100))),
            );
        },
    }
    if (result == 0) {
        return error.EncodeTextureFailed;
    }
}

/// activate and bind to given texture unit
/// NOTE: because a texture unit can be stolen anytime
/// by other textures, we just blindly bind them everytime.
/// Maybe we need to look out for performance issue.
pub fn bindToTextureUnit(self: *Self, unit: TextureUnit) void {
    TextureUnit.alloc(unit, self);
    gl.activeTexture(@enumToInt(self.unit.?));
    defer gl.activeTexture(gl.GL_TEXTURE0);
    gl.bindTexture(@enumToInt(self.type), self.id);
    gl.util.checkError();
}

/// get binded texture unit
pub fn getTextureUnit(self: Self) i32 {
    return @intCast(i32, @enumToInt(self.unit.?) - gl.GL_TEXTURE0);
}

/// set texture wrapping mode
pub fn setWrappingMode(self: Self, coord: WrappingCoord, mode: WrappingMode) void {
    assert(self.type == .texture_2d or self.type == .texture_cube_map);
    gl.bindTexture(@enumToInt(self.type), self.id);
    defer gl.bindTexture(@enumToInt(self.type), 0);
    gl.texParameteri(@enumToInt(self.type), @enumToInt(coord), @enumToInt(mode));
    gl.util.checkError();
}

/// set border color, useful when using `WrappingMode.clamp_to_border`
pub fn setBorderColor(self: Self, color: [4]f32) void {
    assert(self.type == .texture_2d);
    gl.bindTexture(@enumToInt(self.type), self.id);
    defer gl.bindTexture(@enumToInt(self.type), 0);
    gl.texParameterfv(@enumToInt(self.type), gl.GL_TEXTURE_BORDER_COLOR, &color);
    gl.util.checkError();
}

/// set filtering mode
pub fn setFilteringMode(self: Self, situation: FilteringSituation, mode: FilteringMode) void {
    assert(self.type == .texture_2d or self.type == .texture_cube_map);
    if (situation == .magnifying and
        (mode == .linear_mipmap_nearest or
        mode == .linear_mipmap_linear or
        mode == .nearest_mipmap_nearest or
        mode == .nearest_mipmap_linear))
    {
        panic("meaningless filtering parameters!", .{});
    }
    gl.bindTexture(@enumToInt(self.type), self.id);
    defer gl.bindTexture(@enumToInt(self.type), 0);
    gl.texParameteri(@enumToInt(self.type), @enumToInt(situation), @enumToInt(mode));
    gl.util.checkError();
}

/// update image data
pub fn updateImageData(
    self: *Self,
    target: UpdateTarget,
    mipmap_level: i32,
    texture_format: TextureFormat,
    width: u32,
    height: ?u32,
    depth: ?u32,
    image_format: PixelFormat,
    comptime T: type,
    data: ?[*]const T,
    gen_mipmap: bool,
) void {
    gl.bindTexture(@enumToInt(self.type), self.id);
    defer gl.bindTexture(@enumToInt(self.type), 0);
    switch (self.type) {
        .texture_1d => {
            assert(target == .texture_1d or target == .proxy_texture_1d);
            gl.texImage1D(
                @enumToInt(target),
                mipmap_level,
                @intCast(c_int, @enumToInt(texture_format)),
                @intCast(c_int, width),
                0,
                @enumToInt(image_format),
                gl.util.dataType(T),
                data,
            );
        },
        .texture_2d => {
            assert(target == .texture_2d or target == .proxy_texture_2d);
            if (texture_format.getChannels() == 1) {
                gl.pixelStorei(gl.GL_UNPACK_ALIGNMENT, 1);
            }
            gl.texImage2D(
                @enumToInt(target),
                mipmap_level,
                @intCast(c_int, @enumToInt(texture_format)),
                @intCast(c_int, width),
                @intCast(c_int, height.?),
                0,
                @enumToInt(image_format),
                gl.util.dataType(T),
                data,
            );
        },
        .texture_1d_array => {
            assert(target == .texture_1d or target == .proxy_texture_1d);
            gl.texImage2D(
                @enumToInt(target),
                mipmap_level,
                @intCast(c_int, @enumToInt(texture_format)),
                @intCast(c_int, width),
                @intCast(c_int, height.?),
                0,
                @enumToInt(image_format),
                gl.util.dataType(T),
                data,
            );
        },
        .texture_rectangle => {
            assert(target == .texture_rectangle or target == .proxy_texture_rectangle);
            gl.texImage2D(
                @enumToInt(target),
                mipmap_level,
                @intCast(c_int, @enumToInt(texture_format)),
                @intCast(c_int, width),
                @intCast(c_int, height.?),
                0,
                @enumToInt(image_format),
                gl.util.dataType(T),
                data,
            );
        },
        .texture_cube_map => {
            assert(target == .texture_cube_map_positive_x or
                target == .texture_cube_map_negative_x or
                target == .texture_cube_map_positive_y or
                target == .texture_cube_map_negative_y or
                target == .texture_cube_map_positive_z or
                target == .texture_cube_map_negative_z or
                target == .proxy_texture_cube_map);
            gl.texImage2D(
                @enumToInt(target),
                mipmap_level,
                @intCast(c_int, @enumToInt(texture_format)),
                @intCast(c_int, width),
                @intCast(c_int, height.?),
                0,
                @enumToInt(image_format),
                gl.util.dataType(T),
                data,
            );
        },
        .texture_3d => {
            assert(target == .texture_3d or target == .proxy_texture_3d);
            gl.texImage3D(
                @enumToInt(target),
                mipmap_level,
                @intCast(c_int, @enumToInt(texture_format)),
                @intCast(c_int, width),
                @intCast(c_int, height.?),
                @intCast(c_int, depth.?),
                0,
                @enumToInt(image_format),
                gl.util.dataType(T),
                data,
            );
        },
        .texture_2d_array => {
            assert(target == .texture_2d_array or target == .proxy_texture_2d_array);
            gl.texImage3D(
                @enumToInt(target),
                mipmap_level,
                @intCast(c_int, @enumToInt(texture_format)),
                @intCast(c_int, width),
                @intCast(c_int, height.?),
                @intCast(c_int, depth.?),
                0,
                @enumToInt(image_format),
                gl.util.dataType(T),
                data,
            );
        },
        else => {
            panic("invalid operation!", .{});
        },
    }
    gl.util.checkError();

    if (self.type != .texture_rectangle and gen_mipmap) {
        gl.generateMipmap(@enumToInt(self.type));
        gl.util.checkError();
    }

    self.format = texture_format;
    self.width = width;
    self.height = height;
    self.depth = depth;
}

/// allocate multisample data
pub fn allocMultisampleData(
    self: *Self,
    target: MultisampleTarget,
    samples: ?u32,
    texture_format: TextureFormat,
    width: u32,
    height: u32,
) void {
    gl.bindTexture(@enumToInt(self.type), self.id);
    defer gl.bindTexture(@enumToInt(self.type), 0);
    switch (self.type) {
        .texture_2d_multisample => {
            assert(target == .texture_2d_multisample or target == .proxy_texture_2d_multisample);
            gl.texImage2DMultisample(
                @enumToInt(target),
                @intCast(c_int, samples orelse 4),
                @enumToInt(texture_format),
                @intCast(c_int, width),
                @intCast(c_int, height),
                gl.GL_TRUE,
            );
        },
        else => {
            panic("invalid operation!", .{});
        },
    }
    gl.util.checkError();

    self.format = texture_format;
    self.width = width;
    self.height = height;
}

/// get pixel data
pub fn getPixels(self: Self, comptime T: type, pixels: []T) void {
    assert(pixels.len >= self.width * (self.height orelse 1) * self.format.getChannels());
    gl.bindTexture(@enumToInt(self.type), self.id);
    defer gl.bindTexture(@enumToInt(self.type), 0);
    gl.getTexImage(
        @enumToInt(self.type),
        0,
        @enumToInt(self.format),
        gl.util.dataType(T),
        pixels.ptr,
    );
    gl.util.checkError();
}

/// update buffer texture data
pub fn updateBufferTexture(
    self: Self,
    texture_format: TextureFormat,
    vbo: gl.Uint,
) void {
    assert(self.type == .texture_buffer);
    gl.texBuffer(@enumToInt(self.type), @enumToInt(texture_format), vbo);
    gl.util.checkError();
}
