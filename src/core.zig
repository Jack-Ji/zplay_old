const std = @import("std");
const sdl = @import("sdl");
const c = sdl.c;
const gl = @import("gl/gl.zig");
const dig = @import("cimgui/imgui.zig");
const event = @import("event.zig");

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
    pub fn pollEvent(self: *Context) ?event.Event {
        _ = self;
        while (sdl.pollEvent()) |e| {
            if (event.Event.init(e)) |ze| {
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
    pub fn isKeyPressed(self: Context, key: event.KeyboardEvent.ScanCode) bool {
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

    /// borderless window
    enable_borderless: bool = false,

    /// minimize window
    enable_minimized: bool = false,

    /// maximize window
    enable_maximized: bool = false,

    // vsync switch
    enable_vsync: bool = true,

    /// relative mouse mode switch
    enable_relative_mouse_mode: bool = false,

    /// dear imgui switch
    enable_dear_imgui: bool = false,
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
    if (g.enable_borderless) {
        flags.borderless = true;
    }
    if (g.enable_minimized) {
        flags.minimized = true;
    }
    if (g.enable_maximized) {
        flags.maximized = true;
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

    // apply custom options, still changable through Context's methods
    context.toggleResizable(g.enable_resizable);
    context.toggleFullscreeen(g.enable_fullscreen);
    context.toggleVsyncMode(g.enable_vsync);
    context.toggleRelativeMouseMode(g.enable_relative_mouse_mode);

    // setup imgui
    if (g.enable_dear_imgui) {
        try dig.init(context._window);
    }

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

    if (g.enable_dear_imgui) {
        dig.deinit();
    }
}
