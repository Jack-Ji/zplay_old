const std = @import("std");
const sdl = @import("sdl");
const vk = @import("vulkan");
const zp = @import("../../zplay.zig");
const event = zp.event;
const sdl_impl = @import("sdl_impl.zig");
pub const c = @import("c.zig");

/// export friendly api
pub usingnamespace @import("api.zig");

/// icon font: font-awesome
pub const fontawesome = @import("fonts/fontawesome.zig");

/// export 3rd-party extensions
pub const ext = @import("ext/ext.zig");

/// imgui's vulkan impl api
pub const ImGuiImplVulkanInfo = extern struct {
    instance: vk.Instance,
    pdev: vk.PhysicalDevice,
    dev: vk.Device,
    queue_family: u32,
    queue: vk.Queue,
    pipeline_cache: vk.PipelineCache,
    descriptor_pool: vk.DescriptorPool,
    sub_pass: u32,
    min_image_count: u32,
    image_count: u32,
    msaa_samples: vk.SampleCountFlags,
    allocator: [*c]vk.AllocationCallbacks = null,
    checkResultFn: ?fn (err: vk.Result) callconv(.C) void = null,
};
extern fn _ImGui_ImplVulkan_LoadFunctions(loader: vk.PfnGetInstanceProcAddr) bool;
extern fn _ImGui_ImplVulkan_Init(info: *ImGuiImplVulkanInfo, render_pass: vk.RenderPass) bool;
extern fn _ImGui_ImplVulkan_Shutdown() void;
extern fn _ImGui_ImplVulkan_NewFrame() void;
extern fn _ImGui_ImplVulkan_RenderDrawData(draw_data: *c.ImDrawData, command_buffer: vk.CommandBuffer) void;

/// internal static vars
var initialized = false;
var plot_ctx: ?*ext.plot.ImPlotContext = undefined;
var nodes_ctx: ?*ext.nodes.ImNodesContext = undefined;

/// initialize sdl2 and vulkan backend
pub fn init(
    window: sdl.Window,
    info: *ImGuiImplVulkanInfo,
    render_pass: vk.RenderPass,
) !void {
    _ = c.igCreateContext(null);
    try sdl_impl.init(window.ptr);
    const vkGetInstanceProcAddr = sdl.c.SDL_Vulkan_GetVkGetInstanceProcAddr().?;
    if (!_ImGui_ImplVulkan_LoadFunctions(vkGetInstanceProcAddr)) {
        std.debug.panic("load vk functions failed", .{});
    }
    if (!_ImGui_ImplVulkan_Init(info, render_pass)) {
        std.debug.panic("init render backend failed", .{});
    }
    plot_ctx = ext.plot.createContext();
    if (plot_ctx == null) {
        std.debug.panic("init imgui-extension:implot failed", .{});
    }
    nodes_ctx = ext.nodes.createContext();
    if (nodes_ctx == null) {
        std.debug.panic("init imgui-extension:imnodes failed", .{});
    }
    initialized = true;
}

/// release allocated resources
pub fn deinit() void {
    if (!initialized) {
        std.debug.panic("cimgui isn't initialized!", .{});
    }
    ext.nodes.destroyContext(nodes_ctx.?);
    ext.plot.destroyContext(plot_ctx.?);
    sdl_impl.deinit();
    _ImGui_ImplVulkan_Shutdown();
    initialized = false;
}

/// process i/o event
pub fn processEvent(e: event.Event) bool {
    if (!initialized) {
        std.debug.panic("cimgui isn't initialized!", .{});
    }
    return sdl_impl.processEvent(e);
}

/// begin frame
pub fn beginFrame() void {
    if (!initialized) {
        std.debug.panic("cimgui isn't initialized!", .{});
    }
    sdl_impl.newFrame();
    _ImGui_ImplVulkan_NewFrame();
    c.igNewFrame();
}

/// end frame
pub fn endFrame(command_buffer: vk.CommandBuffer) void {
    if (!initialized) {
        std.debug.panic("cimgui isn't initialized!", .{});
    }
    c.igRender();
    _ImGui_ImplVulkan_RenderDrawData(
        c.igGetDrawData(),
        command_buffer,
    );
}

/// load font awesome
pub fn loadFontAwesome(size: f32, regular: bool, monospaced: bool) !*c.ImFont {
    if (!initialized) {
        std.debug.panic("cimgui isn't initialized!", .{});
    }

    var font_atlas = c.igGetIO().*.Fonts;
    _ = c.ImFontAtlas_AddFontDefault(
        font_atlas,
        null,
    );

    var ranges = [3]c.ImWchar{
        fontawesome.ICON_MIN_FA,
        fontawesome.ICON_MAX_FA,
        0,
    };
    var cfg = c.ImFontConfig_ImFontConfig();
    defer c.ImFontConfig_destroy(cfg);
    cfg.*.PixelSnapH = true;
    cfg.*.MergeMode = true;
    if (monospaced) {
        cfg.*.GlyphMinAdvanceX = size;
    }
    const font = c.ImFontAtlas_AddFontFromFileTTF(
        font_atlas,
        if (regular)
            fontawesome.FONT_ICON_FILE_NAME_FAR
        else
            fontawesome.FONT_ICON_FILE_NAME_FAS,
        size,
        cfg,
        &ranges,
    );
    if (font == null) {
        std.debug.panic("load font awesome failed!", .{});
    }
    if (!c.ImFontAtlas_Build(font_atlas)) {
        std.debug.panic("build font atlas failed!", .{});
    }
    return font;
}

/// load custom font
pub fn loadTTF(
    path: [:0]const u8,
    size: f32,
    addional_ranges: ?[*c]const c.ImWchar,
) !*c.ImFont {
    if (!initialized) {
        std.debug.panic("cimgui isn't initialized!", .{});
    }
    var font_atlas = c.igGetIO().*.Fonts;

    var default_ranges = c.ImFontAtlas_GetGlyphRangesDefault(font_atlas);
    var font = c.ImFontAtlas_AddFontFromFileTTF(
        font_atlas,
        path.ptr,
        size,
        null,
        default_ranges,
    );
    if (font == null) {
        std.debug.panic("load font({s}) failed!", .{path});
    }

    if (addional_ranges) |ranges| {
        var cfg = c.ImFontConfig_ImFontConfig();
        defer c.ImFontConfig_destroy(cfg);
        cfg.*.MergeMode = true;
        font = c.ImFontAtlas_AddFontFromFileTTF(
            font_atlas,
            path.ptr,
            size,
            cfg,
            ranges,
        );
        if (font == null) {
            std.debug.panic("load font({s}) failed!", .{path});
        }
    }

    if (!c.ImFontAtlas_Build(font_atlas)) {
        std.debug.panic("build font atlas failed!", .{});
    }
    return font;
}

/// determine whether next character in given buffer is renderable
pub fn isCharRenderable(buf: []const u8) bool {
    var char: c_uint = undefined;
    _ = c.igImTextCharFromUtf8(&char, buf.ptr, buf.ptr + buf.len);
    if (char == 0) {
        return false;
    }
    return c.ImFont_FindGlyphNoFallback(
        c.igGetFont(),
        @intCast(c.ImWchar, char),
    ) != null;
}
