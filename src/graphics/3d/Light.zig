const std = @import("std");
const zp = @import("../../zplay.zig");
const ShaderProgram = zp.graphics.common.ShaderProgram;
const alg = zp.deps.alg;
const Vec3 = alg.Vec3;
const Self = @This();

/// light type
pub const Type = enum {
    directional,
    point,
    spot,
};

/// light properties
pub const Data = union(Type) {
    directional: struct {
        ambient: Vec3,
        diffuse: Vec3,
        specular: Vec3 = Vec3.one(),
        direction: Vec3,
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
};

/// light property data
data: Data,

/// create a new light
pub fn init(data: Data) Self {
    return .{
        .data = data,
    };
}

/// get light type
pub fn getType(self: Self) Type {
    return @as(Type, self.data);
}

/// get light position
pub fn getPosition(self: Self) ?Vec3 {
    return switch (self.data) {
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

/// apply light in the shader
pub fn apply(self: Self, program: *ShaderProgram, uniform_name: [:0]const u8) void {
    const allocator = std.heap.raw_c_allocator;
    var buf = allocator.alloc(u8, uniform_name.len + 64) catch unreachable;
    defer allocator.free(buf);

    switch (self.data) {
        .directional => |d| {
            program.setUniformByName(
                std.fmt.bufPrintZ(buf, "{s}.ambient", .{uniform_name}) catch unreachable,
                d.ambient,
            );
            program.setUniformByName(
                std.fmt.bufPrintZ(buf, "{s}.diffuse", .{uniform_name}) catch unreachable,
                d.diffuse,
            );
            program.setUniformByName(
                std.fmt.bufPrintZ(buf, "{s}.specular", .{uniform_name}) catch unreachable,
                d.specular,
            );
            program.setUniformByName(
                std.fmt.bufPrintZ(buf, "{s}.direction", .{uniform_name}) catch unreachable,
                d.direction,
            );
        },
        .point => |d| {
            program.setUniformByName(
                std.fmt.bufPrintZ(buf, "{s}.ambient", .{uniform_name}) catch unreachable,
                d.ambient,
            );
            program.setUniformByName(
                std.fmt.bufPrintZ(buf, "{s}.diffuse", .{uniform_name}) catch unreachable,
                d.diffuse,
            );
            program.setUniformByName(
                std.fmt.bufPrintZ(buf, "{s}.specular", .{uniform_name}) catch unreachable,
                d.specular,
            );
            program.setUniformByName(
                std.fmt.bufPrintZ(buf, "{s}.position", .{uniform_name}) catch unreachable,
                d.position,
            );
            program.setUniformByName(
                std.fmt.bufPrintZ(buf, "{s}.constant", .{uniform_name}) catch unreachable,
                d.constant,
            );
            program.setUniformByName(
                std.fmt.bufPrintZ(buf, "{s}.linear", .{uniform_name}) catch unreachable,
                d.linear,
            );
            program.setUniformByName(
                std.fmt.bufPrintZ(buf, "{s}.quadratic", .{uniform_name}) catch unreachable,
                d.quadratic,
            );
        },
        .spot => |d| {
            program.setUniformByName(
                std.fmt.bufPrintZ(buf, "{s}.ambient", .{uniform_name}) catch unreachable,
                d.ambient,
            );
            program.setUniformByName(
                std.fmt.bufPrintZ(buf, "{s}.diffuse", .{uniform_name}) catch unreachable,
                d.diffuse,
            );
            program.setUniformByName(
                std.fmt.bufPrintZ(buf, "{s}.specular", .{uniform_name}) catch unreachable,
                d.specular,
            );
            program.setUniformByName(
                std.fmt.bufPrintZ(buf, "{s}.position", .{uniform_name}) catch unreachable,
                d.position,
            );
            program.setUniformByName(
                std.fmt.bufPrintZ(buf, "{s}.direction", .{uniform_name}) catch unreachable,
                d.direction,
            );
            program.setUniformByName(
                std.fmt.bufPrintZ(buf, "{s}.constant", .{uniform_name}) catch unreachable,
                d.constant,
            );
            program.setUniformByName(
                std.fmt.bufPrintZ(buf, "{s}.linear", .{uniform_name}) catch unreachable,
                d.linear,
            );
            program.setUniformByName(
                std.fmt.bufPrintZ(buf, "{s}.quadratic", .{uniform_name}) catch unreachable,
                d.quadratic,
            );
            program.setUniformByName(
                std.fmt.bufPrintZ(buf, "{s}.cutoff", .{uniform_name}) catch unreachable,
                std.math.cos(alg.toRadians(d.cutoff)),
            );
            program.setUniformByName(
                std.fmt.bufPrintZ(buf, "{s}.outer_cutoff", .{uniform_name}) catch unreachable,
                std.math.cos(alg.toRadians(d.outer_cutoff)),
            );
        },
    }
}
