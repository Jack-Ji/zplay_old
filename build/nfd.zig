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
    flags.append("-fno-sanitize=undefined") catch unreachable;

    var nfd = b.addStaticLibrary("nfd", null);
    nfd.setTarget(target);
    nfd.linkLibC();
    if (nfd.target.isDarwin()) {
        nfd.linkFramework("AppKit");
    } else if (nfd.target.isWindows()) {
        nfd.linkSystemLibrary("shell32");
        nfd.linkSystemLibrary("ole32");
        nfd.linkSystemLibrary("uuid"); // needed by MinGW
    } else {
        nfd.linkSystemLibrary("atk-1.0");
        nfd.linkSystemLibrary("gdk-3");
        nfd.linkSystemLibrary("gtk-3");
        nfd.linkSystemLibrary("glib-2.0");
        nfd.linkSystemLibrary("gobject-2.0");
    }
    nfd.addIncludeDir(root_path ++ "/src/deps/nfd/c/include");
    nfd.addCSourceFile(root_path ++ "/src/deps/nfd/c/nfd_common.c", flags.items);
    if (nfd.target.isDarwin()) {
        nfd.addCSourceFile(root_path ++ "/src/deps/nfd/c/nfd_cocoa.m", flags.items);
    } else if (nfd.target.isWindows()) {
        nfd.addCSourceFile(root_path ++ "/src/deps/nfd/c/nfd_win.cpp", flags.items);
    } else {
        nfd.addCSourceFile(root_path ++ "/src/deps/nfd/c/nfd_gtk.c", flags.items);
    }
    exe.linkLibrary(nfd);
}
