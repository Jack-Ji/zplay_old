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

/// id of framebuffer
id: gl.GLuint = undefined,

/// color texture
tex: *Texture = undefined,
owned: bool = undefined,

/// render buffer object, used for depth and stencil
rbo1: gl.GLuint = 0,
rbo2: gl.GLuint = 0,

pub const Option = struct {
    has_alpha: bool = true,
    has_depth_stencil: bool = true,
    separate_depth_stencil: bool = false,
    enable_multisample: bool = false,
    samples: u32 = 4,
};

pub fn init(
    allocator: std.mem.Allocator,
    width: u32,
    height: u32,
    option: Option,
) !Self {
    var self = Self{
        .tex = try Texture.init(
            allocator,
            if (option.enable_multisample)
                .texture_2d_multisample
            else
                .texture_2d,
        ),
        .owned = true,
    };
    gl.genFramebuffers(1, &self.id);
    gl.bindFramebuffer(gl.GL_FRAMEBUFFER, self.id);
    defer gl.bindFramebuffer(gl.GL_FRAMEBUFFER, 0);
    gl.util.checkError();

    // attach color texture
    if (option.enable_multisample) {
        self.tex.allocMultisampleData(
            .texture_2d_multisample,
            option.samples,
            if (option.has_alpha) .rgba else .rgb,
            width,
            height,
        );
    } else {
        self.tex.updateImageData(
            .texture_2d,
            0,
            if (option.has_alpha) .rgba else .rgb,
            width,
            height,
            null,
            if (option.has_alpha) .rgba else .rgb,
            u8,
            null,
            false,
        );
        self.tex.setFilteringMode(.minifying, .linear);
        self.tex.setFilteringMode(.magnifying, .linear);
    }
    gl.framebufferTexture2D(
        gl.GL_FRAMEBUFFER,
        gl.GL_COLOR_ATTACHMENT0,
        if (option.enable_multisample)
            gl.GL_TEXTURE_2D_MULTISAMPLE
        else
            gl.GL_TEXTURE_2D,
        self.tex.id,
        0,
    );
    gl.util.checkError();

    // attach depth/stencil
    if (option.has_depth_stencil) {
        self.allocDepthStencil(
            option.separate_depth_stencil,
            option.enable_multisample,
        );
    }

    var status = gl.checkFramebufferStatus(gl.GL_FRAMEBUFFER);
    gl.util.checkError();
    if (status != gl.GL_FRAMEBUFFER_COMPLETE) {
        panic("frame buffer's status is wrong: {x}", .{status});
    }
    return self;
}

pub fn fromTexture(tex: *Texture, option_: Option) !Self {
    if ((tex.tt != .texture_2d and tex.tt != .texture_2d_multisample) or
        (tex.format != .rgb and tex.format != .rgba))
    {
        return error.InvalidTexture;
    }
    assert(tex.width > 0 and tex.height.? > 0);
    var option = option_;
    if (tex.tt == .texture_2d_multisample) {
        option.enable_multisample = true;
    }

    var self = Self{
        .tex = tex,
        .owned = false,
    };
    gl.genFramebuffers(1, &self.id);
    gl.bindFramebuffer(gl.GL_FRAMEBUFFER, self.id);
    defer gl.bindFramebuffer(gl.GL_FRAMEBUFFER, 0);
    gl.util.checkError();

    // attach color texture
    gl.framebufferTexture2D(
        gl.GL_FRAMEBUFFER,
        gl.GL_COLOR_ATTACHMENT0,
        if (option.enable_multisample)
            gl.GL_TEXTURE_2D_MULTISAMPLE
        else
            gl.GL_TEXTURE_2D,
        self.tex.id,
        0,
    );
    gl.util.checkError();

    // attach depth/stencil
    if (option.has_depth_stencil) {
        self.allocDepthStencil(
            option.separate_depth_stencil,
            option.enable_multisample,
        );
    }

    var status = gl.checkFramebufferStatus(gl.GL_FRAMEBUFFER);
    gl.util.checkError();
    if (status != gl.GL_FRAMEBUFFER_COMPLETE) {
        panic("frame buffer's status is wrong: {x}", .{status});
    }
    return self;
}

/// attach depth/stencil buffers
fn allocDepthStencil(
    self: *Self,
    separate_stecil_depth: bool,
    enable_msaa: bool,
) void {
    gl.genRenderbuffers(1, &self.rbo1);
    defer gl.bindRenderbuffer(gl.GL_RENDERBUFFER, 0);
    if (separate_stecil_depth) {
        gl.genRenderbuffers(1, &self.rbo2);

        // depth
        gl.bindRenderbuffer(gl.GL_RENDERBUFFER, self.rbo1);
        if (enable_msaa) {
            gl.renderbufferStorageMultisample(
                gl.GL_RENDERBUFFER,
                4,
                gl.GL_DEPTH_COMPONENT,
                @intCast(c_int, self.tex.width),
                @intCast(c_int, self.tex.height.?),
            );
        } else {
            gl.renderbufferStorage(
                gl.GL_RENDERBUFFER,
                gl.GL_DEPTH_COMPONENT,
                @intCast(c_int, self.tex.width),
                @intCast(c_int, self.tex.height.?),
            );
        }
        gl.framebufferRenderbuffer(
            gl.GL_FRAMEBUFFER,
            gl.GL_DEPTH_ATTACHMENT,
            gl.GL_RENDERBUFFER,
            self.rbo1,
        );

        // stencil
        gl.bindRenderbuffer(gl.GL_RENDERBUFFER, self.rbo2);
        if (enable_msaa) {
            gl.renderbufferStorageMultisample(
                gl.GL_RENDERBUFFER,
                4,
                gl.GL_STENCIL_INDEX,
                @intCast(c_int, self.tex.width),
                @intCast(c_int, self.tex.height.?),
            );
        } else {
            gl.renderbufferStorage(
                gl.GL_RENDERBUFFER,
                gl.GL_STENCIL_INDEX,
                @intCast(c_int, self.tex.width),
                @intCast(c_int, self.tex.height.?),
            );
        }
        gl.framebufferRenderbuffer(
            gl.GL_FRAMEBUFFER,
            gl.GL_STENCIL_ATTACHMENT,
            gl.GL_RENDERBUFFER,
            self.rbo2,
        );
    } else {
        gl.bindRenderbuffer(gl.GL_RENDERBUFFER, self.rbo1);
        if (enable_msaa) {
            gl.renderbufferStorageMultisample(
                gl.GL_RENDERBUFFER,
                4,
                gl.GL_DEPTH24_STENCIL8,
                @intCast(c_int, self.tex.width),
                @intCast(c_int, self.tex.height.?),
            );
        } else {
            gl.renderbufferStorage(
                gl.GL_RENDERBUFFER,
                gl.GL_DEPTH24_STENCIL8,
                @intCast(c_int, self.tex.width),
                @intCast(c_int, self.tex.height.?),
            );
        }
        gl.framebufferRenderbuffer(
            gl.GL_FRAMEBUFFER,
            gl.GL_DEPTH_STENCIL_ATTACHMENT,
            gl.GL_RENDERBUFFER,
            self.rbo1,
        );
    }
    gl.util.checkError();
}

pub fn deinit(self: Self) void {
    if (self.owned) {
        self.tex.deinit();
    }
    if (self.rbo1 > 0) {
        gl.deleteRenderbuffers(1, &self.rbo1);
    }
    if (self.rbo2 > 0) {
        gl.deleteRenderbuffers(1, &self.rbo2);
    }
    gl.deleteFramebuffers(1, &self.id);
    gl.util.checkError();
}

/// copy pixel data to other framebuffer
/// WARNING: after blit operation, default framebuffer will be activated!
pub fn blitData(src: Self, dst: Self) void {
    defer gl.bindFramebuffer(gl.GL_FRAMEBUFFER, 0);
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
        @intCast(c_int, src.tex.width),
        @intCast(c_int, src.tex.height.?),
        0,
        0,
        @intCast(c_int, dst.tex.width),
        @intCast(c_int, dst.tex.height.?),
        gl.GL_COLOR_BUFFER_BIT,
        gl.GL_NEAREST,
    );
    gl.util.checkError();
}
