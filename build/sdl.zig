const std = @import("std");

pub fn link(
    b: *std.build.Builder,
    exe: *std.build.LibExeObjStep,
    target: std.zig.CrossTarget,
    comptime root_path: []const u8,
) void {
    _ = target;
    _ = root_path;

    const sdl = @import("../src/deps/sdl/Sdk.zig").init(b);
    sdl.link(exe, .dynamic);
}
