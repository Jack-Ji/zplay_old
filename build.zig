const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.build.Builder) void {
    const mode = b.standardReleaseOptions();
    const target = b.standardTargetOptions(.{
        .default_target = .{
            // prefer compatibility over performance here
            // make your own choice
            .cpu_model = .baseline,
        },
    });

    const example_assets_install = b.addInstallDirectory(.{
        .source_dir = "examples/assets",
        .install_dir = .bin,
        .install_subdir = "assets",
    });
    const examples = [_][]const u8{
        "simple_window",
        "font",
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
        "environment_mapping",
        "post_processing",
        "rasterization",
        "bullet_test",
        "chipmunk_test",
        "file_dialog",
        "cube_cross",
        "sprite_sheet",
        "sprite_benchmark",
        "sound_play",
    };
    const build_examples = b.step("build_examples", "compile and install all examples");
    inline for (examples) |name| {
        const exe = b.addExecutable(
            name,
            "examples" ++ std.fs.path.sep_str ++ name ++ ".zig",
        );
        exe.setBuildMode(mode);
        exe.setTarget(target);
        link(exe, .{});
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

pub const LinkOption = struct {
    link_nfd: bool = true,
    link_imgui: bool = true,
    link_nanovg: bool = true,
    link_nanosvg: bool = true,
    link_bullet: bool = true,
    link_chipmunk: bool = true,
};

/// link zplay framework to executable
pub fn link(exe: *std.build.LibExeObjStep, opt: LinkOption) void {
    const root_path = comptime rootPath();

    // link dependencies
    @import("build/sdl.zig").link(exe, root_path);
    @import("build/opengl.zig").link(exe, root_path);
    @import("build/miniaudio.zig").link(exe, root_path);
    @import("build/stb.zig").link(exe, root_path);
    @import("build/gltf.zig").link(exe, root_path);
    if (opt.link_nfd) @import("build/nfd.zig").link(exe, root_path);
    if (opt.link_imgui) @import("build/imgui.zig").link(exe, root_path);
    if (opt.link_nanovg) @import("build/nanovg.zig").link(exe, root_path);
    if (opt.link_nanosvg) @import("build/nanosvg.zig").link(exe, root_path);
    if (opt.link_bullet) @import("build/bullet.zig").link(exe, root_path);
    if (opt.link_chipmunk) @import("build/chipmunk.zig").link(exe, root_path);

    // use zplay
    const sdl = @import("./src/deps/sdl/Sdk.zig").init(exe.builder);
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
