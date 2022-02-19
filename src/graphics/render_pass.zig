const std = @import("std");
const assert = std.debug.assert;
const Camera = @import("Camera.zig");
const Material = @import("Material.zig");
const Renderer = @import("Renderer.zig");
const zp = @import("../zplay.zig");
const Context = zp.graphics.gpu.Context;
const FrameBuffer = zp.graphics.gpu.Framebuffer;
const alg = zp.deps.alg;
const Vec3 = alg.Vec3;
const Mat4 = alg.Mat4;

/// render-pass
pub const RenderPass = struct {
    /// frame buffer of the render-pass
    fb: ?FrameBuffer = null,

    /// viewport setting of the render-pass
    vp: ?Viewport = null,

    /// renderer of the render-pass
    rd: Renderer,

    /// input of renderer
    data: Renderer.Input,
};

/// pipeline (composed render-passes)
pub const Pipeline = struct {
    passes: std.ArrayList(RenderPass),
};

/// viewport settings 
pub const Viewport = struct {
    xpos: u32,
    ypos: u32,
    width: u32,
    height: u32,
};
