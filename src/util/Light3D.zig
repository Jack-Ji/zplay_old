const std = @import("std");
const sdl = @import("sdl");
const zp = @import("../lib.zig");
const gl = zp.gl;
const alg = zp.alg;
const Vec3 = alg.Vec3;
const Mat4 = alg.Mat4;
const Self = @This();

/// light properties
position: Vec3 = undefined,
ambient: Vec3 = undefined,
diffuse: Vec3 = undefined,
specular: Vec3 = undefined,

/// create a new light
pub fn init(position: Vec3, ambient: Vec3, diffuse: Vec3, specular: ?Vec3) Self {
    return .{
        .position = position,
        .ambient = ambient,
        .diffuse = diffuse,
        .specular = specular orelse Vec3.new(1.0, 1.0, 1.0),
    };
}

/// apply light in the shader
pub fn apply(self: Self, program: *gl.ShaderProgram, comptime uniform_name: [:0]const u8) void {
    program.setUniformByName(uniform_name ++ ".ambient", self.ambient);
    program.setUniformByName(uniform_name ++ ".diffuse", self.diffuse);
    program.setUniformByName(uniform_name ++ ".specular", self.specular);
    program.setUniformByName(uniform_name ++ ".position", self.position);
}
