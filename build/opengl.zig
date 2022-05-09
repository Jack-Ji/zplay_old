const std = @import("std");

pub fn link(
    exe: *std.build.LibExeObjStep,
    comptime root_path: []const u8,
) void {
    var flags = std.ArrayList([]const u8).init(std.heap.page_allocator);
    defer flags.deinit();
    flags.append("-Wno-return-type-c-linkage") catch unreachable;
    flags.append("-fno-sanitize=undefined") catch unreachable;

    var lib = exe.builder.addStaticLibrary("gl", null);
    lib.setBuildMode(exe.build_mode);
    lib.setTarget(exe.target);
    lib.linkLibC();
    if (exe.target.isWindows()) {
        lib.linkSystemLibrary("opengl32");
    } else if (exe.target.isDarwin()) {
        lib.linkFramework("OpenGL");
    } else if (exe.target.isLinux()) {
        lib.linkSystemLibrary("GL");
    }
    lib.addIncludeDir(root_path ++ "/src/deps/gl/c/include");
    lib.addCSourceFile(
        root_path ++ "/src/deps/gl/c/src/glad.c",
        flags.items,
    );
    exe.linkLibrary(lib);
}
