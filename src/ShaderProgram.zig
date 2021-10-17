const std = @import("std");
const gl = @import("gl/gl.zig");
const zlm = @import("zlm/zlm.zig");
const Self = @This();

/// id of shader program
id: gl.GLuint,

/// init shader program
pub fn init(
    vs_source: [*:0]const u8,
    fs_source: [*:0]const u8,
) Self {
    var program: Self = undefined;
    var success: gl.GLint = undefined;
    var shader_log: [512]gl.GLchar = undefined;
    var log_size: gl.GLsizei = undefined;

    // vertex shader
    var vshader = gl.createShader(gl.GL_VERTEX_SHADER);
    defer gl.deleteShader(vshader);
    gl.shaderSource(vshader, 1, &vs_source, null);
    gl.compileShader(vshader);
    gl.getShaderiv(vshader, gl.GL_COMPILE_STATUS, &success);
    if (success == 0) {
        gl.getShaderInfoLog(vshader, 512, &log_size, &shader_log);
        std.debug.panic("compile vertex shader failed: {s}", .{shader_log[0..@intCast(usize, log_size)]});
    }

    // fragment shader
    var fshader = gl.createShader(gl.GL_FRAGMENT_SHADER);
    defer gl.deleteShader(fshader);
    gl.shaderSource(fshader, 1, &fs_source, null);
    gl.compileShader(fshader);
    gl.getShaderiv(fshader, gl.GL_COMPILE_STATUS, &success);
    if (success == 0) {
        gl.getShaderInfoLog(fshader, 512, &log_size, &shader_log);
        std.debug.panic("compile fragment shader failed: {s}", .{shader_log[0..@intCast(usize, log_size)]});
    }

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

    return program;
}
