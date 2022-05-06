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
    var sdl_package = sdk.getWrapperPackage("sdl");
    sdl_package.dependencies = &.{
        sdk.getNativePackageVulkan("sdl-native", gen.package),
    };
    exe.addPackage(.{
        .name = "zplay",
        .path = .{ .path = root_path ++ "/src/zplay.zig" },
        .dependencies = &.{
            sdl_package,
            gen.package,
        },
    });
}
