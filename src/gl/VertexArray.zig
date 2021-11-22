const std = @import("std");
const gl = @import("gl.zig");
const Self = @This();

/// max number of vbo
const max_vbo_num = 8;

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

/// id of vertex array
id: gl.GLuint = undefined,

/// buffer objects
vbos: [max_vbo_num]gl.GLuint = undefined,
vbo_num: usize = undefined,

/// init vertex array
pub fn init(vbo_num: usize) Self {
    if (vbo_num == 0) {
        std.debug.panic("invalid parameter", .{});
    }
    if (vbo_num > max_vbo_num) {
        std.debug.panic("do you really need that many vbo?", .{});
    }

    var va: Self = undefined;
    gl.genVertexArrays(1, &va.id);
    va.vbo_num = vbo_num;
    gl.genBuffers(@intCast(c_int, vbo_num), &va.vbos);
    gl.util.checkError();
    return va;
}

/// deinitialize vertex array
pub fn deinit(self: *Self) void {
    gl.deleteVertexArrays(1, &self.id);
    gl.deleteBuffers(@intCast(c_int, self.vbo_num), &self.vbos);
    self.id = undefined;
    self.vbos = undefined;
    self.vbo_num = undefined;
    gl.util.checkError();
}

/// update buffer data
pub fn bufferData(
    self: Self,
    vbo_index: usize,
    comptime T: type,
    data: []const T,
    target: BufferTarget,
    usage: BufferUsage,
) void {
    // check if data type is valid
    _ = gl.util.dataType(T);

    if (vbo_index > self.vbo_num) {
        std.debug.panic("invalid vbo index", .{});
    }

    if (target == .element_array_buffer and T != u16) {
        std.debug.panic("invalid index type", .{});
    }

    gl.bindBuffer(@enumToInt(target), self.vbos[vbo_index]);
    gl.bufferData(
        @enumToInt(target),
        @intCast(c_longlong, data.len * @sizeOf(T)),
        data.ptr,
        @enumToInt(usage),
    );
    gl.util.checkError();
}

// set vertex attribute (will enable attribute afterwards)
pub fn setAttribute(
    self: Self,
    vbo_index: usize,
    loc: gl.GLuint,
    size: u32,
    comptime T: type,
    normalized: bool,
    stride: usize,
    offset: u32,
) void {
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
        @intToPtr(*allowzero c_void, offset),
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
