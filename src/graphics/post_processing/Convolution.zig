const std = @import("std");
const assert = std.debug.assert;
const zp = @import("../../zplay.zig");
const gfx = zp.graphics;
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

/// kernel used for convolution computing
pub const Kernel = struct {
    data: [9]f32, // row-major

    pub fn initShapen() Kernel {
        return .{
            .data = .{
                -1.0, -1.0, -1.0,
                -1.0, 9.0,  -1.0,
                -1.0, -1.0, -1.0,
            },
        };
    }

    pub fn initBlur() Kernel {
        return .{
            .data = .{
                1.0 / 16.0, 2.0 / 16.0, 1.0 / 16.0,
                2.0 / 16.0, 4.0 / 16.0, 2.0 / 16.0,
                1.0 / 16.0, 2.0 / 16.0, 1.0 / 16.0,
            },
        };
    }

    pub fn initEdgeDetection() Kernel {
        return .{
            .data = .{
                1.0, 1.0,  1.0,
                1.0, -8.0, 1.0,
                1.0, 1.0,  1.0,
            },
        };
    }
};

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
    \\uniform sampler2D u_texture;
    \\uniform float u_kernel[9];
    \\
    \\const float offset = 1.0 / 300.0;
    \\
    \\void main()
    \\{
    \\    vec2 offsets[9] = vec2[](
    \\        vec2(-offset,  offset), // top-left
    \\        vec2( 0.0f,    offset), // top-center
    \\        vec2( offset,  offset), // top-right
    \\        vec2(-offset,  0.0f),   // center-left
    \\        vec2( 0.0f,    0.0f),   // center-center
    \\        vec2( offset,  0.0f),   // center-right
    \\        vec2(-offset, -offset), // bottom-left
    \\        vec2( 0.0f,   -offset), // bottom-center
    \\        vec2( offset, -offset)  // bottom-right
    \\    );
    \\
    \\    vec3 sample_color[9];
    \\    for (int i = 0; i < 9; ++i)
    \\        sample_color[i] = vec3(texture(u_texture, v_tex + offsets[i]));
    \\    vec3 color = vec3(0.0);
    \\    for (int i = 0; i < 9; ++i)
    \\        color += sample_color[i] * u_kernel[i];
    \\    frag_color = vec4(color, 1.0);
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
pub fn draw(self: *Self, input: Renderer.Input) anyerror!void {
    const graphics_context = input.ctx;
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
        input.material.?.data.single_texture.getTextureUnit(),
    );
    const kernel = @ptrCast(*align(1) const Kernel, input.custom.?);
    self.program.setUniformByName("u_kernel", kernel.data[0..]);

    // issue draw call
    drawcall.drawElements(
        self.quad.primitive_type,
        0,
        @intCast(u32, self.quad.indices.items.len),
        u32,
    );
}
