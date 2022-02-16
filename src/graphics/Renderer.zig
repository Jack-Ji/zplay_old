const std = @import("std");
const assert = std.debug.assert;
const Camera = @import("Camera.zig");
const Material = @import("Material.zig");
const Mesh = @import("Mesh.zig");
const zp = @import("../zplay.zig");
const drawcall = zp.graphics.gpu.drawcall;
const VertexArray = zp.graphics.gpu.VertexArray;
const Buffer = zp.graphics.gpu.Buffer;
const alg = zp.deps.alg;
const Vec3 = alg.Vec3;
const Mat4 = alg.Mat4;
const Renderer = @This();

/// global pointer to current activated current_renderer
var current_renderer: ?*anyopaque = null;

/// The type erased pointer to Renderer implementation
ptr: *anyopaque,
vtable: *const VTable,

/// current_renderer's status
pub const Status = enum {
    not_ready,
    ready_to_draw,
    ready_to_draw_instanced,
};

/// current_renderer's vertex attribute locations
/// NOTE: renderer's vertex shader should follow this 
/// convention if its purpose is rendering Model/Mesh objects.
pub const ATTRIB_LOCATION_POS = 0;
pub const ATTRIB_LOCATION_COLOR = 1;
pub const ATTRIB_LOCATION_NORMAL = 2;
pub const ATTRIB_LOCATION_TANGENT = 3;
pub const ATTRIB_LOCATION_TEXTURE1 = 4;
pub const ATTRIB_LOCATION_TEXTURE2 = 5;
pub const ATTRIB_LOCATION_TEXTURE3 = 6;
pub const ATTRIB_LOCATION_INSTANCE_TRANSFORM = 10;

/// vbo specially managed for instanced rendering
pub const InstanceTransformArray = struct {
    const Self = @This();

    /// vbo for instance transform matrices
    buf: *Buffer,

    /// number of instances
    count: u32,

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .buf = Buffer.init(allocator),
            .count = 0,
        };
    }

    pub fn deinit(self: Self) void {
        self.buf.deinit();
    }

    /// upload transform data
    pub fn updateTransforms(self: *Self, transforms: []Mat4) !void {
        var total_size: u32 = @intCast(u32, @sizeOf(Mat4) * transforms.len);
        if (self.buf.size < total_size) {
            self.buf.allocData(total_size, .static_draw);
        }
        self.buf.updateData(0, Mat4, transforms);
        self.count = @intCast(u32, transforms.len);
    }

    /// enable vertex attributes
    /// NOTE: VertexArray should have been activated!
    pub fn enableAttributes(self: Self) void {
        self.buf.setAttribute(
            ATTRIB_LOCATION_INSTANCE_TRANSFORM,
            4,
            f32,
            false,
            @sizeOf(Mat4),
            0,
            1,
        );
        self.buf.setAttribute(
            ATTRIB_LOCATION_INSTANCE_TRANSFORM + 1,
            4,
            f32,
            false,
            @sizeOf(Mat4),
            4 * @sizeOf(f32),
            1,
        );
        self.buf.setAttribute(
            ATTRIB_LOCATION_INSTANCE_TRANSFORM + 2,
            4,
            f32,
            false,
            @sizeOf(Mat4),
            8 * @sizeOf(f32),
            1,
        );
        self.buf.setAttribute(
            ATTRIB_LOCATION_INSTANCE_TRANSFORM + 3,
            4,
            f32,
            false,
            @sizeOf(Mat4),
            12 * @sizeOf(f32),
            1,
        );
    }
};

const VTable = struct {
    /// begin using current_renderer
    beginFn: fn (ptr: *anyopaque, instanced_draw: bool) void,

    /// stop using current_renderer
    endFn: fn (ptr: *anyopaque) void,

    /// get supported vertex attributes' locations, instance transforms not included
    getVertexAttribsFn: fn (ptr: *anyopaque) []const u32,

    /// generic rendering
    renderFn: fn (
        ptr: *anyopaque,
        vertex_array: VertexArray,
        use_elements: bool,
        primitive: drawcall.PrimitiveType,
        offset: u32,
        count: u32,
        transform: Mat4,
        projection: ?Mat4,
        camera: ?Camera,
        material: ?Material,
    ) anyerror!void,

    /// instanced generic rendering
    renderInstancedFn: fn (
        ptr: *anyopaque,
        vertex_array: VertexArray,
        use_elements: bool,
        primitive: drawcall.PrimitiveType,
        offset: u32,
        count: u32,
        transforms: InstanceTransformArray,
        projection: ?Mat4,
        camera: ?Camera,
        material: ?Material,
        instance_count: u32,
    ) anyerror!void,
};

pub fn init(
    pointer: anytype,
    comptime beginFn: fn (ptr: @TypeOf(pointer), instanced_draw: bool) void,
    comptime endFn: fn (ptr: @TypeOf(pointer)) void,
    comptime getVertexAttribsFn: fn (ptr: @TypeOf(pointer)) []const u32,
    comptime renderFn: fn (
        ptr: @TypeOf(pointer),
        vertex_array: VertexArray,
        use_elements: bool,
        primitive: drawcall.PrimitiveType,
        offset: u32,
        count: u32,
        transform: Mat4,
        projection: ?Mat4,
        camera: ?Camera,
        material: ?Material,
    ) anyerror!void,
    comptime renderInstancedFn: fn (
        ptr: @TypeOf(pointer),
        vertex_array: VertexArray,
        use_elements: bool,
        primitive: drawcall.PrimitiveType,
        offset: u32,
        count: u32,
        transforms: InstanceTransformArray,
        projection: ?Mat4,
        camera: ?Camera,
        material: ?Material,
        instance_count: u32,
    ) anyerror!void,
) Renderer {
    const Ptr = @TypeOf(pointer);
    const ptr_info = @typeInfo(Ptr);

    assert(ptr_info == .Pointer); // must be a pointer
    assert(ptr_info.Pointer.size == .One); // must be a single-item pointer

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

        fn getVertexAttribsImpl(ptr: *anyopaque) []const u32 {
            const self = @ptrCast(Ptr, @alignCast(alignment, ptr));
            return @call(.{ .modifier = .always_inline }, getVertexAttribsFn, .{self});
        }

        fn renderImpl(
            ptr: *anyopaque,
            vertex_array: VertexArray,
            use_elements: bool,
            primitive: drawcall.PrimitiveType,
            offset: u32,
            count: u32,
            transform: Mat4,
            projection: ?Mat4,
            camera: ?Camera,
            material: ?Material,
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
                    transform,
                    projection,
                    camera,
                    material,
                },
            );
        }

        fn renderInstancedImpl(
            ptr: *anyopaque,
            vertex_array: VertexArray,
            use_elements: bool,
            primitive: drawcall.PrimitiveType,
            offset: u32,
            count: u32,
            transforms: InstanceTransformArray,
            projection: ?Mat4,
            camera: ?Camera,
            material: ?Material,
            instance_count: u32,
        ) anyerror!void {
            const self = @ptrCast(Ptr, @alignCast(alignment, ptr));
            return @call(
                .{ .modifier = .always_inline },
                renderInstancedFn,
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

        const vtable = VTable{
            .beginFn = beginImpl,
            .endFn = endImpl,
            .getVertexAttribsFn = getVertexAttribsImpl,
            .renderFn = renderImpl,
            .renderInstancedFn = renderInstancedImpl,
        };
    };

    return .{
        .ptr = pointer,
        .vtable = &gen.vtable,
    };
}

pub fn begin(rd: Renderer, instanced_draw: bool) void {
    assert(current_renderer == null);
    rd.vtable.beginFn(rd.ptr, instanced_draw);
    current_renderer = rd.ptr;
}

pub fn end(rd: Renderer) void {
    assert(current_renderer != null);
    assert(current_renderer == rd.ptr);
    rd.vtable.endFn(rd.ptr);
    current_renderer = null;
}

pub fn getVertexAttribs(rd: Renderer) []const u32 {
    return rd.vtable.getVertexAttribsFn(rd.ptr);
}

pub fn render(
    rd: Renderer,
    vertex_array: VertexArray,
    use_elements: bool,
    primitive: drawcall.PrimitiveType,
    offset: u32,
    count: u32,
    transform: Mat4,
    projection: ?Mat4,
    camera: ?Camera,
    material: ?Material,
) anyerror!void {
    assert(current_renderer == rd.ptr);
    return rd.vtable.renderFn(
        rd.ptr,
        vertex_array,
        use_elements,
        primitive,
        offset,
        count,
        transform,
        projection,
        camera,
        material,
    );
}

pub fn renderInstanced(
    rd: Renderer,
    vertex_array: VertexArray,
    use_elements: bool,
    primitive: drawcall.PrimitiveType,
    offset: u32,
    count: u32,
    transforms: InstanceTransformArray,
    projection: ?Mat4,
    camera: ?Camera,
    material: ?Material,
    instance_count: ?u32,
) anyerror!void {
    assert(current_renderer == rd.ptr);
    if (instance_count) |cnt| {
        assert(cnt <= transforms.count);
    }
    return rd.vtable.renderInstancedFn(
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
        instance_count orelse transforms.count,
    );
}
