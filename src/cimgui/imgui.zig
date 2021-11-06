const std = @import("std");
const zp = @import("../lib.zig");
const event = zp.event;
const sdl = @import("sdl");
const sdl_impl = @import("sdl_impl.zig");

/// export imgui api
pub usingnamespace @import("api.zig");
const api = @import("api.zig");

/// export custom component
pub const custom = @import("custom_component.zig");

extern fn _ImGui_ImplOpenGL3_Init(glsl_version: [*c]u8) bool;
extern fn _ImGui_ImplOpenGL3_Shutdown() void;
extern fn _ImGui_ImplOpenGL3_NewFrame() void;
extern fn _ImGui_ImplOpenGL3_RenderDrawData(draw_data: *api.ImDrawData) void;

/// init detect
var initialized = false;

/// initialize sdl2 and opengl3 backend
pub fn init(window: sdl.Window) !void {
    _ = api.igCreateContext(null);
    try sdl_impl.init(window.ptr);
    if (!_ImGui_ImplOpenGL3_Init(null)) {
        std.debug.panic("init render backend failed", .{});
    }
    initialized = true;
}

/// release allocated resources
pub fn deinit() void {
    if (!initialized) {
        std.debug.panic("cimgui isn't initialized!", .{});
    }
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
    api.igNewFrame();
}

/// end frame
pub fn endFrame() void {
    if (!initialized) {
        std.debug.panic("cimgui isn't initialized!", .{});
    }
    api.igRender();
    _ImGui_ImplOpenGL3_RenderDrawData(api.igGetDrawData());
}
