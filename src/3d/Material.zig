const std = @import("std");
const sdl = @import("sdl");
const zp = @import("../lib.zig");
const gl = zp.gl;
const Texture2D = zp.texture.Texture2D;
const Self = @This();

/// material properties
diffuse_map: Texture2D = undefined,
specular_map: Texture2D = undefined,
shiness: f32 = undefined,

/// create a new material
pub fn init(texture: Texture2D, specular: Texture2D, shiness: f32) Self {
    return .{
        .diffuse_map = texture,
        .specular_map = specular,
        .shiness = shiness,
    };
}

/// apply material in the shader
pub fn apply(self: Self, program: *gl.ShaderProgram, uniform_name: [:0]const u8) void {
    const allocator = std.heap.raw_c_allocator;
    var buf = allocator.alloc(u8, uniform_name.len + 64) catch unreachable;
    defer allocator.free(buf);

    program.setUniformByName(
        std.fmt.bufPrintZ(buf, "{s}.diffuse", .{uniform_name}) catch unreachable,
        self.diffuse_map.tex.getTextureUnit(),
    );
    program.setUniformByName(
        std.fmt.bufPrintZ(buf, "{s}.specular", .{uniform_name}) catch unreachable,
        self.specular_map.tex.getTextureUnit(),
    );
    program.setUniformByName(
        std.fmt.bufPrintZ(buf, "{s}.shiness", .{uniform_name}) catch unreachable,
        self.shiness,
    );
}
