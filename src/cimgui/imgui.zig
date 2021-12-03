const std = @import("std");
const endian = @import("builtin").target.cpu.arch.endian();
const zp = @import("../lib.zig");
const event = zp.event;
const sdl = @import("sdl");
const sdl_impl = @import("sdl_impl.zig");

/// export imgui api
pub usingnamespace @import("api.zig");
const api = @import("api.zig");

/// icon font: font-awesome 
pub const fontawesome = @import("fonts/fontawesome.zig");

/// export custom component
pub const custom = @import("custom_component.zig");

/// export 3rd-party extensions
pub const ext = @import("ext/ext.zig");

extern fn _ImGui_ImplOpenGL3_Init(glsl_version: [*c]u8) bool;
extern fn _ImGui_ImplOpenGL3_Shutdown() void;
extern fn _ImGui_ImplOpenGL3_NewFrame() void;
extern fn _ImGui_ImplOpenGL3_RenderDrawData(draw_data: *api.ImDrawData) void;

/// internal static vars
var initialized = false;
var plot_ctx: ?*ext.plot.ImPlotContext = undefined;
var nodes_ctx: ?*ext.nodes.ImNodesContext = undefined;

/// initialize sdl2 and opengl3 backend
pub fn init(window: sdl.Window) !void {
    _ = api.createContext(null);
    try sdl_impl.init(window.ptr);
    if (!_ImGui_ImplOpenGL3_Init(null)) {
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
    ext.nodes.destroyContext(nodes_ctx);
    ext.plot.destroyContext(plot_ctx);
    sdl_impl.deinit();
    _ImGui_ImplOpenGL3_Shutdown();
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
    _ImGui_ImplOpenGL3_NewFrame();
    api.newFrame();
}

/// end frame
pub fn endFrame() void {
    if (!initialized) {
        std.debug.panic("cimgui isn't initialized!", .{});
    }
    api.render();
    _ImGui_ImplOpenGL3_RenderDrawData(api.getDrawData());
}

/// load font awesome
pub fn loadFontAwesome(size: f32, regular: bool, monospaced: bool) !*api.ImFont {
    if (!initialized) {
        std.debug.panic("cimgui isn't initialized!", .{});
    }

    var font_atlas = api.getIO().*.Fonts;
    _ = api.ImFontAtlas_AddFontDefault(
        font_atlas,
        null,
    );

    var ranges = [3]api.ImWchar{
        fontawesome.ICON_MIN_FA,
        fontawesome.ICON_MAX_FA,
        0,
    };
    var cfg = api.ImFontConfig_ImFontConfig();
    defer api.ImFontConfig_destroy(cfg);
    cfg.*.PixelSnapH = true;
    cfg.*.MergeMode = true;
    if (monospaced) {
        cfg.*.GlyphMinAdvanceX = size;
    }
    const font = api.ImFontAtlas_AddFontFromFileTTF(
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
    if (!api.ImFontAtlas_Build(font_atlas)) {
        std.debug.panic("build font atlas failed!", .{});
    }
    return font;
}

/// load custom font
pub fn loadTTF(
    path: [:0]const u8,
    size: f32,
    addional_ranges: ?[*c]const api.ImWchar,
) !*api.ImFont {
    if (!initialized) {
        std.debug.panic("cimgui isn't initialized!", .{});
    }
    var font_atlas = api.getIO().*.Fonts;

    var default_ranges = api.ImFontAtlas_GetGlyphRangesDefault(font_atlas);
    var font = api.ImFontAtlas_AddFontFromFileTTF(
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
        var cfg = api.ImFontConfig_ImFontConfig();
        defer api.ImFontConfig_destroy(cfg);
        cfg.*.MergeMode = true;
        font = api.ImFontAtlas_AddFontFromFileTTF(
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

    if (!api.ImFontAtlas_Build(font_atlas)) {
        std.debug.panic("build font atlas failed!", .{});
    }
    return font;
}

/// determine whether next character in given buffer is renderable
pub fn isCharRenderable(buf: []const u8) bool {
    var char: c_uint = undefined;
    _ = api.imTextCharFromUtf8(&char, buf.ptr, buf.ptr + buf.len);
    if (char == 0) {
        return false;
    }
    return api.ImFont_FindGlyphNoFallback(
        api.getFont(),
        @intCast(api.ImWchar, char),
    ) != null;
}
