const std = @import("std");
const assert = std.debug.assert;
const zp = @import("../zplay.zig");
const gfx = zp.graphics;
const Context = gfx.gpu.Context;
const VertexArray = gfx.gpu.VertexArray;
const Renderer = gfx.Renderer;
const Camera = gfx.Camera;
const alg = zp.deps.alg;
const cp = zp.deps.cp;
const Vec2 = alg.Vec2;
const Vec3 = alg.Vec3;
const Vec4 = alg.Vec4;
const Mat4 = alg.Mat4;
const Quat = alg.Quat;
const Self = @This();

const Object = struct {
    size: Vec3,
};
