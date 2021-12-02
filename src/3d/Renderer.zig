const std = @import("std");
const Camera = @import("Camera.zig");
const Material = @import("Material.zig");
const Mesh = @import("Mesh.zig");
const zp = @import("../lib.zig");
const gl = zp.gl;
const alg = zp.alg;
const Vec3 = alg.Vec3;
const Mat4 = alg.Mat4;
const Texture2D = zp.texture.Texture2D;
const Self = @This();

/// begin using renderer
beginFn: fn (self: *Self) void,

/// stop using renderer
endFn: fn (self: *Self) void,

/// do rendering
renderFn: fn (
    self: *Self,
    vertex_array: gl.VertexArray,
    use_elements: bool,
    primitive: gl.util.PrimitiveType,
    offset: usize,
    count: usize,
    model: Mat4,
    projection: Mat4,
    camera: ?Camera,
    material: ?Material,
) anyerror!void,

pub fn begin(self: *Self) void {
    self.beginFn(self);
}

pub fn end(self: *Self) void {
    self.endFn(self);
}

pub fn render(
    self: *Self,
    vertex_array: gl.VertexArray,
    use_elements: bool,
    primitive: gl.util.PrimitiveType,
    offset: usize,
    count: usize,
    model: Mat4,
    projection: Mat4,
    camera: ?Camera,
    material: ?Material,
) anyerror!void {
    return self.renderFn(
        self,
        vertex_array,
        use_elements,
        primitive,
        offset,
        count,
        model,
        projection,
        camera,
        material,
    );
}

/// render a mesh
pub fn renderMesh(
    self: *Self,
    mesh: Mesh,
    model: Mat4,
    projection: Mat4,
    camera: ?Camera,
    material: ?Material,
) !void {
    if (mesh.vertex_indices.items.len > 0) {
        try self.render(
            mesh.vertex_array,
            true,
            .triangles,
            0,
            mesh.vertex_indices.items.len,
            model,
            projection,
            camera,
            material,
        );
    } else {
        try self.render(
            mesh.vertex_array,
            false,
            .triangles,
            0,
            mesh.vertex_num,
            model,
            projection,
            camera,
            material,
        );
    }
}
