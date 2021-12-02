const std = @import("std");
const sdl = @import("sdl");
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

/// memory allocator
allocator: *std.mem.Allocator,

/// meshes
meshes: std.ArrayList(Mesh) = undefined,
transforms: std.ArrayList(Mat4) = undefined,
global_transform: Mat4 = Mat4.identity(),
mesh_materials: std.ArrayList(usize) = undefined,

/// materials
materials: std.ArrayList(Material) = undefined,

/// load gltf model file
pub fn fromGLTF(allocator: *std.mem.Allocator, gltf_path: [:0]const u8) !Self {
    var data = try cgltf.loadFile(gltf_path, null);
    defer cgltf.free(data);

    var model = .Self{
        .allocator = allocator,
        .meshes = std.ArrayList(Mesh).initCapacity(allocator, 1) catch unreachable,
        .transforms = std.ArrayList(Mat4).initCapacity(allocator, 1),
        .mesh_materials = std.ArrayList(usize).initCapacity(allocator, 1) catch unreachable,
        .materials = std.ArrayList(Material).initCapacity(allocator, 1) catch unreachable,
    };

    // load materials
    var i: usize = 0;
    while (i < data.materials_count) : (i += 1) {
        var material = data.materials[i];
        if (material.has_pbr_metallic_roughness) {
            // TODO load pbr material
            model.materials.append(Material.init(.{
                .single_color = Vec3.new(
                    material.pbr_metallic_roughness.base_color_factor[0],
                    material.pbr_metallic_roughness.base_color_factor[1],
                    material.pbr_metallic_roughness.base_color_factor[2],
                ),
            }));
        }
    }

    // load meshes
    if (data.nodes_count == 0) {
        std.debug.panic("can't find root node!");
    }
    var root = data.scene.nodes[0];
    if (root.has_scale) {
        model.global_transform = Mat4.fromScale(
            Vec3.new(
                root.scale[0],
                root.scale[1],
                root.scale[2],
            ),
        );
    }
    if (root.has_rotation) {
        model.global_transform = Quat.new(
            root.rotation[3],
            root.rotation[2],
            root.rotation[1],
            root.rotation[0],
        ).toMat4().mult(model.global_transform);
    }
    if (root.has_translation) {
        model.global_transform = model.global_transform.translate(
            root.translation[0],
            root.translation[1],
            root.translation[2],
        );
    }
    i = 0;
    while (i < root.children_count) : (i += 1) {
        var node = &root.children[i];

        //  determine transform matrix
        var transform = Mat4.identity();
        if (node.has_scale) {
            transform = Mat4.fromScale(
                Vec3.new(
                    node.scale[0],
                    node.scale[1],
                    node.scale[2],
                ),
            );
        }
        if (node.has_rotation) {
            transform = Quat.new(
                node.rotation[3],
                node.rotation[2],
                node.rotation[1],
                node.rotation[0],
            ).toMat4().mult(transform);
        }
        if (node.has_translation) {
            transform = transform.translate(
                node.translation[0],
                node.translation[1],
                node.translation[2],
            );
        }
        model.transforms.append(transform);

        // load vertex attributes
        var vertices = std.ArrayList(f32).init(allocator);
        var indices = std.ArrayList(u32).init(allocator);
        var j:usize = 0;
        while (j < node.mesh.primitives_count): (j += 1) {
            var primitive = &node.mesh.primitives[j];
        }

        // TODO determine material idx
        model.mesh_materials.append(0);
    }

    return model;
}

/// deallocate resources
pub fn deinit(self: *Self) void {
    for (self.meshes.items) |*m| {
        m.deinit();
    }
    self.meshes.deinit();
    self.transforms.deinit();
    self.mesh_materials.deinit();
    for (self.materials.items) |*m| {
        m.deinit();
    }
    self.materials.deinit();
}
