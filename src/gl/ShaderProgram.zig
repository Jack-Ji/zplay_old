const std = @import("std");
const gl = @import("gl.zig");
const alg = @import("../lib.zig").alg;
const Self = @This();
const allocator = std.heap.raw_c_allocator;

/// id of shader program
id: gl.GLuint = undefined,

/// uniform location cache
/// Q: Why use string cache?
/// A: Because we don't know where the given uniform name resides in(static, stack, heap),
///    which means it could be disappeared/invalid in anytime! So, we clone it to make sure
///    the memory is valid as long as shader is living.
uniform_locs: std.StringHashMap(gl.GLint) = undefined,
string_cache: std.ArrayList([]u8) = undefined,

/// init shader program
pub fn init(
    vs_source: [:0]const u8,
    fs_source: [:0]const u8,
) Self {
    var program: Self = undefined;
    var success: gl.GLint = undefined;
    var shader_log: [512]gl.GLchar = undefined;
    var log_size: gl.GLsizei = undefined;

    // vertex shader
    var vshader = gl.createShader(gl.GL_VERTEX_SHADER);
    defer gl.deleteShader(vshader);
    gl.shaderSource(vshader, 1, &vs_source.ptr, null);
    gl.compileShader(vshader);
    gl.getShaderiv(vshader, gl.GL_COMPILE_STATUS, &success);
    if (success == 0) {
        gl.getShaderInfoLog(vshader, 512, &log_size, &shader_log);
        std.debug.panic("compile vertex shader failed: {s}", .{shader_log[0..@intCast(usize, log_size)]});
    }
    gl.util.checkError();

    // fragment shader
    var fshader = gl.createShader(gl.GL_FRAGMENT_SHADER);
    defer gl.deleteShader(fshader);
    gl.shaderSource(fshader, 1, &fs_source.ptr, null);
    gl.compileShader(fshader);
    gl.getShaderiv(fshader, gl.GL_COMPILE_STATUS, &success);
    if (success == 0) {
        gl.getShaderInfoLog(fshader, 512, &log_size, &shader_log);
        std.debug.panic("compile fragment shader failed: {s}", .{shader_log[0..@intCast(usize, log_size)]});
    }
    gl.util.checkError();

    // link program
    program.id = gl.createProgram();
    gl.attachShader(program.id, vshader);
    gl.attachShader(program.id, fshader);
    gl.linkProgram(program.id);
    gl.getProgramiv(program.id, gl.GL_LINK_STATUS, &success);
    if (success == 0) {
        gl.getProgramInfoLog(program.id, 512, &log_size, &shader_log);
        std.debug.panic("link shader program failed: {s}", .{shader_log[0..@intCast(usize, log_size)]});
    }
    gl.util.checkError();

    // init uniform location cache
    program.uniform_locs = std.StringHashMap(gl.GLint).init(allocator);
    program.string_cache = std.ArrayList([]u8).init(allocator);

    return program;
}

/// deinitialize shader program
pub fn deinit(self: *Self) void {
    gl.deleteProgram(self.id);
    self.id = undefined;
    self.uniform_locs.deinit();
    for (self.string_cache) |s| {
        allocator.free(s);
    }
    self.string_cache.deinit();
    gl.util.checkError();
}

/// start using shader program
pub fn use(self: Self) void {
    gl.useProgram(self.id);
    gl.util.checkError();
}

/// stop using shader program
pub fn disuse(self: Self) void {
    _ = self;
    gl.useProgram(0);
    gl.util.checkError();
}

/// check if program is being used
pub fn isUsing(self: Self) bool {
    var current_program: gl.GLint = undefined;
    gl.getIntegerv(gl.GL_CURRENT_PROGRAM, &current_program);
    return current_program == self.id;
}

/// set uniform value with name
pub fn setUniformByName(self: *Self, name: [:0]const u8, v: anytype) void {
    if (!self.isUsing()) {
        std.debug.panic("invalid operation, must use program first!", .{});
    }

    var loc: gl.GLint = undefined;
    if (self.uniform_locs.get(name)) |l| {
        // check cache first
        loc = l;
    } else {
        // query driver
        loc = gl.getUniformLocation(self.id, name.ptr);
        gl.util.checkError();
        if (loc < 0) {
            std.debug.panic("can't find location of uniform {s}", .{name});
        }

        // save into cache
        const cloned_name = allocator.dupe(u8, name) catch unreachable;
        self.uniform_locs.put(cloned_name, loc) catch unreachable;
        self.string_cache.append(cloned_name) catch unreachable;
    }
    self.setUniform(loc, v);
}

/// set uniform value with location
pub fn setUniformByLocation(self: Self, loc: gl.GLuint, v: anytype) void {
    if (!self.isUsing()) {
        std.debug.panic("invalid operation, must use program first!", .{});
    }
    self.setUniform(@intCast(gl.GLuint, loc), v);
}

/// internal generic function for setting uniform value
fn setUniform(self: Self, loc: gl.GLint, v: anytype) void {
    _ = self;
    switch (@TypeOf(v)) {
        bool => gl.uniform1i(loc, gl.util.boolType(v)),
        i32, comptime_int, usize => gl.uniform1i(loc, @intCast(gl.GLint, v)),
        []i32 => gl.uniform1iv(loc, v.len, v.ptr),
        [2]i32 => gl.uniform2iv(loc, 1, &v),
        [3]i32 => gl.uniform3iv(loc, 1, &v),
        [4]i32 => gl.uniform4iv(loc, 1, &v),
        u32 => gl.uniform1ui(loc, v),
        []u32 => gl.uniform1uiv(loc, v.len, v.ptr),
        [2]u32 => gl.uniform2uiv(loc, 1, &v),
        [3]u32 => gl.uniform3uiv(loc, 1, &v),
        [4]u32 => gl.uniform4uiv(loc, 1, &v),
        f32 => gl.uniform1f(loc, v),
        []f32 => gl.uniform1fv(loc, v.len, v.ptr),
        [2]f32 => gl.uniform2fv(loc, 1, &v),
        [3]f32 => gl.uniform3fv(loc, 1, &v),
        [4]f32 => gl.uniform4fv(loc, 1, &v),
        alg.Vec2 => gl.uniform2f(loc, v.x, v.y),
        alg.Vec3 => gl.uniform3f(loc, v.x, v.y, v.z),
        alg.Vec4 => gl.uniform4f(loc, v.x, v.y, v.z, v.w),
        alg.Mat4 => gl.uniformMatrix4fv(loc, 1, gl.GL_FALSE, v.getData()),
        else => std.debug.panic("unsupported type {s}", .{@typeName(@TypeOf(v))}),
    }
    gl.util.checkError();
}
