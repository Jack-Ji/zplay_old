const std = @import("std");

pub fn link(
    exe: *std.build.LibExeObjStep,
    comptime root_path: []const u8,
) void {
    var flags = std.ArrayList([]const u8).init(std.heap.page_allocator);
    if (exe.builder.is_release) flags.append("-Os") catch unreachable;
    flags.append("-Wno-return-type-c-linkage") catch unreachable;
    flags.append("-fno-sanitize=undefined") catch unreachable;

    var stb = exe.builder.addStaticLibrary("stb", null);
    stb.setTarget(exe.target);
    stb.linkLibC();
    stb.addCSourceFile(
        root_path ++ "/src/deps/stb/c/stb_wrapper.c",
        flags.items,
    );
    exe.linkLibrary(stb);
}
