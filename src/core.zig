const std = @import("std");
const zp = @import("zplay.zig");
const GraphicsContext = zp.graphics.gpu.Context;
const console = zp.graphics.font.console;
const event = zp.event;
const audio = zp.audio;
const sdl = zp.deps.sdl;

/// application context
pub const Context = struct {
    /// internal window
    window: sdl.Window,

    /// graphics context
    graphics: GraphicsContext = undefined,

    /// audio engine
    audio: *audio.Engine = undefined,

    /// quit switch
    quit: bool = false,

    /// resizable mode
    resizable: bool = undefined,

    /// fullscreen mode
    fullscreen: bool = undefined,

    /// relative mouse mode
    relative_mouse: bool = undefined,

    /// number of seconds since launch/last-frame
    tick: f32 = undefined,
    delta_tick: f32 = undefined,

    /// text buffer for rendering console font
    text_buf: [512]u8 = undefined,

    /// kill app
    pub fn kill(self: *Context) void {
        self.quit = true;
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
            self.resizable = state;
        } else {
            self.resizable = !self.resizable;
        }
        _ = sdl.c.SDL_SetWindowResizable(
            self.window.ptr,
            if (self.resizable) sdl.c.SDL_TRUE else sdl.c.SDL_FALSE,
        );
    }

    /// toggle fullscreen
    pub fn toggleFullscreeen(self: *Context, on_off: ?bool) void {
        if (on_off) |state| {
            self.fullscreen = state;
        } else {
            self.fullscreen = !self.fullscreen;
        }
        _ = sdl.c.SDL_SetWindowFullscreen(
            self.window.ptr,
            if (self.fullscreen) sdl.c.SDL_WINDOW_FULLSCREEN_DESKTOP else 0,
        );
    }

    /// toggle relative mouse mode
    pub fn toggleRelativeMouseMode(self: *Context, on_off: ?bool) void {
        if (on_off) |state| {
            self.relative_mouse = state;
        } else {
            self.relative_mouse = !self.relative_mouse;
        }
        _ = sdl.c.SDL_SetRelativeMouseMode(
            if (self.relative_mouse) sdl.c.SDL_TRUE else sdl.c.SDL_FALSE,
        );
    }

    /// get position of window
    pub fn getPosition(self: Context) struct { x: u32, y: u32 } {
        var x: u32 = undefined;
        var y: u32 = undefined;
        sdl.c.SDL_GetWindowPosition(
            self.window.ptr,
            @ptrCast(*c_int, &x),
            @ptrCast(*c_int, &y),
        );
        return .{ .x = x, .y = y };
    }

    /// get size of window
    pub fn getWindowSize(self: Context) struct { w: u32, h: u32 } {
        var w: u32 = undefined;
        var h: u32 = undefined;
        sdl.c.SDL_GetWindowSize(
            self.window.ptr,
            @ptrCast(*c_int, &w),
            @ptrCast(*c_int, &h),
        );
        return .{ .w = w, .h = h };
    }

    /// get pixel ratio
    pub fn getPixelRatio(self: Context) f32 {
        const wsize = self.getWindowSize();
        const fsize = self.graphics.getDrawableSize();
        return @intToFloat(f32, fsize.w) / @intToFloat(f32, wsize.w);
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
        sdl.c.SDL_GetWindowSize(self.window.ptr, &w, &h);
        sdl.c.SDL_WarpMouseInWindow(
            self.window.ptr,
            @floatToInt(i32, @intToFloat(f32, w) * xrel),
            @floatToInt(i32, @intToFloat(f32, h) * yrel),
        );
    }

    /// convenient text drawing
    pub fn drawText(
        self: *Context,
        comptime fmt: []const u8,
        args: anytype,
        opt: console.DrawOption,
    ) console.DrawRect {
        const text = std.fmt.bufPrint(&self.text_buf, fmt, args) catch unreachable;
        return console.drawText(text, opt) catch unreachable;
    }
};

/// application configurations
pub const Game = struct {
    /// default memory allocator
    allocator: std.mem.Allocator = std.heap.c_allocator,

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

    /// relative mouse mode switch
    enable_relative_mouse_mode: bool = false,

    /// graphics api
    graphics_api: GraphicsContext.Api = .opengl,

    /// depth-testing capability
    enable_depth_test: bool = false,

    /// face-culling capability
    enable_face_culling: bool = false,

    /// stencil-testing capability
    enable_stencil_test: bool = false,

    /// blending capability
    enable_color_blend: bool = true,

    // vsync switch
    enable_vsync: bool = true,

    /// enable MSAA
    enable_msaa: bool = false,

    /// enable high resolution depth buffer
    enable_highres_depth: bool = false,

    /// enable console module
    enable_console: bool = false,
    console_font_size: u32 = 16,
};

/// entrance point, never return until application is killed
pub fn run(g: Game) !void {
    try sdl.init(sdl.InitFlags.everything);
    defer sdl.quit();

    // prepare graphics params
    try GraphicsContext.prepare(g);

    // create window
    var flags = sdl.WindowFlags{
        .allow_high_dpi = true,
        .mouse_capture = true,
        .mouse_focus = true,
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
    if (g.graphics_api == .opengl) {
        flags.opengl = true;
    }
    var context: Context = .{
        .window = try sdl.createWindow(
            g.title,
            g.pos_x,
            g.pos_y,
            g.width,
            g.height,
            flags,
        ),
    };
    defer context.window.destroy();

    // allocate graphics context
    context.graphics = try GraphicsContext.init(context.window, g);
    defer context.graphics.deinit();
    context.graphics.setVsyncMode(g.enable_vsync);

    // allocate audio engine
    context.audio = try audio.Engine.init(g.allocator, .{});
    defer context.audio.deinit();

    // apply window options, still changable through Context's methods
    context.toggleResizable(g.enable_resizable);
    context.toggleFullscreeen(g.enable_fullscreen);
    context.toggleRelativeMouseMode(g.enable_relative_mouse_mode);

    // init console
    if (g.enable_console) {
        console.init(std.heap.c_allocator, g.console_font_size);
    }

    // init before loop
    try g.initFn(&context);
    defer g.quitFn(&context);

    // init time clock
    const counter_freq = @intToFloat(f32, sdl.c.SDL_GetPerformanceFrequency());
    var last_counter = sdl.c.SDL_GetPerformanceCounter();
    context.tick = 0;

    // game loop
    if (g.enable_console) {
        while (!context.quit) {
            // update tick
            const counter = sdl.c.SDL_GetPerformanceCounter();
            context.delta_tick = @intToFloat(f32, counter - last_counter) / counter_freq;
            context.tick += context.delta_tick;
            last_counter = counter;

            // clear console text
            console.clear();

            // main loop
            g.loopFn(&context);

            // render console text
            console.submitAndRender(&context.graphics);

            // swap buffers
            context.graphics.swap();
        }
    } else {
        while (!context.quit) {
            // update tick
            const counter = sdl.c.SDL_GetPerformanceCounter();
            context.delta_tick = @intToFloat(f32, counter - last_counter) / counter_freq;
            context.tick += context.delta_tick;
            last_counter = counter;

            // main loop
            g.loopFn(&context);

            // swap buffers
            context.graphics.swap();
        }
    }
}
