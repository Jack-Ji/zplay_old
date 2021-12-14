const std = @import("std");
const PhongRenderer = @import("PhongRenderer.zig");
const SimpleRenderer = @import("SimpleRenderer.zig");
const zp = @import("../../zplay.zig");
const TextureUnit = zp.graphics.common.Texture.TextureUnit;
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

/// alloc texture unit, return next unused unit
pub fn allocTextureUnit(self: *Self, start_unit: i32) i32 {
    var unit = start_unit;
    switch (self.data) {
        .phong => |*mr| {
            mr.diffuse_map.tex.bindToTextureUnit(TextureUnit.fromInt(unit));
            unit += 1;
            mr.specular_map.tex.bindToTextureUnit(TextureUnit.fromInt(unit));
            unit += 1;
        },
        .pbr => {},
        .single_texture => |*t| {
            t.tex.bindToTextureUnit(TextureUnit.fromInt(unit));
            unit += 1;
        },
        .single_color => {},
    }
    return unit;
}
