const sdl = @import("sdl");
const c = sdl.c;

pub const Window = sdl.Window;
pub const WindowPosition = sdl.WindowPosition;

/// application context
pub const Context = struct {
    window: Window = undefined,
    tick: u64 = undefined,
    title: [:0]const u8 = "zplay",
    pos_x: WindowPosition = .default,
    pos_y: WindowPosition = .default,
    width: usize = 800,
    height: usize = 600,
    fullscreen: bool = false,
    enable_vsync: bool = true,
    quit: bool = false,

    /// quit game
    pub fn kill(self: *Context) void {
        self.quit = true;
    }

    /// toggle fullscreen
    pub fn toggleFullscreeen(self: *Context) void {
        if (self.fullscreen) {
            if (c.SDL_SetWindowFullscreen(self.window.ptr, 0) == 0) {
                self.fullscreen = false;
            }
        } else {
            if (c.SDL_SetWindowFullscreen(self.window.ptr, c.SDL_WINDOW_FULLSCREEN) == 0) {
                self.fullscreen = true;
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
    var context: Context = .{};
    try g.init_fn(&context);
    defer g.quit_fn(&context);

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
    if (context.fullscreen) {
        flags.fullscreen = true;
    }
    context.window = try sdl.createWindow(
        context.title,
        context.pos_x,
        context.pos_y,
        context.width,
        context.height,
        flags,
    );
    defer context.window.destroy();

    // enable opengl context
    const gl_ctx = try sdl.gl.createContext(context.window);
    defer sdl.gl.deleteContext(gl_ctx);
    try sdl.gl.makeCurrent(gl_ctx, context.window);
    if (context.enable_vsync) {
        try sdl.gl.setSwapInterval(.vsync);
    }

    // game loop
    while (!context.quit) {
        while (sdl.pollEvent()) |e| {
            if (Event.init(e)) |ze| {
                g.event_fn(&context, ze);
            }
        }

        g.loop_fn(&context);
    }
}
