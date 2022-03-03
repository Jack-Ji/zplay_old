const std = @import("std");
const assert = std.debug.assert;
const Buffer = @import("Buffer.zig");
const zp = @import("../../zplay.zig");
const gl = zp.deps.gl;
const Self = @This();

/// max number of vbo
const MAX_VBO_NUM = 8;

/// id of vertex array
id: gl.GLuint = undefined,

/// buffer objects
vbos: [MAX_VBO_NUM]*Buffer = [_]*Buffer{null} ** MAX_VBO_NUM,
vbo_num: u32 = undefined,
borrowed: bool = undefined,

/// current active vertex array
var current: gl.GLuint = 0;

/// init vertex array
pub fn init(allocator: std.mem.Allocator, vbo_num: u32) Self {
    assert(vbo_num > 0 and vbo_num <= MAX_VBO_NUM);
    var self: Self = undefined;
    gl.genVertexArrays(1, &self.id);
    gl.util.checkError();

    self.borrowed = false;
    self.vbo_num = vbo_num;
    for (self.vbos) |_, i| {
        if (i == vbo_num) break;
        self.vbos[i] = Buffer.init(allocator);
    }
    return self;
}

/// init vertex array with given buffers
/// NOTE: VertexArray will consider these buffers borrowed, thus 
/// buffers won't be destroyed during deinitialize.
pub fn fromBuffers(buffers: []*Buffer) Self {
    assert(buffers.len > 0 and buffers.len <= MAX_VBO_NUM);
    var self: Self = undefined;
    gl.genVertexArrays(1, &self.id);
    gl.util.checkError();

    self.borrowed = true;
    self.vbo_num = @intCast(u32, buffers.len);
    for (buffers) |b, i| {
        self.vbos[i] = b;
    }
    return self;
}

/// deinitialize vertex array
pub fn deinit(self: Self) void {
    gl.deleteVertexArrays(1, &self.id);
    gl.util.checkError();

    if (!self.borrowed) {
        for (self.vbos) |b, i| {
            if (i == self.vbo_num) break;
            b.deinit();
        }
    }
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
    assert(current == self.id);
    assert(vbo_index < self.vbo_num);
    self.vbos[vbo_index].setAttribute(loc, size, T, normalized, stride, offset, null);
}

/// start using vertex array
pub fn use(self: Self) void {
    current = self.id;
    gl.bindVertexArray(self.id);
    gl.util.checkError();
}

/// stop using vertex array
pub fn disuse(self: Self) void {
    _ = self;
    current = 0;
    gl.bindVertexArray(0);
    gl.util.checkError();
}
