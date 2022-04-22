const std = @import("std");

pub fn link(
    exe: *std.build.LibExeObjStep,
    comptime root_path: []const u8,
) void {
    var flags = std.ArrayList([]const u8).init(std.heap.page_allocator);
    defer flags.deinit();
    flags.append("-Wno-return-type-c-linkage") catch unreachable;
    flags.append("-fno-sanitize=undefined") catch unreachable;

    var lib = exe.builder.addStaticLibrary("miniaudio", null);
    lib.setBuildMode(exe.build_mode);
    lib.setTarget(exe.target);
    lib.linkLibC();
    if (exe.target.isLinux()) {
        lib.linkSystemLibrary("pthread");
        lib.linkSystemLibrary("m");
        lib.linkSystemLibrary("dl");
    }
    lib.addCSourceFile(
        root_path ++ "/src/deps/miniaudio/c/miniaudio.c",
        flags.items,
    );
    exe.linkLibrary(lib);
}
