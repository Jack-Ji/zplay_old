const std = @import("std");
const assert = std.debug.assert;
const Model = @import("Model");
const zp = @import("../../zplay.zig");
const gfx = zp.graphics;
const Camera = gfx.Camera;
const Material = gfx.Material;
const bt = zp.deps.bt;
const alg = zp.deps.alg;
const Vec2 = alg.Vec2;
const Vec3 = alg.Vec3;
const Vec4 = alg.Vec4;
const Mat4 = alg.Mat4;
const Quat = alg.Quat;
const Self = @This();

const Object = struct {
    model: Model,
    body: bt.Body,
    size: Vec3 = undefined,
};
