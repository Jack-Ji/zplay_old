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

    const example_assets_install = b.addInstallDirectory(.{
        .source_dir = "examples/assets",
        .install_dir = .bin,
        .install_subdir = "assets",
    });
    const examples = [_][]const u8{
        "simple_window",
        "single_triangle",
        "cubes",
        "phong_lighting",
        "imgui_demo",
        "imgui_fontawesome",
        "imgui_ttf",
        "vector_graphics",
        "vg_benchmark",
        "mesh_generation",
        "gltf_demo",
    };
    const build_examples = b.step("build_examples", "compile and install all examples");
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
        run_cmd.step.dependOn(&example_assets_install.step);
        run_cmd.cwd = "zig-out" ++ std.fs.path.sep_str ++ "bin";
        const run_step = b.step(
            name,
            "run example " ++ name,
        );
        run_step.dependOn(&run_cmd.step);
        build_examples.dependOn(&install_cmd.step);
    }
}

/// link zplay framework to executable 
pub fn link(
    b: *std.build.Builder,
    exe: *std.build.LibExeObjStep,
    target: std.zig.CrossTarget,
) void {
    const root_path = comptime rootPath();

    // link dependencies
    const deps = .{
        @import("build/sdl.zig"),
        @import("build/opengl.zig"),
        @import("build/stb.zig"),
        @import("build/imgui.zig"),
        @import("build/gltf.zig"),
        @import("build/nanovg.zig"),
        @import("build/nanosvg.zig"),
        @import("build/bullet.zig"),
    };
    inline for (deps) |d| {
        d.link(b, exe, target, root_path);
    }

    // use zplay
    const sdl = @import("./src/deps/sdl/Sdk.zig").init(b);
    exe.addPackage(.{
        .name = "zplay",
        .path = .{ .path = root_path ++ "/src/zplay.zig" },
        .dependencies = &[_]std.build.Pkg{
            sdl.getWrapperPackage("sdl"),
        },
    });
}

/// root path
fn rootPath() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}
