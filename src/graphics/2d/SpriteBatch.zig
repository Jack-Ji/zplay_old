const std = @import("std");
const assert = std.debug.assert;
const Sprite = @import("Sprite.zig");
const SpriteSheet = @import("SpriteSheet.zig");
const SpriteRenderer = @import("SpriteRenderer.zig");
const zp = @import("../../zplay.zig");
const gfx = zp.graphics;
const Context = gfx.gpu.Context;
const VertexArray = gfx.gpu.VertexArray;
const Renderer = gfx.Renderer;
const Material = gfx.Material;
const Mat4 = zp.deps.alg.Mat4;
const Self = @This();

pub const Error = error{
    TooMuchSheet,
    TooMuchSprite,
};

pub const DepthSortMethod = enum {
    none,
    back_to_forth,
    forth_to_back,
};

pub const BlendMethod = enum {
    alpha_blend,
    additive,
    overwrite,
};

pub const DrawOption = struct {
    pos: Sprite.Point,
    color: [4]f32 = [_]f32{ 1, 1, 1, 1 },
    scale_w: f32 = 1.0,
    scale_h: f32 = 1.0,
    rotate_degree: f32 = 0,
    anchor_point: Sprite.Point = .{ .x = 0, .y = 0 },
    depth: f32 = 0.5,
};

const BatchData = struct {
    const SpriteData = struct {
        sprite: Sprite,
        draw_option: DrawOption,
    };

    sprites_data: std.ArrayList(SpriteData),
    vertex_array: VertexArray,
    vattrib: std.ArrayList(f32),
    vtransforms: std.ArrayList(Mat4),
    material: Material,
};

/// memory allocator
allocator: std.mem.Allocator,

/// graphics context
gctx: *Context,

/// renderer
default_renderer: SpriteRenderer,
current_renderer: ?SpriteRenderer = null,

/// all batch data
batches: []BatchData,

/// renderer's input
render_data: Renderer.Input,

/// sprite-sheet search tree
search_tree: std.AutoHashMap(*SpriteSheet, u32),

/// maximum limit
max_sprites_per_drawcall: u32,

///  sort method
depth_sort: DepthSortMethod,

///  blend method
blend: BlendMethod,

/// create sprite-batch
pub fn init(
    allocator: std.mem.Allocator,
    ctx: *Context,
    max_sheet_num: u32,
    max_sprites_per_drawcall: u32,
) !*Self {
    var self = try allocator.create(Self);
    self.* = Self{
        .allocator = allocator,
        .gctx = ctx,
        .default_renderer = SpriteRenderer.init(null),
        .batches = try allocator.alloc(BatchData, max_sheet_num),
        .render_data = try Renderer.Input.init(
            allocator,
            &.{},
            null,
            null,
            null,
        ),
        .search_tree = std.AutoHashMap(*SpriteSheet, u32).init(allocator),
        .max_sprites_per_drawcall = max_sprites_per_drawcall,
        .depth_sort = .none,
        .blend = .additive,
    };
    for (self.batches) |*b| {
        b.sprites_data = try std.ArrayList(BatchData.SpriteData).initCapacity(allocator, 1000);
        b.vertex_array = VertexArray.init(allocator, 2);
        b.vertex_array.vbos[0].allocData(max_sprites_per_drawcall * 32 * 6, .dynamic_draw);
        b.vertex_array.vbos[1].allocData(max_sprites_per_drawcall * 64 * 6, .dynamic_draw);
        SpriteRenderer.setupVertexArray(b.vertex_array);
        b.vattrib = try std.ArrayList(f32).initCapacity(allocator, 32000);
        b.vtransforms = try std.ArrayList(Mat4).initCapacity(allocator, 1000);
    }
    return self;
}

pub fn deinit(self: *Self) void {
    for (self.batches) |b| {
        b.sprites_data.deinit();
        b.vertex_array.deinit();
        b.vattrib.deinit();
        b.vtransforms.deinit();
    }
    self.allocator.free(self.batches);
    self.default_renderer.deinit();
    self.render_data.deinit();
    self.search_tree.deinit();
    self.allocator.destroy(self);
}

/// begin batched data
pub const BatchOption = struct {
    depth_sort: DepthSortMethod = .none,
    blend: BlendMethod = .alpha_blend,
    custom_renderer: ?SpriteRenderer = null,
};
pub fn begin(self: *Self, opt: BatchOption) void {
    self.current_renderer = opt.custom_renderer orelse self.default_renderer;
    self.depth_sort = opt.depth_sort;
    self.blend = opt.blend;
    for (self.render_data.vds.?.items) |_, i| {
        self.batches[i].sprites_data.clearRetainingCapacity();
        self.batches[i].vattrib.clearRetainingCapacity();
        self.batches[i].vtransforms.clearRetainingCapacity();
    }
    self.render_data.vds.?.clearRetainingCapacity();
    self.search_tree.clearRetainingCapacity();
}

/// add sprite to next batch
pub fn drawSprite(self: *Self, sprite: Sprite, opt: DrawOption) !void {
    var index = self.search_tree.get(sprite.sheet) orelse blk: {
        var count = self.search_tree.count();
        if (count == self.batches.len) {
            return error.TooMuchSheet;
        }
        self.batches[count].material = Material.init(.{
            .single_texture = sprite.sheet.tex,
        });
        try self.render_data.vds.?.append(.{
            .element_draw = false,
            .vertex_array = self.batches[count].vertex_array,
            .count = 0,
            .material = &self.batches[count].material,
        });
        try self.search_tree.put(sprite.sheet, count);
        break :blk count;
    };
    if (self.batches[index].sprites_data.items.len >= self.max_sprites_per_drawcall) {
        return error.TooMuchSprite;
    }
    try self.batches[index].sprites_data.append(.{
        .sprite = sprite,
        .draw_option = opt,
    });
}

fn ascendCompare(self: *Self, lhs: BatchData.SpriteData, rhs: BatchData.SpriteData) bool {
    _ = self;
    return lhs.draw_option.depth < rhs.draw_option.depth;
}

fn descendCompare(self: *Self, lhs: BatchData.SpriteData, rhs: BatchData.SpriteData) bool {
    _ = self;
    return lhs.draw_option.depth > rhs.draw_option.depth;
}

/// send batched data to gpu, issue draw command
pub fn end(self: *Self) !void {
    defer self.current_renderer = null;
    if (self.render_data.vds.?.items.len == 0) return;

    // generate draw data
    for (self.batches) |*b| {
        // sort sprites when needed
        switch (self.depth_sort) {
            .back_to_forth => {
                // sort depth value in descending order
                std.sort.sort(
                    BatchData.SpriteData,
                    b.sprites_data.items,
                    self,
                    descendCompare,
                );
            },
            .forth_to_back => {
                // sort depth value in ascending order
                std.sort.sort(
                    BatchData.SpriteData,
                    b.sprites_data.items,
                    self,
                    ascendCompare,
                );
            },
            else => {},
        }

        for (b.sprites_data.items) |data| {
            try data.sprite.appendDrawData(
                &b.vattrib,
                &b.vtransforms,
                .{
                    .pos = data.draw_option.pos,
                    .color = data.draw_option.color,
                    .scale_w = data.draw_option.scale_w,
                    .scale_h = data.draw_option.scale_h,
                    .rotate_degree = data.draw_option.rotate_degree,
                    .anchor_point = data.draw_option.anchor_point,
                },
            );
        }
    }

    // upload vertex data
    for (self.render_data.vds.?.items) |*vd, i| {
        self.batches[i].vertex_array.vbos[0].updateData(
            0,
            f32,
            self.batches[i].vattrib.items,
        );
        self.batches[i].vertex_array.vbos[1].updateData(
            0,
            Mat4,
            self.batches[i].vtransforms.items,
        );
        vd.count = @intCast(u32, self.batches[i].vtransforms.items.len);
    }

    // color blend
    var old_blend_status = self.gctx.isCapabilityEnabled(.blend);
    var old_blend_option = self.gctx.blend_option;
    switch (self.blend) {
        .additive => {
            if (!old_blend_status) {
                self.gctx.toggleCapability(.blend, true);
            }
            self.gctx.setBlendOption(.{ .src_rgb = .one, .dst_rgb = .one });
        },
        .alpha_blend => {
            if (!old_blend_status) {
                self.gctx.toggleCapability(.blend, true);
            }
            self.gctx.setBlendOption(.{});
        },
        .overwrite => {
            if (old_blend_status) {
                self.gctx.toggleCapability(.blend, false);
            }
        },
    }
    defer {
        switch (self.blend) {
            .additive, .alpha_blend => {
                if (!old_blend_status) {
                    self.gctx.toggleCapability(.blend, false);
                } else {
                    self.gctx.setBlendOption(old_blend_option);
                }
            },
            .overwrite => {
                if (old_blend_status) {
                    self.gctx.toggleCapability(.blend, true);
                }
            },
        }
    }

    // send draw command
    try self.current_renderer.?.draw(self.gctx, self.render_data);
}
