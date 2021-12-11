const std = @import("std");
const gl = @import("gl.zig");

/// check error of last opengl call
pub fn checkError() void {
    switch (gl.getError()) {
        gl.GL_NO_ERROR => {},
        gl.GL_INVALID_ENUM => @panic("invalid enum"),
        gl.GL_INVALID_VALUE => @panic("invalid value"),
        gl.GL_INVALID_OPERATION => @panic("invalid operation"),
        gl.GL_OUT_OF_MEMORY => @panic("out of memory"),
        else => @panic("unknow error"),
    }
}

/// convert zig primitive type into opengl enums
pub fn dataType(comptime T: type) c_uint {
    return switch (T) {
        i8 => gl.GL_BYTE,
        u8 => gl.GL_UNSIGNED_BYTE,
        i16 => gl.GL_SHORT,
        u16 => gl.GL_UNSIGNED_SHORT,
        i32 => gl.GL_INT,
        u32 => gl.GL_UNSIGNED_INT,
        f16 => gl.GL_HALF_FLOAT,
        f32 => gl.GL_FLOAT,
        f64 => gl.GL_DOUBLE,
        else => @compileError("invalid data type"),
    };
}

/// convert boolean value into opengl enums
pub fn boolType(b: bool) u8 {
    return if (b) gl.GL_TRUE else gl.GL_FALSE;
}
