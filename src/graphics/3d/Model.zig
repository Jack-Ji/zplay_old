const std = @import("std");
const assert = std.debug.assert;
const Camera = @import("Camera.zig");
const Renderer = @import("Renderer.zig");
const Mesh = @import("Mesh.zig");
const Material = @import("Material.zig");
const zp = @import("../../zplay.zig");
const Texture2D = zp.graphics.texture.Texture2D;
const gltf = zp.deps.gltf;
const alg = zp.deps.alg;
const Vec2 = alg.Vec2;
const Vec3 = alg.Vec3;
const Vec4 = alg.Vec4;
const Mat4 = alg.Mat4;
const Quat = alg.Quat;
const Self = @This();

pub const Error = error{
    NoRootNode,
};

/// materials
materials: std.ArrayList(Material) = undefined,

/// meshes
meshes: std.ArrayList(Mesh) = undefined,
transforms: std.ArrayList(Mat4) = undefined,
material_indices: std.ArrayList(u32) = undefined,

/// generated textures
generated_textures: std.ArrayList(Texture2D) = undefined,

/// loaded textures
loaded_textures: std.ArrayList(Texture2D) = undefined,

/// load gltf model file 
/// WARNING: Model won't deallocate default texture, 
///          cause it might be used somewhere else, 
///          user's code knows better what to do with it.
pub fn fromGLTF(allocator: std.mem.Allocator, filename: [:0]const u8, merge_meshes: bool, default_textre: ?Texture2D) !Self {
    var data: *gltf.Data = try gltf.loadFile(filename, null);
    defer gltf.free(data);

    var self = Self{
        .materials = std.ArrayList(Material).initCapacity(allocator, 1) catch unreachable,
        .meshes = std.ArrayList(Mesh).initCapacity(allocator, 1) catch unreachable,
        .transforms = std.ArrayList(Mat4).initCapacity(allocator, 1) catch unreachable,
        .material_indices = std.ArrayList(u32).initCapacity(allocator, 1) catch unreachable,
        .generated_textures = std.ArrayList(Texture2D).initCapacity(allocator, 1) catch unreachable,
        .loaded_textures = std.ArrayList(Texture2D).initCapacity(allocator, 1) catch unreachable,
    };

    // load vertex attributes
    assert(data.scenes_count > 0);
    assert(data.scene.*.nodes_count > 0);
    var root_node: ?*gltf.Node = blk: {
        var i: u32 = 0;
        while (i < data.scene.*.nodes_count) : (i += 1) {
            const node = @ptrCast(*gltf.Node, data.scene.*.nodes[i]);
            if (node.mesh != null) {
                break :blk node;
            }
        }

        // return first node by default
        break :blk @ptrCast(*gltf.Node, data.scene.*.nodes[0]);
    };
    if (root_node == null) {
        return error.NoRootNode;
    }
    self.parseNode(
        allocator,
        data,
        root_node.?,
        Mat4.identity(),
        merge_meshes,
    );

    // load images
    var i: u32 = 0;
    while (i < data.images_count) : (i += 1) {
        var image = @ptrCast(*gltf.Image, &data.images[i]);
        if (image.buffer_view != null) {
            var buffer_data = @ptrCast([*]const u8, image.buffer_view.*.buffer.*.data.?);
            var image_data = buffer_data + image.buffer_view.*.offset;
            self.loaded_textures.append(try Texture2D.fromFileData(
                allocator,
                image_data[0..image.buffer_view.*.size],
                false,
                .{},
            )) catch unreachable;
        } else {
            var buf: [64]u8 = undefined;
            const dirname = std.fs.path.dirname(filename);
            const image_path = std.fmt.bufPrintZ(
                &buf,
                "{s}{s}{s}",
                .{ dirname, std.fs.path.sep_str, image.uri },
            ) catch unreachable;
            self.loaded_textures.append(try Texture2D.fromFilePath(
                allocator,
                image_path,
                false,
                .{},
            )) catch unreachable;
        }
    }

    // default pixel data
    if (default_textre == null) {
        self.generated_textures.append(try Texture2D.fromPixelData(
            allocator,
            &.{ 255, 255, 255, 255 },
            4,
            1,
            1,
            .{},
        )) catch unreachable;
    }

    // load materials
    var default_tex = if (default_textre) |tex| tex else self.generated_textures.items[0];
    self.materials.append(Material.init(.{
        .phong = .{
            .diffuse_map = default_tex,
            .specular_map = default_tex,
            .shiness = 32,
        },
    })) catch unreachable;
    i = 0;
    MATERIAL_LOOP: while (i < data.materials_count) : (i += 1) {
        var material = &data.materials[i];
        assert(material.has_pbr_metallic_roughness > 0);

        // TODO PBR materials
        const pbrm = material.pbr_metallic_roughness;
        const base_color_texture = pbrm.base_color_texture;

        var image_idx: u32 = 0;
        while (image_idx < data.images_count) : (image_idx += 1) {
            const image = &data.images[image_idx];
            if (base_color_texture.texture != null and
                base_color_texture.texture.*.image.*.uri == image.uri)
            {
                self.materials.append(Material.init(.{
                    .single_texture = self.loaded_textures.items[image_idx],
                })) catch unreachable;
                continue :MATERIAL_LOOP;
            }
        }

        const base_color = pbrm.base_color_factor;
        self.generated_textures.append(try Texture2D.fromPixelData(
            allocator,
            &.{
                @floatToInt(u8, base_color[0] * 255),
                @floatToInt(u8, base_color[1] * 255),
                @floatToInt(u8, base_color[2] * 255),
                @floatToInt(u8, base_color[3] * 255),
            },
            4,
            1,
            1,
            .{},
        )) catch unreachable;
        self.materials.append(Material.init(.{
            .single_texture = self.generated_textures.items[self.generated_textures.items.len - 1],
        })) catch unreachable;
    }

    // TODO load skins
    // TODO load animations

    // setup meshes' vertex buffer
    for (self.meshes.items) |m| {
        m.setup();
    }
    return self;
}

/// deallocate resources
pub fn deinit(self: Self) void {
    self.materials.deinit();
    for (self.meshes.items) |m| {
        m.deinit();
    }
    self.meshes.deinit();
    self.transforms.deinit();
    self.material_indices.deinit();
    for (self.generated_textures.items) |t| {
        t.deinit();
    }
    self.generated_textures.deinit();
    for (self.loaded_textures.items) |t| {
        t.deinit();
    }
    self.loaded_textures.deinit();
}

fn parseNode(
    self: *Self,
    allocator: std.mem.Allocator,
    data: *gltf.Data,
    node: *gltf.Node,
    parent_transform: Mat4,
    merge_meshes: bool,
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
            var quat = Quat.new(
                node.rotation[3],
                node.rotation[0],
                node.rotation[1],
                node.rotation[2],
            );
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
            const primitive = @ptrCast(*gltf.Primitive, &node.mesh.*.primitives[i]);
            const primtype = gltf.getPrimitiveType(primitive);

            // get material index
            const material_index = blk: {
                var index: u32 = 0;
                while (index < data.materials_count) : (index += 1) {
                    const material = @ptrCast([*c]gltf.Material, &data.materials[index]);
                    if (material == primitive.material) {
                        break :blk index + 1;
                    }
                }
                break :blk 0;
            };

            var mergable_mesh: ?*Mesh = null;
            if (merge_meshes) {
                // TODO: there maybe more conditions
                // find mergable mesh, following conditions must be met:
                // 1. same primitive type
                // 2. same transform matrix
                // 3. same material
                mergable_mesh = for (self.meshes.items) |*m, idx| {
                    if (m.primitive_type == primtype and
                        self.transforms.items[idx].eql(transform) and
                        self.material_indices.items[idx] == material_index)
                    {
                        break m;
                    }
                } else null;
            }

            if (mergable_mesh) |m| {
                // merge into existing mesh
                gltf.appendMeshPrimitive(
                    primitive,
                    &m.indices.?,
                    &m.positions,
                    &m.normals.?,
                    &m.texcoords.?,
                    null,
                );
            } else {
                // allocate new mesh
                var positions = std.ArrayList(Vec3).init(allocator);
                var indices = std.ArrayList(u32).init(allocator);
                var normals = std.ArrayList(Vec3).init(allocator);
                var texcoords = std.ArrayList(Vec2).init(allocator);
                gltf.appendMeshPrimitive(
                    primitive,
                    &indices,
                    &positions,
                    &normals,
                    &texcoords,
                    null,
                );
                self.meshes.append(Mesh.fromArrays(
                    allocator,
                    primtype,
                    positions,
                    indices,
                    normals,
                    texcoords,
                    null,
                    null,
                    true,
                )) catch unreachable;
                self.transforms.append(transform) catch unreachable;
                self.material_indices.append(material_index) catch unreachable;
            }
        }
    }

    // parse node's children
    var i: u32 = 0;
    while (i < node.children_count) : (i += 1) {
        self.parseNode(
            allocator,
            data,
            @ptrCast(*gltf.Node, node.children[i]),
            transform,
            merge_meshes,
        );
    }
}

/// draw model using renderer
pub fn render(
    self: Self,
    rd: Renderer,
    transform: Mat4,
    projection: Mat4,
    camera: ?Camera,
    material: ?Material,
) !void {
    for (self.meshes.items) |m, i| {
        try m.render(
            rd,
            transform.mult(self.transforms.items[i]),
            projection,
            camera,
            if (material) |mr| mr else self.materials.items[self.material_indices.items[i]],
        );
    }
}

/// instanced draw model using renderer
pub fn renderInstanced(
    self: Self,
    rd: Renderer,
    mesh_transforms: []Renderer.InstanceTransformArray,
    projection: Mat4,
    camera: ?Camera,
    material: ?Material,
    instance_count: ?u32,
) !void {
    assert(mesh_transforms.len == self.meshes.items.len);
    for (self.meshes.items) |m, i| {
        try m.renderInstanced(
            rd,
            mesh_transforms[i],
            projection,
            camera,
            if (material) |mr| mr else self.materials.items[self.material_indices.items[i]],
            instance_count,
        );
    }
}
