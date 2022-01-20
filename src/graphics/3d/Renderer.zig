const std = @import("std");
const assert = std.debug.assert;
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

/// The type erased pointer to the renderer implementation
ptr: *anyopaque,
vtable: *const VTable,

/// renderer's status
pub const Status = enum {
    not_ready,
    ready_to_draw,
    ready_to_draw_instanced,
};

pub const VTable = struct {
    /// begin using renderer
    beginFn: fn (ptr: *anyopaque, instanced_draw: bool) void,

    /// stop using renderer
    endFn: fn (ptr: *anyopaque) void,

    /// write instanced transform matrices, which is used when doing instanced drawing
    updateInstanceTransformsFn: fn (
        ptr: *anyopaque,
        va: VertexArray,
        transforms: []Mat4,
    ) anyerror!void,

    /// generic rendering
    /// param @transforms is ignored when doing instanced drawing
    renderFn: fn (
        ptr: *anyopaque,
        vertex_array: VertexArray,
        use_elements: bool,
        primitive: drawcall.PrimitiveType,
        offset: u32,
        count: u32,
        transforms: ?[]Mat4,
        projection: ?Mat4,
        camera: ?Camera,
        material: ?Material,
        instance_count: ?u32,
    ) anyerror!void,

    /// mesh rendering
    /// param @transforms is ignored when doing instanced drawing
    renderMeshFn: fn (
        ptr: *anyopaque,
        mesh: Mesh,
        transforms: ?[]Mat4,
        projection: ?Mat4,
        camera: ?Camera,
        material: ?Material,
        instance_count: ?u32,
    ) anyerror!void,
};

pub fn init(
    pointer: anytype,
    comptime beginFn: fn (ptr: @TypeOf(pointer), instanced_draw: bool) void,
    comptime endFn: fn (ptr: @TypeOf(pointer)) void,
    comptime updateInstanceTransformsFn: fn (
        ptr: @TypeOf(pointer),
        va: VertexArray,
        transforms: []Mat4,
    ) anyerror!void,
    comptime renderFn: fn (
        ptr: @TypeOf(pointer),
        vertex_array: VertexArray,
        use_elements: bool,
        primitive: drawcall.PrimitiveType,
        offset: u32,
        count: u32,
        transforms: ?[]Mat4,
        projection: ?Mat4,
        camera: ?Camera,
        material: ?Material,
        instance_count: ?u32,
    ) anyerror!void,
    comptime renderMeshFn: fn (
        ptr: @TypeOf(pointer),
        mesh: Mesh,
        transforms: ?[]Mat4,
        projection: ?Mat4,
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
        fn beginImpl(ptr: *anyopaque, instanced_draw: bool) void {
            const self = @ptrCast(Ptr, @alignCast(alignment, ptr));
            return @call(.{ .modifier = .always_inline }, beginFn, .{ self, instanced_draw });
        }

        fn endImpl(ptr: *anyopaque) void {
            const self = @ptrCast(Ptr, @alignCast(alignment, ptr));
            return @call(.{ .modifier = .always_inline }, endFn, .{self});
        }

        fn updateInstanceTransformsImpl(ptr: *anyopaque, va: VertexArray, transforms: []Mat4) anyerror!void {
            const self = @ptrCast(Ptr, @alignCast(alignment, ptr));
            return @call(
                .{ .modifier = .always_inline },
                updateInstanceTransformsFn,
                .{
                    self,
                    va,
                    transforms,
                },
            );
        }

        fn renderImpl(
            ptr: *anyopaque,
            vertex_array: VertexArray,
            use_elements: bool,
            primitive: drawcall.PrimitiveType,
            offset: u32,
            count: u32,
            transforms: ?[]Mat4,
            projection: ?Mat4,
            camera: ?Camera,
            material: ?Material,
            instance_count: ?u32,
        ) anyerror!void {
            const self = @ptrCast(Ptr, @alignCast(alignment, ptr));
            return @call(
                .{ .modifier = .always_inline },
                renderFn,
                .{
                    self,
                    vertex_array,
                    use_elements,
                    primitive,
                    offset,
                    count,
                    transforms,
                    projection,
                    camera,
                    material,
                    instance_count,
                },
            );
        }

        fn renderMeshImpl(
            ptr: *anyopaque,
            mesh: Mesh,
            transforms: ?[]Mat4,
            projection: ?Mat4,
            camera: ?Camera,
            material: ?Material,
            instance_count: ?u32,
        ) anyerror!void {
            const self = @ptrCast(Ptr, @alignCast(alignment, ptr));
            return @call(
                .{ .modifier = .always_inline },
                renderMeshFn,
                .{
                    self,
                    mesh,
                    transforms,
                    projection,
                    camera,
                    material,
                    instance_count,
                },
            );
        }

        const vtable = VTable{
            .beginFn = beginImpl,
            .endFn = endImpl,
            .updateInstanceTransformsFn = updateInstanceTransformsImpl,
            .renderFn = renderImpl,
            .renderMeshFn = renderMeshImpl,
        };
    };

    return .{
        .ptr = pointer,
        .vtable = &gen.vtable,
    };
}

pub fn begin(rd: Renderer, instanced_draw: bool) void {
    rd.vtable.beginFn(rd.ptr, instanced_draw);
}

pub fn end(rd: Renderer) void {
    rd.vtable.endFn(rd.ptr);
}

pub fn updateInstanceTransforms(rd: Renderer, va: VertexArray, transforms: []Mat4) anyerror!void {
    return rd.vtable.updateInstanceTransformsFn(rd.ptr, va, transforms);
}

pub fn render(
    rd: Renderer,
    vertex_array: VertexArray,
    use_elements: bool,
    primitive: drawcall.PrimitiveType,
    offset: u32,
    count: u32,
    transforms: ?[]Mat4,
    projection: ?Mat4,
    camera: ?Camera,
    material: ?Material,
    instance_count: ?u32,
) anyerror!void {
    assert((transforms == null and instance_count != null) or
        (transforms != null and instance_count == null));
    return rd.vtable.renderFn(
        rd.ptr,
        vertex_array,
        use_elements,
        primitive,
        offset,
        count,
        transforms,
        projection,
        camera,
        material,
        instance_count,
    );
}

pub fn renderMesh(
    rd: Renderer,
    mesh: Mesh,
    transforms: ?[]Mat4,
    projection: ?Mat4,
    camera: ?Camera,
    material: ?Material,
    instance_count: ?u32,
) anyerror!void {
    assert((transforms == null and instance_count != null) or
        (transforms != null and instance_count == null));
    return rd.vtable.renderMeshFn(
        rd.ptr,
        mesh,
        transforms,
        projection,
        camera,
        material,
        instance_count,
    );
}
