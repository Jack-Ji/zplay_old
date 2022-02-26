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
    flags.append("-fno-sanitize=undefined") catch unreachable;

    var stb = b.addStaticLibrary("stb", null);
    stb.setTarget(target);
    stb.linkLibC();
    stb.addCSourceFile(
        root_path ++ "/src/deps/stb/c/stb_image_wrapper.c",
        flags.items,
    );
    exe.linkLibrary(stb);
}
