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

    var nanosvg = b.addStaticLibrary("nanosvg", null);
    nanosvg.setTarget(target);
    nanosvg.linkLibC();
    nanosvg.addIncludeDir(root_path ++ "/src/deps/nanosvg/c");
    nanosvg.addCSourceFile(
        root_path ++ "/src/deps/nanosvg/c/nanosvg_wrapper.c",
        flags.items,
    );
    exe.linkLibrary(nanosvg);
}
