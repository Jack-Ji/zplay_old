const std = @import("std");
const gl = @import("gl.zig");
const Self = @This();

const TextureUnit = enum(c_int) {
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

const WrappingCoord = enum(c_int) {
    s = gl.GL_TEXTURE_WRAP_S,
    t = gl.GL_TEXTURE_WRAP_T,
};

const WrappingMode = enum(c_int) {
    repeat = gl.GL_REPEAT,
    mirrored_repeat = gl.GL_MIRRORED_REPEAT,
    clamp_to_edge = gl.GL_CLAMP_TO_EDGE,
    clamp_to_border = gl.GL_CLAMP_TO_BORDER,
};

const FilteringSituation = enum(c_int) {
    minifying = gl.GL_TEXTURE_MIN_FILTER,
    magnifying = gl.GL_TEXTURE_MAG_FILTER,
};

const FilteringMode = enum(c_int) {
    nearest = gl.GL_NEAREST,
    linear = gl.GL_LINEAR,
};

/// texture unit id
id: gl.GLuint,

pub fn init() Self {
    var texture: Self = undefined;
    gl.genTextures(1, &texture.id);
    gl.checkError();
    return texture;
}

pub fn deinit(self: Self) void {
    gl.deleteTextures(1, &self.id);
    gl.checkError();
}

/// start using texture
pub fn use(self: Self, unit: i32) void {
    gl.bindVertexArray(self.id);
    gl.activeTexture(gl.GL_TEXTURE0 + unit);
    gl.checkError();
}

/// bind texture
pub fn disuse(self: Self) void {
    _ = self;
    gl.bindVertexArray(0);
    gl.checkError();
}

/// set texture wrapping mode
pub fn setWrapping(self: Self, coord: WrappingCoord, mode: WrappingMode) void {
    gl.bindTexture(gl.GL_TEXTURE_2D, self.id);
    gl.texParameteri(gl.GL_TEXTURE_2D, @enumToInt(coord), @enumToInt(mode));
    gl.checkError();
}

// set border color, useful when using `WrappingMode.clamp_to_border`
pub fn setBorderColor(self: Self, color: [4]f32) void {
    gl.bindTexture(gl.GL_TEXTURE_2D, self.id);
    gl.texParameterfv(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_BORDER_COLOR, &color);
    gl.checkError();
}

// set filtering mode
pub fn setFilteringMode(self: Self, situation: FilteringSituation, mode: FilteringMode) void {
    gl.bindTexture(gl.GL_TEXTURE_2D, self.id);
    gl.texParameteri(gl.GL_TEXTURE_2D, @enumToInt(situation), @enumToInt(mode));
    gl.checkError();
}

//pub fn updateData(self:Self, data: []u8) void {}
