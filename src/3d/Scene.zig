const std = @import("std");
const sdl = @import("sdl");
const Model = @import("Model.zig");
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
models: std.ArrayList(Model) = undefined,
transforms: std.ArrayList(Mat4) = undefined,

/// materials
materials: std.ArrayList(Material) = undefined,

pub fn fromGLTF(allocator: std.mem.Allocator, gltf_path: [:0]const u8) !Self {
    var data = try cgltf.loadFile(gltf_path, null);
    defer cgltf.free(data);

    var self = .Self{
        .models = std.ArrayList(Model).initCapacity(allocator, 1) catch unreachable,
        .transforms = std.ArrayList(Mat4).initCapacity(allocator, 1),
        .materials = std.ArrayList(Material).initCapacity(allocator, 1) catch unreachable,
    };

    // load materials
    var i: usize = 0;
    while (i < data.materials_count) : (i += 1) {
        var material = data.materials[i];
        if (material.has_pbr_metallic_roughness) {
            // TODO load pbr material
            self.materials.append(Material.init(.{
                .single_color = Vec3.new(
                    material.pbr_metallic_roughness.base_color_factor[0],
                    material.pbr_metallic_roughness.base_color_factor[1],
                    material.pbr_metallic_roughness.base_color_factor[2],
                ),
            }));
        }
    }

    // load scene
    if (data.scenes_count == 0) {
        std.debug.panic("can't find scene!");
    }
    i = 0;
    while (i < data.scene.nodes_count) : (i += 1) {
        var node = data.scene.nodes[i];

        // create model
        var model = try Model.fromGLTF(&self, data, node);
        self.models.append(model);

        // model's transform matrix
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
        self.transforms.append(transform);
    }

    return self;
}

/// deallocate resources
pub fn deinit(self: *Self) void {
    for (self.models.items) |*m| {
        m.deinit();
    }
    self.transforms.deinit();
    for (self.materials.items) |*m| {
        m.deinit();
    }
    self.materials.deinit();
}
