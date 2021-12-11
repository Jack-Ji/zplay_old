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

    var nanovg = exe.builder.addStaticLibrary("nanovg", null);
    nanovg.linkLibC();
    nanovg.addIncludeDir(root_path ++ "/src/deps/gl/c/include");
    nanovg.addIncludeDir(root_path ++ "/src/deps/nanovg/c");
    nanovg.addCSourceFiles(&.{
        root_path ++ "/src/deps/nanovg/c/nanovg.c",
        root_path ++ "/src/deps/nanovg/c/nanovg_gl3_impl.c",
    }, flags.items);
    exe.linkLibrary(nanovg);
}
