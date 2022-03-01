const std = @import("std");
const assert = std.debug.assert;
const panic = std.debug.panic;
const Texture = @import("Texture.zig");
const zp = @import("../../zplay.zig");
const gl = zp.deps.gl;
const Self = @This();

pub const FramebufferError = error{
    InvalidTexture,
};

pub var current_fb: gl.GLuint = 0;

const ColorType = enum {
    rgb,
    rgb_f16,
    rgb_f32,
    rgba,
    rgba_f16,
    rgba_f32,
};

const ValueBufferType = enum {
    none,
    renderbuffer,
    texture,
};

const ValueBuffer = union(enum) {
    tex: *Texture,
    rbo: gl.GLuint,
};

const max_tex_num = 6;

/// id of framebuffer
id: gl.GLuint = undefined,

/// color texture
tex: ?*Texture = null,
texs: [max_tex_num]?*Texture = [_]?*Texture{null} ** max_tex_num,
tex_num: u32 = 0,

/// depth or depth/stencil buffer
depth_stencil: ?ValueBuffer = null,

/// stencil buffer
stencil: ?ValueBuffer = null,

pub const Option = struct {
    color_type: ColorType = .rgba,
    color_tex_num: u32 = 1,
    depth_type: ValueBufferType = .renderbuffer,
    stencil_type: ValueBufferType = .renderbuffer,
    compose_depth_stencil: bool = true,
    multisamples: ?u32 = null,
};

pub fn init(
    allocator: std.mem.Allocator,
    width: u32,
    height: u32,
    option: Option,
) !Self {
    var self = Self{};
    gl.genFramebuffers(1, &self.id);
    gl.bindFramebuffer(gl.GL_FRAMEBUFFER, self.id);
    defer gl.bindFramebuffer(gl.GL_FRAMEBUFFER, 0);
    gl.util.checkError();

    // allocate and attach color texture
    var i: u32 = 0;
    assert(option.color_tex_num <= max_tex_num);
    self.tex_num = option.color_tex_num;
    while (i < option.color_tex_num) : (i += 1) {
        self.texs[i] = try allocAndAttachTexture(
            allocator,
            @intToEnum(AttachmentType, gl.GL_COLOR_ATTACHMENT0 + @intCast(c_int, i)),
            width,
            height,
            switch (option.color_type) {
                .rgb => .rgb,
                .rgb_f16 => .rgb_f16,
                .rgb_f32 => .rgb_f32,
                .rgba => .rgba,
                .rgba_f16 => .rgba_f16,
                .rgba_f32 => .rgba_f32,
            },
            switch (option.color_type) {
                .rgb, .rgb_f16, .rgb_f32 => .rgb,
                .rgba, .rgba_f16, .rgba_f32 => .rgba,
            },
            option.multisamples,
        );
        if (i == 0) self.tex = self.texs[0];
    }

    // allocate and attach depth/stencil buffer
    if (option.compose_depth_stencil and option.depth_type != .none and option.stencil_type != .none) {
        // use depth buffer's option
        if (option.depth_type == .renderbuffer) {
            self.depth_stencil = .{
                .rbo = allocAndAttachRenderBuffer(
                    .depth_stencil,
                    width,
                    height,
                    .depth_stencil,
                    option.multisamples,
                ),
            };
        } else {
            self.depth_stencil = .{
                .tex = try allocAndAttachTexture(
                    allocator,
                    .depth_stencil,
                    width,
                    height,
                    .depth_stencil,
                    .depth_stencil,
                    option.multisamples,
                ),
            };
        }
    } else {
        // allocate and attach depth buffer
        if (option.depth_type != .none) {
            if (option.depth_type == .renderbuffer) {
                self.depth_stencil = .{
                    .rbo = allocAndAttachRenderBuffer(
                        .depth,
                        width,
                        height,
                        .depth,
                        option.multisamples,
                    ),
                };
            } else {
                self.depth_stencil = .{
                    .tex = try allocAndAttachTexture(
                        allocator,
                        .depth,
                        width,
                        height,
                        .depth_component,
                        .depth_component,
                        option.multisamples,
                    ),
                };
            }
        }

        // allocate and attach stencil buffer
        // only support renderbuffer
        if (option.stencil_type != .none) {
            self.stencil = .{
                .rbo = allocAndAttachRenderBuffer(
                    .stencil,
                    width,
                    height,
                    .stencil,
                    option.multisamples,
                ),
            };
        }
    }

    assert(self.tex != null or self.depth_stencil != null);
    var status = gl.checkFramebufferStatus(gl.GL_FRAMEBUFFER);
    gl.util.checkError();
    if (status != gl.GL_FRAMEBUFFER_COMPLETE) {
        panic("frame buffer's status is wrong: {x}", .{status});
    }

    // disable color rendering when necessary
    if (option.color_tex_num == 0) {
        gl.drawBuffer(gl.GL_NONE);
        gl.readBuffer(gl.GL_NONE);
        gl.util.checkError();
    }

    return self;
}

pub fn initForShadowMapping(
    allocator: std.mem.Allocator,
    width: u32,
    height: u32,
) !Self {
    var fb = try init(allocator, width, height, .{
        .color_tex_num = 0,
        .depth_type = .texture,
        .stencil_type = .none,
    });
    fb.depth_stencil.?.tex.setWrappingMode(.s, .clamp_to_border);
    fb.depth_stencil.?.tex.setWrappingMode(.t, .clamp_to_border);
    fb.depth_stencil.?.tex.setBorderColor(.{ 1.0, 1.0, 1.0, 1.0 });
    return fb;
}

const AttachmentType = enum(c_int) {
    color0 = gl.GL_COLOR_ATTACHMENT0,
    color1 = gl.GL_COLOR_ATTACHMENT1,
    color2 = gl.GL_COLOR_ATTACHMENT2,
    color3 = gl.GL_COLOR_ATTACHMENT3,
    color4 = gl.GL_COLOR_ATTACHMENT4,
    color5 = gl.GL_COLOR_ATTACHMENT5,
    color6 = gl.GL_COLOR_ATTACHMENT6,
    color7 = gl.GL_COLOR_ATTACHMENT7,
    color8 = gl.GL_COLOR_ATTACHMENT8,
    color9 = gl.GL_COLOR_ATTACHMENT9,
    color10 = gl.GL_COLOR_ATTACHMENT10,
    color11 = gl.GL_COLOR_ATTACHMENT11,
    color12 = gl.GL_COLOR_ATTACHMENT12,
    color13 = gl.GL_COLOR_ATTACHMENT13,
    color14 = gl.GL_COLOR_ATTACHMENT14,
    color15 = gl.GL_COLOR_ATTACHMENT15,
    color16 = gl.GL_COLOR_ATTACHMENT16,
    color17 = gl.GL_COLOR_ATTACHMENT17,
    color18 = gl.GL_COLOR_ATTACHMENT18,
    color19 = gl.GL_COLOR_ATTACHMENT19,
    color20 = gl.GL_COLOR_ATTACHMENT20,
    color21 = gl.GL_COLOR_ATTACHMENT21,
    color22 = gl.GL_COLOR_ATTACHMENT22,
    color23 = gl.GL_COLOR_ATTACHMENT23,
    color24 = gl.GL_COLOR_ATTACHMENT24,
    color25 = gl.GL_COLOR_ATTACHMENT25,
    color26 = gl.GL_COLOR_ATTACHMENT26,
    color27 = gl.GL_COLOR_ATTACHMENT27,
    color28 = gl.GL_COLOR_ATTACHMENT28,
    color29 = gl.GL_COLOR_ATTACHMENT29,
    color30 = gl.GL_COLOR_ATTACHMENT30,
    color31 = gl.GL_COLOR_ATTACHMENT31,
    depth = gl.GL_DEPTH_ATTACHMENT,
    stencil = gl.GL_STENCIL_ATTACHMENT,
    depth_stencil = gl.GL_DEPTH_STENCIL_ATTACHMENT,
};

fn allocAndAttachTexture(
    allocator: std.mem.Allocator,
    attachment: AttachmentType,
    width: u32,
    height: u32,
    texture_format: Texture.TextureFormat,
    pixel_format: Texture.PixelFormat,
    multisamples: ?u32,
) !*Texture {
    var tex = try Texture.init(
        allocator,
        if (multisamples != null)
            .texture_2d_multisample
        else
            .texture_2d,
    );

    if (multisamples) |samples| {
        tex.allocMultisampleData(
            .texture_2d_multisample,
            samples,
            texture_format,
            width,
            height,
        );
    } else {
        tex.updateImageData(
            .texture_2d,
            0,
            texture_format,
            width,
            height,
            null,
            pixel_format,
            u8,
            null,
            false,
        );
        tex.setFilteringMode(.minifying, .nearest);
        tex.setFilteringMode(.magnifying, .nearest);
    }

    gl.framebufferTexture2D(
        gl.GL_FRAMEBUFFER,
        @intCast(c_uint, @enumToInt(attachment)),
        if (multisamples != null)
            gl.GL_TEXTURE_2D_MULTISAMPLE
        else
            gl.GL_TEXTURE_2D,
        tex.id,
        0,
    );
    gl.util.checkError();
    return tex;
}

const RenderBufferType = enum(c_uint) {
    depth = gl.GL_DEPTH_COMPONENT,
    stencil = gl.GL_STENCIL_INDEX,
    depth_stencil = gl.GL_DEPTH24_STENCIL8,
};

fn allocAndAttachRenderBuffer(
    attachment: AttachmentType,
    width: u32,
    height: u32,
    _type: RenderBufferType,
    multisamples: ?u32,
) gl.GLuint {
    var id: gl.GLuint = undefined;
    gl.genRenderbuffers(1, &id);
    defer gl.bindRenderbuffer(gl.GL_RENDERBUFFER, 0);

    gl.bindRenderbuffer(gl.GL_RENDERBUFFER, id);
    if (multisamples) |samples| {
        gl.renderbufferStorageMultisample(
            gl.GL_RENDERBUFFER,
            @intCast(c_int, samples),
            @enumToInt(_type),
            @intCast(c_int, width),
            @intCast(c_int, height),
        );
    } else {
        gl.renderbufferStorage(
            gl.GL_RENDERBUFFER,
            @enumToInt(_type),
            @intCast(c_int, width),
            @intCast(c_int, height),
        );
    }

    assert(attachment == .depth or attachment == .stencil or attachment == .depth_stencil);
    gl.framebufferRenderbuffer(
        gl.GL_FRAMEBUFFER,
        @intCast(c_uint, @enumToInt(attachment)),
        gl.GL_RENDERBUFFER,
        id,
    );
    gl.util.checkError();
    return id;
}

pub fn deinit(self: Self) void {
    for (self.texs) |t| {
        t.deinit();
    }
    if (self.depth_stencil) |vb| {
        switch (vb) {
            .tex => |t| t.deinit(),
            .rbo => |o| gl.deleteRenderbuffers(1, &o),
        }
    }
    if (self.stencil) |vb| {
        switch (vb) {
            .tex => |t| t.deinit(),
            .rbo => |o| gl.deleteRenderbuffers(1, &o),
        }
    }
    gl.deleteFramebuffers(1, &self.id);
    gl.util.checkError();
}

/// copy pixel data to other framebuffer
/// WARNING: after blit operation, default framebuffer will be activated!
pub fn blitData(src: Self, dst: Self) void {
    defer Self.use(null);
    gl.bindFramebuffer(
        gl.GL_READ_FRAMEBUFFER,
        src.id,
    );
    gl.bindFramebuffer(
        gl.GL_DRAW_FRAMEBUFFER,
        dst.id,
    );
    gl.util.checkError();

    gl.blitFramebuffer(
        0,
        0,
        @intCast(c_int, src.tex.?.width),
        @intCast(c_int, src.tex.?.height.?),
        0,
        0,
        @intCast(c_int, dst.tex.?.width),
        @intCast(c_int, dst.tex.?.height.?),
        gl.GL_COLOR_BUFFER_BIT,
        gl.GL_NEAREST,
    );
    gl.util.checkError();
}

pub fn use(framebuffer: ?Self) void {
    current_fb = if (framebuffer) |fb| fb.id else 0;
    gl.bindFramebuffer(gl.GL_FRAMEBUFFER, current_fb);
    gl.util.checkError();
}
