const std = @import("std");
const assert = std.debug.assert;
const Camera = @import("Camera.zig");
const Material = @import("Material.zig");
const Mesh = @import("Mesh.zig");
const Renderer = @import("Renderer.zig");
const zp = @import("../../zplay.zig");
const drawcall = zp.graphics.common.drawcall;
const ShaderProgram = zp.graphics.common.ShaderProgram;
const VertexArray = zp.graphics.common.VertexArray;
const alg = zp.deps.alg;
const Mat4 = alg.Mat4;
const Vec2 = alg.Vec2;
const Vec3 = alg.Vec3;
const Self = @This();

const vertex_attribs = [_]u32{
    Renderer.ATTRIB_LOCATION_POS,
    Renderer.ATTRIB_LOCATION_NORMAL,
};

const vs =
    \\#version 330 core
    \\layout (location = 0) in vec3 a_pos;
    \\layout (location = 2) in vec3 a_normal;
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
    \\    gl_Position = u_project * u_view * u_model * vec4(a_pos, 1.0);
    \\    v_pos = vec3(u_model * vec4(a_pos, 1.0));
    \\    v_normal = mat3(u_normal) * a_normal;
    \\}
;

const vs_instanced =
    \\#version 330 core
    \\layout (location = 0) in vec3 a_pos;
    \\layout (location = 2) in vec3 a_normal;
    \\layout (location = 10) in mat4 a_transform;
    \\
    \\out vec3 v_pos;
    \\out vec3 v_normal;
    \\
    \\uniform mat4 u_view = mat4(1.0);
    \\uniform mat4 u_project = mat4(1.0);
    \\
    \\void main()
    \\{
    \\    gl_Position = u_project * u_view * a_transform * vec4(a_pos, 1.0);
    \\    v_pos = vec3(a_transform * vec4(a_pos, 1.0));
    \\    v_normal = mat3(transpose(inverse(a_transform))) * a_normal;
    \\}
;

const reflect_fs =
    \\#version 330 core
    \\out vec4 frag_color;
    \\
    \\in vec3 v_pos;
    \\in vec3 v_normal;
    \\
    \\uniform vec3 u_view_pos;
    \\uniform samplerCube u_texture;
    \\
    \\void main()
    \\{
    \\    vec3 view_dir = normalize(v_pos - u_view_pos);
    \\    vec3 reflect_dir = reflect(view_dir, v_normal);
    \\    frag_color = vec4(texture(u_texture, reflect_dir).rgb, 1.0);
    \\}
;

const refract_fs =
    \\#version 330 core
    \\out vec4 frag_color;
    \\
    \\in vec3 v_pos;
    \\in vec3 v_normal;
    \\
    \\uniform vec3 u_view_pos;
    \\uniform samplerCube u_texture;
    \\uniform float u_ratio;
    \\
    \\void main()
    \\{
    \\    vec3 view_dir = normalize(v_pos - u_view_pos);
    \\    vec3 refract_dir = refract(view_dir, v_normal, u_ratio);
    \\    frag_color = vec4(texture(u_texture, refract_dir).rgb, 1.0);
    \\}
;

// environment mapping type
const Type = enum {
    reflect,
    refract,
};

/// status of renderer
status: Renderer.Status = .not_ready,

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
                .reflect => reflect_fs,
                .refract => refract_fs,
            },
            null,
        ),
        .program_instanced = ShaderProgram.init(
            vs_instanced,
            switch (t) {
                .reflect => reflect_fs,
                .refract => refract_fs,
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
    switch (self.type) {
        .reflect => {
            assert(material.data == .single_cubemap);
            self.getProgram().setUniformByName(
                "u_texture",
                material.data.single_cubemap.tex.getTextureUnit(),
            );
        },
        .refract => {
            assert(material.data == .refract_mapping);
            self.getProgram().setUniformByName(
                "u_texture",
                material.data.refract_mapping.cubemap.tex.getTextureUnit(),
            );
            self.getProgram().setUniformByName(
                "u_ratio",
                1.0 / material.data.refract_mapping.ratio,
            );
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
    self.getProgram().setUniformByName("u_project", projection.?);
    self.getProgram().setUniformByName("u_view", camera.?.getViewMatrix());
    self.getProgram().setUniformByName("u_view_pos", camera.?.position);
    self.applyMaterial(material.?);
}

/// render geometries
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
    self.program.setUniformByName("u_normal", transform.inv().transpose());

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
