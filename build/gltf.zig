const std = @import("std");

pub fn link(
    b: *std.build.Builder,
    exe: *std.build.LibExeObjStep,
    target: std.zig.CrossTarget,
    comptime root_path: []const u8,
) void {
    var flags = std.ArrayList([]const u8).init(std.heap.page_allocator);
    if (b.is_release) flags.append("-Os") catch unreachable;
    flags.append("-Wno-return-type-c-linkage") catch unreachable;

    var gltf = b.addStaticLibrary("gltf", null);
    gltf.setTarget(target);
    gltf.linkLibC();
    gltf.addIncludeDir(root_path ++ "/src/deps/gltf/c");
    gltf.addCSourceFile(
        root_path ++ "/src/deps/gltf/c/cgltf_wrapper.c",
        flags.items,
    );
    exe.linkLibrary(gltf);
}
