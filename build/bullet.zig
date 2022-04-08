const std = @import("std");

pub fn link(
    exe: *std.build.LibExeObjStep,
    comptime root_path: []const u8,
) void {
    var flags = std.ArrayList([]const u8).init(std.heap.page_allocator);
    if (exe.builder.is_release) flags.append("-Os") catch unreachable;
    flags.append("-Wno-return-type-c-linkage") catch unreachable;
    flags.append("-fno-sanitize=undefined") catch unreachable;

    var bullet = exe.builder.addStaticLibrary("bullet", null);
    bullet.setTarget(exe.target);
    bullet.linkLibC();
    bullet.linkLibCpp();
    bullet.addIncludeDir(root_path ++ "/src/deps/bullet/c");
    bullet.addCSourceFiles(&.{
        root_path ++ "/src/deps/bullet/c/cbullet.cpp",
        root_path ++ "/src/deps/bullet/c/btLinearMathAll.cpp",
        root_path ++ "/src/deps/bullet/c/btBulletCollisionAll.cpp",
        root_path ++ "/src/deps/bullet/c/btBulletDynamicsAll.cpp",
    }, flags.items);
    exe.linkLibrary(bullet);
}
