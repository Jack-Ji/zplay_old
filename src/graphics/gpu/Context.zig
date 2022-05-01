const std = @import("std");
const assert = std.debug.assert;
const Framebuffer = @import("Framebuffer.zig");
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
    point = gl.GL_POINT,
    line = gl.GL_LINE,
    fill = gl.GL_FILL,
};

pub const TestFunc = enum(c_uint) {
    always = gl.GL_ALWAYS, // The test always passes.
    never = gl.GL_NEVER, // The test never passes.
    less = gl.GL_LESS, // Passes if the fragment's value is less than the stored value.
    equal = gl.GL_EQUAL, // Passes if the fragment's value is equal to the stored value.
    less_or_equal = gl.GL_LEQUAL, // Passes if the fragment's value is less than or equal to the stored value.
    greater = gl.GL_GREATER, // Passes if the fragment's value is greater than the stored value.
    not_equal = gl.GL_NOTEQUAL, // Passes if the fragment's value is not equal to the stored value.
    greater_or_equal = gl.GL_GEQUAL, // Passes if the fragment's value is greater than or equal to the stored value.
};

pub const StencilOp = enum(c_uint) {
    keep = gl.GL_KEEP, // The currently stored stencil value is kept.
    zero = gl.GL_ZERO, // The stencil value is set to 0.
    replace = gl.GL_REPLACE, // The stencil value is replaced with the reference value set with glStencilFunc.
    incr = gl.GL_INCR, // The stencil value is increased by 1 if it is lower than the maximum value.
    incr_wrap = gl.GL_INCR_WRAP, // Same as GL_INCR, but wraps it back to 0 as soon as the maximum value is exceeded.
    decr = gl.GL_DECR, // The stencil value is decreased by 1 if it is higher than the minimum value.
    decr_wrap = gl.GL_DECR_WRAP, // Same as GL_DECR, but wraps it to the maximum value if it ends up lower than 0.
    invert = gl.GL_INVERT, // Bitwise inverts the current stencil buffer value.
};

pub const BlendFactor = enum(c_uint) {
    zero = gl.GL_ZERO, // Factor is equal to 0.
    one = gl.GL_ONE, // Factor is equal to 1.
    src_color = gl.GL_SRC_COLOR, // Factor is equal to the source color vector C¯source.
    one_minus_src_color = gl.GL_ONE_MINUS_SRC_COLOR, // Factor is equal to 1 minus the source color vector: 1−C¯source.
    dst_color = gl.GL_DST_COLOR, // Factor is equal to the destination color vector C¯destination
    one_minus_dst_color = gl.GL_ONE_MINUS_DST_COLOR, // Factor is equal to 1 minus the destination color vector: 1−C¯destination.
    src_alpha = gl.GL_SRC_ALPHA, // Factor is equal to the alpha component of the source color vector C¯source.
    one_minus_src_alpha = gl.GL_ONE_MINUS_SRC_ALPHA, // Factor is equal to 1−alpha of the source color vector C¯source.
    dst_alpha = gl.GL_DST_ALPHA, // Factor is equal to the alpha component of the destination color vector C¯destination.
    one_minus_dst_alpha = gl.GL_ONE_MINUS_DST_ALPHA, // Factor is equal to 1−alpha of the destination color vector C¯destination.
    constant_color = gl.GL_CONSTANT_COLOR, // Factor is equal to the constant color vector C¯constant.
    one_minus_constant_color = gl.GL_ONE_MINUS_CONSTANT_COLOR, // Factor is equal to 1 - the constant color vector C¯constant.
    constant_alpha = gl.GL_CONSTANT_ALPHA, // Factor is equal to the alpha component of the constant color vector C¯constant.
    one_minus_constant_alpha = gl.GL_ONE_MINUS_CONSTANT_ALPHA, // Factor is equal to 1−alpha of the constant color vector C¯constant.
};

pub const BlendEquation = enum(c_uint) {
    add = gl.GL_FUNC_ADD, // the default, adds both colors to each other: C¯result=Src+Dst.
    sub = gl.GL_FUNC_SUBTRACT, // subtracts both colors from each other: C¯result=Src−Dst.
    rev_sub = gl.GL_FUNC_REVERSE_SUBTRACT, // subtracts both colors, but reverses order: C¯result=Dst−Src.
    min = gl.GL_MIN, // takes the component-wise minimum of both colors: C¯result=min(Dst,Src).
    max = gl.GL_MAX, // takes the component-wise maximum of both colors: C¯result=max(Dst,Src).
};

pub const CullFace = enum(c_uint) {
    back = gl.GL_BACK, // Culls only the back faces.
    front = gl.GL_FRONT, // Culls only the front faces.
    front_and_back = gl.GL_FRONT_AND_BACK, // Culls both the front and back faces.
};

pub const FrontFace = enum(c_uint) {
    ccw = gl.GL_CCW, // counter-clockwise ordering
    cw = gl.GL_CW, // clockwise ordering
};

/// related window
window: sdl.Window,

/// opengl context
gl_ctx: sdl.gl.Context,

/// capability status
cap_status: std.EnumMap(Capability, bool) = undefined,

/// current viewport
viewport: Viewport = undefined,

/// vsync switch
vsync: bool = undefined,

/// current color
color: [4]f32 = .{ 0, 0, 0, 1 },

/// line width
line_width: f32 = 1,

/// current polygon mode
polygon_mode: PolygonMode = undefined,

/// current depth option
depth_option: DepthOption = undefined,

/// current stencil option
stencil_option: StencilOption = undefined,

/// current blend option
blend_option: BlendOption = undefined,

/// current culling option
culling_option: CullingOption = undefined,

/// prepare graphics api
pub fn prepare(g: zp.Game) !void {
    assert(g.graphics_api == .opengl); // only opengl for now
    if (sdl.c.SDL_GL_SetAttribute(sdl.c.SDL_GL_CONTEXT_FLAGS, 0) != 0) {
        return sdl.makeError();
    }
    if (sdl.c.SDL_GL_SetAttribute(sdl.c.SDL_GL_CONTEXT_PROFILE_MASK, sdl.c.SDL_GL_CONTEXT_PROFILE_CORE) != 0) {
        return sdl.makeError();
    }
    if (sdl.c.SDL_GL_SetAttribute(sdl.c.SDL_GL_CONTEXT_MAJOR_VERSION, 3) != 0) {
        return sdl.makeError();
    }
    if (sdl.c.SDL_GL_SetAttribute(sdl.c.SDL_GL_CONTEXT_MINOR_VERSION, 3) != 0) {
        return sdl.makeError();
    }
    if (sdl.c.SDL_GL_SetAttribute(sdl.c.SDL_GL_DOUBLEBUFFER, 1) != 0) {
        return sdl.makeError();
    }
    if (sdl.c.SDL_GL_SetAttribute(sdl.c.SDL_GL_STENCIL_SIZE, 8) != 0) {
        return sdl.makeError();
    }
    if (g.enable_msaa) {
        if (sdl.c.SDL_GL_SetAttribute(sdl.c.SDL_GL_MULTISAMPLEBUFFERS, 1) != 0) {
            return sdl.makeError();
        }
        if (sdl.c.SDL_GL_SetAttribute(sdl.c.SDL_GL_MULTISAMPLESAMPLES, 4) != 0) {
            return sdl.makeError();
        }
    }
    if (g.enable_highres_depth) {
        if (sdl.c.SDL_GL_SetAttribute(sdl.c.SDL_GL_DEPTH_SIZE, 32) != 0) {
            return sdl.makeError();
        }
    } else {
        if (sdl.c.SDL_GL_SetAttribute(sdl.c.SDL_GL_DEPTH_SIZE, 24) != 0) {
            return sdl.makeError();
        }
    }
}

/// allocate graphics context
pub fn init(window: sdl.Window, g: zp.Game) !Self {
    assert(g.graphics_api == .opengl); // only opengl for now
    const size = window.getSize();
    const gl_ctx = try sdl.gl.createContext(window);
    try sdl.gl.makeCurrent(gl_ctx, window);
    if (gl.gladLoadGLLoader(sdl.c.SDL_GL_GetProcAddress) == 0) {
        @panic("load opengl functions failed!");
    }

    var self = Self{
        .window = window,
        .gl_ctx = gl_ctx,
        .cap_status = std.EnumMap(Capability, bool).initFull(false),
    };
    self.setViewport(.{
        .x = 0,
        .y = 0,
        .w = @intCast(u32, size.width),
        .h = @intCast(u32, size.height),
    });
    self.toggleCapability(.depth_test, g.enable_depth_test);
    self.toggleCapability(.cull_face, g.enable_face_culling);
    self.toggleCapability(.stencil_test, g.enable_stencil_test);
    self.toggleCapability(.blend, g.enable_color_blend);
    self.setDepthOption(.{});
    self.setCullingOption(.{});
    self.setStencilOption(.{});
    self.setBlendOption(.{});
    self.setPolygonMode(.fill);

    // output graphics info
    const gl_vendor = @ptrCast([*:0]const u8, gl.getString(gl.GL_VENDOR));
    const gl_renderer = @ptrCast([*:0]const u8, gl.getString(gl.GL_RENDERER));
    const gl_version = @ptrCast([*:0]const u8, gl.getString(gl.GL_VERSION));
    const glsl_version = @ptrCast([*:0]const u8, gl.getString(gl.GL_SHADING_LANGUAGE_VERSION));
    std.log.info("GL Vendor: {s}", .{gl_vendor});
    std.log.info("GL Renderer: {s}", .{gl_renderer});
    std.log.info("GL Version: {s}", .{gl_version});
    std.log.info("GLSL Version: {s}", .{glsl_version});

    return self;
}

/// delete graphics context
pub fn deinit(self: Self) void {
    sdl.gl.deleteContext(self.gl_ctx);
}

/// swap buffer, rendering take effect here
pub fn swap(self: Self) void {
    sdl.gl.swapWindow(self.window);
}

/// get size of drawable place
pub fn getDrawableSize(self: Self) struct { w: u32, h: u32 } {
    var w: u32 = undefined;
    var h: u32 = undefined;
    sdl.c.SDL_GL_GetDrawableSize(
        self.window.ptr,
        @ptrCast(*c_int, &w),
        @ptrCast(*c_int, &h),
    );
    return .{ .w = w, .h = h };
}

///  set vsync mode
pub fn setVsyncMode(self: *Self, on_off: bool) void {
    _ = self;
    sdl.gl.setSwapInterval(
        if (on_off) .vsync else .immediate,
    ) catch |e| {
        std.debug.print("toggle vsync failed, {}", .{e});
        std.debug.print("using mode: {s}", .{
            if (sdl.c.SDL_GL_GetSwapInterval() == 1) "immediate" else "vsync    ",
        });
    };
    self.vsync = on_off;
}

/// clear buffers
pub fn clear(
    self: *Self,
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
        self.color = rgba;
    }
    gl.clear(clear_flags);
    gl.util.checkError();
}

/// change viewport
pub const Viewport = struct {
    x: u32 = 0,
    y: u32 = 0,
    w: u32,
    h: u32,

    pub fn getAspectRatio(self: Viewport) f32 {
        return @intToFloat(f32, self.w) / @intToFloat(f32, self.h);
    }
};
pub fn setViewport(self: *Self, vp: Viewport) void {
    _ = self;
    gl.viewport(
        @intCast(c_int, vp.x),
        @intCast(c_int, vp.y),
        @intCast(c_int, vp.w),
        @intCast(c_int, vp.h),
    );
    self.viewport = vp;
    gl.util.checkError();
}

/// toggle capability
pub fn toggleCapability(self: *Self, cap: Capability, on_off: bool) void {
    _ = self;
    if (on_off) {
        gl.enable(@enumToInt(cap));
        self.cap_status.put(cap, true);
    } else {
        gl.disable(@enumToInt(cap));
        self.cap_status.put(cap, false);
    }
    gl.util.checkError();
}

/// check capability' s status
pub fn isCapabilityEnabled(self: *Self, cap: Capability) bool {
    const status = self.cap_status.get(cap).?;
    assert((gl.isEnabled(@enumToInt(cap)) == gl.GL_TRUE) == status);
    return status;
}

/// set line width
pub fn setLineWidth(self: *Self, w: f32) void {
    self.line_width = w;
    gl.lineWidth(w);
    gl.util.checkError();
}

/// set polygon mode
pub fn setPolygonMode(self: *Self, mode: PolygonMode) void {
    _ = self;
    gl.polygonMode(gl.GL_FRONT_AND_BACK, @enumToInt(mode));
    self.polygon_mode = mode;
    gl.util.checkError();
}

/// set depth options
pub const DepthOption = struct {
    test_func: TestFunc = .less, // test function determines whether fragment is accepted
    update_switch: bool = true, // false means depth buffer won't be updated during rendering
};
pub fn setDepthOption(self: *Self, option: DepthOption) void {
    _ = self;
    gl.depthFunc(@enumToInt(option.test_func));
    gl.depthMask(gl.util.boolType(option.update_switch));
    self.depth_option = option;
    gl.util.checkError();
}

/// set stencil options
pub const StencilOption = struct {
    action_sfail: StencilOp = .keep, // action to take if the stencil test fails.
    action_dpfail: StencilOp = .keep, // action to take if the stencil test passes, but the depth test fails.
    action_dppass: StencilOp = .keep, // action to take if both the stencil and the depth test pass.
    test_func: TestFunc = .always, // stencil test function that determines whether a fragment passes or is discarded.
    test_ref: u8 = 0, // the reference value for the stencil test. The stencil buffer's content is compared to this value.
    test_mask: u8 = 0xff, // ANDed with both the reference value and the stored stencil value before the test compares them.
    write_mask: u8 = 0xff, // bitmask that is ANDed with the stencil value about to be written to the buffer.
};
pub fn setStencilOption(self: *Self, option: StencilOption) void {
    _ = self;
    gl.stencilOp(
        @enumToInt(option.action_sfail),
        @enumToInt(option.action_dpfail),
        @enumToInt(option.action_dppass),
    );
    gl.stencilFunc(
        @enumToInt(option.test_func),
        @intCast(gl.GLint, option.test_ref),
        @intCast(gl.GLuint, 0xff),
    );
    gl.stencilMask(@intCast(gl.GLuint, option.write_mask));
    self.stencil_option = option;
    gl.util.checkError();
}

/// set color blending options
pub const BlendOption = struct {
    src_rgb: BlendFactor = .src_alpha, // blend factors for rgb
    dst_rgb: BlendFactor = .one_minus_src_alpha,
    src_alpha: BlendFactor = .one, // blend factors for alpha
    dst_alpha: BlendFactor = .zero,
    constant_color: [4]f32 = [4]f32{ 0, 0, 0, 0 }, // constant blend color
    equation: BlendEquation = .add, // blend equation
};
pub fn setBlendOption(self: *Self, option: BlendOption) void {
    _ = self;
    gl.blendFuncSeparate(
        @enumToInt(option.src_rgb),
        @enumToInt(option.dst_rgb),
        @enumToInt(option.src_alpha),
        @enumToInt(option.dst_alpha),
    );
    gl.blendColor(
        option.constant_color[0],
        option.constant_color[1],
        option.constant_color[2],
        option.constant_color[3],
    );
    gl.blendEquation(@enumToInt(option.equation));
    self.blend_option = option;
    gl.util.checkError();
}

/// set face culling options
pub const CullingOption = struct {
    face: CullFace = .back,
    front: FrontFace = .ccw,
};
pub fn setCullingOption(self: *Self, option: CullingOption) void {
    _ = self;
    gl.cullFace(@enumToInt(option.face));
    gl.frontFace(@enumToInt(option.front));
    self.culling_option = option;
    gl.util.checkError();
}
