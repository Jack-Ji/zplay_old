const std = @import("std");
const sdl = @import("sdl");
const c = sdl.c;
const gl = @import("gl/gl.zig");

/// application context
pub const Context = struct {
    _window: sdl.Window = undefined,
    _quit: bool = undefined,
    _title: [:0]const u8 = undefined,

    /// resizable mode
    _resizable: bool = undefined,

    /// fullscreen mode
    _fullscreen: bool = undefined,

    /// vsync mode
    _vsync: bool = undefined,

    /// relative mouse mode
    _relative_moouse: bool = undefined,

    /// number of seconds since launch/last-frame
    tick: f32 = undefined,
    delta_tick: f32 = undefined,

    /// kill app
    pub fn kill(self: *Context) void {
        self._quit = true;
    }

    /// poll event
    pub fn pollEvent(self: *Context) ?Event {
        _ = self;
        while (sdl.pollEvent()) |e| {
            if (Event.init(e)) |ze| {
                return ze;
            }
        }
        return null;
    }

    /// toggle resizable
    pub fn toggleResizable(self: *Context, on_off: ?bool) void {
        if (on_off) |state| {
            self._resizable = state;
        } else {
            self._resizable = !self._resizable;
        }
        _ = c.SDL_SetWindowResizable(
            self._window.ptr,
            if (self._resizable) c.SDL_TRUE else c.SDL_FALSE,
        );
    }

    /// toggle fullscreen
    pub fn toggleFullscreeen(self: *Context, on_off: ?bool) void {
        if (on_off) |state| {
            self._fullscreen = state;
        } else {
            self._fullscreen = !self._fullscreen;
        }
        _ = c.SDL_SetWindowFullscreen(
            self._window.ptr,
            if (self._fullscreen) c.SDL_WINDOW_FULLSCREEN else 0,
        );
    }

    ///  toggle vsync mode 
    pub fn toggleVsyncMode(self: *Context, on_off: ?bool) void {
        if (on_off) |state| {
            self._vsync = state;
        } else {
            self._vsync = !self._vsync;
        }
        sdl.gl.setSwapInterval(
            if (self._vsync) .vsync else .immediate,
        ) catch |e| {
            std.debug.print("toggle vsync failed, {}", .{e});
            std.debug.print("using mode: {s}", .{
                if (c.SDL_GL_GetSwapInterval() == 1) "immediate" else "vsync    ",
            });
        };
    }

    /// toggle relative mouse mode
    pub fn toggleRelativeMouseMode(self: *Context, on_off: ?bool) void {
        if (on_off) |state| {
            self._relative_moouse = state;
        } else {
            self._relative_moouse = !self._relative_moouse;
        }
        _ = c.SDL_SetRelativeMouseMode(
            if (self._relative_moouse) c.SDL_TRUE else c.SDL_FALSE,
        );
    }

    /// get position of window
    pub fn getPosition(self: Context, x: ?*i32, y: ?*i32) void {
        c.SDL_GetWindowPosition(self._window.ptr, x.?, y.?);
    }

    /// get size of window
    pub fn getSize(self: Context, w: ?*i32, h: ?*i32) void {
        c.SDL_GetWindowSize(self._window.ptr, w.?, h.?);
    }

    /// get key status
    pub fn isKeyPressed(self: Context, key: KeyboardEvent.ScanCode) bool {
        _ = self;
        const state = c.SDL_GetKeyboardState(null);
        return state[@enumToInt(key)] == 1;
    }

    /// get mouse state
    pub fn getMouseState(self: Context) sdl.MouseState {
        _ = self;
        return sdl.getMouseState();
    }

    /// move mouse to given position (relative to window)
    pub fn setMousePosition(self: Context, xrel: f32, yrel: f32) void {
        var w: i32 = undefined;
        var h: i32 = undefined;
        c.SDL_GetWindowSize(self._window.ptr, &w, &h);
        c.SDL_WarpMouseInWindow(
            self._window.ptr,
            @floatToInt(i32, @intToFloat(f32, w) * xrel),
            @floatToInt(i32, @intToFloat(f32, h) * yrel),
        );
    }

    /// toggle opengl capability
    pub fn toggleCapability(self: Context, cap: gl.Capability, on_off: bool) void {
        _ = self;
        if (on_off) {
            gl.enable(@enumToInt(cap));
        } else {
            gl.disable(@enumToInt(cap));
        }
        gl.checkError();
    }

    /// clear buffers
    pub fn clear(
        self: Context,
        clear_color: bool,
        clear_depth: bool,
        clear_stencil: bool,
        color: ?[4]f32,
    ) void {
        _ = self;
        var clear_flags: c_uint = 0;
        if (clear_color) {
            clear_flags |= gl.GL_COLOR_BUFFER_BIT;
        }
        if (clear_depth) {
            clear_flags |= gl.GL_DEPTH_BUFFER_BIT;
        }
        if (clear_stencil) {
            clear_flags |= gl.GL_STENCIL_BUFFER_BIT;
        }
        if (color) |rgba| {
            gl.clearColor(rgba[0], rgba[1], rgba[2], rgba[3]);
        }
        gl.clear(clear_flags);
        gl.checkError();
    }

    /// issue draw call
    pub fn drawBuffer(self: Context, primitive: gl.PrimitiveType, offset: usize, vertex_count: usize) void {
        _ = self;
        gl.drawArrays(
            @enumToInt(primitive),
            @intCast(gl.GLint, offset),
            @intCast(gl.GLsizei, vertex_count),
        );
        gl.checkError();
    }

    /// issue draw call (only accept unsigned-integer indices!)
    pub fn drawElements(self: Context, primitive: gl.PrimitiveType, offset: usize, element_count: usize) void {
        _ = self;
        gl.drawElements(
            @enumToInt(primitive),
            @intCast(gl.GLsizei, element_count),
            gl.dataType(u32),
            @intToPtr(*allowzero c_void, offset),
        );
        gl.checkError();
    }
};

/// application configurations
pub const Game = struct {
    /// called once before rendering loop starts
    init_fn: fn (ctx: *Context) anyerror!void,

    /// called every frame
    loop_fn: fn (ctx: *Context) void,

    /// called before life ends
    quit_fn: fn (ctx: *Context) void,

    /// window's title
    title: [:0]const u8 = "zplay",

    /// position of window
    pos_x: sdl.WindowPosition = .default,
    pos_y: sdl.WindowPosition = .default,

    /// width/height of window
    width: usize = 800,
    height: usize = 600,

    // resizable switch
    enable_resizable: bool = false,

    /// display switch
    enable_fullscreen: bool = false,

    // vsync switch
    enable_vsync: bool = true,

    /// relative mouse mode switch
    enable_relative_mouse_mode: bool = false,
};

/// system event
pub const WindowEvent = @import("WindowEvent.zig");
pub const KeyboardEvent = @import("KeyboardEvent.zig");
pub const MouseEvent = @import("MouseEvent.zig");
pub const GamepadEvent = @import("GamepadEvent.zig");
pub const QuitEvent = struct {};
pub const Event = union(enum) {
    window_event: WindowEvent,
    keyboard_event: KeyboardEvent,
    mouse_event: MouseEvent,
    gamepad_event: GamepadEvent,
    quit_event: QuitEvent,

    fn init(e: sdl.Event) ?Event {
        return switch (e) {
            .window => |ee| Event{
                .window_event = WindowEvent.init(ee),
            },
            .key_up => |ee| Event{
                .keyboard_event = KeyboardEvent.init(ee),
            },
            .key_down => |ee| Event{
                .keyboard_event = KeyboardEvent.init(ee),
            },
            .mouse_motion => |ee| Event{
                .mouse_event = MouseEvent.fromMotionEvent(ee),
            },
            .mouse_button_up => |ee| Event{
                .mouse_event = MouseEvent.fromButtonEvent(ee),
            },
            .mouse_button_down => |ee| Event{
                .mouse_event = MouseEvent.fromButtonEvent(ee),
            },
            .mouse_wheel => |ee| Event{
                .mouse_event = MouseEvent.fromWheelEvent(ee),
            },
            .controller_axis_motion => |ee| Event{
                .gamepad_event = GamepadEvent.fromAxisEvent(ee),
            },
            .controller_button_up => |ee| Event{
                .gamepad_event = GamepadEvent.fromButtonEvent(ee),
            },
            .controller_button_down => |ee| Event{
                .gamepad_event = GamepadEvent.fromButtonEvent(ee),
            },
            .controller_device_added => |ee| Event{
                .gamepad_event = GamepadEvent.fromDeviceEvent(ee),
            },
            .controller_device_removed => |ee| Event{
                .gamepad_event = GamepadEvent.fromDeviceEvent(ee),
            },
            .controller_device_remapped => |ee| Event{
                .gamepad_event = GamepadEvent.fromDeviceEvent(ee),
            },
            .quit => Event{
                .quit_event = QuitEvent{},
            },

            // ignored other events
            else => null,
        };
    }
};

/// entrance point, never return until application is killed
pub fn run(g: Game) !void {
    try sdl.init(sdl.InitFlags.everything);
    defer sdl.quit();

    // initialize context
    var context: Context = .{
        ._quit = false,
        ._title = g.title,
        ._fullscreen = g.enable_fullscreen,
        ._vsync = g.enable_vsync,
        ._relative_moouse = g.enable_relative_mouse_mode,
    };

    // decide opengl params
    _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_MAJOR_VERSION, 3);
    _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_MINOR_VERSION, 3);
    //_ = c.SDL_GL_SetAttribute(c.SDL_GL_DEPTH_SIZE, 24);
    //_ = c.SDL_GL_SetAttribute(c.SDL_GL_MULTISAMPLEBUFFERS, c.SDL_TRUE);
    //_ = c.SDL_GL_SetAttribute(c.SDL_GL_MULTISAMPLESAMPLES, 4);

    // create window
    var flags = sdl.WindowFlags{
        .allow_high_dpi = true,
        .mouse_capture = true,
        .mouse_focus = true,
        .opengl = true,
    };
    context._window = try sdl.createWindow(
        g.title,
        g.pos_x,
        g.pos_y,
        g.width,
        g.height,
        flags,
    );
    defer context._window.destroy();

    // enable opengl context
    const gl_ctx = try sdl.gl.createContext(context._window);
    defer sdl.gl.deleteContext(gl_ctx);
    try sdl.gl.makeCurrent(gl_ctx, context._window);
    if (gl.gladLoadGL() == 0) {
        @panic("load opengl functions failed!");
    }

    // apply custom options, still changable through Context's methods
    context.toggleResizable(g.enable_resizable);
    context.toggleFullscreeen(g.enable_fullscreen);
    context.toggleVsyncMode(g.enable_vsync);
    context.toggleRelativeMouseMode(g.enable_relative_mouse_mode);

    // init before loop
    try g.init_fn(&context);
    defer g.quit_fn(&context);

    // init time clock
    const counter_freq = @intToFloat(f32, c.SDL_GetPerformanceFrequency());
    var last_counter = c.SDL_GetPerformanceCounter();
    context.tick = 0;

    // game loop
    while (!context._quit) {
        // update tick
        const counter = c.SDL_GetPerformanceCounter();
        context.delta_tick = @intToFloat(f32, counter - last_counter) / counter_freq;
        context.tick += context.delta_tick;
        last_counter = counter;

        // main loop
        g.loop_fn(&context);

        // swap buffers
        sdl.gl.swapWindow(context._window);
    }
}
