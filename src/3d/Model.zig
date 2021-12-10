const std = @import("std");
const assert = std.debug.assert;
const sdl = @import("sdl");
const Camera = @import("Camera.zig");
const Renderer = @import("Renderer.zig");
const Mesh = @import("Mesh.zig");
const Material = @import("Material.zig");
const zp = @import("../lib.zig");
const Texture2D = zp.texture.Texture2D;
const alg = zp.alg;
const Vec2 = alg.Vec2;
const Vec3 = alg.Vec3;
const Vec4 = alg.Vec4;
const Mat4 = alg.Mat4;
const Quat = alg.Quat;
const cgltf = zp.cgltf;
const Self = @This();

/// materials
materials: std.ArrayList(Material) = undefined,

/// meshes
meshes: std.ArrayList(Mesh) = undefined,
transforms: std.ArrayList(Mat4) = undefined,
material_indices: std.ArrayList(usize) = undefined,

/// load gltf model file
pub fn fromGLTF(allocator: std.mem.Allocator, filename: [:0]const u8) Self {
    var data: *cgltf.Data = cgltf.loadFile(filename, null) catch unreachable;
    defer cgltf.free(data);

    var self = Self{
        .materials = std.ArrayList(Material).initCapacity(allocator, 1) catch unreachable,
        .meshes = std.ArrayList(Mesh).initCapacity(allocator, 1) catch unreachable,
        .transforms = std.ArrayList(Mat4).initCapacity(allocator, 1) catch unreachable,
        .material_indices = std.ArrayList(usize).initCapacity(allocator, 1) catch unreachable,
    };

    // load vertex attributes
    assert(data.scenes_count > 0);
    assert(data.scene.*.nodes_count > 0);
    var root_node = @ptrCast(*cgltf.Node, data.scene.*.nodes[0]);
    self.parseNode(allocator, data, root_node, Mat4.identity());

    // determine material idx
    var i: u32 = 0;
    while (i < data.materials_count) : (i += 1) {
        var material = &data.materials[i];
        if (material.has_pbr_metallic_roughness > 0) {
            // TODO PBR materials
            const base_color = material.pbr_metallic_roughness.base_color_factor;
            self.materials.append(Material.init(.{
                .single_color = Vec4.fromSlice(&base_color),
            })) catch unreachable;
        } else {
            // use green color by default
            self.materials.append(Material.init(.{
                .single_color = Vec4.new(0, 1, 0, 1),
            })) catch unreachable;
        }
    }

    return self;
}

/// deallocate resources
pub fn deinit(self: *Self) void {
    for (self.materials) |*m| {
        m.deinit();
    }
    self.materials.deinit();
    for (self.meshes.items) |*m| {
        m.deinit();
    }
    self.meshes.deinit();
    self.transforms.deinit();
    self.material_indices.deinit();
}

fn parseNode(
    self: *Self,
    allocator: std.mem.Allocator,
    data: *cgltf.Data,
    node: *cgltf.Node,
    parent_transform: Mat4,
) void {
    // load transform matrix
    var transform = Mat4.identity();
    if (node.has_matrix > 0) {
        transform = Mat4.fromSlice(&node.matrix).mult(transform);
    } else {
        if (node.has_scale > 0) {
            transform = Mat4.fromScale(Vec3.fromSlice(&node.scale)).mult(transform);
        }
        if (node.has_rotation > 0) {
            var quat = Quat.new(node.rotation[3], node.rotation[0], node.rotation[1], node.rotation[2]);
            transform = quat.toMat4().mult(transform);
        }
        if (node.has_translation > 0) {
            transform = Mat4.fromTranslate(Vec3.fromSlice(&node.translation)).mult(transform);
        }
    }
    transform = parent_transform.mult(transform);

    // load meshes
    if (node.mesh != null) {
        var i: u32 = 0;
        while (i < node.mesh.*.primitives_count) : (i += 1) {
            const primitive = @ptrCast(*cgltf.Primitive, &node.mesh.*.primitives[i]);
            var positions = std.ArrayList(Vec3).init(allocator);
            var indices = std.ArrayList(u32).init(allocator);
            var normals = std.ArrayList(Vec3).init(allocator);
            var texcoords = std.ArrayList(Vec2).init(allocator);
            cgltf.appendMeshPrimitive(
                primitive,
                &indices,
                &positions,
                &normals,
                &texcoords,
                null,
            );
            self.meshes.append(Mesh.fromArrayLists(
                cgltf.getPrimitiveType(primitive),
                positions,
                indices,
                normals,
                texcoords,
                null,
                null,
                true,
            )) catch unreachable;

            // add transform matrix
            self.transforms.append(transform) catch unreachable;

            // add material index
            i = 0;
            self.material_indices.append(
                while (i < data.materials_count) : (i += 1) {
                    const material = @ptrCast([*c]cgltf.Material, &data.materials[i]);
                    if (material == primitive.material) {
                        break i;
                    }
                } else 0,
            ) catch unreachable;
        }
    }

    // parse node's children
    var i: u32 = 0;
    while (i < node.children_count) : (i += 1) {
        self.parseNode(
            allocator,
            data,
            @ptrCast(*cgltf.Node, node.children[i]),
            transform,
        );
    }
}

/// draw model using renderer
pub fn render(
    self: Self,
    renderer: Renderer,
    model: Mat4,
    projection: Mat4,
    camera: ?Camera,
    instance_count: ?usize,
) !void {
    for (self.meshes.items) |m, i| {
        try renderer.renderMesh(
            m,
            model.mult(self.transforms.items[i]),
            projection,
            camera,
            self.materials.items[self.material_indices.items[i]],
            instance_count,
        );
    }
}
