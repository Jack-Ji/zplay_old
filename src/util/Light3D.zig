const std = @import("std");
const sdl = @import("sdl");
const zp = @import("../lib.zig");
const gl = zp.gl;
const alg = zp.alg;
const Vec3 = alg.Vec3;
const Self = @This();

/// light type
pub const Type = enum {
    directional,
    point,
    spot,
};

/// light properties
pub const Data = union(Type) {
    directional: struct {
        ambient: Vec3,
        diffuse: Vec3,
        specular: Vec3 = Vec3.one(),
        direction: Vec3,
    },
    point: struct {
        ambient: Vec3,
        diffuse: Vec3,
        specular: Vec3 = Vec3.one(),
        position: Vec3,
        constant: f32 = 1.0,
        linear: f32,
        quadratic: f32,
    },
    spot: struct {
        ambient: Vec3,
        diffuse: Vec3,
        specular: Vec3 = Vec3.one(),
        position: Vec3,
        direction: Vec3,
        constant: f32 = 1.0,
        linear: f32,
        quadratic: f32,
        cutoff: f32,
        outer_cutoff: f32,
    },
};

/// light property data
data: Data,

/// create a new light
pub fn init(data: Data) Self {
    return .{
        .data = data,
    };
}

/// get light type
pub fn getType(self: Self) Type {
    return @as(Type, self.data);
}

/// get light position
pub fn getPosition(self: Self) ?Vec3 {
    return switch (self.data) {
        .point => |d| d.position,
        .spot => |d| d.position,
        else => null,
    };
}

/// update light colors
pub fn updateColors(self: *Self, ambient: ?Vec3, diffuse: ?Vec3, specular: ?Vec3) void {
    switch (self.data) {
        .directional => |*d| {
            if (ambient) |color| {
                d.ambient = color;
            }
            if (diffuse) |color| {
                d.diffuse = color;
            }
            if (specular) |color| {
                d.specular = color;
            }
        },
        .point => |*d| {
            if (ambient) |color| {
                d.ambient = color;
            }
            if (diffuse) |color| {
                d.diffuse = color;
            }
            if (specular) |color| {
                d.specular = color;
            }
        },
        .spot => |*d| {
            if (ambient) |color| {
                d.ambient = color;
            }
            if (diffuse) |color| {
                d.diffuse = color;
            }
            if (specular) |color| {
                d.specular = color;
            }
        },
    }
}

/// apply light in the shader
pub fn apply(self: Self, program: *gl.ShaderProgram, comptime uniform_name: [:0]const u8) void {
    switch (self.data) {
        .directional => |d| {
            program.setUniformByName(uniform_name ++ ".ambient", d.ambient);
            program.setUniformByName(uniform_name ++ ".diffuse", d.diffuse);
            program.setUniformByName(uniform_name ++ ".specular", d.specular);
            program.setUniformByName(uniform_name ++ ".direction", d.direction);
        },
        .point => |d| {
            program.setUniformByName(uniform_name ++ ".ambient", d.ambient);
            program.setUniformByName(uniform_name ++ ".diffuse", d.diffuse);
            program.setUniformByName(uniform_name ++ ".specular", d.specular);
            program.setUniformByName(uniform_name ++ ".position", d.position);
            program.setUniformByName(uniform_name ++ ".constant", d.constant);
            program.setUniformByName(uniform_name ++ ".linear", d.linear);
            program.setUniformByName(uniform_name ++ ".quadratic", d.quadratic);
        },
        .spot => |d| {
            program.setUniformByName(uniform_name ++ ".ambient", d.ambient);
            program.setUniformByName(uniform_name ++ ".diffuse", d.diffuse);
            program.setUniformByName(uniform_name ++ ".specular", d.specular);
            program.setUniformByName(uniform_name ++ ".position", d.position);
            program.setUniformByName(uniform_name ++ ".direction", d.direction);
            program.setUniformByName(uniform_name ++ ".constant", d.constant);
            program.setUniformByName(uniform_name ++ ".linear", d.linear);
            program.setUniformByName(uniform_name ++ ".quadratic", d.quadratic);
            program.setUniformByName(uniform_name ++ ".cutoff", std.math.cos(alg.toRadians(d.cutoff)));
            program.setUniformByName(uniform_name ++ ".outer_cutoff", std.math.cos(alg.toRadians(d.outer_cutoff)));
        },
    }
}
