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
    };
    inline for (examples) |name| {
        const exe = b.addExecutable(
            name,
            "examples" ++ std.fs.path.sep_str ++ name ++ ".zig",
        );
        exe.setBuildMode(mode);
        exe.setTarget(target);
        link(b, exe);
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

pub fn link(b: *std.build.Builder, exe: *std.build.LibExeObjStep) void {
    const sdl = @import("src/sdl/Sdk.zig").init(b);
    sdl.link(exe, .dynamic);
    exe.addPackage(.{
        .name = "zplay",
        .path = .{
            .path = libRoot() ++ "/src/lib.zig",
        },
        .dependencies = &[_]std.build.Pkg{
            sdl.getWrapperPackage("sdl"),
        },
    });
}

fn libRoot() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}
