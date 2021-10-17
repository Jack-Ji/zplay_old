const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.build.Builder) void {
    const default_abi = if (builtin.os.tag == .windows) .gnu else null; // doesn't require vcruntime
    const mode = b.standardReleaseOptions();
    const target = b.standardTargetOptions(.{
        .default_target = .{
            .abi = default_abi,
        },
    });

    const examples = [_][]const u8{
        "simple_window",
        "simple_triangle",
    };
    inline for (examples) |name| {
        const exe = b.addExecutable(
            name,
            "examples" ++ std.fs.path.sep_str ++ name ++ ".zig",
        );
        exe.setBuildMode(mode);
        exe.setTarget(target);
        link(b, exe, target);
        const install_cmd = b.addInstallArtifact(exe);
        const run_cmd = exe.run();
        run_cmd.step.dependOn(&install_cmd.step);
        const run_step = b.step(
            name,
            "run example " ++ name,
        );
        run_step.dependOn(&run_cmd.step);
    }
}

pub fn link(b: *std.build.Builder, exe: *std.build.LibExeObjStep, target: std.build.Target) void {
    // link sdl
    const sdl = @import("src/sdl/Sdk.zig").init(b);
    sdl.link(exe, .dynamic);

    // link opengl
    var gl = b.addStaticLibrary("gl", null);
    gl.linkLibC();
    var flags = std.ArrayList([]const u8).init(std.heap.page_allocator);
    if (b.is_release) flags.append("-Os") catch unreachable;
    if (target.isWindows()) {
        gl.linkSystemLibrary("opengl32");
    } else if (target.isDarwin()) {
        gl.linkFramework("OpenGL");
    } else if (target.isLinux()) {
        gl.linkSystemLibrary("GL");
    }
    gl.addIncludeDir(rootPath() ++ "/src/gl/c/include");
    gl.addCSourceFile(
        rootPath() ++ "/src/gl/c/src/glad.c",
        flags.items,
    );
    exe.linkLibrary(gl);

    // use zplay
    exe.addPackage(.{
        .name = "zplay",
        .path = .{
            .path = rootPath() ++ "/src/lib.zig",
        },
        .dependencies = &[_]std.build.Pkg{
            sdl.getWrapperPackage("sdl"),
        },
    });
}

fn rootPath() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}
