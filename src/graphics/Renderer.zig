const std = @import("std");
const assert = std.debug.assert;
const Camera = @import("Camera.zig");
const Material = @import("Material.zig");
const zp = @import("../zplay.zig");
const Context = zp.graphics.gpu.Context;
const drawcall = zp.graphics.gpu.drawcall;
const VertexArray = zp.graphics.gpu.VertexArray;
const Buffer = zp.graphics.gpu.Buffer;
const alg = zp.deps.alg;
const Vec3 = alg.Vec3;
const Mat4 = alg.Mat4;
const Renderer = @This();

/// The type erased pointer to Renderer implementation
ptr: *anyopaque,
vtable: *const VTable,

/// common shader head
pub const shader_head =
    \\#version 330 core
    \\
;

/// local coordinate transform(s)
pub const LocalTransform = union(enum) {
    single: Mat4,
    instanced: *InstanceTransformArray,
};

/// vbo specially managed for instanced rendering
pub const InstanceTransformArray = struct {
    const Self = @This();

    allocator: std.mem.Allocator,

    /// vbo for instance transform matrices
    buf: *Buffer,

    /// number of instances
    count: u32,

    pub fn init(allocator: std.mem.Allocator) !*Self {
        var self = try allocator.create(Self);
        self.allocator = allocator;
        self.buf = Buffer.init(allocator);
        self.count = 0;
        return self;
    }

    pub fn deinit(self: *Self) void {
        self.buf.deinit();
        self.allocator.destroy(self);
    }

    /// upload transform data
    pub fn updateTransforms(self: *Self, transforms: []Mat4) !void {
        var total_size: u32 = @intCast(u32, @sizeOf(Mat4) * transforms.len);
        if (self.buf.size < total_size) {
            self.buf.allocData(total_size, .dynamic_draw);
        }
        self.buf.updateData(0, Mat4, transforms);
        self.count = @intCast(u32, transforms.len);
    }

    /// enable vertex attributes
    /// NOTE: VertexArray should have been activated!
    pub fn enableAttributes(self: Self, location: c_uint) void {
        self.buf.setAttribute(
            location,
            4,
            f32,
            false,
            @sizeOf(Mat4),
            0,
            1,
        );
        self.buf.setAttribute(
            location + 1,
            4,
            f32,
            false,
            @sizeOf(Mat4),
            4 * @sizeOf(f32),
            1,
        );
        self.buf.setAttribute(
            location + 2,
            4,
            f32,
            false,
            @sizeOf(Mat4),
            8 * @sizeOf(f32),
            1,
        );
        self.buf.setAttribute(
            location + 3,
            4,
            f32,
            false,
            @sizeOf(Mat4),
            12 * @sizeOf(f32),
            1,
        );
    }
};

/// generic renderer's input
pub const Input = struct {
    /// array of vertex data, waiting to be rendered
    vds: ?std.ArrayList(VertexData) = null,

    /// camera
    camera: ?*Camera = null,

    /// globally shared material data
    material: ?*Material = null,

    /// renderer's custom data, if any
    custom: ?*const anyopaque = null,

    /// vertex data
    pub const VertexData = struct {
        /// whether data is valid
        valid: bool = true,

        /// whether use element indices, normally we do
        element_draw: bool = true,

        /// vertex attributes array
        vertex_array: VertexArray,

        /// drawing primitive
        primitive: drawcall.PrimitiveType = .triangles,

        /// offset into vertex attributes array
        offset: u32 = 0,

        /// count of vertices
        count: u32,

        /// material data, usually prefered over default one
        material: ?*Material = null,

        /// local transformation(s)
        transform: LocalTransform = .{
            .single = Mat4.identity(),
        },
    };

    /// allocate renderer's input container
    pub fn init(
        allocator: std.mem.Allocator,
        vds: []VertexData,
        camera: ?*Camera,
        material: ?*Material,
        custom: ?*anyopaque,
    ) !Input {
        var self = Input{
            .vds = try std.ArrayList(VertexData)
                .initCapacity(allocator, std.math.max(vds.len, 1)),
            .camera = camera,
            .material = material,
            .custom = custom,
        };
        self.vds.?.appendSliceAssumeCapacity(vds);
        return self;
    }

    /// create a copy of renderer's input
    pub fn clone(self: Input, allocator: std.mem.Allocator) !Input {
        var cloned = self;
        if (self.vds) |ds| {
            cloned.vds = try std.ArrayList(VertexData).initCapacity(
                allocator,
                ds.items.len,
            );
            cloned.vds.?.appendSliceAssumeCapacity(ds.items);
        }
        return cloned;
    }

    /// only free vds's memory, won't touch anything else
    pub fn deinit(self: Input) void {
        if (self.vds) |d| d.deinit();
    }
};

const VTable = struct {
    /// generic drawing
    drawFn: fn (ptr: *anyopaque, ctx: *Context, input: Input) anyerror!void,
};

pub fn init(
    pointer: anytype,
    comptime drawFn: fn (ptr: @TypeOf(pointer), ctx: *Context, input: Input) anyerror!void,
) Renderer {
    const Ptr = @TypeOf(pointer);
    const ptr_info = @typeInfo(Ptr);

    assert(ptr_info == .Pointer); // must be a pointer
    assert(ptr_info.Pointer.size == .One); // must be a single-item pointer

    const alignment = ptr_info.Pointer.alignment;

    const gen = struct {
        fn drawImpl(ptr: *anyopaque, ctx: *Context, input: Input) anyerror!void {
            const self = @ptrCast(Ptr, @alignCast(alignment, ptr));
            return @call(
                .{ .modifier = .always_inline },
                drawFn,
                .{ self, ctx, input },
            );
        }

        const vtable = VTable{
            .drawFn = drawImpl,
        };
    };

    return .{
        .ptr = pointer,
        .vtable = &gen.vtable,
    };
}

pub fn draw(rd: Renderer, ctx: *Context, input: Input) anyerror!void {
    return rd.vtable.drawFn(rd.ptr, ctx, input);
}
