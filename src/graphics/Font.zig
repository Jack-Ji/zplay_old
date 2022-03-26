const std = @import("std");
const assert = std.debug.assert;
const unicode = std.unicode;
const zp = @import("../zplay.zig");
const truetype = zp.deps.stb.truetype;
const gfx = zp.graphics;
const Texture = gfx.gpu.Texture;
const Self = @This();

/// memory allocator
allocator: std.mem.Allocator,

/// font file's data
font_data: []const u8,

/// internal font information
font_info: truetype.stbtt_fontinfo,

/// accept 20M font file at most
const MaxFontSize = 1 << 21;

/// init Font instance with truetype file
pub fn fromTrueType(allocator: std.mem.Allocator, path: [:0]const u8) !*Self {
    const dir = std.fs.cwd();

    var self = try allocator.create(Self);
    self.font_data = try dir.readFileAlloc(allocator, path, MaxFontSize);

    // extract font info
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

pub const Atlas = struct {
    const CharRange = struct {
        codepoint_begin: u32,
        codepoint_end: u32,
        packedchar: std.ArrayList(truetype.stbtt_packedchar),
    };

    const map_size = 4096;

    tex: *Texture,
    ranges: std.ArrayList(CharRange),

    /// create font atlas
    pub fn init(
        allocator: std.mem.Allocator,
        font_info: *truetype.stbtt_fontinfo,
        font_size: u32,
        codepoint_ranges: [][2]u32,
    ) !Atlas {
        assert(codepoint_ranges.len > 0);

        // allocate memory
        var ranges = try std.ArrayList(CharRange).initCapacity(codepoint_ranges.len);
        errdefer ranges.deinit();

        // create texture
        var tex = Texture.init(allocator, .texture_2d);
        const pixels = try allocator.alloc(u8, map_size * map_size);
        defer allocator.free(pixels);

        // generate atlas
        var pack_ctx = std.mem.zeroes(truetype.stbtt_pack_context);
        var rc = truetype.stbtt_PackBegin(
            &pack_ctx,
            pixels,
            @intCast(c_int, map_size),
            @intCast(c_int, map_size),
            0,
            1,
            null,
        );
        assert(rc > 0);
        for (codepoint_ranges) |cs, i| {
            assert(cs[1] >= cs[0]);
            ranges.items[i].codepoint_begin = cs[0];
            ranges.items[i].codepoint_end = cs[1];
            ranges.items[i].packedchar = try std.ArrayList(truetype.stbtt_packedchar)
                .initCapacity(cs[1] - cs[0] + 1);
            _ = truetype.stbtt_PackFontRange(
                &pack_ctx,
                font_info.data,
                0,
                @intToFloat(f32, font_size),
                @intCast(c_int, cs[0]),
                @intCast(c_int, cs[1] - cs[0] + 1),
                ranges.items[i].packedchar.ptr,
            );
        }
        truetype.stbtt_PackEnd(&pack_ctx);

        // upload to gpu
        tex.updateImageData(
            .texture_2d,
            0,
            .red,
            map_size,
            map_size,
            null,
            .red,
            u8,
            pixels.ptr,
            false,
        ) catch unreachable;
        tex.setWrappingMode(.s, .clamp_to_edge);
        tex.setWrappingMode(.t, .clamp_to_edge);
        tex.setFilteringMode(.minifying, .linear);
        tex.setFilteringMode(.magnifying, .linear);

        return .{
            .tex = tex,
            .ranges = ranges,
        };
    }

    pub fn deinit(self: Atlas) void {
        self.tex.deinit();
        for (self.ranges.items) |r| {
            r.packedchar.deinit();
        }
        self.ranges.deinit();
    }

    /// append draw data for rendering utf8 string
    pub fn appendDrawDataFromUTF8String(
        self: Atlas,
        text: []const u8,
        _xpos: f32,
        _ypos: f32,
        vpos: *std.ArrayList(f32),
        tcoords: *std.ArrayList(f32),
    ) !f32 {
        if (text.len == 0) return _xpos;

        var xpos = _xpos;
        var ypos = _ypos;
        var pxpos = &xpos;
        var pypos = &ypos;

        var i: u32 = 0;
        while (i < text.len) {
            var size = try unicode.utf8ByteSequenceLength(text[i]);
            var codepoint = @intCast(u32, try unicode.utf8Decode(text[i .. i + size]));
            for (self.ranges.items) |range| {
                if (codepoint < range.codepoint_begin or codepoint > range.codepoint_end) continue;

                var quad: truetype.stbtt_aligned_quad = undefined;
                truetype.stbtt_GetPackedQuad(
                    range.packedchar.items.ptr,
                    @intCast(c_int, map_size),
                    @intCast(c_int, map_size),
                    @intCast(c_int, codepoint - range.codepoint_begin),
                    pxpos,
                    pypos,
                    &quad,
                    0,
                );
                try vpos.appendSlice(&[_]f32{
                    quad.x0, quad.y0, 0,
                    quad.x1, quad.y0, 0,
                    quad.x1, quad.y1, 0,
                    quad.x0, quad.y0, 0,
                    quad.x1, quad.y1, 0,
                    quad.x1, quad.y0, 0,
                });
                try tcoords.appendSlice(&[_]f32{
                    quad.s0, quad.t0,
                    quad.s1, quad.t0,
                    quad.s1, quad.t1,
                    quad.s0, quad.t0,
                    quad.s1, quad.t1,
                    quad.s1, quad.t0,
                });
            }
            i += size;
        }

        return *pxpos;
    }
};
