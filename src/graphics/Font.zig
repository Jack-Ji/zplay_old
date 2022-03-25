const std = @import("std");
const assert = std.debug.assert;
const zp = @import("../zplay.zig");
const truetype = zp.deps.stb.truetype;
const Self = @This();

/// memory allocator
allocator: std.mem.Allocator,

/// font file's data
font_data: []const u8,

/// internal info of font
font_info: truetype.stbtt_fontinfo,

/// accept 20M font file at most
const MaxFontSize = 1 << 21;

/// init Font instance with truetype file
pub fn fromTrueType(allocator: std.mem.Allocator, path: [:0]const u8) !*Self {
    const dir = std.fs.cwd();

    var self = try allocator.create(Self);
    self.font_data = try dir.readFileAlloc(allocator, path, MaxFontSize);
    var rc = truetype.stbtt_InitFont(
        &self.font_info,
        self.font_data.ptr,
        truetype.stbtt_GetFontOffsetForIndex(self.font_data.ptr, 0),
    );
    assert(rc > 0);
    return self;
}

pub fn deinit(self: *Self) void {
    self.allocator.destroy(self.font_data);
    self.allocator.destroy(self);
}
