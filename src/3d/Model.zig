const std = @import("std");
const sdl = @import("sdl");
const Mesh = @import("Mesh.zig");
const Material = @import("Material.zig");
const zp = @import("../lib.zig");
const Texture2D = zp.texture.Texture2D;
const alg = zp.alg;
const cgltf = zp.cgltf;
const Self = @This();

/// memory allocator
allocator: *std.mem.Allocator,

/// meshes
meshes: std.ArrayList(Mesh) = undefined,
mesh_materials: std.ArrayList(usize) = undefined,

/// materials
materials: std.ArrayList(Material) = undefined,

/// allocate instance
pub fn init(allocator: *std.mem.Allocator, gltf_path: [:0]const u8) !Self {
    var data = try cgltf.loadFile(gltf_path, null);
    defer cgltf.free(data);

    var model = .Self{
        .allocator = allocator,
        .meshes = std.ArrayList(Mesh).initCapacity(allocator, 1) catch unreachable,
        .mesh_materials = std.ArrayList(usize).initCapacity(allocator, 1) catch unreachable,
        .materials = std.ArrayList(Material).initCapacity(allocator, 1) catch unreachable,
    };

    // allocate materials
    var i: usize = 0;
    while (i < data.materials_count) : (i += 1) {
        //var material = data.materials[i];
    }

    // allocate meshes
    i = 0;
    while (i < data.meshes_count) : (i += 1) {
        //var mesh = data.meshes[i];
    }

    return model;
}

/// deallocate resources
pub fn deinit(self: *Self) void {
    for (self.meshes.items) |*m| {
        m.deinit();
    }
    self.meshes.deinit();
    self.mesh_materials.deinit();
    for (self.materials.items) |*m| {
        m.deinit();
    }
    self.materials.deinit();
}
