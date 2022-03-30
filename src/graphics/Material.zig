const std = @import("std");
const assert = std.debug.assert;
const zp = @import("../zplay.zig");
const gfx = zp.graphics;
const Texture = gfx.gpu.Texture;
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
        diffuse_map: *Texture,
        specular_map: *Texture,
        shiness: f32,
        shadow_map: ?*Texture = null,
    },
    pbr: struct {},
    refract_mapping: struct {
        cubemap: *Texture,
        ratio: f32,
    },
    single_texture: *Texture,
    single_cubemap: *Texture,
};

/// material properties
data: Data,

/// create material
pub fn init(data: Data) Self {
    var self = Self{
        .data = data,
    };
    switch (self.data) {
        .phong => |mr| {
            assert(mr.diffuse_map.type == .texture_2d);
            assert(mr.specular_map.type == .texture_2d);
            assert(mr.shiness >= 0);
            if (mr.shadow_map) |tex| {
                assert(tex.type == .texture_2d);
            }
        },
        .pbr => {},
        .refract_mapping => |mr| {
            assert(mr.cubemap.type == .texture_cube_map);
            assert(mr.ratio >= 0);
        },
        .single_texture => |tex| {
            assert(tex.type == .texture_2d);
        },
        .single_cubemap => |tex| {
            assert(tex.type == .texture_cube_map);
        },
    }
    return self;
}

/// alloc texture unit, return next unused unit
pub fn allocTextureUnit(self: Self, start_unit: i32) i32 {
    var unit = start_unit;
    switch (self.data) {
        .phong => |mr| {
            mr.diffuse_map.bindToTextureUnit(Texture.TextureUnit.fromInt(unit));
            unit += 1;
            if (mr.specular_map != mr.diffuse_map) {
                mr.specular_map.bindToTextureUnit(Texture.TextureUnit.fromInt(unit));
                unit += 1;
            }
            if (mr.shadow_map) |tex| {
                tex.bindToTextureUnit(Texture.TextureUnit.fromInt(unit));
                unit += 1;
            }
        },
        .pbr => {},
        .refract_mapping => |mr| {
            mr.cubemap.bindToTextureUnit(Texture.TextureUnit.fromInt(unit));
            unit += 1;
        },
        .single_texture => |tex| {
            tex.bindToTextureUnit(Texture.TextureUnit.fromInt(unit));
            unit += 1;
        },
        .single_cubemap => |tex| {
            tex.bindToTextureUnit(Texture.TextureUnit.fromInt(unit));
            unit += 1;
        },
    }
    return unit;
}
