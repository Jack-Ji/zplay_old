const std = @import("std");
const assert = std.debug.assert;
const Light = @import("Light.zig");
const zp = @import("../../zplay.zig");
const gfx = zp.graphics;
const drawcall = gfx.common.drawcall;
const ShaderProgram = gfx.common.ShaderProgram;
const VertexArray = gfx.common.VertexArray;
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

const vs =
    \\#version 330 core
    \\layout (location = 0) in vec3 a_pos;
    \\layout (location = 1) in vec4 a_color;
    \\layout (location = 4) in vec2 a_tex1;
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
    \\    gl_Position = u_project * u_view * u_model * vec4(a_pos, 1.0);
    \\    v_pos = vec3(u_model * vec4(a_pos, 1.0));
    \\    v_tex = a_tex1;
    \\    v_color = a_color;
    \\}
;

const vs_instanced =
    \\#version 330 core
    \\layout (location = 0) in vec3 a_pos;
    \\layout (location = 1) in vec4 a_color;
    \\layout (location = 4) in vec2 a_tex1;
    \\layout (location = 10) in mat4 a_transform;
    \\
    \\uniform mat4 u_view = mat4(1.0);
    \\uniform mat4 u_project = mat4(1.0);
    \\
    \\out vec3 v_pos;
    \\out vec2 v_tex;
    \\out vec4 v_color;
    \\
    \\void main()
    \\{
    \\    gl_Position = u_project * u_view * a_transform * vec4(a_pos, 1.0);
    \\    v_pos = vec3(a_transform * vec4(a_pos, 1.0));
    \\    v_tex = a_tex1;
    \\    v_color = a_color;
    \\}
;

const fs =
    \\#version 330 core
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
    \\    frag_color = mix(texture(u_texture, v_tex), v_color, u_mix_factor);
    \\}
;

/// status of renderer
status: Renderer.Status = .not_ready,

/// shader programs
program: ShaderProgram,
program_instanced: ShaderProgram,

/// factor used to mix texture and vertex's colors
mix_factor: f32 = 0,

/// create a simple renderer
pub fn init() Self {
    return .{
        .program = ShaderProgram.init(vs, fs, null),
        .program_instanced = ShaderProgram.init(vs_instanced, fs, null),
    };
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
            self.getProgram().setUniformByName("u_texture", m.diffuse_map.tex.getTextureUnit());
        },
        .single_texture => |t| {
            self.getProgram().setUniformByName("u_texture", t.tex.getTextureUnit());
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
    self.getProgram().setUniformByName("u_mix_factor", self.mix_factor);
    if (material) |mr| {
        self.applyMaterial(mr);
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
