const std = @import("std");
const PhongRenderer = @import("PhongRenderer.zig");
const SimpleRenderer = @import("SimpleRenderer.zig");
const zp = @import("../../zplay.zig");
const TextureUnit = zp.graphics.common.Texture.TextureUnit;
const Texture2D = zp.graphics.texture.Texture2D;
const TextureCube = zp.graphics.texture.TextureCube;
const alg = zp.deps.alg;
const Vec3 = alg.Vec3;
const Vec4 = alg.Vec4;
const Self = @This();

/// material type
pub const Type = enum {
    phong,
    pbr,
    refract_mapping,
    single_texture,
    single_cubemap,
};

/// material parameters
pub const Data = union(Type) {
    phong: struct {
        diffuse_map: Texture2D,
        specular_map: Texture2D,
        shiness: f32,
    },
    pbr: struct {},
    refract_mapping: struct {
        cubemap: TextureCube,
        ratio: f32,
    },
    single_texture: Texture2D,
    single_cubemap: TextureCube,
};

/// material properties
data: Data = undefined,

/// create material
pub fn init(data: Data) Self {
    return .{
        .data = data,
    };
}

/// alloc texture unit, return next unused unit
pub fn allocTextureUnit(self: Self, start_unit: i32) i32 {
    var unit = start_unit;
    switch (self.data) {
        .phong => |mr| {
            mr.diffuse_map.tex.bindToTextureUnit(TextureUnit.fromInt(unit));
            unit += 1;
            mr.specular_map.tex.bindToTextureUnit(TextureUnit.fromInt(unit));
            unit += 1;
        },
        .pbr => {},
        .refract_mapping => |mr| {
            mr.cubemap.tex.bindToTextureUnit(TextureUnit.fromInt(unit));
            unit += 1;
        },
        .single_texture => |t| {
            t.tex.bindToTextureUnit(TextureUnit.fromInt(unit));
            unit += 1;
        },
        .single_cubemap => |t| {
            t.tex.bindToTextureUnit(TextureUnit.fromInt(unit));
            unit += 1;
        },
    }
    return unit;
}
