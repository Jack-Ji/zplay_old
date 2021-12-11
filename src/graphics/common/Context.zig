const std = @import("std");
const assert = std.debug.assert;
const zp = @import("../../zplay.zig");
const sdl = zp.deps.sdl;
const gl = zp.deps.gl;
const Self = @This();

pub const Api = enum {
    opengl,
    vulkan,
    metal,
};

pub const Capability = enum(c_uint) {
    blend = gl.GL_BLEND,
    color_logic_op = gl.GL_COLOR_LOGIC_OP,
    cull_face = gl.GL_CULL_FACE,
    depth_clamp = gl.GL_DEPTH_CLAMP,
    depth_test = gl.GL_DEPTH_TEST,
    dither = gl.GL_DITHER,
    framebuffer_srgb = gl.GL_FRAMEBUFFER_SRGB,
    line_smooth = gl.GL_LINE_SMOOTH,
    multisample = gl.GL_MULTISAMPLE,
    polygon_offset_fill = gl.GL_POLYGON_OFFSET_FILL,
    polygon_offset_line = gl.GL_POLYGON_OFFSET_LINE,
    polygon_offset_point = gl.GL_POLYGON_OFFSET_POINT,
    polygon_smooth = gl.GL_POLYGON_SMOOTH,
    primitive_restart = gl.GL_PRIMITIVE_RESTART,
    rasterizer_discard = gl.GL_RASTERIZER_DISCARD,
    sample_alpha_to_coverage = gl.GL_SAMPLE_ALPHA_TO_COVERAGE,
    sample_alpha_to_one = gl.GL_SAMPLE_ALPHA_TO_ONE,
    sample_coverage = gl.GL_SAMPLE_COVERAGE,
    sample_mask = gl.GL_SAMPLE_MASK,
    scissor_test = gl.GL_SCISSOR_TEST,
    stencil_test = gl.GL_STENCIL_TEST,
    texture_cube_map_seamless = gl.GL_TEXTURE_CUBE_MAP_SEAMLESS,
    program_point_size = gl.GL_PROGRAM_POINT_SIZE,
};

pub const PolygonMode = enum(c_uint) {
    fill = gl.GL_FILL,
    line = gl.GL_LINE,
};

/// opengl context
gl_ctx: sdl.gl.Context,

/// prepare graphics api
pub fn prepare(api: Api, enable_msaa: bool) void {
    assert(api == .opengl); // only opengl for now
    _ = sdl.c.SDL_GL_SetAttribute(sdl.c.SDL_GL_CONTEXT_MAJOR_VERSION, 3);
    _ = sdl.c.SDL_GL_SetAttribute(sdl.c.SDL_GL_CONTEXT_MINOR_VERSION, 3);
    _ = sdl.c.SDL_GL_SetAttribute(sdl.c.SDL_GL_STENCIL_SIZE, 1);
    _ = sdl.c.SDL_GL_SetAttribute(sdl.c.SDL_GL_DEPTH_SIZE, 24);
    if (enable_msaa) {
        _ = sdl.c.SDL_GL_SetAttribute(sdl.c.SDL_GL_MULTISAMPLEBUFFERS, 1);
        _ = sdl.c.SDL_GL_SetAttribute(sdl.c.SDL_GL_MULTISAMPLESAMPLES, 4);
    }
}

/// allocate graphics context
pub fn init(window: sdl.Window, api: Api) !Self {
    assert(api == .opengl); // only opengl for now
    const gl_ctx = try sdl.gl.createContext(window);
    try sdl.gl.makeCurrent(gl_ctx, window);
    if (gl.gladLoadGL() == 0) {
        @panic("load opengl functions failed!");
    }
    return Self{
        .gl_ctx = gl_ctx,
    };
}

/// delete graphics context
pub fn deinit(self: Self) void {
    sdl.gl.deleteContext(self.gl_ctx);
}

/// swap buffer, rendering take effect here 
pub fn swap(self: Self, window: sdl.Window) void {
    _ = self;
    sdl.gl.swapWindow(window);
}
/// get size of drawable place
pub fn getDrawableSize(self: Self, window: sdl.Window, w: *u32, h: *u32) void {
    _ = self;
    sdl.c.SDL_GL_GetDrawableSize(
        window.ptr,
        @ptrCast(*c_int, w),
        @ptrCast(*c_int, h),
    );
}

///  set vsync mode 
pub fn setVsyncMode(self: Self, on_off: bool) void {
    _ = self;
    sdl.gl.setSwapInterval(
        if (on_off) .vsync else .immediate,
    ) catch |e| {
        std.debug.print("toggle vsync failed, {}", .{e});
        std.debug.print("using mode: {s}", .{
            if (sdl.c.SDL_GL_GetSwapInterval() == 1) "immediate" else "vsync    ",
        });
    };
}

/// clear buffers
pub fn clear(
    self: Self,
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
    gl.util.checkError();
}

/// change viewport
pub fn setViewport(self: Self, x: u32, y: u32, width: u32, height: u32) void {
    _ = self;
    gl.viewport(
        @intCast(c_int, x),
        @intCast(c_int, y),
        @intCast(c_int, width),
        @intCast(c_int, height),
    );
    gl.util.checkError();
}

/// toggle opengl capability
pub fn toggleCapability(self: Self, cap: Capability, on_off: bool) void {
    _ = self;
    if (on_off) {
        gl.enable(@enumToInt(cap));
    } else {
        gl.disable(@enumToInt(cap));
    }
    gl.util.checkError();
}

/// set polygon mode
pub fn setPolygonMode(self: Self, mode: PolygonMode) void {
    _ = self;
    gl.polygonMode(gl.GL_FRONT_AND_BACK, @enumToInt(mode));
    gl.util.checkError();
}
