const std = @import("std");
const PhongRenderer = @import("PhongRenderer.zig");
const SimpleRenderer = @import("SimpleRenderer.zig");
const zp = @import("../../zplay.zig");
const Texture2D = zp.graphics.texture.Texture2D;
const alg = zp.deps.alg;
const Vec3 = alg.Vec3;
const Vec4 = alg.Vec4;
const Self = @This();

/// material type enum
pub const MaterialType = enum {
    phong,
    pbr,
    single_texture,
    single_color,
};

/// material property definition
pub const MaterialData = union(MaterialType) {
    phong: struct {
        diffuse_map: Texture2D = undefined,
        specular_map: Texture2D = undefined,
        shiness: f32 = undefined,
    },
    pbr: struct {},
    single_texture: Texture2D,
    single_color: Vec4,
};

/// material properties
data: MaterialData = undefined,

/// create a new material
pub fn init(data: MaterialData) Self {
    return .{
        .data = data,
    };
}
