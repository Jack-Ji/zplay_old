const std = @import("std");
const assert = std.debug.assert;
const zp = @import("../../zplay.zig");
const gfx = zp.graphics;
const Context = gfx.gpu.Context;
const drawcall = gfx.gpu.drawcall;
const ShaderProgram = gfx.gpu.ShaderProgram;
const Material = gfx.Material;
const Renderer = gfx.Renderer;
const alg = zp.deps.alg;
const Vec2 = alg.Vec2;
const Vec3 = alg.Vec3;
const Vec4 = alg.Vec4;
const Mat4 = alg.Mat4;
const Self = @This();

const vs_body =
    \\layout (location = 0) in vec3 a_pos;
    \\layout (location = 1) in vec2 a_tex;
    \\
    \\uniform mat4 u_project;
    \\
    \\out vec2 v_tex;
    \\
    \\void main()
    \\{
    \\    gl_Position = u_project * vec4(a_pos, 1.0);
    \\    v_tex = a_tex;
    \\}
;

const fs_body =
    \\out vec4 frag_color;
    \\
    \\in vec2 v_tex;
    \\
    \\uniform vec3 u_color;
    \\uniform sampler2D u_texture;
    \\
    \\void main()
    \\{
    \\    frag_color = vec4(u_color, texture(u_texture, v_tex).r);
    \\}
;

const vs = Renderer.shader_head ++ vs_body;
const fs = Renderer.shader_head ++ fs_body;

/// shader programs
program: ShaderProgram = undefined,

/// create a simple renderer
pub fn init() Self {
    var self = Self{};
    self.program = ShaderProgram.init(vs, fs, null);
    return self;
}

/// free resources
pub fn deinit(self: *Self) void {
    self.program.deinit();
}

/// get renderer instance
pub fn renderer(self: *Self) Renderer {
    return Renderer.init(self, draw);
}

/// generic rendering implementation
pub fn draw(self: *Self, ctx: *Context, input: Renderer.Input) anyerror!void {
    _ = ctx;
    if (input.vds == null or input.vds.?.items.len == 0) return;
    self.program.use();
    defer self.program.disuse();

    // apply common uniform vars
    var width: u32 = undefined;
    var height: u32 = undefined;
    ctx.getDrawableSize(&width, &height);
    self.program.setUniformByName("u_project", if (input.camera) |c|
        c.getProjectMatrix()
    else
        Mat4.orthographic(0, @intToFloat(f32, width), @intToFloat(f32, height), 0, -1, 1));

    // render vertex data one by one
    var current_material: *Material = undefined;
    for (input.vds.?.items) |vd| {
        if (!vd.valid) continue;
        vd.vertex_array.use();
        defer vd.vertex_array.disuse();

        // apply material
        var material = vd.material orelse input.material;
        if (material) |mr| {
            if (mr != current_material) {
                current_material = mr;
                _ = current_material.allocTextureUnit(0);
                switch (mr.data) {
                    .font => |m| {
                        self.program.setUniformByName("u_color", m.color);
                        self.program.setUniformByName("u_texture", m.atlas.getTextureUnit());
                    },
                    else => {
                        std.debug.panic("unsupported material type", .{});
                    },
                }
            }
        }

        // send draw command
        if (vd.element_draw) {
            drawcall.drawElements(vd.primitive, vd.offset, vd.count, u32);
        } else {
            drawcall.drawBuffer(vd.primitive, vd.offset, vd.count);
        }
    }
}
