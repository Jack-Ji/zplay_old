const std = @import("std");

pub fn link(
    exe: *std.build.LibExeObjStep,
    comptime root_path: []const u8,
) void {
    var flags = std.ArrayList([]const u8).init(std.heap.page_allocator);
    if (exe.builder.is_release) flags.append("-Os") catch unreachable;
    flags.append("-Wno-return-type-c-linkage") catch unreachable;

    var gltf = exe.builder.addStaticLibrary("gltf", null);
    gltf.setTarget(exe.target);
    gltf.linkLibC();
    gltf.addIncludeDir(root_path ++ "/src/deps/gltf/c");
    gltf.addCSourceFile(
        root_path ++ "/src/deps/gltf/c/cgltf_wrapper.c",
        flags.items,
    );
    exe.linkLibrary(gltf);
}
