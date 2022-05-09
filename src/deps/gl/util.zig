const std = @import("std");
const gl = @import("gl.zig");

pub const ErrorHandling = enum {
    /// OpenGL functions will log the error, but will not assert that no error happened
    log,

    /// Asserts that no errors will happen.
    assert,

    /// No error checking will be executed. Gotta go fast!
    none,
};

const error_handling: ErrorHandling =
    std.meta.globalOption("opengl_error_handling", ErrorHandling) orelse
    if (std.debug.runtime_safety) .assert else .none;

/// check error of last opengl call
pub inline fn checkError() void {
    if (error_handling == .none) return;

    var error_code = gl.getError();
    if (error_code == gl.GL_NO_ERROR)
        return;
    while (error_code != gl.GL_NO_ERROR) : (error_code = gl.getError()) {
        const name = switch (error_code) {
            gl.GL_INVALID_ENUM => "invalid enum",
            gl.GL_INVALID_VALUE => "invalid value",
            gl.GL_INVALID_OPERATION => "invalid operation",
            gl.GL_OUT_OF_MEMORY => "out of memory",
            gl.GL_INVALID_FRAMEBUFFER_OPERATION => "invalid framebuffer operation",
            //gl.GL_STACK_OVERFLOW => "stack overflow",
            //gl.GL_STACK_UNDERFLOW => "stack underflow",
            //gl.GL_INVALID_FRAMEBUFFER_OPERATION_EXT => Error.InvalidFramebufferOperation,
            //gl.GL_INVALID_FRAMEBUFFER_OPERATION_OES => Error.InvalidFramebufferOperation,
            //gl.GL_TABLE_TOO_LARGE => "Table too large",
            //gl.GL_TABLE_TOO_LARGE_EXT => Error.TableTooLarge,
            //gl.GL_TEXTURE_TOO_LARGE_EXT => "Texture too large",
            else => "unknown error",
        };

        std.log.scoped(.OpenGL).err("OpenGL failure: {s}\n", .{name});
        switch (error_handling) {
            .log => {},
            .assert => @panic("OpenGL error"),
            .none => unreachable,
        }
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
