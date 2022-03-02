const std = @import("std");
const assert = std.debug.assert;
const zp = @import("../../zplay.zig");
const gfx = zp.graphics;
const Context = zp.Context;
const Renderer = gfx.Renderer;
const Camera = gfx.Camera;
const render_pass = gfx.render_pass;
const alg = zp.deps.alg;
const Vec2 = alg.Vec2;
const Vec3 = alg.Vec3;
const Vec4 = alg.Vec4;
const Mat4 = alg.Mat4;
const Quat = alg.Quat;
const Self = @This();

/// rendering data
render_data: Renderer.Input,

/// create scene
pub fn init(allocator: std.mem.Allocator) !Self {
    var self = Self{
        .render_data = try Renderer.Input.init(
            allocator,
            &.{},
            null,
            null,
            null,
            null,
        ),
    };
    return self;
}

/// remove scene
pub fn deinit(self: Self) void {
    self.render_data.deinit();
}
