const std = @import("std");
const assert = std.debug.assert;
const Camera = @import("Camera.zig");
const Material = @import("Material.zig");
const zp = @import("../../zplay.zig");
const drawcall = zp.graphics.common.drawcall;
const Context = zp.graphics.common.Context;
const ShaderProgram = zp.graphics.common.ShaderProgram;
const VertexArray = zp.graphics.common.VertexArray;
const alg = zp.deps.alg;
const Vec2 = alg.Vec2;
const Vec3 = alg.Vec3;
const Vec4 = alg.Vec4;
const Mat4 = alg.Mat4;
const Self = @This();

/// vertex attribute locations
pub const ATTRIB_LOCATION_POS = 0;

const vs =
    \\#version 330 core
    \\layout (location = 0) in vec3 a_pos;
    \\
    \\uniform mat4 u_view;
    \\uniform mat4 u_project;
    \\
    \\out vec3 v_tex;
    \\
    \\void main()
    \\{
    \\    vec4 pos = u_project * u_view * vec4(a_pos, 1.0);
    \\    gl_Position = pos.xyww;
    \\    v_tex = a_pos;
    \\}
;

const fs =
    \\#version 330 core
    \\out vec4 frag_color;
    \\
    \\in vec3 v_tex;
    \\
    \\uniform samplerCube u_texture;
    \\
    \\void main()
    \\{
    \\    frag_color = texture(u_texture, v_tex);
    \\}
;

/// lighting program
program: ShaderProgram,

/// unit cube
vertex_array: VertexArray,

/// create a simple renderer
pub fn init(allocator: std.mem.Allocator) Self {
    var self = Self{
        .program = ShaderProgram.init(vs, fs, null),
        .vertex_array = VertexArray.init(allocator, 1),
    };

    self.vertex_array.use();
    defer self.vertex_array.disuse();
    self.vertex_array.vbos[0].allocInitData(
        f32,
        &[_]f32{
            -1.0, 1.0,  -1.0,
            -1.0, -1.0, -1.0,
            1.0,  -1.0, -1.0,
            1.0,  -1.0, -1.0,
            1.0,  1.0,  -1.0,
            -1.0, 1.0,  -1.0,

            -1.0, -1.0, 1.0,
            -1.0, -1.0, -1.0,
            -1.0, 1.0,  -1.0,
            -1.0, 1.0,  -1.0,
            -1.0, 1.0,  1.0,
            -1.0, -1.0, 1.0,

            1.0,  -1.0, -1.0,
            1.0,  -1.0, 1.0,
            1.0,  1.0,  1.0,
            1.0,  1.0,  1.0,
            1.0,  1.0,  -1.0,
            1.0,  -1.0, -1.0,

            -1.0, -1.0, 1.0,
            -1.0, 1.0,  1.0,
            1.0,  1.0,  1.0,
            1.0,  1.0,  1.0,
            1.0,  -1.0, 1.0,
            -1.0, -1.0, 1.0,

            -1.0, 1.0,  -1.0,
            1.0,  1.0,  -1.0,
            1.0,  1.0,  1.0,
            1.0,  1.0,  1.0,
            -1.0, 1.0,  1.0,
            -1.0, 1.0,  -1.0,

            -1.0, -1.0, -1.0,
            -1.0, -1.0, 1.0,
            1.0,  -1.0, -1.0,
            1.0,  -1.0, -1.0,
            -1.0, -1.0, 1.0,
            1.0,  -1.0, 1.0,
        },
        .array_buffer,
        .static_draw,
    );
    self.vertex_array.setAttribute(
        0,
        ATTRIB_LOCATION_POS,
        3,
        f32,
        false,
        0,
        0,
    );

    return self;
}

/// free resources
pub fn deinit(self: Self) void {
    self.program.deinit();
    self.vertex_array.deinit();
}

/// draw skybox
pub fn draw(
    self: *Self,
    graphics_context: *Context,
    projection: Mat4,
    camera: Camera,
    material: Material,
) void {
    const old_polygon_mode = graphics_context.polygon_mode;
    graphics_context.setPolygonMode(.fill);
    defer graphics_context.setPolygonMode(old_polygon_mode);

    const old_depth_option = graphics_context.depth_option;
    graphics_context.setDepthOption(.{ .test_func = .less_or_equal });
    defer graphics_context.setDepthOption(old_depth_option);

    self.program.use();
    defer self.program.disuse();

    self.vertex_array.use();
    defer self.vertex_array.disuse();

    // set uniforms
    var view = camera.getViewMatrix();
    view.data[3][0] = 0;
    view.data[3][1] = 0;
    view.data[3][2] = 0;
    self.program.setUniformByName("u_view", view);
    self.program.setUniformByName("u_project", projection);
    assert(material.data == .single_cubemap);
    self.program.setUniformByName(
        "u_texture",
        material.data.single_cubemap.tex.getTextureUnit(),
    );

    // issue draw call
    drawcall.drawBuffer(
        .triangles,
        0,
        36,
        null,
    );
}
