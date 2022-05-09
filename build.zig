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
    const examples = [_]struct { name: []const u8, link_opt: LinkOption }{
        .{ .name = "simple_window", .link_opt = .{} },
        .{ .name = "font", .link_opt = .{} },
        .{ .name = "single_triangle", .link_opt = .{} },
        .{ .name = "cubes", .link_opt = .{ .link_imgui = true } },
        .{ .name = "phong_lighting", .link_opt = .{ .link_imgui = true } },
        .{ .name = "imgui_demo", .link_opt = .{ .link_imgui = true } },
        .{ .name = "imgui_fontawesome", .link_opt = .{ .link_imgui = true } },
        .{ .name = "imgui_ttf", .link_opt = .{ .link_imgui = true } },
        .{ .name = "vector_graphics", .link_opt = .{ .link_imgui = true, .link_vg = true } },
        .{ .name = "vg_benchmark", .link_opt = .{ .link_imgui = true, .link_vg = true } },
        .{ .name = "mesh_generation", .link_opt = .{ .link_imgui = true } },
        .{ .name = "gltf_demo", .link_opt = .{ .link_imgui = true } },
        .{ .name = "environment_mapping", .link_opt = .{ .link_imgui = true } },
        .{ .name = "post_processing", .link_opt = .{ .link_imgui = true } },
        .{ .name = "rasterization", .link_opt = .{ .link_imgui = true } },
        .{ .name = "bullet_test", .link_opt = .{ .link_imgui = true, .link_bullet = true } },
        .{ .name = "chipmunk_test", .link_opt = .{ .link_imgui = true, .link_chipmunk = true } },
        .{ .name = "file_dialog", .link_opt = .{ .link_imgui = true, .link_nfd = true } },
        .{ .name = "cube_cross", .link_opt = .{ .link_imgui = true } },
        .{ .name = "sprite_sheet", .link_opt = .{} },
        .{ .name = "sprite_benchmark", .link_opt = .{} },
        .{ .name = "sound_play", .link_opt = .{} },
        .{ .name = "particle_2d", .link_opt = .{ .link_imgui = true } },
    };
    const build_examples = b.step("build_examples", "compile and install all examples");
    inline for (examples) |demo| {
        const exe = b.addExecutable(
            demo.name,
            "examples" ++ std.fs.path.sep_str ++ demo.name ++ ".zig",
        );
        exe.setBuildMode(mode);
        exe.setTarget(target);
        link(exe, demo.link_opt);
        const install_cmd = b.addInstallArtifact(exe);
        const run_cmd = exe.run();
        run_cmd.step.dependOn(&install_cmd.step);
        run_cmd.step.dependOn(&example_assets_install.step);
        run_cmd.cwd = "zig-out" ++ std.fs.path.sep_str ++ "bin";
        const run_step = b.step(
            demo.name,
            "run example " ++ demo.name,
        );
        run_step.dependOn(&run_cmd.step);
        build_examples.dependOn(&install_cmd.step);
    }
}

pub const LinkOption = struct {
    link_nfd: bool = false,
    link_imgui: bool = false,
    link_vg: bool = false,
    link_bullet: bool = false,
    link_chipmunk: bool = false,
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
    if (opt.link_vg) {
        @import("build/nanovg.zig").link(exe, root_path);
        @import("build/nanosvg.zig").link(exe, root_path);
    }
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
