const std = @import("std");
const Camera = @import("Camera.zig");
const Material = @import("Material.zig");
const Mesh = @import("Mesh.zig");
const zp = @import("../../zplay.zig");
const drawcall = zp.graphics.common.drawcall;
const VertexArray = zp.graphics.common.VertexArray;
const alg = zp.deps.alg;
const Vec3 = alg.Vec3;
const Mat4 = alg.Mat4;
const Renderer = @This();

// The type erased pointer to the renderer implementation
ptr: *c_void,
vtable: *const VTable,

pub const VTable = struct {
    /// begin using renderer
    beginFn: fn (ptr: *c_void) void,

    /// stop using renderer
    endFn: fn (ptr: *c_void) void,

    /// generic rendering
    renderFn: fn (
        ptr: *c_void,
        vertex_array: VertexArray,
        use_elements: bool,
        primitive: drawcall.PrimitiveType,
        offset: u32,
        count: u32,
        model: Mat4,
        projection: Mat4,
        camera: ?Camera,
        material: ?Material,
        instance_count: ?u32,
    ) anyerror!void,

    /// mesh rendering
    renderMeshFn: fn (
        ptr: *c_void,
        mesh: Mesh,
        model: Mat4,
        projection: Mat4,
        camera: ?Camera,
        material: ?Material,
        instance_count: ?u32,
    ) anyerror!void,
};

pub fn init(
    pointer: anytype,
    comptime beginFn: fn (ptr: @TypeOf(pointer)) void,
    comptime endFn: fn (ptr: @TypeOf(pointer)) void,
    comptime renderFn: fn (
        ptr: @TypeOf(pointer),
        vertex_array: VertexArray,
        use_elements: bool,
        primitive: drawcall.PrimitiveType,
        offset: u32,
        count: u32,
        model: Mat4,
        projection: Mat4,
        camera: ?Camera,
        material: ?Material,
        instance_count: ?u32,
    ) anyerror!void,
    comptime renderMeshFn: fn (
        ptr: @TypeOf(pointer),
        mesh: Mesh,
        model: Mat4,
        projection: Mat4,
        camera: ?Camera,
        material: ?Material,
        instance_count: ?u32,
    ) anyerror!void,
) Renderer {
    const Ptr = @TypeOf(pointer);
    const ptr_info = @typeInfo(Ptr);

    std.debug.assert(ptr_info == .Pointer); // Must be a pointer
    std.debug.assert(ptr_info.Pointer.size == .One); // Must be a single-item pointer

    const alignment = ptr_info.Pointer.alignment;

    const gen = struct {
        fn beginImpl(ptr: *c_void) void {
            const self = @ptrCast(Ptr, @alignCast(alignment, ptr));
            return @call(.{ .modifier = .always_inline }, beginFn, .{self});
        }
        fn endImpl(ptr: *c_void) void {
            const self = @ptrCast(Ptr, @alignCast(alignment, ptr));
            return @call(.{ .modifier = .always_inline }, endFn, .{self});
        }
        fn renderImpl(
            ptr: *c_void,
            vertex_array: VertexArray,
            use_elements: bool,
            primitive: drawcall.PrimitiveType,
            offset: u32,
            count: u32,
            model: Mat4,
            projection: Mat4,
            camera: ?Camera,
            material: ?Material,
            instance_count: ?u32,
        ) anyerror!void {
            const self = @ptrCast(Ptr, @alignCast(alignment, ptr));
            return @call(.{ .modifier = .always_inline }, renderFn, .{
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
                instance_count,
            });
        }

        fn renderMeshImpl(
            ptr: *c_void,
            mesh: Mesh,
            model: Mat4,
            projection: Mat4,
            camera: ?Camera,
            material: ?Material,
            instance_count: ?u32,
        ) anyerror!void {
            const self = @ptrCast(Ptr, @alignCast(alignment, ptr));
            return @call(.{ .modifier = .always_inline }, renderMeshFn, .{
                self,
                mesh,
                model,
                projection,
                camera,
                material,
                instance_count,
            });
        }

        const vtable = VTable{
            .beginFn = beginImpl,
            .endFn = endImpl,
            .renderFn = renderImpl,
            .renderMeshFn = renderMeshImpl,
        };
    };

    return .{
        .ptr = pointer,
        .vtable = &gen.vtable,
    };
}

pub fn begin(renderer: Renderer) void {
    renderer.vtable.beginFn(renderer.ptr);
}

pub fn end(renderer: Renderer) void {
    renderer.vtable.endFn(renderer.ptr);
}

pub fn render(
    renderer: Renderer,
    vertex_array: VertexArray,
    use_elements: bool,
    primitive: drawcall.PrimitiveType,
    offset: u32,
    count: u32,
    model: Mat4,
    projection: Mat4,
    camera: ?Camera,
    material: ?Material,
    instance_count: ?u32,
) anyerror!void {
    return renderer.vtable.renderFn(
        renderer.ptr,
        vertex_array,
        use_elements,
        primitive,
        offset,
        count,
        model,
        projection,
        camera,
        material,
        instance_count,
    );
}

/// render a mesh
pub fn renderMesh(
    renderer: Renderer,
    mesh: Mesh,
    model: Mat4,
    projection: Mat4,
    camera: ?Camera,
    material: ?Material,
    instance_count: ?u32,
) anyerror!void {
    return renderer.vtable.renderMeshFn(
        renderer.ptr,
        mesh,
        model,
        projection,
        camera,
        material,
        instance_count,
    );
}
