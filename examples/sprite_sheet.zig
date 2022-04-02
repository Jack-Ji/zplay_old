const std = @import("std");
const zp = @import("zplay");
const alg = zp.deps.alg;
const Vec3 = alg.Vec3;
const Mat4 = alg.Mat4;
const gfx = zp.graphics;
const Texture = gfx.gpu.Texture;
const VertexArray = gfx.gpu.VertexArray;
const Renderer = gfx.Renderer;
const Camera = gfx.Camera;
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
    );
    sprite = try sprite_sheet.createSprite(
        "ogre",
        .{ .x = 50, .y = 500 },
    );
    sprite_batch = try SpriteBatch.init(
        std.testing.allocator,
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
    }) catch unreachable;

    sprite_batch.clear();
    sprite_batch.drawSprite(sprite) catch unreachable;
    sprite_batch.submitAndRender(&ctx.graphics) catch unreachable;

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
    });
}
