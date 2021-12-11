const std = @import("std");
const zp = @import("../../zplay.zig");
const gl = zp.deps.gl;

pub const PrimitiveType = enum(c_uint) {
    points = gl.GL_POINTS,
    line_strip = gl.GL_LINE_STRIP,
    line_loop = gl.GL_LINE_LOOP,
    lines = gl.GL_LINES,
    line_strip_adjacency = gl.GL_LINE_STRIP_ADJACENCY,
    lines_adjacency = gl.GL_LINES_ADJACENCY,
    triangle_strip = gl.GL_TRIANGLE_STRIP,
    triangle_fan = gl.GL_TRIANGLE_FAN,
    triangles = gl.GL_TRIANGLES,
    triangle_strip_adjacency = gl.GL_TRIANGLE_STRIP_ADJACENCY,
    triangles_adjacency = gl.GL_TRIANGLES_ADJACENCY,
};

/// issue draw call
pub fn drawBuffer(
    primitive: PrimitiveType,
    offset: u32,
    vertex_count: u32,
    instance_count: ?u32,
) void {
    if (instance_count) |count| {
        gl.drawArraysInstanced(
            @enumToInt(primitive),
            @intCast(gl.GLint, offset),
            @intCast(gl.GLsizei, vertex_count),
            @intCast(gl.GLsizei, count),
        );
    } else {
        gl.drawArrays(
            @enumToInt(primitive),
            @intCast(gl.GLint, offset),
            @intCast(gl.GLsizei, vertex_count),
        );
    }
    gl.util.checkError();
}

/// issue draw call (only accept unsigned-integer indices!)
pub fn drawElements(
    primitive: PrimitiveType,
    offset: u32,
    element_count: u32,
    comptime ElementType: type,
    instance_count: ?u32,
) void {
    if (ElementType != u16 and ElementType != u32) {
        std.debug.panic("unsupported element type!", .{});
    }
    if (instance_count) |count| {
        gl.drawElementsInstanced(
            @enumToInt(primitive),
            @intCast(gl.GLsizei, element_count),
            gl.util.dataType(ElementType),
            @intToPtr(*allowzero c_void, offset),
            @intCast(gl.GLsizei, count),
        );
    } else {
        gl.drawElements(
            @enumToInt(primitive),
            @intCast(gl.GLsizei, element_count),
            gl.util.dataType(ElementType),
            @intToPtr(*allowzero c_void, offset),
        );
    }
    gl.util.checkError();
}
