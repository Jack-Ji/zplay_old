const std = @import("std");
const assert = std.debug.assert;
const Mesh = @import("Mesh.zig");
const zp = @import("../../zplay.zig");
const gfx = zp.graphics;
const Context = gfx.gpu.Context;
const drawcall = gfx.gpu.drawcall;
const ShaderProgram = gfx.gpu.ShaderProgram;
const Renderer = gfx.Renderer;
const Material = gfx.Material;
const alg = zp.deps.alg;
const Mat4 = alg.Mat4;
const Vec2 = alg.Vec2;
const Vec3 = alg.Vec3;
const Self = @This();

const vs_body =
    \\layout (location = 0) in vec3 a_pos;
    \\layout (location = 2) in vec3 a_normal;
    \\layout (location = 10) in mat4 a_transform;
    \\
    \\out vec3 v_pos;
    \\out vec3 v_normal;
    \\
    \\uniform mat4 u_model = mat4(1.0);
    \\uniform mat4 u_normal = mat4(1.0);
    \\uniform mat4 u_view = mat4(1.0);
    \\uniform mat4 u_project = mat4(1.0);
    \\
    \\void main()
    \\{
    \\#ifdef INSTANCED_DRAW
    \\    v_pos = vec3(a_transform * vec4(a_pos, 1.0));
    \\    v_normal = mat3(transpose(inverse(a_transform))) * a_normal;
    \\#else
    \\    v_pos = vec3(u_model * vec4(a_pos, 1.0));
    \\    v_normal = mat3(u_normal) * a_normal;
    \\#endif
    \\    gl_Position = u_project * u_view * vec4(v_pos, 1.0);
    \\    v_pos = vec3(u_model * vec4(a_pos, 1.0));
    \\}
;

const fs_body =
    \\out vec4 frag_color;
    \\
    \\in vec3 v_pos;
    \\in vec3 v_normal;
    \\
    \\uniform vec3 u_view_pos;
    \\uniform samplerCube u_texture;
    \\
    \\#ifdef RETRACT_MAPPING
    \\uniform float u_ratio;
    \\#endif
    \\
    \\void main()
    \\{
    \\    vec3 view_dir = normalize(v_pos - u_view_pos);
    \\#ifdef REFLECT_MAPPING
    \\    vec3 mapping_dir = reflect(view_dir, v_normal);
    \\#elif defined(RETRACT_MAPPING)
    \\    vec3 mapping_dir = refract(view_dir, v_normal, u_ratio);
    \\#endif
    \\    frag_color = vec4(texture(u_texture, mapping_dir).rgb, 1.0);
    \\}
;

const vs = Renderer.shader_head ++ vs_body;
const vs_instanced = Renderer.shader_head ++ "\n#define INSTANCED_DRAW\n" ++ vs_body;
const fs_reflect = Renderer.shader_head ++ "\n#define REFLECT_MAPPING\n" ++ fs_body;
const fs_retract = Renderer.shader_head ++ "\n#define RETRACT_MAPPING\n" ++ fs_body;

// environment mapping type
const Type = enum {
    reflect,
    refract,
};

/// lighting program
program: ShaderProgram,
program_instanced: ShaderProgram,

/// type of mapping
type: Type,

/// create a Phong lighting renderer
pub fn init(t: Type) Self {
    return .{
        .program = ShaderProgram.init(
            vs,
            switch (t) {
                .reflect => fs_reflect,
                .refract => fs_retract,
            },
            null,
        ),
        .program_instanced = ShaderProgram.init(
            vs_instanced,
            switch (t) {
                .reflect => fs_reflect,
                .refract => fs_retract,
            },
            null,
        ),
        .type = t,
    };
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
pub fn draw(self: *Self, ctx: *Context, input: Renderer.Input) anyerror!void {
    _ = ctx;
    assert(input.vds.?.items.len > 0);
    var is_instanced_drawing = input.vds.?.items[0].transform == .instanced;
    var prog = if (is_instanced_drawing) &self.program_instanced else &self.program;
    prog.use();
    defer prog.disuse();

    // set uniforms
    prog.setUniformByName("u_project", input.camera.?.getProjectMatrix());
    prog.setUniformByName("u_view", input.camera.?.getViewMatrix());
    prog.setUniformByName("u_view_pos", input.camera.?.position);

    // render vertex data one by one
    var current_material: *Material = undefined;
    for (input.vds.?.items) |vd| {
        if (!vd.valid) continue;
        vd.vertex_array.use();
        defer vd.vertex_array.disuse();

        // apply material
        var mr: *Material = input.material orelse vd.material.?;
        if (mr != current_material) {
            current_material = mr;
            _ = current_material.allocTextureUnit(0);
            switch (self.type) {
                .reflect => {
                    assert(mr.data == .single_cubemap);
                    prog.setUniformByName(
                        "u_texture",
                        mr.data.single_cubemap.getTextureUnit(),
                    );
                },
                .refract => {
                    assert(mr.data == .refract_mapping);
                    prog.setUniformByName(
                        "u_texture",
                        mr.data.refract_mapping.cubemap.getTextureUnit(),
                    );
                    prog.setUniformByName(
                        "u_ratio",
                        1.0 / mr.data.refract_mapping.ratio,
                    );
                },
            }
        }

        // send draw command
        if (is_instanced_drawing) {
            vd.transform.instanced.enableAttributes(
                @enumToInt(Mesh.AttribLocation.instance_transform),
            );
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
            prog.setUniformByName("u_normal", vd.transform.single.inv().transpose());
            if (vd.element_draw) {
                drawcall.drawElements(vd.primitive, vd.offset, vd.count, u32);
            } else {
                drawcall.drawBuffer(vd.primitive, vd.offset, vd.count);
            }
        }
    }
}
