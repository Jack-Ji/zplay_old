const std = @import("std");
const assert = std.debug.assert;
const zp = @import("../../zplay.zig");
const gl = zp.deps.gl;
const Self = @This();

pub const BindTarget = enum(c_uint) {
    framebuffer = gl.GL_FRAMEBUFFER, // read and write
    read_framebuffer = gl.GL_READ_FRAMEBUFFER, // only read
    draw_framebuffer = gl.GL_DRAW_FRAMEBUFFER, // only write
};

pub const Status = enum(c_uint) {
    // framebuffer is complete
    complete = gl.GL_FRAMEBUFFER_COMPLETE,

    // framebuffer is the default read or draw framebuffer, but the default
    // framebuffer does not exist.
    undefined = gl.GL_FRAMEBUFFER_UNDEFINED,

    // the framebuffer attachment points are framebuffer incomplete.
    incomplete_attachment = gl.GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT,

    // framebuffer does not have at least one image attached to it.
    incomplete_missing_attachment = gl.GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT,

    // value of GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE is GL_NONE for any color attachment point(s)
    // named by GL_DRAW_BUFFERi.
    incomplete_draw_buffer = gl.GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER,

    // GL_READ_BUFFER is not GL_NONE and the value of GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE
    // is GL_NONE for the color attachment point named by GL_READ_BUFFER.
    incomplete_read_buffer = gl.GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER,

    // combination of internal formats of the attached images violates an
    // implementation-dependent set of restrictions.
    unsupported = gl.GL_FRAMEBUFFER_UNSUPPORTED,

    // 1. value of of GL_RENDERBUFFER_SAMPLES is not the same for all attached renderbuffers; if the
    // value of GL_TEXTURE_SAMPLES is the not same for all attached textures; or, if the
    // attached images are a mix of renderbuffers and textures, the value of GL_RENDERBUFFER_SAMPLES
    // does not match the value of GL_TEXTURE_SAMPLES.
    // 2. value of GL_TEXTURE_FIXED_SAMPLE_LOCATIONS is not the same for all attached textures; or, if the
    // attached images are a mix of renderbuffers and textures, the value of GL_TEXTURE_FIXED_SAMPLE_LOCATIONS
    // is not GL_TRUE for all attached textures.
    incomplete_multisample = gl.GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE,

    // attachment is layered, and any populated attachment is not layered, or if all populated color
    // attachments are not from textures of the same target.
    incomplete_layer_targets = gl.GL_FRAMEBUFFER_INCOMPLETE_LAYER_TARGETS,
};

/// id of framebuffer
id: gl.GLuint = undefined,

/// target of framebuffer
target: BindTarget,

/// current active framebuffer
var current: gl.GLuint = 0;

pub fn init(target: BindTarget) Self {
    var self = Self{
        .target = target,
    };
    gl.genFramebuffers(1, &self.id);
    gl.util.checkError();
    return self;
}

pub fn deinit(self: Self) void {
    gl.deleteFramebuffers(1, &self.id);
    gl.util.checkError();
}

pub fn use(self: Self) void {
    current = self.id;
    gl.bindFramebuffer(@enumToInt(self.target), self.id);
    gl.util.checkError();
}

pub fn disuse(self: Self) void {
    _ = self;
    current = 0;
    gl.bindFramebuffer(@enumToInt(self.target), 0);
}

pub fn getStatus(self: Self) Status {
    assert(self.id == current);
    var status = gl.checkFramebufferStatus(@enumToInt(self.target));
    gl.util.checkError();
    return @as(Status, status);
}
