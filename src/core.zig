const sdl = @import("sdl");
const c = sdl.c;
const gl = @import("gl/gl.zig");

/// application context
pub const Context = struct {
    // following fields are readonly, user code shouldn't modify them
    _window: sdl.Window = undefined,
    _quit: bool = undefined,
    _title: [:0]const u8 = undefined,
    _fullscreen: bool = undefined,
    _enable_vsync: bool = undefined,

    /// time tick, updated every loop
    tick: u64 = undefined,

    /// kill app
    pub fn kill(self: *Context) void {
        self._quit = true;
    }

    /// toggle fullscreen
    pub fn toggleFullscreeen(self: *Context) void {
        if (self._fullscreen) {
            if (c.SDL_SetWindowFullscreen(self._window.ptr, 0) == 0) {
                self._fullscreen = false;
            }
        } else {
            if (c.SDL_SetWindowFullscreen(self._window.ptr, c.SDL_WINDOW_FULLSCREEN) == 0) {
                self._fullscreen = true;
            }
        }
    }

    /// get position of window
    pub fn getPosition(self: *Context, x: ?*i32, y: ?*i32) void {
        c.SDL_GetWindowPosition(self._window.ptr, x.?, y.?);
    }

    /// get size of window
    pub fn getSize(self: *Context, w: ?*i32, h: ?*i32) void {
        c.SDL_GetWindowSize(self._window.ptr, w.?, h.?);
    }
};

/// game running callbacks
pub const Game = struct {
    init_fn: fn (ctx: *Context) anyerror!void,
    event_fn: fn (ctx: *Context, e: Event) void,
    loop_fn: fn (ctx: *Context) void,
    quit_fn: fn (ctx: *Context) void,

    /// window's title
    title: [:0]const u8 = "zplay",

    /// position of window
    pos_x: sdl.WindowPosition = .default,
    pos_y: sdl.WindowPosition = .default,

    // whether window is resizable
    resizable: bool = false,

    /// width/height of window
    width: usize = 800,
    height: usize = 600,

    /// display switch
    fullscreen: bool = false,

    // vsync switch
    enable_vsync: bool = true,
};

/// system event
const WindowEvent = @import("WindowEvent.zig");
const KeyboardEvent = @import("KeyboardEvent.zig");
const MouseEvent = @import("MouseEvent.zig");
const GamepadEvent = @import("GamepadEvent.zig");
const QuitEvent = struct {};
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
        ._fullscreen = g.fullscreen,
        ._enable_vsync = g.enable_vsync,
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
        .opengl = true,
    };
    if (g.resizable) {
        flags.resizable = true;
    }
    if (g.fullscreen) {
        flags.fullscreen = true;
    }
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
    if (g.enable_vsync) {
        try sdl.gl.setSwapInterval(.vsync);
    }

    // init before loop
    try g.init_fn(&context);
    defer g.quit_fn(&context);

    // game loop
    while (!context._quit) {
        // event loop
        while (sdl.pollEvent()) |e| {
            if (Event.init(e)) |ze| {
                g.event_fn(&context, ze);
            }
        }

        // main loop
        g.loop_fn(&context);

        // swap buffers
        sdl.gl.swapWindow(context._window);
    }
}
