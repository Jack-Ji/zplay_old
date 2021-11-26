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

pub const Capability = enum(c_uint) {
    blend = gl.GL_BLEND,
    color_logic_op = gl.GL_COLOR_LOGIC_OP,
    cull_face = gl.GL_CULL_FACE,
    depth_clamp = gl.GL_DEPTH_CLAMP,
    depth_test = gl.GL_DEPTH_TEST,
    dither = gl.GL_DITHER,
    framebuffer_srgb = gl.GL_FRAMEBUFFER_SRGB,
    line_smooth = gl.GL_LINE_SMOOTH,
    multisample = gl.GL_MULTISAMPLE,
    polygon_offset_fill = gl.GL_POLYGON_OFFSET_FILL,
    polygon_offset_line = gl.GL_POLYGON_OFFSET_LINE,
    polygon_offset_point = gl.GL_POLYGON_OFFSET_POINT,
    polygon_smooth = gl.GL_POLYGON_SMOOTH,
    primitive_restart = gl.GL_PRIMITIVE_RESTART,
    rasterizer_discard = gl.GL_RASTERIZER_DISCARD,
    sample_alpha_to_coverage = gl.GL_SAMPLE_ALPHA_TO_COVERAGE,
    sample_alpha_to_one = gl.GL_SAMPLE_ALPHA_TO_ONE,
    sample_coverage = gl.GL_SAMPLE_COVERAGE,
    sample_mask = gl.GL_SAMPLE_MASK,
    scissor_test = gl.GL_SCISSOR_TEST,
    stencil_test = gl.GL_STENCIL_TEST,
    texture_cube_map_seamless = gl.GL_TEXTURE_CUBE_MAP_SEAMLESS,
    program_point_size = gl.GL_PROGRAM_POINT_SIZE,
};

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

/// toggle opengl capability
pub fn toggleCapability(cap: Capability, on_off: bool) void {
    if (on_off) {
        gl.enable(@enumToInt(cap));
    } else {
        gl.disable(@enumToInt(cap));
    }
    checkError();
}

/// clear buffers
pub fn clear(
    clear_color: bool,
    clear_depth: bool,
    clear_stencil: bool,
    color: ?[4]f32,
) void {
    var clear_flags: c_uint = 0;
    if (clear_color) {
        clear_flags |= gl.GL_COLOR_BUFFER_BIT;
    }
    if (clear_depth) {
        clear_flags |= gl.GL_DEPTH_BUFFER_BIT;
    }
    if (clear_stencil) {
        clear_flags |= gl.GL_STENCIL_BUFFER_BIT;
    }
    if (color) |rgba| {
        gl.clearColor(rgba[0], rgba[1], rgba[2], rgba[3]);
    }
    gl.clear(clear_flags);
    checkError();
}

/// issue draw call
pub fn drawBuffer(primitive: PrimitiveType, offset: usize, vertex_count: usize, instance_count: ?usize) void {
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
    checkError();
}

/// issue draw call (only accept unsigned-integer indices!)
pub fn drawElements(primitive: PrimitiveType, offset: usize, element_count: usize, instance_count: ?usize) void {
    if (instance_count) |count| {
        gl.drawElementsInstanced(
            @enumToInt(primitive),
            @intCast(gl.GLsizei, element_count),
            dataType(u16),
            @intToPtr(*allowzero c_void, offset),
            @intCast(gl.GLsizei, count),
        );
    } else {
        gl.drawElements(
            @enumToInt(primitive),
            @intCast(gl.GLsizei, element_count),
            dataType(u16),
            @intToPtr(*allowzero c_void, offset),
        );
    }
    checkError();
}
