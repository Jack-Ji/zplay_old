const std = @import("std");
const assert = std.debug.assert;
const zp = @import("../../zplay.zig");
const gfx = zp.graphics;
const Texture = gfx.gpu.Texture;
const stb_rect_pack = zp.deps.stb.rect_pack;
const stb_image = zp.deps.stb.image;
const Self = @This();

const ImagePixels = struct {
    data: []const u8,
    width: u32,
    height: u32,
};

pub const PackError = error{
    TextureNotLargeEnough,
};

/// image data source
pub const ImageSource = struct {
    name: []const u8,
    image: union(enum) {
        file_path: [:0]const u8,
        pixels: ImagePixels,
    },
};

/// sprite rectangle
pub const SpriteRect = struct {
    // texture coordinate of top-left
    s0: f32,
    t0: f32,

    // texture coordinate of bottom-right
    s1: f32,
    t1: f32,

    // size of sprite
    width: f32,
    height: f32,
};

/// memoery allocator
allocator: std.mem.Allocator,

/// packed texture
tex: *Texture,

/// sprite rectangles
rects: []SpriteRect,

/// sprite search-tree
search_tree: std.StringHashMap(u32),

/// create sprite-sheet
pub fn init(
    allocator: std.mem.Allocator,
    sources: []ImageSource,
    width: u32,
    height: u32,
) !Self {
    assert(sources.len > 0);
    const ImageData = struct {
        is_file: bool,
        pixels: ImagePixels,
    };

    var rects = try allocator.alloc(SpriteRect, sources.len);
    errdefer allocator.free(rects);

    var tree = std.StringHashMap(u32).init();
    var pixels = try allocator.alloc(u8, width * height * 4);
    defer allocator.free(pixels);

    var stb_rects = try allocator.alloc(stb_rect_pack.stbrp_rect, sources.len);
    defer allocator.free(stb_rects);

    var stb_nodes = try allocator.alloc(stb_rect_pack.stbrp_node, width);
    defer allocator.free(stb_nodes);

    var images = try allocator.alloc(ImageData, sources.len);
    defer allocator.free(images);

    // flip image files, cause stb_image use top-left pixel as first one
    stb_image.stbi_set_flip_vertically_on_load(1);

    // load images' data
    for (sources) |s, i| {
        switch (s.image) {
            .file_path => |path| {
                var image_width: c_int = undefined;
                var image_height: c_int = undefined;
                var image_channels: c_int = undefined;
                var image_data = stb_image.stbi_load(
                    path.ptr,
                    &image_width,
                    &image_height,
                    &image_channels,
                    4, // alpha channel is required
                );
                assert(image_data != null);
                var image_len = image_width * image_height * image_channels;
                images[i] = .{
                    .is_file = false,
                    .pixels = .{
                        .data = image_data[0..@intCast(usize, image_len)],
                        .width = @intCast(u32, image_width),
                        .height = @intCast(u32, image_height),
                    },
                };
            },
            .pixels => |ps| {
                assert(ps.data.len > 0 and ps.width > 0 and ps.height > 0);
                assert(ps.data.len == ps.width * ps.height * 4);
                images = .{
                    .is_file = false,
                    .pixels = ps,
                };
            },
        }
        stb_rects[i] = std.mem.zeroes(stb_rect_pack.stbrp_rect);
        stb_rects[i].id = @intCast(c_int, i);
        stb_rects[i].w = @intCast(c_ushort, images[i].pixels.width);
        stb_rects[i].h = @intCast(c_ushort, images[i].pixels.height);
    }
    defer {
        // free file-images' data when we're done
        for (images) |img| {
            if (img.is_file) {
                stb_image.stbi_image_free(img.pixels.data.ptr);
            }
        }
    }

    // start packing images
    var pack_ctx: stb_rect_pack.stbrp_context = undefined;
    stb_rect_pack.stbrp_init_target(
        &pack_ctx,
        width,
        height,
        stb_nodes.ptr,
        @intCast(c_int, stb_nodes.len),
    );
    const rc = stb_rect_pack.stbrp_pack_rects(
        &pack_ctx,
        stb_rects.ptr,
        @intCast(c_int, stb_rects.len),
    );
    if (rc == 0) {
        return error.TextureNotLargeEnough;
    }

    // merge textures and upload to gpu
    const inv_width = 1.0 / @intToFloat(f32, width);
    const inv_height = 1.0 / @intToFloat(f32, height);
    for (stb_rects) |r, i| {
        rects[i] = .{
            .s0 = @intToFloat(f32, r.x) * inv_width,
            .t0 = (@intToFloat(f32, height) - @intToFloat(f32, r.y)) * inv_height,
            .s1 = @intToFloat(f32, r.x + r.w) * inv_width,
            .t1 = (@intToFloat(f32, height) - @intToFloat(f32, r.y + r.h)) * inv_height,
            .width = @intCast(u32, r.w),
            .height = @intCast(u32, r.h),
        };
        const y_begin: u32 = height - @intCast(u32, r.y + r.h);
        const y_end: u32 = height - @intCast(u32, r.y);
        const src_pixels = images[i].pixels;
        const dst_stride: u32 = width * 4;
        const src_stride: u32 = src_pixels.width * 4;
        var y: u32 = y_begin;
        while (y < y_end) : (y += 1) {
            const dst_offset: u32 = y * dst_stride + @intCast(u32, r.x) * 4;
            const src_offset: u32 = (y - y_begin) * src_stride;
            std.mem.copy(
                u8,
                pixels[dst_offset .. dst_offset + src_stride],
                src_pixels[src_offset .. src_offset + src_stride],
            );
        }
    }
    var tex = try Texture.init2DFromPixels(
        allocator,
        pixels,
        .rgba,
        width,
        height,
    );

    return Self{
        .allocator = allocator,
        .tex = tex,
        .rects = rects,
        .search_tree = tree,
    };
}

/// destroy sprite-sheet
pub fn deinit(self: *Self) void {
    self.tex.deinit();
    self.allocator.free(self.rects);
    self.search_tree.deinit();
}
