const std = @import("std");
const zp = @import("zplay");
const alg = zp.deps.alg;
const Vec3 = alg.Vec3;
const Mat4 = alg.Mat4;
const gfx = zp.graphics;
const Material = gfx.Material;
const TextureDisplay = gfx.post_processing.TextureDisplay;
const SpriteSheet = gfx.@"2d".SpriteSheet;
const Sprite = gfx.@"2d".Sprite;
const SpriteBatch = gfx.@"2d".SpriteBatch;

var sprite_sheet: *SpriteSheet = undefined;
var tex_display: TextureDisplay = undefined;
var sprite: Sprite = undefined;
var sprite_batch: SpriteBatch = undefined;

fn init(ctx: *zp.Context) anyerror!void {
    _ = ctx;
    std.log.info("game init", .{});

    var width: u32 = undefined;
    var height: u32 = undefined;
    ctx.graphics.getDrawableSize(&width, &height);

    // create sprite sheet
    sprite_sheet = try SpriteSheet.fromPicturesInDir(
        std.testing.allocator,
        "assets/images",
        width,
        height,
        .{},
    );
    //sprite_sheet = try SpriteSheet.fromSheetFiles(
    //    std.testing.allocator,
    //    "sheet",
    //);
    sprite = try sprite_sheet.createSprite("ogre");
    sprite_batch = try SpriteBatch.init(
        std.testing.allocator,
        &ctx.graphics,
        10,
        1000,
    );

    // create renderer
    tex_display = try TextureDisplay.init(std.testing.allocator);
}

fn loop(ctx: *zp.Context) void {
    while (ctx.pollEvent()) |e| {
        switch (e) {
            .keyboard_event => |key| {
                if (key.trigger_type == .up) {
                    switch (key.scan_code) {
                        .escape => ctx.kill(),
                        .f1 => ctx.toggleFullscreeen(null),
                        .f2 => sprite_sheet.saveToFiles("sheet") catch unreachable,
                        else => {},
                    }
                }
            },
            .quit_event => ctx.kill(),
            else => {},
        }
    }

    ctx.graphics.clear(true, true, false, [_]f32{ 0.3, 0.3, 0.3, 1.0 });
    tex_display.draw(&ctx.graphics, .{
        .material = &Material.init(
            .{
                .single_texture = sprite_sheet.tex,
            },
        ),
        .custom = &Mat4.fromScale(Vec3.new(0.5, 0.5, 1)).translate(Vec3.new(0.5, 0.5, 0)),
    }) catch unreachable;

    sprite_batch.begin(.back_to_forth);
    sprite_batch.drawSprite(sprite, .{
        .pos = .{ .x = 100, .y = 400 },
        .scale_w = 2,
        .scale_h = 2,
        .rotate_degree = ctx.tick * 30,
    }) catch unreachable;
    sprite_batch.drawSprite(sprite, .{
        .pos = .{ .x = 100, .y = 400 },
        .anchor_point = .{ .x = 0.5, .y = 0.5 },
        .rotate_degree = ctx.tick * 30,
        .scale_w = 4 + 2 * std.math.cos(ctx.tick),
        .scale_h = 4 + 2 * std.math.sin(ctx.tick),
        .color = [_]f32{ 1, 0, 0, 1 },
        .depth = 0.6,
    }) catch unreachable;
    sprite_batch.end() catch unreachable;

    // draw fps
    _ = ctx.drawText("fps: {d:.2}", .{1 / ctx.delta_tick}, .{
        .color = [3]f32{ 1, 1, 1 },
    });
}

fn quit(ctx: *zp.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
}

pub fn main() anyerror!void {
    try zp.run(.{
        .initFn = init,
        .loopFn = loop,
        .quitFn = quit,
        .enable_console = true,
        .enable_depth_test = false,
    });
}
