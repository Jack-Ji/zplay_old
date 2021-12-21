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
};

pub fn init(
    allocator: std.mem.Allocator,
    width: u32,
    height: u32,
    option: Option,
) Self {
    var self = Self{
        .tex = Texture.init(allocator, .texture_2d),
        .owned = true,
    };
    gl.genFramebuffers(1, &self.id);
    gl.bindFramebuffer(gl.GL_FRAMEBUFFER, self.id);
    defer gl.bindFramebuffer(gl.GL_FRAMEBUFFER, 0);
    gl.util.checkError();

    // attach color texture
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
    gl.framebufferTexture2D(gl.GL_FRAMEBUFFER, gl.GL_COLOR_ATTACHMENT0, gl.GL_TEXTURE_2D, self.tex.id, 0);
    gl.util.checkError();

    // attach depth/stencil
    if (option.has_depth_stencil) {
        self.allocRenderbuffers(option.separate_stecil_depth);
    }

    var status = gl.checkFramebufferStatus(gl.GL_FRAMEBUFFER);
    gl.util.checkError();
    if (status != gl.GL_FRAMEBUFFER_COMPLETE) {
        panic("frame buffer's status is wrong: {x}", .{status});
    }
    return self;
}

pub fn fromTexture(tex: *Texture, option: Option) !Self {
    if (tex.tt != .texture_2d or (tex.format != .rgb and tex.format != .rgba)) {
        return error.InvalidTexture;
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
        gl.GL_TEXTURE_2D,
        self.tex.id,
        0,
    );
    gl.util.checkError();

    // attach depth/stencil
    if (option.has_depth_stencil) {
        self.allocDepthStencil(option.separate_depth_stencil);
    }

    var status = gl.checkFramebufferStatus(gl.GL_FRAMEBUFFER);
    gl.util.checkError();
    if (status != gl.GL_FRAMEBUFFER_COMPLETE) {
        panic("frame buffer's status is wrong: {x}", .{status});
    }
    return self;
}

/// attach depth/stencil buffers
fn allocDepthStencil(self: *Self, separate_stecil_depth: bool) void {
    gl.genRenderbuffers(1, &self.rbo1);
    defer gl.bindRenderbuffer(gl.GL_RENDERBUFFER, 0);
    if (separate_stecil_depth) {
        gl.genRenderbuffers(1, &self.rbo2);

        // depth
        gl.bindRenderbuffer(gl.GL_RENDERBUFFER, self.rbo1);
        gl.renderbufferStorage(
            gl.GL_RENDERBUFFER,
            gl.GL_DEPTH_COMPONENT,
            @intCast(c_int, self.tex.width),
            @intCast(c_int, self.tex.height.?),
        );
        gl.framebufferRenderbuffer(
            gl.GL_FRAMEBUFFER,
            gl.GL_DEPTH_ATTACHMENT,
            gl.GL_RENDERBUFFER,
            self.rbo1,
        );

        // stencil
        gl.bindRenderbuffer(gl.GL_RENDERBUFFER, self.rbo2);
        gl.renderbufferStorage(
            gl.GL_RENDERBUFFER,
            gl.GL_STENCIL_INDEX,
            @intCast(c_int, self.tex.width),
            @intCast(c_int, self.tex.height.?),
        );
        gl.framebufferRenderbuffer(
            gl.GL_FRAMEBUFFER,
            gl.GL_STENCIL_ATTACHMENT,
            gl.GL_RENDERBUFFER,
            self.rbo2,
        );
    } else {
        gl.bindRenderbuffer(gl.GL_RENDERBUFFER, self.rbo1);
        gl.renderbufferStorage(
            gl.GL_RENDERBUFFER,
            gl.GL_DEPTH24_STENCIL8,
            @intCast(c_int, self.tex.width),
            @intCast(c_int, self.tex.height.?),
        );
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
