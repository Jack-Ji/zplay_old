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

    var gl = b.addStaticLibrary("gl", null);
    gl.linkLibC();
    if (target.isWindows()) {
        gl.linkSystemLibrary("opengl32");
    } else if (target.isDarwin()) {
        gl.linkFramework("OpenGL");
    } else if (target.isLinux()) {
        gl.linkSystemLibrary("GL");
    }
    gl.addIncludeDir(root_path ++ "/src/deps/gl/c/include");
    gl.addCSourceFile(
        root_path ++ "/src/deps/gl/c/src/glad.c",
        flags.items,
    );
    exe.linkLibrary(gl);
}
