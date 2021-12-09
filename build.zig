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
        "2d_texture",
        "cubes",
        "3d_camera",
        "phong_lighting",
        "imgui_demo",
        "imgui_fontawesome",
        "imgui_ttf",
        "vector_graphics",
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

pub fn link(b: *std.build.Builder, exe: *std.build.LibExeObjStep, target: std.zig.CrossTarget) void {
    var flags = std.ArrayList([]const u8).init(std.heap.page_allocator);
    if (b.is_release) flags.append("-Os") catch unreachable;
    flags.append("-Wno-return-type-c-linkage") catch unreachable;

    // link sdl
    const sdl = @import("src/sdl/Sdk.zig").init(b);
    sdl.link(exe, .dynamic);

    // link opengl
    var gl = b.addStaticLibrary("gl", null);
    gl.linkLibC();
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

    // link stb
    var stb = b.addStaticLibrary("stb", null);
    stb.linkLibC();
    stb.addCSourceFile(
        rootPath() ++ "/src/stb/c/stb_image_wrapper.c",
        flags.items,
    );
    exe.linkLibrary(stb);

    // link cimgui
    var cimgui = exe.builder.addStaticLibrary("cimgui", null);
    cimgui.linkLibC();
    cimgui.linkLibCpp();
    if (exe.target.isWindows()) {
        cimgui.linkSystemLibrary("winmm");
        cimgui.linkSystemLibrary("user32");
        cimgui.linkSystemLibrary("imm32");
        cimgui.linkSystemLibrary("gdi32");
    }
    cimgui.addIncludeDir("src/cimgui/c");
    cimgui.addCSourceFiles(&.{
        rootPath() ++ "/src/cimgui/c/imgui.cpp",
        rootPath() ++ "/src/cimgui/c/imgui_demo.cpp",
        rootPath() ++ "/src/cimgui/c/imgui_draw.cpp",
        rootPath() ++ "/src/cimgui/c/imgui_tables.cpp",
        rootPath() ++ "/src/cimgui/c/imgui_widgets.cpp",
        rootPath() ++ "/src/cimgui/c/cimgui.cpp",
        rootPath() ++ "/src/cimgui/c/imgui_impl_opengl3.cpp",
        rootPath() ++ "/src/cimgui/c/imgui_impl_opengl3_wrapper.cpp",
    }, flags.items);
    cimgui.addCSourceFiles(&.{
        rootPath() ++ "/src/cimgui/ext/cimplot/c/implot.cpp",
        rootPath() ++ "/src/cimgui/ext/cimplot/c/implot_items.cpp",
        rootPath() ++ "/src/cimgui/ext/cimplot/c/implot_demo.cpp",
        rootPath() ++ "/src/cimgui/ext/cimplot/c/cimplot.cpp",
    }, flags.items);
    cimgui.addCSourceFiles(&.{
        rootPath() ++ "/src/cimgui/ext/cimnodes/c/imnodes.cpp",
        rootPath() ++ "/src/cimgui/ext/cimnodes/c/cimnodes.cpp",
    }, flags.items);
    exe.linkLibrary(cimgui);

    // link cgltf
    var cgltf = exe.builder.addStaticLibrary("cgltf", null);
    cgltf.linkLibC();
    cgltf.addIncludeDir(rootPath() ++ "/src/cgltf/c");
    cgltf.addCSourceFile(rootPath() ++ "/src/cgltf/c/cgltf_wrapper.c", flags.items);
    exe.linkLibrary(cgltf);

    // link nanovg
    var nanovg = exe.builder.addStaticLibrary("nanovg", null);
    nanovg.linkLibC();
    nanovg.addIncludeDir(rootPath() ++ "/src/gl/c/include");
    nanovg.addIncludeDir(rootPath() ++ "/src/nanovg/c");
    nanovg.addCSourceFiles(&.{
        rootPath() ++ "/src/nanovg/c/nanovg.c",
        rootPath() ++ "/src/nanovg/c/nanovg_gl3_impl.c",
    }, flags.items);
    exe.linkLibrary(nanovg);

    // link nanosvg
    var nanosvg = exe.builder.addStaticLibrary("nanosvg", null);
    nanosvg.linkLibC();
    nanosvg.addIncludeDir(rootPath() ++ "/src/nanosvg/c");
    nanosvg.addCSourceFile(rootPath() ++ "/src/nanosvg/c/nanosvg_wrapper.c", flags.items);
    exe.linkLibrary(nanosvg);

    // use zplay
    exe.addPackage(.{
        .name = "zplay",
        .path = .{ .path = rootPath() ++ "/src/lib.zig" },
        .dependencies = &[_]std.build.Pkg{
            sdl.getWrapperPackage("sdl"),
        },
    });
}

fn rootPath() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}
