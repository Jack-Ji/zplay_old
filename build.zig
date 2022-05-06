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
        .{ .name = "triangle", .link_opt = .{} },
        .{ .name = "cubes", .link_opt = .{ .link_imgui = true } },
        .{ .name = "phong_lighting", .link_opt = .{ .link_imgui = true } },
        .{ .name = "imgui_demo", .link_opt = .{ .link_imgui = true } },
        .{ .name = "imgui_fontawesome", .link_opt = .{ .link_imgui = true } },
        .{ .name = "imgui_ttf", .link_opt = .{ .link_imgui = true } },
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
    link_bullet: bool = false,
    link_chipmunk: bool = false,
};

/// link zplay framework to executable
pub fn link(exe: *std.build.LibExeObjStep, opt: LinkOption) void {
    const root_path = comptime rootPath();

    // link dependencies
    @import("build/core.zig").link(exe, root_path);
    @import("build/opengl.zig").link(exe, root_path);
    @import("build/miniaudio.zig").link(exe, root_path);
    @import("build/stb.zig").link(exe, root_path);
    @import("build/gltf.zig").link(exe, root_path);
    if (opt.link_nfd) @import("build/nfd.zig").link(exe, root_path);
    if (opt.link_imgui) @import("build/imgui.zig").link(exe, root_path);
    if (opt.link_bullet) @import("build/bullet.zig").link(exe, root_path);
    if (opt.link_chipmunk) @import("build/chipmunk.zig").link(exe, root_path);
}

/// compile shaders and load it as package
pub const ShaderSource = struct {
    shader_name: []const u8,
    shader_file: []const u8,
};
pub fn loadShaders(
    exe: *std.build.LibExeObjStep,
    srcs: []ShaderSource,
    package_name: []const u8,
) void {
    var buf: [64]u8 = undefined;
    const file_name = std.fmt.bufPrint(&buf, "{s}.zig", package_name) catch unreachable;

    // compile shader
    const vkbuild = @import("src/deps/vulkan/build.zig");
    const res = vkbuild.ResourceGenStep.init(exe.builder, file_name);
    for (srcs) |s| {
        res.addShader(s.shader_name, s.shader_file);
    }

    // add package
    exe.addPackage(.{
        .name = package_name,
        .path = .{ .generated = &res.output_file },
        .dependencies = null,
    });
}

/// root path
fn rootPath() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}
