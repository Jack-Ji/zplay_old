const std = @import("std");

pub fn link(
    b: *std.build.Builder,
    exe: *std.build.LibExeObjStep,
    target: std.zig.CrossTarget,
    comptime root_path: []const u8,
) void {
    _ = target;

    var flags = std.ArrayList([]const u8).init(std.heap.page_allocator);
    if (b.is_release) flags.append("-Os") catch unreachable;
    flags.append("-Wno-return-type-c-linkage") catch unreachable;

    var gltf = exe.builder.addStaticLibrary("gltf", null);
    gltf.linkLibC();
    gltf.addIncludeDir(root_path ++ "/src/deps/gltf/c");
    gltf.addCSourceFile(
        root_path ++ "/src/deps/gltf/c/cgltf_wrapper.c",
        flags.items,
    );
    exe.linkLibrary(gltf);
}
