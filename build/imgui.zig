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

    var imgui = b.addStaticLibrary("imgui", null);
    imgui.setTarget(target);
    imgui.linkLibC();
    imgui.linkLibCpp();
    if (exe.target.isWindows()) {
        imgui.linkSystemLibrary("winmm");
        imgui.linkSystemLibrary("user32");
        imgui.linkSystemLibrary("imm32");
        imgui.linkSystemLibrary("gdi32");
    }
    imgui.addIncludeDir("src/deps/imgui/c");
    imgui.addCSourceFiles(&.{
        root_path ++ "/src/deps/imgui/c/imgui.cpp",
        root_path ++ "/src/deps/imgui/c/imgui_demo.cpp",
        root_path ++ "/src/deps/imgui/c/imgui_draw.cpp",
        root_path ++ "/src/deps/imgui/c/imgui_tables.cpp",
        root_path ++ "/src/deps/imgui/c/imgui_widgets.cpp",
        root_path ++ "/src/deps/imgui/c/cimgui.cpp",
        root_path ++ "/src/deps/imgui/c/imgui_impl_opengl3.cpp",
        root_path ++ "/src/deps/imgui/c/imgui_impl_opengl3_wrapper.cpp",
    }, flags.items);
    imgui.addCSourceFiles(&.{
        root_path ++ "/src/deps/imgui/ext/implot/c/implot.cpp",
        root_path ++ "/src/deps/imgui/ext/implot/c/implot_items.cpp",
        root_path ++ "/src/deps/imgui/ext/implot/c/implot_demo.cpp",
        root_path ++ "/src/deps/imgui/ext/implot/c/cimplot.cpp",
    }, flags.items);
    imgui.addCSourceFiles(&.{
        root_path ++ "/src/deps/imgui/ext/imnodes/c/imnodes.cpp",
        root_path ++ "/src/deps/imgui/ext/imnodes/c/cimnodes.cpp",
    }, flags.items);
    exe.linkLibrary(imgui);
}
