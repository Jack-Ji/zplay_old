const std = @import("std");
const sdl = @import("sdl");
const PhongRenderer = @import("PhongRenderer.zig");
const SimpleRenderer = @import("SimpleRenderer.zig");
const zp = @import("../lib.zig");
const alg = zp.alg;
const Vec3 = alg.Vec3;
const gl = zp.gl;
const Texture2D = zp.texture.Texture2D;
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
    single_color: Vec3,
};

/// material properties
data: MaterialData = undefined,

/// create a new material
pub fn init(data: MaterialData) Self {
    return .{
        .data = data,
    };
}

/// deallocate resources
pub fn deinit(self: *Self) void {
    switch (self.data) {
        .phong => |*m| {
            m.diffuse_map.deinit();
            m.specular_map.deinit();
        },
        .pbr => {
            // TODO delete pbr textures
        },
        .single_texture => |*t| {
            t.deinit();
        },
        .single_color => {},
    }
}
