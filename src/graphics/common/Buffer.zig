const std = @import("std");
const assert = std.debug.assert;
const zp = @import("../../zplay.zig");
const gl = zp.deps.gl;
const Self = @This();

/// buffer data's binding target
pub const Target = enum(c_uint) {
    array_buffer = gl.GL_ARRAY_BUFFER,
    copy_read_buffer = gl.GL_COPY_READ_BUFFER,
    copy_write_buffer = gl.GL_COPY_WRITE_BUFFER,
    element_array_buffer = gl.GL_ELEMENT_ARRAY_BUFFER,
    pixel_pack_buffer = gl.GL_PIXEL_PACK_BUFFER,
    pixel_unpack_buffer = gl.GL_PIXEL_UNPACK_BUFFER,
    texture_buffer = gl.GL_TEXTURE_BUFFER,
    transform_feedback_buffer = gl.GL_TRANSFORM_FEEDBACK_BUFFER,
    uniform_buffer = gl.GL_UNIFORM_BUFFER,
};

/// buffer data's usage
pub const Usage = enum(c_uint) {
    stream_draw = gl.GL_STREAM_DRAW,
    stream_read = gl.GL_STREAM_READ,
    stream_copy = gl.GL_STREAM_COPY,
    static_draw = gl.GL_STATIC_DRAW,
    static_read = gl.GL_STATIC_READ,
    static_copy = gl.GL_STATIC_COPY,
    dynamic_draw = gl.GL_DYNAMIC_DRAW,
    dynamic_read = gl.GL_DYNAMIC_READ,
    dynamic_copy = gl.GL_DYNAMIC_COPY,
};

/// buffer data's access level
pub const Access = enum(c_uint) {
    read = gl.GL_READ_ONLY,
    write = gl.GL_WRITE_ONLY,
    read_write = gl.GL_READ_WRITE,
};

/// memory allocator
allocator: std.mem.Allocator,

/// id of vbo
id: gl.GLuint,

/// size of buffer
size: u32,

/// init buffer object
pub fn init(allocator: std.mem.Allocator) *Self {
    var self: *Self = allocator.create(Self) catch unreachable;
    self.allocator = allocator;
    gl.genBuffers(1, &self.id);
    gl.util.checkError();
    self.size = 0;
    return self;
}

/// destroy buffer object
pub fn deinit(self: *Self) void {
    gl.deleteBuffers(1, &self.id);
    gl.util.checkError();
    self.allocator.destroy(self);
}

/// allocate and initialize gpu memory
pub fn allocInitData(self: *Self, comptime T: type, data: []const T, target: Target, usage: Usage) void {
    gl.bindBuffer(@enumToInt(target), self.id);
    gl.bufferData(
        @enumToInt(target),
        @intCast(c_longlong, data.len * @sizeOf(T)),
        data.ptr,
        @enumToInt(usage),
    );
    self.size = @intCast(u32, data.len * @sizeOf(T));
    gl.util.checkError();
}

/// only allocate gpu memory
pub fn allocData(self: *Self, size: u32, target: Target, usage: Usage) void {
    gl.bindBuffer(@enumToInt(target), self.id);
    gl.bufferData(
        @enumToInt(target),
        @intCast(c_longlong, size),
        null,
        @enumToInt(usage),
    );
    self.size = size;
    gl.util.checkError();
}

/// update gpu memory, user need to make sure enough memory had been allocated
pub fn updateData(self: Self, offset: u32, comptime T: type, data: []const T, target: Target) void {
    assert(self.size >= offset + data.len * @sizeOf(T));
    gl.bindBuffer(@enumToInt(target), self.id);
    gl.bufferSubData(
        @enumToInt(target),
        @intCast(c_longlong, offset),
        @intCast(c_longlong, data.len * @sizeOf(T)),
        data.ptr,
    );
    gl.util.checkError();
}

/// copy gpu memory to user space
pub fn getBufferData(
    self: Self,
    offset: u32,
    data: []const u8,
    target: Target,
) void {
    assert(self.size >= offset + data.len);
    gl.bindBuffer(@enumToInt(target), self.id);
    gl.getBufferSubData(
        @enumToInt(target),
        @intCast(c_longlong, offset),
        @intCast(c_longlong, data.len),
        data.ptr,
    );
    gl.util.checkError();
}

/// get mapped memory pointer
pub fn mapBufferRange(self: Self, offset: u32, size: u32, target: Target, access: Access) ?[*]u8 {
    assert(self.size >= offset + size);
    gl.bindBuffer(@enumToInt(target), self.id);
    var data = gl.mapBufferRange(
        @enumToInt(target),
        @intCast(c_longlong, offset),
        @intCast(c_longlong, size),
        @enumToInt(access),
    );
    if (data) |ptr| {
        return @ptrCast([*]u8, ptr);
    }
    return null;
}

/// unmap specified buffer object
/// returns true unless data store become corrupted, which means user needs to reinitialize data.
pub fn unmapBuffer(self: Self, target: Target) bool {
    _ = self;
    return gl.util.boolType(gl.unmapBuffer(@enumToInt(target)));
}

/// copy data between buffers
pub fn copy(dst: Self, src: Self, dst_offset: u32, src_offset: u32, size: u32) void {
    assert(dst.size >= dst_offset + size);
    assert(src.size >= src_offset + size);
    gl.bindBuffer(@enumToInt(Target.copy_write_buffer), dst.id);
    gl.bindBuffer(@enumToInt(Target.copy_read_buffer), src.id);
    gl.util.checkError();

    gl.copyBufferSubData(
        @enumToInt(Target.copy_read_buffer),
        @enumToInt(Target.copy_write_buffer),
        @intCast(c_longlong, src_offset),
        @intCast(c_longlong, dst_offset),
        @intCast(c_longlong, size),
    );
    gl.util.checkError();
}
