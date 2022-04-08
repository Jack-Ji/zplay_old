const std = @import("std");

pub fn link(
    exe: *std.build.LibExeObjStep,
    comptime root_path: []const u8,
) void {
    var flags = std.ArrayList([]const u8).init(std.heap.page_allocator);
    if (exe.builder.is_release) flags.append("-Os") catch unreachable;
    flags.append("-Wno-return-type-c-linkage") catch unreachable;
    flags.append("-fno-sanitize=undefined") catch unreachable;

    var gl = exe.builder.addStaticLibrary("gl", null);
    gl.setTarget(exe.target);
    gl.linkLibC();
    if (exe.target.isWindows()) {
        gl.linkSystemLibrary("opengl32");
    } else if (exe.target.isDarwin()) {
        gl.linkFramework("OpenGL");
    } else if (exe.target.isLinux()) {
        gl.linkSystemLibrary("GL");
    }
    gl.addIncludeDir(root_path ++ "/src/deps/gl/c/include");
    gl.addCSourceFile(
        root_path ++ "/src/deps/gl/c/src/glad.c",
        flags.items,
    );
    exe.linkLibrary(gl);
}
