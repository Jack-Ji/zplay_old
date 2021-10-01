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
    initFn: fn (ctx: *Context) anyerror!void,
    eventFn: fn (ctx: *Context, e: Event) void,
    loopFn: fn (ctx: *Context) void,
    quitFn: fn (ctx: *Context) void,
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
    try g.initFn(&context);
    defer g.quitFn(&context);

    // create window
    var flags = sdl.WindowFlags{
        .allow_high_dpi = true,
        .mouse_capture = true,
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

    // game loop
    while (!context.quit) {
        while (sdl.pollEvent()) |e| {
            if (Event.init(e)) |ze| {
                g.eventFn(&context, ze);
            }
        }

        g.loopFn(&context);
    }
}
