const std = @import("std");
const builtin = @import("builtin");
const zp = @import("../zplay.zig");
const event = zp.event;
const sdl = @import("sdl");
const c = sdl.c;
const api = @import("api.zig");

const string_c = @cImport({
    @cInclude("string.h");
});
extern fn SDL_free(mem: ?*c_void) void;

var performance_frequency: u64 = undefined;

const BackendData = struct {
    window: *c.SDL_Window,
    time: u64,
    mouse_pressed: [3]bool,
    mouse_cursors: [api.ImGuiMouseCursor_COUNT]?*c.SDL_Cursor,
    clipboard_text_data: ?[*c]u8,
    mouse_can_use_global_state: bool,
};

pub fn init(window: *c.SDL_Window) !void {
    const io = @ptrCast(*api.ImGuiIO, api.igGetIO());
    if (io.BackendPlatformUserData != null) {
        std.debug.panic("already initialized!", .{});
    }

    var mouse_can_use_global_state = false;
    const backend = @ptrCast(?[*:0]const u8, c.SDL_GetCurrentVideoDriver());
    if (backend) |bkd| {
        const global_mouse_whitelist = .{
            "windows",
            "cocoa",
            "x11",
            "DIVE",
            "VMAN",
        };
        inline for (global_mouse_whitelist) |wh| {
            if (string_c.strcmp(wh, bkd) == 0) {
                mouse_can_use_global_state = true;
            }
        }
    }

    const bd = try std.heap.c_allocator.create(BackendData);
    bd.window = window;
    bd.time = 0;
    bd.mouse_pressed = [_]bool{false} ** bd.mouse_pressed.len;
    bd.mouse_cursors = [_]?*c.SDL_Cursor{null} ** bd.mouse_cursors.len;
    bd.clipboard_text_data = null;
    bd.mouse_can_use_global_state = mouse_can_use_global_state;
    io.BackendPlatformUserData = bd;
    io.BackendPlatformName = "imgui_impl_sdl";
    io.BackendFlags |= api.ImGuiBackendFlags_HasMouseCursors;
    io.BackendFlags |= api.ImGuiBackendFlags_HasSetMousePos;

    // keyboard mapping. Dear ImGui will use those indices to peek into the io.KeysDown[] array.
    io.KeyMap[api.ImGuiKey_Tab] = c.SDL_SCANCODE_TAB;
    io.KeyMap[api.ImGuiKey_LeftArrow] = c.SDL_SCANCODE_LEFT;
    io.KeyMap[api.ImGuiKey_RightArrow] = c.SDL_SCANCODE_RIGHT;
    io.KeyMap[api.ImGuiKey_UpArrow] = c.SDL_SCANCODE_UP;
    io.KeyMap[api.ImGuiKey_DownArrow] = c.SDL_SCANCODE_DOWN;
    io.KeyMap[api.ImGuiKey_PageUp] = c.SDL_SCANCODE_PAGEUP;
    io.KeyMap[api.ImGuiKey_PageDown] = c.SDL_SCANCODE_PAGEDOWN;
    io.KeyMap[api.ImGuiKey_Home] = c.SDL_SCANCODE_HOME;
    io.KeyMap[api.ImGuiKey_End] = c.SDL_SCANCODE_END;
    io.KeyMap[api.ImGuiKey_Insert] = c.SDL_SCANCODE_INSERT;
    io.KeyMap[api.ImGuiKey_Delete] = c.SDL_SCANCODE_DELETE;
    io.KeyMap[api.ImGuiKey_Backspace] = c.SDL_SCANCODE_BACKSPACE;
    io.KeyMap[api.ImGuiKey_Space] = c.SDL_SCANCODE_SPACE;
    io.KeyMap[api.ImGuiKey_Enter] = c.SDL_SCANCODE_RETURN;
    io.KeyMap[api.ImGuiKey_Escape] = c.SDL_SCANCODE_ESCAPE;
    io.KeyMap[api.ImGuiKey_KeyPadEnter] = c.SDL_SCANCODE_KP_ENTER;
    io.KeyMap[api.ImGuiKey_A] = c.SDL_SCANCODE_A;
    io.KeyMap[api.ImGuiKey_C] = c.SDL_SCANCODE_C;
    io.KeyMap[api.ImGuiKey_V] = c.SDL_SCANCODE_V;
    io.KeyMap[api.ImGuiKey_X] = c.SDL_SCANCODE_X;
    io.KeyMap[api.ImGuiKey_Y] = c.SDL_SCANCODE_Y;
    io.KeyMap[api.ImGuiKey_Z] = c.SDL_SCANCODE_Z;

    // clipboard callbacks
    io.SetClipboardTextFn = setClipboardText;
    io.GetClipboardTextFn = getClipboardText;
    io.ClipboardUserData = null;

    // load mouse cursors
    bd.mouse_cursors[api.ImGuiMouseCursor_Arrow] = c.SDL_CreateSystemCursor(c.SDL_SYSTEM_CURSOR_ARROW);
    bd.mouse_cursors[api.ImGuiMouseCursor_TextInput] = c.SDL_CreateSystemCursor(c.SDL_SYSTEM_CURSOR_IBEAM);
    bd.mouse_cursors[api.ImGuiMouseCursor_ResizeAll] = c.SDL_CreateSystemCursor(c.SDL_SYSTEM_CURSOR_SIZEALL);
    bd.mouse_cursors[api.ImGuiMouseCursor_ResizeNS] = c.SDL_CreateSystemCursor(c.SDL_SYSTEM_CURSOR_SIZENS);
    bd.mouse_cursors[api.ImGuiMouseCursor_ResizeEW] = c.SDL_CreateSystemCursor(c.SDL_SYSTEM_CURSOR_SIZEWE);
    bd.mouse_cursors[api.ImGuiMouseCursor_ResizeNESW] = c.SDL_CreateSystemCursor(c.SDL_SYSTEM_CURSOR_SIZENESW);
    bd.mouse_cursors[api.ImGuiMouseCursor_ResizeNWSE] = c.SDL_CreateSystemCursor(c.SDL_SYSTEM_CURSOR_SIZENWSE);
    bd.mouse_cursors[api.ImGuiMouseCursor_Hand] = c.SDL_CreateSystemCursor(c.SDL_SYSTEM_CURSOR_HAND);
    bd.mouse_cursors[api.ImGuiMouseCursor_NotAllowed] = c.SDL_CreateSystemCursor(c.SDL_SYSTEM_CURSOR_NO);

    // Set SDL hint to receive mouse click events on window focus, otherwise SDL doesn't emit the event.
    // Without this, when clicking to gain focus, our widgets wouldn't activate even though they showed as hovered.
    // (This is unfortunately a global SDL setting, so enabling it might have a side-effect on your application.
    // It is unlikely to make a difference, but if your app absolutely needs to ignore the initial on-focus click:
    // you can ignore SDL_MOUSEBUTTONDOWN events coming right after a SDL_WINDOWEVENT_FOCUS_GAINED)
    _ = c.SDL_SetHint(c.SDL_HINT_MOUSE_FOCUS_CLICKTHROUGH, "1");

    performance_frequency = c.SDL_GetPerformanceFrequency();
}

pub fn deinit() void {
    const io = @ptrCast(*api.ImGuiIO, api.igGetIO());
    const bd = getBackendData().?;

    if (bd.clipboard_text_data) |data| {
        SDL_free(data);
    }

    for (bd.mouse_cursors) |cursor| {
        c.SDL_FreeCursor(cursor);
    }

    io.BackendPlatformUserData = null;
    io.BackendPlatformName = null;
    std.heap.c_allocator.destroy(bd);
}

// You can read the io.WantCaptureMouse, io.WantCaptureKeyboard flags to tell if dear api wants to use your inputs.
// - When io.WantCaptureMouse is true, do not dispatch mouse input data to your main application.
// - When io.WantCaptureKeyboard is true, do not dispatch keyboard input data to your main application.
// Generally you may always pass all inputs to dear api, and hide them from your application based on those two flags.
// If you have multiple SDL events and some of them are not meant to be used by dear api, you may need to filter events based on their windowID field.
pub fn processEvent(e: event.Event) bool {
    const io = @ptrCast(*api.ImGuiIO, api.igGetIO());
    const bd = getBackendData().?;

    switch (e) {
        .mouse_event => |ee| {
            switch (ee.data) {
                .button => |button| {
                    if (button.clicked) {
                        bd.mouse_pressed[
                            switch (button.btn) {
                                .left => 0,
                                .right => 1,
                                .middle => 2,
                            }
                        ] = true;
                    }
                },
                .wheel => |wheel| {
                    if (wheel.scroll_x > 0) io.MouseWheelH += 1;
                    if (wheel.scroll_x < 0) io.MouseWheelH -= 1;
                    if (wheel.scroll_y > 0) io.MouseWheel += 1;
                    if (wheel.scroll_y < 0) io.MouseWheel -= 1;
                },
                else => {},
            }
        },
        .text_input_event => |ee| {
            api.ImGuiIO_AddInputCharactersUTF8(io, &ee.text);
        },
        .keyboard_event => |ee| {
            const key = ee.scan_code;
            const mod_state = c.SDL_GetModState();
            io.KeysDown[@intCast(u32, @enumToInt(key))] = (ee.trigger_type == .down);
            io.KeyShift = ((mod_state & c.KMOD_SHIFT) != 0);
            io.KeyCtrl = ((mod_state & c.KMOD_CTRL) != 0);
            io.KeyAlt = ((mod_state & c.KMOD_ALT) != 0);
            if (builtin.os.tag == .windows) {
                io.KeySuper = false;
            } else {
                io.KeySuper = ((mod_state & c.KMOD_GUI) != 0);
            }
        },
        else => {
            return false;
        },
    }

    return true;
}

// begin new frame for gui rendering
pub fn newFrame() void {
    const io = @ptrCast(*api.ImGuiIO, api.igGetIO());
    const bd = getBackendData().?;

    // Setup display size (every frame to accommodate for window resizing)
    var w: c_int = undefined;
    var h: c_int = undefined;
    var display_w: c_int = undefined;
    var display_h: c_int = undefined;
    c.SDL_GetWindowSize(bd.window, &w, &h);
    if ((c.SDL_GetWindowFlags(bd.window) & c.SDL_WINDOW_MINIMIZED) != 0) {
        w = 0;
        h = 0;
    }
    c.SDL_GL_GetDrawableSize(bd.window, &display_w, &display_h);
    io.DisplaySize = .{
        .x = @intToFloat(f32, w),
        .y = @intToFloat(f32, h),
    };
    if (w > 0 and h > 0) {
        io.DisplayFramebufferScale = .{
            .x = @intToFloat(f32, display_w) / @intToFloat(f32, w),
            .y = @intToFloat(f32, display_h) / @intToFloat(f32, h),
        };
    }

    // Setup time step (we don't use SDL_GetTicks() because it is using millisecond resolution)
    const current_time = c.SDL_GetPerformanceCounter();
    if (bd.time > 0) {
        io.DeltaTime = @floatCast(f32, @intToFloat(f64, current_time - bd.time) / @intToFloat(f64, performance_frequency));
    } else {
        io.DeltaTime = 1.0 / 60.0;
    }
    bd.time = current_time;

    updateMousePosAndButtons();
    updateMouseCursor();

    // Update game controllers (if enabled and available)
    updateGamePads();
}

// backend data stored in io.BackendPlatformUserData to allow support for multiple Dear ImGui contexts
// It is STRONGLY preferred that you use docking branch with multi-viewports (== single Dear ImGui context + multiple windows) instead of multiple Dear ImGui contexts.
fn getBackendData() ?*BackendData {
    const io = @ptrCast(*api.ImGuiIO, api.igGetIO());
    const context = @ptrCast(?*api.ImGuiContext, api.igGetCurrentContext());
    if (context) |_| {
        return @ptrCast(
            ?*BackendData,
            @alignCast(@alignOf(*BackendData), io.BackendPlatformUserData),
        );
    }
    return null;
}

// clipboard callback
fn getClipboardText(_: ?*c_void) callconv(.C) [*c]u8 {
    const bd = getBackendData().?;

    if (bd.clipboard_text_data) |data| {
        SDL_free(data);
    }
    bd.clipboard_text_data = @ptrCast([*c]u8, c.SDL_GetClipboardText());
    return bd.clipboard_text_data.?;
}

// clipboard callback
fn setClipboardText(_: ?*c_void, text: [*c]const u8) callconv(.C) void {
    _ = c.SDL_SetClipboardText(text);
}

fn updateMousePosAndButtons() void {
    const io = @ptrCast(*api.ImGuiIO, api.igGetIO());
    const bd = getBackendData().?;

    const mouse_pos_prev = io.MousePos;
    io.MousePos = .{
        .x = -std.math.f32_max,
        .y = -std.math.f32_max,
    };

    // update mouse buttons
    var mouse_x_local: c_int = undefined;
    var mouse_y_local: c_int = undefined;
    const mouse_buttons = @bitCast(c_int, c.SDL_GetMouseState(&mouse_x_local, &mouse_y_local));
    io.MouseDown[0] = bd.mouse_pressed[0] or (mouse_buttons & SDL_BUTTON_LMASK) != 0; // If a mouse press event came, always pass it as "mouse held this frame", so we don't miss click-release events that are shorter than 1 frame.
    io.MouseDown[1] = bd.mouse_pressed[1] or (mouse_buttons & SDL_BUTTON_RMASK) != 0;
    io.MouseDown[2] = bd.mouse_pressed[2] or (mouse_buttons & SDL_BUTTON_MMASK) != 0;
    bd.mouse_pressed[0] = false;
    bd.mouse_pressed[1] = false;
    bd.mouse_pressed[2] = false;

    // Obtain focused and hovered window. We forward mouse input when focused or when hovered (and no other window is capturing)
    const focused_window = c.SDL_GetKeyboardFocus();
    const hovered_window = c.SDL_GetMouseFocus();
    var mouse_window: ?*c.SDL_Window = null;
    if (hovered_window != null and bd.window == hovered_window.?) {
        mouse_window = hovered_window;
    } else if (focused_window != null and bd.window == focused_window.?) {
        mouse_window = focused_window;
    }

    // SDL_CaptureMouse() let the OS know e.g. that our api drag outside the SDL window boundaries shouldn't e.g. trigger other operations outside
    _ = c.SDL_CaptureMouse(if (api.igIsAnyMouseDown())
        c.SDL_TRUE
    else
        c.SDL_FALSE);

    if (mouse_window == null) return;

    // Set OS mouse position from Dear ImGui if requested (rarely used, only when ImGuiConfigFlags_NavEnableSetMousePos is enabled by user)
    if (io.WantSetMousePos) {
        c.SDL_WarpMouseInWindow(
            bd.window,
            @floatToInt(i32, mouse_pos_prev.x),
            @floatToInt(i32, mouse_pos_prev.y),
        );
    }

    // Set Dear ImGui mouse position from OS position + get buttons. (this is the common behavior)
    if (bd.mouse_can_use_global_state) {
        var mouse_x_global: c_int = undefined;
        var mouse_y_global: c_int = undefined;
        var window_x: c_int = undefined;
        var window_y: c_int = undefined;
        _ = c.SDL_GetGlobalMouseState(&mouse_x_global, &mouse_y_global);
        _ = c.SDL_GetWindowPosition(mouse_window, &window_x, &window_y);
        io.MousePos = .{
            .x = @intToFloat(f32, mouse_x_global - window_x),
            .y = @intToFloat(f32, mouse_y_global - window_y),
        };
    } else {
        io.MousePos = .{
            .x = @intToFloat(f32, mouse_x_local),
            .y = @intToFloat(f32, mouse_y_local),
        };
    }
}

fn updateMouseCursor() void {
    const io = @ptrCast(*api.ImGuiIO, api.igGetIO());
    const bd = getBackendData().?;

    if ((io.ConfigFlags & api.ImGuiConfigFlags_NoMouseCursorChange) != 0) {
        return;
    }

    const cursor = api.igGetMouseCursor();
    if (io.MouseDrawCursor or cursor == api.ImGuiMouseCursor_None) {
        // hide OS mouse cursor if api is drawing it or if it wants no cursor
        _ = c.SDL_ShowCursor(c.SDL_FALSE);
    } else {
        // show OS mouse cursor
        if (bd.mouse_cursors[@intCast(u32, cursor)]) |cs| {
            c.SDL_SetCursor(cs);
        } else {
            c.SDL_SetCursor(bd.mouse_cursors[api.ImGuiMouseCursor_Arrow]);
        }
        _ = c.SDL_ShowCursor(c.SDL_TRUE);
    }
}

fn updateGamePads() void {
    const io = @ptrCast(*api.ImGuiIO, api.igGetIO());
    @memset(@ptrCast([*]u8, &io.NavInputs), 0, @sizeOf(@TypeOf(io.NavInputs)));

    if ((io.ConfigFlags & api.ImGuiConfigFlags_NavEnableGamepad) == 0) {
        return;
    }

    // get gamepad
    const controller = c.SDL_GameControllerOpen(0);
    if (controller == null) {
        io.BackendFlags &= ~api.ImGuiBackendFlags_HasGamepad;
    }

    // update gamepad inputs
    const thumb_dead_zone = 8000; // SDL_gamecontroller.h suggests using this value.
    mapButton(io, controller, api.ImGuiNavInput_Activate, c.SDL_CONTROLLER_BUTTON_A); // Cross / A
    mapButton(io, controller, api.ImGuiNavInput_Cancel, c.SDL_CONTROLLER_BUTTON_B); // Circle / B
    mapButton(io, controller, api.ImGuiNavInput_Menu, c.SDL_CONTROLLER_BUTTON_X); // Square / X
    mapButton(io, controller, api.ImGuiNavInput_Input, c.SDL_CONTROLLER_BUTTON_Y); // Triangle / Y
    mapButton(io, controller, api.ImGuiNavInput_DpadLeft, c.SDL_CONTROLLER_BUTTON_DPAD_LEFT); // D-Pad Left
    mapButton(io, controller, api.ImGuiNavInput_DpadRight, c.SDL_CONTROLLER_BUTTON_DPAD_RIGHT); // D-Pad Right
    mapButton(io, controller, api.ImGuiNavInput_DpadUp, c.SDL_CONTROLLER_BUTTON_DPAD_UP); // D-Pad Up
    mapButton(io, controller, api.ImGuiNavInput_DpadDown, c.SDL_CONTROLLER_BUTTON_DPAD_DOWN); // D-Pad Down
    mapButton(io, controller, api.ImGuiNavInput_FocusPrev, c.SDL_CONTROLLER_BUTTON_LEFTSHOULDER); // L1 / LB
    mapButton(io, controller, api.ImGuiNavInput_FocusNext, c.SDL_CONTROLLER_BUTTON_RIGHTSHOULDER); // R1 / RB
    mapButton(io, controller, api.ImGuiNavInput_TweakSlow, c.SDL_CONTROLLER_BUTTON_LEFTSHOULDER); // L1 / LB
    mapButton(io, controller, api.ImGuiNavInput_TweakFast, c.SDL_CONTROLLER_BUTTON_RIGHTSHOULDER); // R1 / RB
    mapAnalog(io, controller, api.ImGuiNavInput_LStickLeft, c.SDL_CONTROLLER_AXIS_LEFTX, -thumb_dead_zone, -32768);
    mapAnalog(io, controller, api.ImGuiNavInput_LStickRight, c.SDL_CONTROLLER_AXIS_LEFTX, thumb_dead_zone, 32767);
    mapAnalog(io, controller, api.ImGuiNavInput_LStickUp, c.SDL_CONTROLLER_AXIS_LEFTY, -thumb_dead_zone, -32767);
    mapAnalog(io, controller, api.ImGuiNavInput_LStickDown, c.SDL_CONTROLLER_AXIS_LEFTY, thumb_dead_zone, 32767);

    io.BackendFlags |= api.ImGuiBackendFlags_HasGamepad;
}

inline fn mapButton(
    io: *api.ImGuiIO,
    controller: ?*c.SDL_GameController,
    input: c_int,
    button: c_int,
) void {
    if (c.SDL_GameControllerGetButton(controller, button) != 0) {
        io.NavInputs[@intCast(u32, input)] = 1.0;
    } else {
        io.NavInputs[@intCast(u32, input)] = 0.0;
    }
}

inline fn mapAnalog(
    io: *api.ImGuiIO,
    controller: ?*c.SDL_GameController,
    input: api.ImGuiNavInput,
    axis: c_int,
    v0: i16,
    v1: i16,
) void {
    var vn = @intToFloat(f32, c.SDL_GameControllerGetAxis(controller, axis) - v0) / @intToFloat(f32, v1 - v0);
    if (vn > 1.0)
        vn = 1.0;
    if (vn > 0 and vn > io.NavInputs[@intCast(u32, input)])
        io.NavInputs[@intCast(u32, input)] = vn;
}

// TODO: use sdl binding if possible, have to get my own because of compile issue
inline fn SDL_BUTTON(X: c_int) c_int {
    return @as(c_int, 1) << @intCast(u5, X - @as(c_int, 1));
}
const SDL_BUTTON_LEFT = @as(c_int, 1);
const SDL_BUTTON_MIDDLE = @as(c_int, 2);
const SDL_BUTTON_RIGHT = @as(c_int, 3);
const SDL_BUTTON_X1 = @as(c_int, 4);
const SDL_BUTTON_X2 = @as(c_int, 5);
const SDL_BUTTON_LMASK = SDL_BUTTON(SDL_BUTTON_LEFT);
const SDL_BUTTON_MMASK = SDL_BUTTON(SDL_BUTTON_MIDDLE);
const SDL_BUTTON_RMASK = SDL_BUTTON(SDL_BUTTON_RIGHT);
const SDL_BUTTON_X1MASK = SDL_BUTTON(SDL_BUTTON_X1);
const SDL_BUTTON_X2MASK = SDL_BUTTON(SDL_BUTTON_X2);
