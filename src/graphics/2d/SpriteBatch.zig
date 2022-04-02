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

const BatchData = struct {
    vertex_array: VertexArray,
    vattrib: std.ArrayList(f32),
    vtransforms: std.ArrayList(Mat4),
    material: Material,
};

/// memory allocator
allocator: std.mem.Allocator,

/// renderer
renderer: SpriteRenderer,

/// all batch data
batches: []BatchData,

/// renderer's input 
render_data: Renderer.Input,

/// sprite-sheet search tree
search_tree: std.AutoHashMap(*SpriteSheet, u32),

/// maximum limit
max_sprites_per_drawcall: u32,

/// create sprite-batch
pub fn init(
    allocator: std.mem.Allocator,
    max_sheet_num: u32,
    max_sprites_per_drawcall: u32,
) !Self {
    var self = Self{
        .allocator = allocator,
        .renderer = SpriteRenderer.init(),
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
    };
    for (self.batches) |*b| {
        b.vertex_array = VertexArray.init(allocator, 2);
        b.vertex_array.vbos[0].allocData(max_sprites_per_drawcall * 16, .dynamic_draw);
        b.vertex_array.vbos[1].allocData(max_sprites_per_drawcall * 64, .dynamic_draw);
        SpriteRenderer.setupVertexArray(b.vertex_array);
        b.vattrib = try std.ArrayList(f32).initCapacity(allocator, 16000);
        b.vtransforms = try std.ArrayList(Mat4).initCapacity(allocator, 1000);
    }
    return self;
}

pub fn deinit(self: *Self) void {
    for (self.batches) |b| {
        b.vertex_array.deinit();
        b.vattrib.deinit();
        b.vtransforms.deinit();
    }
    self.allocator.free(self.batches);
    self.renderer.deinit();
    self.render_data.deinit();
    self.search_tree.deinit();
}

/// clear batched data
pub fn clear(self: *Self) void {
    for (self.render_data.vds.?.items) |_, i| {
        self.batches[i].vattrib.clearRetainingCapacity();
        self.batches[i].vtransforms.clearRetainingCapacity();
    }
    self.render_data.vds.?.clearRetainingCapacity();
    self.search_tree.clearRetainingCapacity();
}

/// add sprite to next batch
pub fn drawSprite(self: *Self, sprite: Sprite) !void {
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
    if (self.batches[index].vtransforms.items.len >= self.max_sprites_per_drawcall) {
        return error.TooMuchSprite;
    }
    try sprite.appendDrawData(
        &self.batches[index].vattrib,
        &self.batches[index].vtransforms,
    );
}

/// send batched data to gpu, issue draw command
pub fn submitAndRender(self: *Self, ctx: *Context) !void {
    if (self.render_data.vds.?.items.len == 0) return;
    for (self.render_data.vds.?.items) |*vd, i| {
        self.batches[i].vertex_array.vbos[0].updateData(
            0,
            f32,
            self.batches[i].vattrib.items,
        );
        self.batches[i].vertex_array.vbos[0].updateData(
            0,
            Mat4,
            self.batches[i].vtransforms.items,
        );
        vd.count = @intCast(u32, self.batches[i].vtransforms.items.len);
    }
    try self.renderer.draw(ctx, self.render_data);
}
