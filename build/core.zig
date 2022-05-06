const std = @import("std");
const vkgen = @import("../src/deps/vulkan/generator/index.zig");

pub fn link(
    exe: *std.build.LibExeObjStep,
    comptime root_path: []const u8,
) void {
    // generate vulkan bindings
    const gen = vkgen.VkGenerateStep.init(
        exe.builder,
        root_path ++ "/src/deps/vulkan/examples/vk.xml",
        "vk.zig",
    );

    // link sdl
    const sdk = @import("../src/deps/sdl/Sdk.zig").init(exe.builder);
    sdk.link(exe, .dynamic);

    // use zplay
    exe.addPackage(.{
        .name = "zplay",
        .path = .{ .path = root_path ++ "/src/zplay.zig" },
        .dependencies = &.{
            sdk.getWrapperPackageVulkan("sdl", gen.package),
            gen.package,
        },
    });
}
