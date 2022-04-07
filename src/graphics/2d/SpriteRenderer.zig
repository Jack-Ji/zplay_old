const std = @import("std");
const assert = std.debug.assert;
const zp = @import("../../zplay.zig");
const gfx = zp.graphics;
const Context = gfx.gpu.Context;
const VertexArray = gfx.gpu.VertexArray;
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
    \\layout (location = 1) in vec4 a_color;
    \\layout (location = 2) in vec2 a_tex;
    \\layout (location = 3) in mat4 a_transform;
    \\
    \\uniform mat4 u_project;
    \\
    \\out vec3 v_pos;
    \\out vec4 v_color;
    \\out vec2 v_tex;
    \\
    \\void main()
    \\{
    \\    v_pos = vec3(a_transform * vec4(a_pos, 1.0));
    \\    v_color = a_color;
    \\    v_tex = a_tex;
    \\    gl_Position = u_project * vec4(v_pos, 1.0);
    \\}
;

const fs_body =
    \\out vec4 frag_color;
    \\
    \\in vec3 v_pos;
    \\in vec4 v_color;
    \\in vec2 v_tex;
    \\
    \\uniform sampler2D u_texture;
    \\
    \\void main()
    \\{
    \\    frag_color = v_color * texture(u_texture, v_tex);
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

/// get vertex array ready for rendering sprites
pub fn setupVertexArray(va: VertexArray) void {
    assert(va.vbo_num > 1);
    va.use();
    defer va.disuse();
    va.setAttribute(0, 0, 3, f32, false, 9 * @sizeOf(f32), 0);
    va.setAttribute(0, 1, 3, f32, false, 9 * @sizeOf(f32), 3 * @sizeOf(f32));
    va.setAttribute(0, 2, 2, f32, false, 9 * @sizeOf(f32), 7 * @sizeOf(f32));
    va.setAttribute(1, 3, 4, f32, false, @sizeOf(Mat4), 0);
    va.setAttribute(1, 4, 4, f32, false, @sizeOf(Mat4), 4 * @sizeOf(f32));
    va.setAttribute(1, 5, 4, f32, false, @sizeOf(Mat4), 8 * @sizeOf(f32));
    va.setAttribute(1, 6, 4, f32, false, @sizeOf(Mat4), 12 * @sizeOf(f32));
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
    self.program.setUniformByName("u_project", if (input.camera) |c|
        c.getProjectMatrix()
    else blk: {
        var width: u32 = undefined;
        var height: u32 = undefined;
        ctx.getDrawableSize(&width, &height);
        var mat = Mat4.orthographic(0, @intToFloat(f32, width), @intToFloat(f32, height), 0, -1, 1);
        break :blk mat;
    });

    // render vertex data one by one
    var current_material: *Material = undefined;
    for (input.vds.?.items) |vd| {
        if (!vd.valid) continue;
        if (vd.count == 0) continue;
        vd.vertex_array.use();
        defer vd.vertex_array.disuse();

        // apply material
        var material = vd.material orelse input.material;
        if (material) |mr| {
            if (mr != current_material) {
                current_material = mr;
                _ = current_material.allocTextureUnit(0);
                switch (mr.data) {
                    .phong => |m| {
                        self.program.setUniformByName("u_texture", m.diffuse_map.getTextureUnit());
                    },
                    .single_texture => |tex| {
                        self.program.setUniformByName("u_texture", tex.getTextureUnit());
                    },
                    else => {
                        std.debug.panic("unsupported material type", .{});
                    },
                }
            }
        }

        // send draw command
        drawcall.drawBuffer(vd.primitive, vd.offset, vd.count);
    }
}
