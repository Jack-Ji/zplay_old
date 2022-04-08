const std = @import("std");

pub fn link(
    exe: *std.build.LibExeObjStep,
    comptime root_path: []const u8,
) void {
    _ = root_path;

    const sdl = @import("../src/deps/sdl/Sdk.zig").init(exe.builder);
    sdl.link(exe, .dynamic);
}
