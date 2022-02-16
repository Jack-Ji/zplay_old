const std = @import("std");
const assert = std.debug.assert;
const zp = @import("../../zplay.zig");
const gfx = zp.graphics;
const drawcall = gfx.gpu.drawcall;
const Context = gfx.gpu.Context;
const ShaderProgram = gfx.gpu.ShaderProgram;
const Renderer = gfx.Renderer;
const Material = gfx.Material;
const Mesh = gfx.Mesh;
const alg = zp.deps.alg;
const Vec2 = alg.Vec2;
const Vec3 = alg.Vec3;
const Vec4 = alg.Vec4;
const Mat4 = alg.Mat4;
const Self = @This();

const vs =
    \\#version 330 core
    \\layout (location = 0) in vec3 a_pos;
    \\layout (location = 4) in vec2 a_tex;
    \\
    \\out vec2 v_tex;
    \\
    \\void main()
    \\{
    \\    gl_Position = vec4(a_pos, 1.0);
    \\    v_tex = a_tex;
    \\}
;

const fs =
    \\#version 330 core
    \\out vec4 frag_color;
    \\
    \\in vec2 v_tex;
    \\
    \\uniform float u_gamma;
    \\uniform sampler2D u_texture;
    \\
    \\void main()
    \\{
    \\    frag_color = texture(u_texture, v_tex);
    \\    frag_color.rgb = pow(frag_color.rgb, vec3(1.0/u_gamma));
    \\}
;

/// lighting program
program: ShaderProgram,

/// quad
quad: Mesh,

/// init gmma-correction instance
pub fn init(allocator: std.mem.Allocator) !Self {
    var self = Self{
        .program = ShaderProgram.init(vs, fs, null),
        .quad = try Mesh.genQuad(allocator, 2, 2),
    };

    self.quad.vertex_array.?.use();
    defer self.quad.vertex_array.?.disuse();
    self.quad.enableAttributes(&.{ .position, .texture1 });

    return self;
}

/// free resources
pub fn deinit(self: Self) void {
    self.program.deinit();
    self.quad.deinit();
}

/// draw texture with gamma correction
pub fn draw(
    self: *Self,
    graphics_context: *Context,
    material: Material,
    gamma: ?f32,
) void {
    const old_depth_test_status = graphics_context.isCapabilityEnabled(.depth_test);
    graphics_context.toggleCapability(.depth_test, false);
    defer graphics_context.toggleCapability(.depth_test, old_depth_test_status);

    const old_polygon_mode = graphics_context.polygon_mode;
    graphics_context.setPolygonMode(.fill);
    defer graphics_context.setPolygonMode(old_polygon_mode);

    self.program.use();
    defer self.program.disuse();

    self.quad.vertex_array.?.use();
    defer self.quad.vertex_array.?.disuse();

    // set uniforms
    self.program.setUniformByName(
        "u_texture",
        material.data.single_texture.getTextureUnit(),
    );
    self.program.setUniformByName(
        "u_gamma",
        gamma orelse 2.2,
    );

    // issue draw call
    drawcall.drawElements(
        self.quad.primitive_type,
        0,
        @intCast(u32, self.quad.indices.items.len),
        u32,
    );
}
