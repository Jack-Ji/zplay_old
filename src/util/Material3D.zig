const std = @import("std");
const sdl = @import("sdl");
const zp = @import("../lib.zig");
const gl = zp.gl;
const Texture2D = zp.util.Texture2D;
const Self = @This();

/// material properties
diffuse_map: Texture2D = undefined,
specular_map: Texture2D = undefined,
shiness: f32 = undefined,

/// create a new material
pub fn init(texture: Texture2D, specular: Texture2D, shiness: f32) Self {
    return .{
        .diffuse_map = texture,
        .specular_map = specular,
        .shiness = shiness,
    };
}

/// apply material in the shader
pub fn apply(self: Self, program: *gl.ShaderProgram, comptime uniform_name: [:0]const u8) void {
    program.setUniformByName(
        uniform_name ++ ".diffuse",
        self.diffuse_map.tex.getTextureUnit(),
    );
    program.setUniformByName(
        uniform_name ++ ".specular",
        self.specular_map.tex.getTextureUnit(),
    );
    program.setUniformByName(
        uniform_name ++ ".shiness",
        self.shiness,
    );
}
