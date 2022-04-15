const std = @import("std");

pub fn link(
    exe: *std.build.LibExeObjStep,
    comptime root_path: []const u8,
) void {
    var flags = std.ArrayList([]const u8).init(std.heap.page_allocator);
    if (exe.builder.is_release) flags.append("-Os") catch unreachable;
    flags.append("-Wno-return-type-c-linkage") catch unreachable;
    flags.append("-fno-sanitize=undefined") catch unreachable;

    var miniaudio = exe.builder.addStaticLibrary("miniaudio", null);
    miniaudio.setTarget(exe.target);
    miniaudio.linkLibC();
    if (exe.target.isLinux()) {
        miniaudio.linkSystemLibrary("pthread");
        miniaudio.linkSystemLibrary("m");
        miniaudio.linkSystemLibrary("dl");
    }
    miniaudio.addCSourceFile(
        root_path ++ "/src/deps/miniaudio/c/miniaudio.c",
        flags.items,
    );
    exe.linkLibrary(miniaudio);
}
