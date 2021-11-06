const std = @import("std");
const sdl = @import("sdl");
const zp = @import("../lib.zig");
const gl = zp.gl;
const alg = zp.alg;
const Vec3 = alg.Vec3;
const Mat4 = alg.Mat4;
const Self = @This();

/// predefined materials in real world
pub const emerald = Self.init(
    Vec3.new(0.0215, 0.1745, 0.0215),
    Vec3.new(0.07568, 0.61424, 0.07568),
    Vec3.new(0.633, 0.727811, 0.633),
    0.6 * 128.0,
);
pub const jade = Self.init(
    Vec3.new(0.135, 0.2225, 0.1575),
    Vec3.new(0.54, 0.89, 0.63),
    Vec3.new(0.316228, 0.316228, 0.316228),
    0.1 * 128.0,
);
pub const obsidian = Self.init(
    Vec3.new(0.05375, 0.05, 0.06625),
    Vec3.new(0.18275, 0.17, 0.22525),
    Vec3.new(0.332741, 0.328634, 0.346435),
    0.3 * 128.0,
);
pub const pearl = Self.init(
    Vec3.new(0.25, 0.20725, 0.20725),
    Vec3.new(1, 0.829, 0.829),
    Vec3.new(0.296648, 0.296648, 0.296648),
    0.088 * 128.0,
);
pub const ruby = Self.init(
    Vec3.new(0.1745, 0.01175, 0.01175),
    Vec3.new(0.61424, 0.04136, 0.04136),
    Vec3.new(0.727811, 0.626959, 0.626959),
    0.6 * 128.0,
);
pub const turquoise = Self.init(
    Vec3.new(0.1, 0.18725, 0.1745),
    Vec3.new(0.396, 0.74151, 0.69102),
    Vec3.new(0.297254, 0.30829, 0.306678),
    0.1 * 128.0,
);
pub const brass = Self.init(
    Vec3.new(0.329412, 0.223529, 0.027451),
    Vec3.new(0.780392, 0.568627, 0.113725),
    Vec3.new(0.992157, 0.941176, 0.807843),
    0.21794872 * 128.0,
);
pub const bronze = Self.init(
    Vec3.new(0.2125, 0.1275, 0.054),
    Vec3.new(0.714, 0.4284, 0.18144),
    Vec3.new(0.393548, 0.271906, 0.166721),
    0.2 * 128.0,
);
pub const chrome = Self.init(
    Vec3.new(0.25, 0.25, 0.25),
    Vec3.new(0.4, 0.4, 0.4),
    Vec3.new(0.774597, 0.774597, 0.774597),
    0.6 * 128.0,
);
pub const copper = Self.init(
    Vec3.new(0.19125, 0.0735, 0.0225),
    Vec3.new(0.7038, 0.27048, 0.0828),
    Vec3.new(0.256777, 0.137622, 0.086014),
    0.1 * 128.0,
);
pub const gold = Self.init(
    Vec3.new(0.24725, 0.1995, 0.0745),
    Vec3.new(0.75164, 0.60648, 0.22648),
    Vec3.new(0.628281, 0.555802, 0.366065),
    0.4 * 128.0,
);
pub const silver = Self.init(
    Vec3.new(0.19225, 0.19225, 0.19225),
    Vec3.new(0.50754, 0.50754, 0.50754),
    Vec3.new(0.508273, 0.508273, 0.508273),
    0.4 * 128.0,
);
pub const black_plastic = Self.init(
    Vec3.new(0.0, 0.0, 0.0),
    Vec3.new(0.01, 0.01, 0.01),
    Vec3.new(0.50, 0.50, 0.50),
    0.25 * 128.0,
);
pub const cyan_plastic = Self.init(
    Vec3.new(0.0, 0.1, 0.06),
    Vec3.new(0.0, 0.50980392, 0.50980392),
    Vec3.new(0.50196078, 0.50196078, 0.50196078),
    0.25 * 128.0,
);
pub const green_plastic = Self.init(
    Vec3.new(0.0, 0.0, 0.0),
    Vec3.new(0.1, 0.35, 0.1),
    Vec3.new(0.45, 0.55, 0.45),
    0.25 * 128.0,
);
pub const red_plastic = Self.init(
    Vec3.new(0.0, 0.0, 0.0),
    Vec3.new(0.5, 0.0, 0.0),
    Vec3.new(0.7, 0.6, 0.6),
    0.25 * 128.0,
);
pub const white_plastic = Self.init(
    Vec3.new(0.0, 0.0, 0.0),
    Vec3.new(0.55, 0.55, 0.55),
    Vec3.new(0.70, 0.70, 0.70),
    0.25 * 128.0,
);
pub const yellow_plastic = Self.init(
    Vec3.new(0.0, 0.0, 0.0),
    Vec3.new(0.5, 0.5, 0.0),
    Vec3.new(0.60, 0.60, 0.50),
    0.25 * 128.0,
);
pub const black_rubber = Self.init(
    Vec3.new(0.02, 0.02, 0.02),
    Vec3.new(0.01, 0.01, 0.01),
    Vec3.new(0.4, 0.4, 0.4),
    0.078125 * 128.0,
);
pub const cyan_rubber = Self.init(
    Vec3.new(0.0, 0.05, 0.05),
    Vec3.new(0.4, 0.5, 0.5),
    Vec3.new(0.04, 0.7, 0.7),
    0.078125 * 128.0,
);
pub const green_rubber = Self.init(
    Vec3.new(0.0, 0.05, 0.0),
    Vec3.new(0.4, 0.5, 0.4),
    Vec3.new(0.04, 0.7, 0.04),
    0.078125 * 128.0,
);
pub const red_rubber = Self.init(
    Vec3.new(0.05, 0.0, 0.0),
    Vec3.new(0.5, 0.4, 0.4),
    Vec3.new(0.7, 0.04, 0.04),
    0.078125 * 128.0,
);
pub const white_rubber = Self.init(
    Vec3.new(0.05, 0.05, 0.05),
    Vec3.new(0.5, 0.5, 0.5),
    Vec3.new(0.7, 0.7, 0.7),
    0.078125 * 128.0,
);
pub const yellow_rubber = Self.init(
    Vec3.new(0.05, 0.05, 0.0),
    Vec3.new(0.5, 0.5, 0.4),
    Vec3.new(0.7, 0.7, 0.04),
    0.078125 * 128.0,
);

/// material properties
ambient: Vec3 = undefined,
diffuse: Vec3 = undefined,
specular: Vec3 = undefined,
shiness: f32 = undefined,

/// create a new material
pub fn init(ambient: Vec3, diffuse: Vec3, specular: Vec3, shiness: f32) Self {
    return .{
        .ambient = ambient,
        .diffuse = diffuse,
        .specular = specular,
        .shiness = shiness,
    };
}

/// apply material in the shader
pub fn apply(self: Self, program: *gl.ShaderProgram, comptime name: [:0]const u8) void {
    program.setUniformByName(name ++ ".ambient", self.ambient);
    program.setUniformByName(name ++ ".diffuse", self.diffuse);
    program.setUniformByName(name ++ ".specular", self.specular);
    program.setUniformByName(name ++ ".shiness", self.shiness);
}
