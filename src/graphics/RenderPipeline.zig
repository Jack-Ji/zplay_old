const std = @import("std");
const assert = std.debug.assert;
const Camera = @import("Camera.zig");
const Material = @import("Material.zig");
const Renderer = @import("Renderer.zig");
const zp = @import("../zplay.zig");
const Context = zp.graphics.gpu.Context;
const Framebuffer = zp.graphics.gpu.Framebuffer;
const alg = zp.deps.alg;
const Vec3 = alg.Vec3;
const Mat4 = alg.Mat4;
const Self = @This();

pub const TriggerFunc = fn (ctx: *Context, custom: ?*anyopaque) void;

/// render-pass
pub const RenderPass = struct {
    /// frame buffer of the render-pass
    fb: ?Framebuffer = null,

    /// do some work before/after rendering
    beforeFn: ?TriggerFunc = null,
    afterFn: ?TriggerFunc = null,

    /// renderer of the render-pass
    rd: Renderer,

    /// input of renderer
    data: *const Renderer.Input,

    /// custom data
    custom: ?*anyopaque = null,

    /// execute render pass
    pub fn run(self: RenderPass, ctx: *Context) anyerror!void {
        // set current frame buffer
        var fb_changed = false;
        if (self.fb) |f| {
            if (Framebuffer.current_fb != f.id) {
                Framebuffer.use(f);
                fb_changed = true;
            }
        } else if (Framebuffer.current_fb != 0) {
            Framebuffer.use(null);
            fb_changed = true;
        }

        if (self.beforeFn) |f| {
            f(ctx, self.custom);
        } else if (std.debug.runtime_safety) {
            if (fb_changed) {
                std.log.warn("New framebuffer is used without any preparing job, probably something is wrong, please double check!", .{});
            }
        }
        defer if (self.afterFn) |f| f(ctx, self.custom);

        try self.rd.draw(ctx, self.data.*);
    }
};

passes: std.ArrayList(RenderPass),

/// create pipeline
pub fn init(allocator: std.mem.Allocator, passes: []RenderPass) !Self {
    var self = Self{
        .passes = try std.ArrayList(RenderPass)
            .initCapacity(allocator, std.math.max(passes.len, 1)),
    };
    self.passes.appendSliceAssumeCapacity(passes);
    return self;
}

/// destroy pipeline
pub fn deinit(self: Self) void {
    self.passes.deinit();
}

/// clear pipeline
pub fn clear(self: *Self) void {
    self.passes.clearRetainingCapacity();
}

/// append new render pass
pub fn appendPass(self: *Self, pass: RenderPass) !void {
    try self.passes.append(pass);
}

/// execute render pass
pub fn run(self: Self, ctx: *Context) anyerror!void {
    for (self.passes.items) |p| {
        try p.run(ctx);
    }
}
