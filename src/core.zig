const std = @import("std");
const zp = @import("zplay.zig");
const GraphicsContext = zp.graphics.common.Context;
const event = zp.event;
const sdl = zp.deps.sdl;
const dig = zp.deps.dig;
const nvg = zp.deps.nvg;

/// application context
pub const Context = struct {
    _window: sdl.Window = undefined,
    _quit: bool = undefined,
    _title: [:0]const u8 = undefined,

    /// graphics context
    graphics: GraphicsContext = undefined,

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
        _ = sdl.c.SDL_SetWindowResizable(
            self._window.ptr,
            if (self._resizable) sdl.c.SDL_TRUE else sdl.c.SDL_FALSE,
        );
    }

    /// toggle fullscreen
    pub fn toggleFullscreeen(self: *Context, on_off: ?bool) void {
        if (on_off) |state| {
            self._fullscreen = state;
        } else {
            self._fullscreen = !self._fullscreen;
        }
        _ = sdl.c.SDL_SetWindowFullscreen(
            self._window.ptr,
            if (self._fullscreen) sdl.c.SDL_WINDOW_FULLSCREEN else 0,
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
                if (sdl.c.SDL_GL_GetSwapInterval() == 1) "immediate" else "vsync    ",
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
        _ = sdl.c.SDL_SetRelativeMouseMode(
            if (self._relative_moouse) sdl.c.SDL_TRUE else sdl.c.SDL_FALSE,
        );
    }

    /// get position of window
    pub fn getPosition(self: Context, x: *i32, y: *i32) void {
        sdl.c.SDL_GetWindowPosition(self._window.ptr, x, y);
    }

    /// get size of window
    pub fn getWindowSize(self: Context, w: *i32, h: *i32) void {
        sdl.c.SDL_GetWindowSize(self._window.ptr, w, h);
    }

    /// get size of frame buffer
    pub fn getFramebufferSize(self: Context, w: *i32, h: *i32) void {
        sdl.c.SDL_GL_GetDrawableSize(self._window.ptr, w, h);
    }

    /// get key status
    pub fn isKeyPressed(self: Context, key: sdl.Scancode) bool {
        _ = self;
        const state = sdl.c.SDL_GetKeyboardState(null);
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
        sdl.c.SDL_GetWindowSize(self._window.ptr, &w, &h);
        sdl.c.SDL_WarpMouseInWindow(
            self._window.ptr,
            @floatToInt(i32, @intToFloat(f32, w) * xrel),
            @floatToInt(i32, @intToFloat(f32, h) * yrel),
        );
    }
};

/// application configurations
pub const Game = struct {
    /// called once before rendering loop starts
    initFn: fn (ctx: *Context) anyerror!void,

    /// called every frame
    loopFn: fn (ctx: *Context) void,

    /// called before life ends
    quitFn: fn (ctx: *Context) void,

    /// window's title
    title: [:0]const u8 = "zplay",

    /// position of window
    pos_x: sdl.WindowPosition = .default,
    pos_y: sdl.WindowPosition = .default,

    /// width/height of window
    width: u32 = 800,
    height: u32 = 600,

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

    /// enable MSAA
    enable_msaa: bool = false,

    /// dear imgui switch
    enable_dear_imgui: bool = false,

    /// nanovg switch
    enable_nanovg: bool = false,
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
    _ = sdl.c.SDL_GL_SetAttribute(sdl.c.SDL_GL_CONTEXT_MAJOR_VERSION, 3);
    _ = sdl.c.SDL_GL_SetAttribute(sdl.c.SDL_GL_CONTEXT_MINOR_VERSION, 3);
    _ = sdl.c.SDL_GL_SetAttribute(sdl.c.SDL_GL_STENCIL_SIZE, 1);
    _ = sdl.c.SDL_GL_SetAttribute(sdl.c.SDL_GL_DEPTH_SIZE, 24);
    if (g.enable_msaa) {
        _ = sdl.c.SDL_GL_SetAttribute(sdl.c.SDL_GL_MULTISAMPLEBUFFERS, 1);
        _ = sdl.c.SDL_GL_SetAttribute(sdl.c.SDL_GL_MULTISAMPLESAMPLES, 4);
    }

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

    // enable graphics context
    context.graphics = try GraphicsContext.init(context._window);
    defer context.graphics.deinit();

    // apply custom options, still changable through Context's methods
    context.toggleResizable(g.enable_resizable);
    context.toggleRelativeMouseMode(g.enable_relative_mouse_mode);
    context.toggleFullscreeen(g.enable_fullscreen);
    context.toggleVsyncMode(g.enable_vsync);

    // setup imgui
    if (g.enable_dear_imgui) {
        try dig.init(context._window);
    }

    // setup nanovg
    if (g.enable_nanovg) {
        nvg.init(
            if (g.enable_msaa)
                nvg.c.NVG_STENCIL_STROKES
            else
                nvg.c.NVG_ANTIALIAS | nvg.c.NVG_STENCIL_STROKES,
        );
    }

    // init before loop
    try g.initFn(&context);
    defer g.quitFn(&context);

    // init time clock
    const counter_freq = @intToFloat(f32, sdl.c.SDL_GetPerformanceFrequency());
    var last_counter = sdl.c.SDL_GetPerformanceCounter();
    context.tick = 0;

    // game loop
    while (!context._quit) {
        // update tick
        const counter = sdl.c.SDL_GetPerformanceCounter();
        context.delta_tick = @intToFloat(f32, counter - last_counter) / counter_freq;
        context.tick += context.delta_tick;
        last_counter = counter;

        // main loop
        g.loopFn(&context);

        // swap buffers
        sdl.gl.swapWindow(context._window);
    }

    if (g.enable_dear_imgui) {
        dig.deinit();
    }

    if (g.enable_nanovg) {
        nvg.deinit();
    }
}
