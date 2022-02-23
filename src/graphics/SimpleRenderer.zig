const std = @import("std");
const assert = std.debug.assert;
const zp = @import("../zplay.zig");
const gfx = zp.graphics;
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
    \\layout (location = 4) in vec2 a_tex1;
    \\layout (location = 10) in mat4 a_transform;
    \\
    \\uniform mat4 u_model = mat4(1.0);
    \\uniform mat4 u_view = mat4(1.0);
    \\uniform mat4 u_project = mat4(1.0);
    \\
    \\out vec3 v_pos;
    \\out vec2 v_tex;
    \\out vec4 v_color;
    \\
    \\void main()
    \\{
    \\#ifdef INSTANCED_DRAW
    \\    v_pos = vec3(a_transform * vec4(a_pos, 1.0));
    \\#else
    \\    v_pos = vec3(u_model * vec4(a_pos, 1.0));
    \\#endif
    \\    gl_Position = u_project * u_view * vec4(v_pos, 1.0);
    \\    v_tex = a_tex1;
    \\    v_color = a_color;
    \\}
;

const fs_body =
    \\out vec4 frag_color;
    \\
    \\in vec3 v_pos;
    \\in vec2 v_tex;
    \\in vec4 v_color;
    \\
    \\uniform sampler2D u_texture;
    \\uniform float u_mix_factor;
    \\
    \\void main()
    \\{
    \\#ifndef NO_DRAW
    \\    frag_color = mix(texture(u_texture, v_tex), v_color, u_mix_factor);
    \\#endif
    \\}
;

const vs = Renderer.shader_head ++ vs_body;
const vs_instanced = Renderer.shader_head ++ "\n#define INSTANCED_DRAW\n" ++ vs_body;
const fs = Renderer.shader_head ++ fs_body;
const fs_no_draw = Renderer.shader_head ++ "\n#define NO_DRAW\n" ++ fs_body;

/// shader programs
program: ShaderProgram = undefined,
program_instanced: ShaderProgram = undefined,

/// rendering options
mix_factor: f32 = undefined,
no_draw: bool = undefined,

/// rendering options
pub const Option = struct {
    mix_factor: f32 = 0,
    no_draw: bool = false,
};

/// create a simple renderer
pub fn init(option: Option) Self {
    var self = Self{};
    self.mix_factor = option.mix_factor;
    self.no_draw = option.no_draw;
    if (self.no_draw) {
        self.program = ShaderProgram.init(vs, fs_no_draw, null);
        self.program_instanced = ShaderProgram.init(vs_instanced, fs_no_draw, null);
    } else {
        self.program = ShaderProgram.init(vs, fs, null);
        self.program_instanced = ShaderProgram.init(vs_instanced, fs, null);
    }
    return self;
}

/// free resources
pub fn deinit(self: *Self) void {
    self.program.deinit();
    self.program_instanced.deinit();
}

/// get renderer instance
pub fn renderer(self: *Self) Renderer {
    return Renderer.init(self, draw);
}

/// generic rendering implementation
pub fn draw(self: *Self, input: Renderer.Input) anyerror!void {
    if (input.vds == null or input.vds.?.items.len == 0) return;
    var is_instanced_drawing = input.vds.?.items[0].transform == .instanced;
    var prog = if (is_instanced_drawing) &self.program_instanced else &self.program;
    prog.use();
    defer prog.disuse();

    // apply common uniform vars
    prog.setUniformByName("u_project", input.projection orelse Mat4.identity());
    prog.setUniformByName("u_view", if (input.camera) |c| c.getViewMatrix() else Mat4.identity());
    if (!self.no_draw) {
        prog.setUniformByName("u_mix_factor", self.mix_factor);
    }

    // render vertex data one by one
    var current_material: *Material = undefined;
    for (input.vds.?.items) |vd| {
        vd.vertex_array.use();
        defer vd.vertex_array.disuse();

        // apply material
        if (!self.no_draw) {
            var material = vd.material orelse input.material;
            if (material) |mr| {
                if (mr != current_material) {
                    switch (mr.data) {
                        .phong => |m| {
                            prog.setUniformByName("u_texture", m.diffuse_map.getTextureUnit());
                        },
                        .single_texture => |tex| {
                            prog.setUniformByName("u_texture", tex.getTextureUnit());
                        },
                        else => {
                            std.debug.panic("unsupported material type", .{});
                        },
                    }
                }
            }
        }

        // send draw command
        if (is_instanced_drawing) {
            vd.transform.instanced.enableAttributes();
            if (vd.element_draw) {
                drawcall.drawElementsInstanced(
                    vd.primitive,
                    vd.offset,
                    vd.count,
                    u32,
                    vd.transform.instanced.count,
                );
            } else {
                drawcall.drawBufferInstanced(
                    vd.primitive,
                    vd.offset,
                    vd.count,
                    vd.transform.instanced.count,
                );
            }
        } else {
            prog.setUniformByName("u_model", vd.transform.single);
            if (vd.element_draw) {
                drawcall.drawElements(vd.primitive, vd.offset, vd.count, u32);
            } else {
                drawcall.drawBuffer(vd.primitive, vd.offset, vd.count);
            }
        }
    }
}
