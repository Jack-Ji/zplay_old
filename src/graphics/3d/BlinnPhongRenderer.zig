const std = @import("std");
const assert = std.debug.assert;
const Light = @import("Light.zig");
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
const Mat4 = alg.Mat4;
const Vec2 = alg.Vec2;
const Vec3 = alg.Vec3;
const Self = @This();

const max_point_light_num = 16;
const max_spot_light_num = 16;

pub const Error = error{
    TooManyPointLights,
    TooManySpotLights,
};

const vertex_attribs = [_]u32{
    Renderer.ATTRIB_LOCATION_POS,
    Renderer.ATTRIB_LOCATION_NORMAL,
    Renderer.ATTRIB_LOCATION_TEXTURE1,
};

const vs = @embedFile("shaders/phong.vert");
const vs_instanced = @embedFile("shaders/phong_instanced.vert");
const fs = @embedFile("shaders/blinn_phong.frag");

/// status of renderer
status: Renderer.Status = .not_ready,

/// shader programs
program: ShaderProgram = undefined,
program_instanced: ShaderProgram,

/// various lights
dir_light: Light = undefined,
point_lights: std.ArrayList(Light) = undefined,
spot_lights: std.ArrayList(Light) = undefined,

/// create a Phong lighting renderer
pub fn init(allocator: std.mem.Allocator) Self {
    return .{
        .program = ShaderProgram.init(vs, fs, null),
        .program_instanced = ShaderProgram.init(vs_instanced, fs, null),
        .dir_light = Light.init(
            .{
                .directional = .{
                    .ambient = alg.Vec3.new(0.1, 0.1, 0.1),
                    .diffuse = alg.Vec3.new(0.1, 0.1, 0.1),
                    .specular = alg.Vec3.new(0.1, 0.1, 0.1),
                    .direction = alg.Vec3.one().negate(),
                },
            },
        ),
        .point_lights = std.ArrayList(Light).init(allocator),
        .spot_lights = std.ArrayList(Light).init(allocator),
    };
}

/// free resources
pub fn deinit(self: *Self) void {
    self.program.deinit();
    self.program_instanced.deinit();
    self.point_lights.deinit();
    self.spot_lights.deinit();
}

/// get renderer
pub fn renderer(self: *Self) Renderer {
    return Renderer.init(self, begin, end, getVertexAttribs, render, renderInstanced);
}

/// set directional light
pub fn setDirLight(self: *Self, light: Light) void {
    std.debug.assert(light.getType() == .directional);
    self.dir_light = light;
}

/// add point/spot light
pub fn addLight(self: *Self, light: Light) !u32 {
    switch (light.getType()) {
        .point => {
            if (self.point_lights.items.len == max_point_light_num)
                return error.TooManyPointLights;
            try self.point_lights.append(light);
            return @intCast(u32, self.point_lights.items.len - 1);
        },
        .spot => {
            if (self.spot_lights.items.len == max_spot_light_num)
                return error.TooManySpotLights;
            try self.spot_lights.append(light);
            return @intCast(u32, self.spot_lights.items.len - 1);
        },
        else => {
            std.debug.panic("invalid light type!", .{});
        },
    }
}

/// clear point lights
pub fn clearPointLights(self: *Self) void {
    self.point_lights.resize(0) catch unreachable;
}

/// clear spot lights
pub fn clearSpotLights(self: *Self) void {
    self.spot_lights.resize(0) catch unreachable;
}

/// begin rendering
fn begin(self: *Self, instanced_draw: bool) void {
    // enable program
    if (instanced_draw) {
        self.program_instanced.use();
        self.status = .ready_to_draw_instanced;
    } else {
        self.program.use();
        self.status = .ready_to_draw;
    }

    // directional light
    self.dir_light.apply(&self.program, "u_directional_light");

    // point lights
    var buf = [_]u8{0} ** 64;
    self.program.setUniformByName("u_point_light_count", self.point_lights.items.len);
    for (self.point_lights.items) |*light, i| {
        const name = std.fmt.bufPrintZ(&buf, "u_point_lights[{d}]", .{i}) catch unreachable;
        light.apply(&self.program, name);
    }

    // spot lights
    self.program.setUniformByName("u_spot_light_count", self.spot_lights.items.len);
    for (self.spot_lights.items) |*light, i| {
        const name = std.fmt.bufPrintZ(&buf, "u_spot_lights[{d}]", .{i}) catch unreachable;
        light.apply(&self.program, name);
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
    assert(material.data == .phong);
    var buf: [64]u8 = undefined;
    self.getProgram().setUniformByName(
        std.fmt.bufPrintZ(&buf, "u_material.diffuse", .{}) catch unreachable,
        material.data.phong.diffuse_map.getTextureUnit(),
    );
    self.getProgram().setUniformByName(
        std.fmt.bufPrintZ(&buf, "u_material.specular", .{}) catch unreachable,
        material.data.phong.specular_map.getTextureUnit(),
    );
    self.getProgram().setUniformByName(
        std.fmt.bufPrintZ(&buf, "u_material.shiness", .{}) catch unreachable,
        material.data.phong.shiness,
    );
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
    self.getProgram().setUniformByName("u_model", transform);
    self.getProgram().setUniformByName("u_normal", transform.inv().transpose());

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
