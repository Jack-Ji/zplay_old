const std = @import("std");
const sdl = @import("sdl");
const Scene = @import("Scene.zig");
const Mesh = @import("Mesh.zig");
const Material = @import("Material.zig");
const zp = @import("../lib.zig");
const Texture2D = zp.texture.Texture2D;
const alg = zp.alg;
const Mat4 = alg.Mat4;
const Quat = alg.Quat;
const Vec3 = alg.Vec3;
const cgltf = zp.cgltf;
const Self = @This();

/// meshes
meshes: std.ArrayList(Mesh) = undefined,
transforms: std.ArrayList(Mat4) = undefined,
material_indices: std.ArrayList(usize) = undefined,

/// load gltf model file
pub fn fromGLTF(allocator: std.mem.Allocator, data: *cgltf.cgltf_data, root_node: *cgltf.cgltf_node,) !Self {
    var self = .Self{
        .meshes = std.ArrayList(Mesh).initCapacity(allocator, 1) catch unreachable,
        .transforms = std.ArrayList(Mat4).initCapacity(allocator, 1),
        .material_indices= std.ArrayList(usize).initCapacity(allocator, 1) catch unreachable,
    };

    var i:usize = 0;
    while (i < root_node.children_count) : (i += 1) {
        var node = &root_node.children[i];

        // load vertex attributes
        var vertices = std.ArrayList(f32).init(allocator);
        var indices = std.ArrayList(u32).init(allocator);
        var j:usize = 0;
        while (j < node.mesh.primitives_count): (j += 1) {
            //var primitive = &node.mesh.primitives[j];
            var attr_types = [_]?Mesh.VertexAttribute{null} ** Mesh.MAX_ATTRIB_NUM;

            var mesh = Mesh.init(allocator, vertices, indices, attr_types);
            self.meshes.append(mesh);
        }

        // TODO determine material idx
        self.material_indices.append(0);
    }

    return self;
}

/// deallocate resources
pub fn deinit(self: *Self) void {
    for (self.meshes.items) |*m| {
        m.deinit();
    }
    self.meshes.deinit();
    self.transforms.deinit();
    self.material_indices.deinit();
}

