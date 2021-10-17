const sdl = @import("sdl");
const c = sdl.c;
const gl = @import("gl/gl.zig");

pub const WindowPosition = sdl.WindowPosition;

/// application context
pub const Context = struct {
    _window: sdl.Window = undefined,
    _quit: bool = undefined,
    _title: [:0]const u8 = undefined,
    _resizable: bool = undefined,
    _fullscreen: bool = undefined,
    _enable_vsync: bool = undefined,
    _pos_x: i32 = undefined,
    _pos_y: i32 = undefined,
    _width: i32 = undefined,
    _height: i32 = undefined,

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
    pos_x: WindowPosition = .default,
    pos_y: WindowPosition = .default,

    // whether window is resizable
    resizable: bool = false,

    /// width/height of window
    width: usize = 800,
    height: usize = 600,

    /// display switch
    fullscreen: bool = false,

    // vsync switch
    enable_vsync: bool = true,

    // update window's status
    refresh_window_status_per_frame: bool = false,
};

/// user i/o event
const KeyboardEvent = @import("KeyboardEvent.zig");
const MouseEvent = @import("MouseEvent.zig");
const GamepadEvent = @import("GamepadEvent.zig");
const QuitEvent = struct {};
pub const Event = union(enum) {
    keyboard_event: KeyboardEvent,
    mouse_event: MouseEvent,
    gamepad_event: GamepadEvent,
    quit_event: QuitEvent,

    fn init(e: sdl.Event) ?Event {
        return switch (e) {
            .quit => Event{
                .quit_event = QuitEvent{},
            },
            .key_up => |key| Event{
                .keyboard_event = KeyboardEvent.init(key),
            },
            .key_down => |key| Event{
                .keyboard_event = KeyboardEvent.init(key),
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
        ._resizable = g.resizable,
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
    c.SDL_GetWindowPosition(
        context._window.ptr,
        &context._pos_x,
        &context._pos_y,
    );
    c.SDL_GetWindowSize(
        context._window.ptr,
        &context._width,
        &context._height,
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
        // update window status
        if (g.refresh_window_status_per_frame) {
            c.SDL_GetWindowPosition(
                context._window.ptr,
                &context._pos_x,
                &context._pos_y,
            );
            c.SDL_GetWindowSize(
                context._window.ptr,
                &context._width,
                &context._height,
            );
        }

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
