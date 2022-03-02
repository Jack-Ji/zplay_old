const std = @import("std");
const assert = std.debug.assert;
const zp = @import("../../zplay.zig");
const gfx = zp.graphics;
const Context = gfx.gpu.Context;
const drawcall = gfx.gpu.drawcall;
const ShaderProgram = gfx.gpu.ShaderProgram;
const Renderer = gfx.Renderer;
const Mesh = gfx.Mesh;
const alg = zp.deps.alg;
const Vec2 = alg.Vec2;
const Vec3 = alg.Vec3;
const Vec4 = alg.Vec4;
const Mat4 = alg.Mat4;
const Self = @This();

const vs = Renderer.shader_head ++
    \\layout (location = 0) in vec3 a_pos;
    \\layout (location = 4) in vec2 a_tex;
    \\
    \\out vec2 v_tex;
    \\
    \\uniform mat4 u_transform;
    \\
    \\void main()
    \\{
    \\    gl_Position = u_transform * vec4(a_pos, 1.0);
    \\    v_tex = a_tex;
    \\}
;

const fs = Renderer.shader_head ++
    \\out vec4 frag_color;
    \\
    \\in vec2 v_tex;
    \\
    \\uniform sampler2D u_texture;
    \\
    \\void main()
    \\{
    \\    frag_color = texture(u_texture, v_tex);
    \\}
;

/// lighting program
program: ShaderProgram,

/// quad
quad: Mesh,

/// init gmma-correction instance
pub fn init(allocator: std.mem.Allocator) !Self {
    return Self{
        .program = ShaderProgram.init(vs, fs, null),
        .quad = try Mesh.genQuad(allocator, 2, 2),
    };
}

/// free resources
pub fn deinit(self: Self) void {
    self.program.deinit();
    self.quad.deinit();
}

/// get renderer instance
pub fn renderer(self: *Self) Renderer {
    return Renderer.init(self, draw);
}

/// generic rendering implementation
pub fn draw(self: *Self, ctx: *Context, input: Renderer.Input) anyerror!void {
    const old_depth_test_status = ctx.isCapabilityEnabled(.depth_test);
    ctx.toggleCapability(.depth_test, false);
    defer ctx.toggleCapability(.depth_test, old_depth_test_status);

    const old_polygon_mode = ctx.polygon_mode;
    ctx.setPolygonMode(.fill);
    defer ctx.setPolygonMode(old_polygon_mode);

    self.program.use();
    defer self.program.disuse();

    self.quad.vertex_array.?.use();
    defer self.quad.vertex_array.?.disuse();

    // apply aterial
    _ = input.material.?.allocTextureUnit(0);

    // set uniforms
    self.program.setUniformByName(
        "u_texture",
        input.material.?.data.single_texture.getTextureUnit(),
    );
    const transform = if (input.custom) |ptr| @ptrCast(*align(1) const Mat4, ptr).* else Mat4.identity();
    self.program.setUniformByName("u_transform", transform);

    // issue draw call
    drawcall.drawElements(
        self.quad.primitive_type,
        0,
        @intCast(u32, self.quad.indices.items.len),
        u32,
    );
}
