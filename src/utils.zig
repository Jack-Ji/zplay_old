const std = @import("std");
const assert = std.debug.assert;
const zp = @import("zplay.zig");
const alg = zp.deps.alg;
const Vec3 = alg.Vec3;
const Vec4 = alg.Vec4;
const Mat4 = alg.Mat4;

/// calculate a plane determined by normal vector and point
pub fn getPlane(normal: Vec3, point: Vec3, size: f32) [12]f32 {
    const normal_p = if (normal.x() != 0)
        Vec3.new(
            (-normal.y() - normal.z()) / normal.x(),
            1,
            1,
        ).norm()
    else if (normal.y() != 0)
        Vec3.new(
            1,
            (-normal.x() - normal.z()) / normal.y(),
            1,
        ).norm()
    else if (normal.z() != 0)
        Vec3.new(
            1,
            1,
            (-normal.x() - normal.y()) / normal.z(),
        ).norm()
    else
        unreachable;
    const normal_pp = normal_p.cross(normal).norm();
    const v1 = point.add(normal_p.scale(size / 2));
    const v2 = point.add(normal_pp.scale(size / 2));
    const v3 = point.sub(normal_p.scale(size / 2));
    const v4 = point.sub(normal_pp.scale(size / 2));
    return [12]f32{
        v1.x(), v1.y(), v1.z(),
        v2.x(), v2.y(), v2.z(),
        v3.x(), v3.y(), v3.z(),
        v4.x(), v4.y(), v4.z(),
    };
}
