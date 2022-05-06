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
    exe.addPackage(gen.package);

    // link sdl
    const sdk = @import("../src/deps/sdl/Sdk.zig").init(exe.builder);
    const build_options = sdk.builder.addOptions();
    build_options.addOption(bool, "vulkan", true);
    sdk.link(exe, .dynamic);

    // use zplay
    exe.addPackage(.{
        .name = "zplay",
        .path = .{ .path = root_path ++ "/src/zplay.zig" },
        .dependencies = &.{
            sdk.getWrapperPackage("sdl"),
        },
    });
}
