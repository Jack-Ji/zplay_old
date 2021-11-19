const std = @import("std");
const sdl = @import("sdl");
const Material = @import("Material.zig");
const Mesh = @import("Mesh.zig");
const zp = @import("../lib.zig");
const alg = zp.alg;
const cgltf = zp.cgltf;
const Self = @This();

/// gltf data being used
gltf_data: *cgltf.cgltf_data = undefined,

/// meshes
meshes: std.ArrayList(Mesh) = undefined,

/// allocate instance
pub fn init(allocator: *std.mem.Allocator, gltf_path: [:0]const u8) !Self {
    var data = try cgltf.parseFile(gltf_path, null);

    var i: usize = 0;
    while (i < data.meshes_count) : (i+=1){
    var mesh = data.meshes[i];
    }
}

/// deallocate resources
pub fn deinit(self: *Self) void {
    for (self.meshes.items) |*m| {
        m.deinit();
    }
    self.meshes.deinit();
    cgltf.free(self.gltf_data);
}
