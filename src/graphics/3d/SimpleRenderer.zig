const std = @import("std");
const assert = std.debug.assert;
const zp = @import("../../zplay.zig");
const gfx = zp.graphics;
const drawcall = gfx.gpu.drawcall;
const ShaderProgram = gfx.gpu.ShaderProgram;
const VertexArray = gfx.gpu.VertexArray;
const Renderer = gfx.Renderer;
const Camera = gfx.Camera;
const Mesh = gfx.Mesh;
const Material = gfx.Material;
const alg = zp.deps.alg;
const Vec2 = alg.Vec2;
const Vec3 = alg.Vec3;
const Vec4 = alg.Vec4;
const Mat4 = alg.Mat4;
const Self = @This();

const vertex_attribs = [_]u32{
    Renderer.ATTRIB_LOCATION_POS,
    Renderer.ATTRIB_LOCATION_COLOR,
    Renderer.ATTRIB_LOCATION_TEXTURE1,
};

const shader_head =
    \\#version 330 core
    \\
;

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

const vs = shader_head ++ vs_body;
const vs_instanced = shader_head ++ "\n#define INSTANCED_DRAW\n" ++ vs_body;
const fs = shader_head ++ fs_body;
const fs_no_draw = shader_head ++ "\n#define NO_DRAW\n" ++ fs_body;

/// status of renderer
status: Renderer.Status = .not_ready,

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

/// get renderer
pub fn renderer(self: *Self) Renderer {
    return Renderer.init(self, begin, end, getVertexAttribs, render, renderInstanced);
}

/// begin rendering
fn begin(self: *Self, instanced_draw: bool) void {
    if (instanced_draw) {
        self.program_instanced.use();
        self.status = .ready_to_draw_instanced;
    } else {
        self.program.use();
        self.status = .ready_to_draw;
    }
}

/// end rendering
fn end(self: *Self) void {
    assert(self.status != .not_ready);
    self.getProgram().disuse();
    self.status = .not_ready;
}

/// get supported attributes
fn getVertexAttribs(self: *Self) []const u32 {
    _ = self;
    return &vertex_attribs;
}

// get current using shader program
inline fn getProgram(self: *Self) *ShaderProgram {
    assert(self.status != .not_ready);
    return if (self.status == .ready_to_draw) &self.program else &self.program_instanced;
}

/// use material data
fn applyMaterial(self: *Self, material: Material) void {
    switch (material.data) {
        .phong => |m| {
            self.getProgram().setUniformByName("u_texture", m.diffuse_map.getTextureUnit());
        },
        .single_texture => |tex| {
            self.getProgram().setUniformByName("u_texture", tex.getTextureUnit());
        },
        else => {
            std.debug.panic("unsupported material type", .{});
        },
    }
}

/// init common uniform variables
fn initCommonUniformVars(
    self: *Self,
    projection: ?Mat4,
    camera: ?Camera,
    material: ?Material,
) void {
    if (projection) |proj| {
        self.getProgram().setUniformByName("u_project", proj);
    }
    if (camera) |c| {
        self.getProgram().setUniformByName("u_view", c.getViewMatrix());
    } else {
        self.getProgram().setUniformByName("u_view", Mat4.identity());
    }
    if (!self.no_draw) {
        self.getProgram().setUniformByName("u_mix_factor", self.mix_factor);
        if (material) |mr| {
            self.applyMaterial(mr);
        }
    }
}

fn render(
    self: *Self,
    vertex_array: VertexArray,
    use_elements: bool,
    primitive: drawcall.PrimitiveType,
    offset: u32,
    count: u32,
    transform: Mat4,
    projection: ?Mat4,
    camera: ?Camera,
    material: ?Material,
) !void {
    assert(self.status == .ready_to_draw);
    vertex_array.use();
    defer vertex_array.disuse();

    // set uniforms
    self.initCommonUniformVars(projection, camera, material);
    self.program.setUniformByName("u_model", transform);

    if (use_elements) {
        drawcall.drawElements(primitive, offset, count, u32);
    } else {
        drawcall.drawBuffer(primitive, offset, count);
    }
}

pub fn renderInstanced(
    self: *Self,
    vertex_array: VertexArray,
    use_elements: bool,
    primitive: drawcall.PrimitiveType,
    offset: u32,
    count: u32,
    transforms: Renderer.InstanceTransformArray,
    projection: ?Mat4,
    camera: ?Camera,
    material: ?Material,
    instance_count: u32,
) anyerror!void {
    assert(self.status == .ready_to_draw_instanced);
    vertex_array.use();
    defer vertex_array.disuse();

    // enable instance transforms attribute
    transforms.enableAttributes();

    // set uniforms
    self.initCommonUniformVars(projection, camera, material);

    if (use_elements) {
        drawcall.drawElementsInstanced(
            primitive,
            offset,
            count,
            u32,
            instance_count,
        );
    } else {
        drawcall.drawBufferInstanced(
            primitive,
            offset,
            count,
            instance_count,
        );
    }
}
