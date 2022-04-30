const std = @import("std");
const assert = std.debug.assert;
const zp = @import("../../zplay.zig");
const ShaderProgram = zp.graphics.gpu.ShaderProgram;
const alg = zp.deps.alg;
const Vec3 = alg.Vec3;
const Mat4 = alg.Mat4;

pub const max_point_light_num = 16;
pub const max_spot_light_num = 16;

pub const ShaderDefinitions =
    \\
    \\struct DirectionalLight {
    \\    vec3 ambient;
    \\    vec3 diffuse;
    \\    vec3 specular;
    \\    vec3 direction;
    \\    mat4 space_matrix;
    \\};
    \\uniform DirectionalLight u_directional_light;
    \\
    \\struct PointLight {
    \\    vec3 ambient;
    \\    vec3 diffuse;
    \\    vec3 specular;
    \\    vec3 position;
    \\    float constant;
    \\    float linear;
    \\    float quadratic;
    \\};
    \\uniform int u_point_light_count;
    \\#define NR_POINT_LIGHTS 16
    \\uniform PointLight u_point_lights[NR_POINT_LIGHTS];
    \\
    \\struct SpotLight {
    \\    vec3 ambient;
    \\    vec3 diffuse;
    \\    vec3 specular;
    \\    vec3 position;
    \\    vec3 direction;
    \\    float constant;
    \\    float linear;
    \\    float quadratic;
    \\    float cutoff;
    \\    float outer_cutoff;
    \\};
    \\uniform int u_spot_light_count;
    \\#define NR_SPOT_LIGHTS 16
    \\uniform SpotLight u_spot_lights[NR_SPOT_LIGHTS];
    \\
;

/// light type
pub const Type = enum {
    directional,
    point,
    spot,
};

/// light properties
pub const Light = union(Type) {
    directional: struct {
        ambient: Vec3,
        diffuse: Vec3,
        specular: Vec3 = Vec3.one(),
        direction: Vec3,
        space_matrix: ?Mat4 = null,
    },
    point: struct {
        ambient: Vec3,
        diffuse: Vec3,
        specular: Vec3 = Vec3.one(),
        position: Vec3,
        constant: f32 = 1.0,
        linear: f32,
        quadratic: f32,
    },
    spot: struct {
        ambient: Vec3,
        diffuse: Vec3,
        specular: Vec3 = Vec3.one(),
        position: Vec3,
        direction: Vec3,
        constant: f32 = 1.0,
        linear: f32,
        quadratic: f32,
        cutoff: f32,
        outer_cutoff: f32,
    },

    const Self = @This();

    /// get light type
    pub fn getType(self: Self) Type {
        return @as(Type, self);
    }

    /// get light position
    pub fn getPosition(self: Self) ?Vec3 {
        return switch (self) {
            .point => |d| d.position,
            .spot => |d| d.position,
            else => null,
        };
    }

    /// get light direction
    pub fn getDirection(self: Self) ?Vec3 {
        return switch (self.data) {
            .directional => |d| d.direction,
            .spot => |d| d.direction,
            else => null,
        };
    }

    /// update light colors
    pub fn updateColors(self: *Self, ambient: ?Vec3, diffuse: ?Vec3, specular: ?Vec3) void {
        switch (self.data) {
            .directional => |*d| {
                if (ambient) |color| {
                    d.ambient = color;
                }
                if (diffuse) |color| {
                    d.diffuse = color;
                }
                if (specular) |color| {
                    d.specular = color;
                }
            },
            .point => |*d| {
                if (ambient) |color| {
                    d.ambient = color;
                }
                if (diffuse) |color| {
                    d.diffuse = color;
                }
                if (specular) |color| {
                    d.specular = color;
                }
            },
            .spot => |*d| {
                if (ambient) |color| {
                    d.ambient = color;
                }
                if (diffuse) |color| {
                    d.diffuse = color;
                }
                if (specular) |color| {
                    d.specular = color;
                }
            },
        }
    }
};

/// apply lights in the shader
pub fn applyLights(program: *ShaderProgram, lights: []Light) void {
    const allocator = std.heap.raw_c_allocator;
    var buf = allocator.alloc(u8, 64) catch unreachable;
    defer allocator.free(buf);

    var dir_light_num: i32 = 0;
    var point_light_num: i32 = 0;
    var spot_light_num: i32 = 0;
    for (lights) |light| {
        switch (light) {
            .directional => |d| {
                assert(dir_light_num == 0);
                program.setUniformByName("u_directional_light.ambient", d.ambient);
                program.setUniformByName("u_directional_light.diffuse", d.diffuse);
                program.setUniformByName("u_directional_light.specular", d.specular);
                program.setUniformByName("u_directional_light.direction", d.direction);
                if (d.space_matrix) |m| {
                    program.setUniformByName("u_directional_light.space_matrix", m);
                }
                dir_light_num += 1;
            },
            .point => |d| {
                assert(point_light_num < max_point_light_num);
                program.setUniformByName(
                    std.fmt.bufPrintZ(
                        buf,
                        "u_point_lights[{d}].ambient",
                        .{point_light_num},
                    ) catch unreachable,
                    d.ambient,
                );
                program.setUniformByName(
                    std.fmt.bufPrintZ(
                        buf,
                        "u_point_lights[{d}].diffuse",
                        .{point_light_num},
                    ) catch unreachable,
                    d.diffuse,
                );
                program.setUniformByName(
                    std.fmt.bufPrintZ(
                        buf,
                        "u_point_lights[{d}].specular",
                        .{point_light_num},
                    ) catch unreachable,
                    d.specular,
                );
                program.setUniformByName(
                    std.fmt.bufPrintZ(
                        buf,
                        "u_point_lights[{d}].position",
                        .{point_light_num},
                    ) catch unreachable,
                    d.position,
                );
                program.setUniformByName(
                    std.fmt.bufPrintZ(
                        buf,
                        "u_point_lights[{d}].constant",
                        .{point_light_num},
                    ) catch unreachable,
                    d.constant,
                );
                program.setUniformByName(
                    std.fmt.bufPrintZ(
                        buf,
                        "u_point_lights[{d}].linear",
                        .{point_light_num},
                    ) catch unreachable,
                    d.linear,
                );
                program.setUniformByName(
                    std.fmt.bufPrintZ(
                        buf,
                        "u_point_lights[{d}].quadratic",
                        .{point_light_num},
                    ) catch unreachable,
                    d.quadratic,
                );
                point_light_num += 1;
            },
            .spot => |d| {
                assert(spot_light_num < max_spot_light_num);
                program.setUniformByName(
                    std.fmt.bufPrintZ(
                        buf,
                        "u_spot_lights[{d}].ambient",
                        .{spot_light_num},
                    ) catch unreachable,
                    d.ambient,
                );
                program.setUniformByName(
                    std.fmt.bufPrintZ(
                        buf,
                        "u_spot_lights[{d}].diffuse",
                        .{spot_light_num},
                    ) catch unreachable,
                    d.diffuse,
                );
                program.setUniformByName(
                    std.fmt.bufPrintZ(
                        buf,
                        "u_spot_lights[{d}].specular",
                        .{spot_light_num},
                    ) catch unreachable,
                    d.specular,
                );
                program.setUniformByName(
                    std.fmt.bufPrintZ(
                        buf,
                        "u_spot_lights[{d}].position",
                        .{spot_light_num},
                    ) catch unreachable,
                    d.position,
                );
                program.setUniformByName(
                    std.fmt.bufPrintZ(
                        buf,
                        "u_spot_lights[{d}].direction",
                        .{spot_light_num},
                    ) catch unreachable,
                    d.direction,
                );
                program.setUniformByName(
                    std.fmt.bufPrintZ(
                        buf,
                        "u_spot_lights[{d}].constant",
                        .{spot_light_num},
                    ) catch unreachable,
                    d.constant,
                );
                program.setUniformByName(
                    std.fmt.bufPrintZ(
                        buf,
                        "u_spot_lights[{d}].linear",
                        .{spot_light_num},
                    ) catch unreachable,
                    d.linear,
                );
                program.setUniformByName(
                    std.fmt.bufPrintZ(
                        buf,
                        "u_spot_lights[{d}].quadratic",
                        .{spot_light_num},
                    ) catch unreachable,
                    d.quadratic,
                );
                program.setUniformByName(
                    std.fmt.bufPrintZ(
                        buf,
                        "u_spot_lights[{d}].cutoff",
                        .{spot_light_num},
                    ) catch unreachable,
                    @cos(alg.toRadians(d.cutoff)),
                );
                program.setUniformByName(
                    std.fmt.bufPrintZ(
                        buf,
                        "u_spot_lights[{d}].outer_cutoff",
                        .{spot_light_num},
                    ) catch unreachable,
                    @cos(alg.toRadians(d.outer_cutoff)),
                );
                spot_light_num += 1;
            },
        }
    }
    program.setUniformByName("u_point_light_count", point_light_num);
    program.setUniformByName("u_spot_light_count", spot_light_num);
}

/// supplement interface for light shading
pub const Renderer = struct {
    /// The type erased pointer to Renderer implementation
    ptr: *anyopaque,
    vtable: *const VTable,

    const VTable = struct {
        /// apply lights to renderer
        applyLightsFn: fn (ptr: *anyopaque, lights: []Light) void,
    };

    pub fn init(
        pointer: anytype,
        comptime applyLightsFn: fn (ptr: @TypeOf(pointer), lights: []Light) void,
    ) Renderer {
        const Ptr = @TypeOf(pointer);
        const ptr_info = @typeInfo(Ptr);

        assert(ptr_info == .Pointer); // must be a pointer
        assert(ptr_info.Pointer.size == .One); // must be a single-item pointer

        const alignment = ptr_info.Pointer.alignment;

        const gen = struct {
            fn applyLightsImpl(ptr: *anyopaque, lights: []Light) void {
                const self = @ptrCast(Ptr, @alignCast(alignment, ptr));
                return @call(.{ .modifier = .always_inline }, applyLightsFn, .{ self, lights });
            }

            const vtable = VTable{
                .applyLightsFn = applyLightsImpl,
            };
        };

        return .{
            .ptr = pointer,
            .vtable = &gen.vtable,
        };
    }

    pub fn applyLights(rd: Renderer, lights: []Light) void {
        rd.vtable.applyLightsFn(rd.ptr, lights);
    }
};
