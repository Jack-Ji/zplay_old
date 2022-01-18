const std = @import("std");
const assert = std.debug.assert;
const zp = @import("../../zplay.zig");
const gl = zp.deps.gl;
const alg = zp.deps.alg;
const Vec2 = alg.Vec2;
const Vec3 = alg.Vec3;
const Vec4 = alg.Vec4;
const Mat4 = alg.Mat4;
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

/// current active shader
var current: gl.GLuint = 0;

/// init shader program
pub fn init(
    vs_source: [:0]const u8,
    fs_source: [:0]const u8,
    gs_source: ?[:0]const u8,
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
        std.debug.panic(
            "compile vertex shader failed, error log:\n{s}" ++
                "\n\n>>>>> full shader source <<<<<\n{s}\n",
            .{ shader_log[0..@intCast(u32, log_size)], prettifySource(vs_source) },
        );
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
        std.debug.panic(
            "compile fragment shader failed, error log:\n{s}" ++
                "\n\n>>>>> full shader source <<<<<\n{s}\n",
            .{ shader_log[0..@intCast(u32, log_size)], prettifySource(fs_source) },
        );
    }
    gl.util.checkError();

    // geometry shader
    var gshader: gl.GLuint = undefined;
    if (gs_source) |src| {
        gshader = gl.createShader(gl.GL_GEOMETRY_SHADER);
        gl.shaderSource(gshader, 1, &src.ptr, null);
        gl.compileShader(gshader);
        gl.getShaderiv(gshader, gl.GL_COMPILE_STATUS, &success);
        if (success == 0) {
            gl.getShaderInfoLog(gshader, 512, &log_size, &shader_log);
            std.debug.panic(
                "compile geometry shader failed, error log:\n{s}" ++
                    "\n\n>>>>> full shader source <<<<<\n{s}\n",
                .{ shader_log[0..@intCast(u32, log_size)], prettifySource(src) },
            );
        }
        gl.util.checkError();
    }

    // link program
    program.id = gl.createProgram();
    gl.attachShader(program.id, vshader);
    gl.attachShader(program.id, fshader);
    if (gs_source != null) {
        gl.attachShader(program.id, gshader);
    }
    gl.linkProgram(program.id);
    gl.getProgramiv(program.id, gl.GL_LINK_STATUS, &success);
    if (success == 0) {
        gl.getProgramInfoLog(program.id, 512, &log_size, &shader_log);
        std.debug.panic(
            "link shader program failed, error log:\n{s}" ++
                "\n\n>>>>> vertex shader source <<<<<\n{s}" ++
                "\n\n>>>>> fragment shader source <<<<<\n{s}\n",
            .{ shader_log[0..@intCast(u32, log_size)], prettifySource(vs_source), prettifySource(fs_source) },
        );
    }
    gl.util.checkError();

    // init uniform location cache
    program.uniform_locs = std.StringHashMap(gl.GLint).init(allocator);
    program.string_cache = std.ArrayList([]u8).init(allocator);

    if (gs_source != null) {
        gl.deleteShader(gshader);
    }
    return program;
}

/// deinitialize shader program
pub fn deinit(self: *Self) void {
    gl.deleteProgram(self.id);
    self.id = undefined;
    self.uniform_locs.deinit();
    for (self.string_cache.items) |s| {
        allocator.free(s);
    }
    self.string_cache.deinit();
    gl.util.checkError();
}

/// start using shader program
pub fn use(self: Self) void {
    current = self.id;
    gl.useProgram(self.id);
    gl.util.checkError();
}

/// stop using shader program
pub fn disuse(self: Self) void {
    _ = self;
    current = 0;
    gl.useProgram(0);
    gl.util.checkError();
}

/// check if shader is being used
pub fn isUsing(self: Self) bool {
    return self.id == current;
}

/// get uniform block index
pub fn getUniformBlockIndex(self: *Self, name: [:0]const u8) gl.GLuint {
    var index: gl.GLuint = gl.getUniformBlockIndex(self.id, name.ptr);
    gl.util.checkError();
    if (index == gl.GL_INVALID_INDEX) {
        std.debug.panic("can't find uniform block {s}", .{name});
    }
    return index;
}

/// get uniform location (and cache them)
pub fn getUniformLocation(self: *Self, name: [:0]const u8) gl.GLint {
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
    return loc;
}

/// set uniform value with name
pub fn setUniformByName(self: *Self, name: [:0]const u8, v: anytype) void {
    assert(self.id == current);
    var loc = self.getUniformLocation(name);
    self.setUniform(loc, v);
}

/// set uniform value with location
pub fn setUniformByLocation(self: Self, loc: gl.GLuint, v: anytype) void {
    assert(self.id == current);
    self.setUniform(@intCast(gl.GLuint, loc), v);
}

/// internal generic function for setting uniform value
fn setUniform(self: Self, loc: gl.GLint, v: anytype) void {
    _ = self;
    switch (@TypeOf(v)) {
        bool => gl.uniform1i(loc, gl.util.boolType(v)),
        i32, c_int, comptime_int, usize => gl.uniform1i(loc, @intCast(gl.GLint, v)),
        []i32 => gl.uniform1iv(loc, v.len, v.ptr),
        [2]i32 => gl.uniform2iv(loc, 1, &v),
        [3]i32 => gl.uniform3iv(loc, 1, &v),
        [4]i32 => gl.uniform4iv(loc, 1, &v),
        u32, c_uint => gl.uniform1ui(loc, @intCast(gl.GLuint, v)),
        []u32 => gl.uniform1uiv(loc, v.len, v.ptr),
        [2]u32 => gl.uniform2uiv(loc, 1, &v),
        [3]u32 => gl.uniform3uiv(loc, 1, &v),
        [4]u32 => gl.uniform4uiv(loc, 1, &v),
        comptime_float, f32 => gl.uniform1f(loc, @floatCast(gl.GLfloat, v)),
        []f32 => gl.uniform1fv(loc, v.len, v.ptr),
        [2]f32 => gl.uniform2fv(loc, 1, &v),
        [3]f32 => gl.uniform3fv(loc, 1, &v),
        [4]f32 => gl.uniform4fv(loc, 1, &v),
        Vec2 => gl.uniform2f(loc, v.x, v.y),
        Vec3 => gl.uniform3f(loc, v.x, v.y, v.z),
        Vec4 => gl.uniform4f(loc, v.x, v.y, v.z, v.w),
        Mat4 => gl.uniformMatrix4fv(loc, 1, gl.GL_FALSE, v.getData()),
        else => std.debug.panic("unsupported type {s}", .{@typeName(@TypeOf(v))}),
    }
    gl.util.checkError();
}

/// set default value for attribute
pub fn setAttributeDefaultValue(self: Self, _loc: gl.GLint, v: anytype) void {
    assert(self.id == current);
    const loc = @intCast(gl.GLuint, _loc);
    switch (@TypeOf(v)) {
        Vec2 => gl.vertexAttrib2f(loc, v.x, v.y),
        Vec3 => gl.vertexAttrib3f(loc, v.x, v.y, v.z),
        Vec4 => gl.vertexAttrib4f(loc, v.x, v.y, v.z, v.w),
        f32 => gl.vertexAttrib1f(loc, v),
        i16 => gl.vertexAttrib1s(loc, v),
        f64 => gl.vertexAttrib1d(loc, v),
        i32, c_int, comptime_int, usize => gl.vertexAttribI1i(loc, @intCast(gl.GLint, v)),
        u32, c_uint => gl.vertexAttribI1ui(loc, @intCast(gl.GLuint, v)),
        [1]f32 => gl.vertexAttrib1fv(loc, &v),
        [1]i16 => gl.vertexAttrib1sv(loc, &v),
        [1]f64 => gl.vertexAttrib1dv(loc, &v),
        [1]i32, [1]c_int => gl.vertexAttribI1iv(loc, @ptrCast([*c]gl.GLint, &v)),
        [1]u32, [1]c_uint => gl.vertexAttribI1uiv(loc, @ptrCast([*c]gl.GLuint, &v)),
        [2]f32 => gl.vertexAttrib2fv(loc, &v),
        [2]i16 => gl.vertexAttrib2sv(loc, &v),
        [2]f64 => gl.vertexAttrib2dv(loc, &v),
        [2]i32, [2]c_int => gl.vertexAttribI2iv(loc, @ptrCast([*c]gl.GLint, &v)),
        [2]u32, [2]c_uint => gl.vertexAttribI2uiv(loc, @ptrCast([*c]gl.GLuint, &v)),
        [3]f32 => gl.vertexAttrib3fv(loc, &v),
        [3]i16 => gl.vertexAttrib3sv(loc, &v),
        [3]f64 => gl.vertexAttrib3dv(loc, &v),
        [3]i32, [3]c_int => gl.vertexAttribI3iv(loc, @ptrCast([*c]gl.GLint, &v)),
        [3]u32, [3]c_uint => gl.vertexAttribI3uiv(loc, @ptrCast([*c]gl.GLuint, &v)),
        [4]f32 => gl.vertexAttrib4fv(loc, &v),
        [4]i16 => gl.vertexAttrib4sv(loc, &v),
        [4]f64 => gl.vertexAttrib4dv(loc, &v),
        [4]i32, [4]c_int => gl.vertexAttrib4iv(loc, @ptrCast([*c]gl.GLint, &v)),
        [4]i8 => gl.vertexAttrib4bv(loc, &v),
        [4]u8 => gl.vertexAttrib4ubv(loc, &v),
        [4]u16 => gl.vertexAttrib4usv(loc, &v),
        [4]u32, [4]c_uint => gl.vertexAttrib4uiv(loc, @ptrCast([*c]gl.GLuint, &v)),
        else => std.debug.panic("unsupported type {s}", .{@typeName(@TypeOf(v))}),
    }
    gl.util.checkError();
}

/// caller is responsible for freeing the returned buffer
fn prettifySource(source: [:0]const u8) []u8 {
    const buf = allocator.alloc(u8, 16 * 1024) catch unreachable;
    var line_num: u32 = 1;
    var it = std.mem.split(u8, source, "\n");
    var off: u32 = 0;
    while (it.next()) |s| : (line_num += 1) {
        const ws = std.fmt.bufPrint(buf[off..], "{d:0>4}| {s}\n", .{ line_num, s }) catch unreachable;
        off += @intCast(u32, ws.len);
    }
    std.debug.print("line_num is {d} {d}\n", .{ line_num, off });
    return buf[0..off];
}
