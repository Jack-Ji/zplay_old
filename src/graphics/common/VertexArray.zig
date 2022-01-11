const std = @import("std");
const assert = std.debug.assert;
const zp = @import("../../zplay.zig");
const gl = zp.deps.gl;
const Self = @This();

/// max number of vbo
const MAX_VBO_NUM = 8;

/// buffer data's binding target
const BufferTarget = enum(c_uint) {
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
const BufferUsage = enum(c_uint) {
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
const BufferAccess = enum(c_uint) {
    read = gl.GL_READ_ONLY,
    write = gl.GL_WRITE_ONLY,
    read_write = gl.GL_READ_WRITE,
};

/// id of vertex array
id: gl.GLuint = undefined,

/// buffer objects
vbos: [MAX_VBO_NUM]gl.GLuint = undefined,
vbo_num: u32 = undefined,

/// init vertex array
pub fn init(vbo_num: u32) Self {
    assert(vbo_num > 0 and vbo_num <= MAX_VBO_NUM);
    var va: Self = undefined;
    gl.genVertexArrays(1, &va.id);
    va.vbo_num = vbo_num;
    gl.genBuffers(@intCast(c_int, vbo_num), &va.vbos);
    gl.util.checkError();
    return va;
}

/// deinitialize vertex array
pub fn deinit(self: Self) void {
    gl.deleteVertexArrays(1, &self.id);
    gl.deleteBuffers(@intCast(c_int, self.vbo_num), &self.vbos);
    gl.util.checkError();
}

/// allocate and initialize buffer data
pub fn bufferData(
    self: Self,
    vbo_index: u32,
    comptime T: type,
    data: []const T,
    target: BufferTarget,
    usage: BufferUsage,
) void {
    assert(vbo_index < self.vbo_num);
    gl.bindBuffer(@enumToInt(target), self.vbos[vbo_index]);
    gl.bufferData(
        @enumToInt(target),
        @intCast(c_longlong, data.len * @sizeOf(T)),
        data.ptr,
        @enumToInt(usage),
    );
    gl.util.checkError();
}

/// only allocate buffer data
pub fn bufferDataAlloc(
    self: Self,
    vbo_index: u32,
    size: u32,
    target: BufferTarget,
    usage: BufferUsage,
) void {
    assert(vbo_index < self.vbo_num);
    gl.bindBuffer(@enumToInt(target), self.vbos[vbo_index]);
    gl.bufferData(
        @enumToInt(target),
        @intCast(c_longlong, size),
        null,
        @enumToInt(usage),
    );
    gl.util.checkError();
}

/// update buffer data, user need to make sure enough memory had been allocated
pub fn bufferSubData(
    self: Self,
    vbo_index: u32,
    offset: u32,
    comptime T: type,
    data: []const T,
    target: BufferTarget,
) void {
    assert(vbo_index < self.vbo_num);
    gl.bindBuffer(@enumToInt(target), self.vbos[vbo_index]);
    gl.bufferSubData(
        @enumToInt(target),
        @intCast(c_longlong, offset),
        @intCast(c_longlong, data.len * @sizeOf(T)),
        data.ptr,
    );
    gl.util.checkError();
}

/// copy buffer data from gpu
pub fn getBufferData(
    self: Self,
    vbo_index: u32,
    offset: u32,
    data: []const u8,
    target: BufferTarget,
) void {
    assert(vbo_index < self.vbo_num);
    gl.bindBuffer(@enumToInt(target), self.vbos[vbo_index]);
    gl.getBufferSubData(
        @enumToInt(target),
        @intCast(c_longlong, offset),
        @intCast(c_longlong, data.len),
        data.ptr,
    );
    gl.util.checkError();
}

/// get mapped memory pointer
pub fn mapBuffer(
    self: Self,
    vbo_index: u32,
    target: BufferTarget,
    access: BufferAccess,
) ?[*]u8 {
    assert(vbo_index < self.vbo_num);
    gl.bindBuffer(@enumToInt(target), self.vbos[vbo_index]);
    var data = gl.mapBuffer(@enumToInt(target), @enumToInt(access));
    if (data) |ptr| {
        return @ptrCast([*]u8, ptr);
    }
    return null;
}

/// unmap specified buffer object
/// returns true unless data store become corrupted, which means user needs to reinitialize data.
pub fn unmapBuffer(self: Self, target: BufferTarget) bool {
    _ = self;
    return gl.util.boolType(gl.unmapBuffer(@enumToInt(target)));
}

// set vertex attribute (will enable attribute afterwards)
pub fn setAttribute(
    self: Self,
    vbo_index: u32,
    loc: gl.GLuint,
    size: u32,
    comptime T: type,
    normalized: bool,
    stride: u32,
    offset: u32,
) void {
    assert(vbo_index < self.vbo_num);
    gl.bindBuffer(
        @enumToInt(BufferTarget.array_buffer),
        self.vbos[vbo_index],
    );
    gl.util.checkError();

    gl.vertexAttribPointer(
        loc,
        @intCast(c_int, size),
        gl.util.dataType(T),
        gl.util.boolType(normalized),
        @intCast(c_int, stride),
        @intToPtr(*allowzero anyopaque, offset),
    );
    gl.enableVertexAttribArray(loc);
    gl.util.checkError();
}

/// start using vertex array
pub fn use(self: Self) void {
    gl.bindVertexArray(self.id);
    gl.util.checkError();
}

/// stop using vertex array
pub fn disuse(self: Self) void {
    _ = self;
    gl.bindVertexArray(0);
    gl.util.checkError();
}
