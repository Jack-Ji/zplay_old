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
const Camera = gfx.@"2d".Camera;
const console = gfx.font.console;

var sprite_sheet: *SpriteSheet = undefined;
var tex_display: TextureDisplay = undefined;
var sprite: Sprite = undefined;
var sprite_batch: SpriteBatch = undefined;
var camera: *Camera = undefined;

fn init(ctx: *zp.Context) anyerror!void {
    _ = ctx;
    std.log.info("game init", .{});

    const size = ctx.graphics.getDrawableSize();

    // create sprite sheet
    sprite_sheet = try SpriteSheet.fromPicturesInDir(
        std.testing.allocator,
        "assets/images",
        size.w,
        size.h,
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
    camera = try Camera.fromViewport(
        std.testing.allocator,
        ctx.graphics.viewport,
    );
    sprite_batch.render_data.camera = camera.getCamera();

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
                        .f2 => sprite_sheet.saveToFiles("sheet") catch unreachable,
                        .left => camera.move(-10, 0, .{}),
                        .right => camera.move(10, 0, .{}),
                        .up => camera.move(0, -10, .{}),
                        .down => camera.move(0, 10, .{}),
                        .z => camera.setZoom(std.math.min(2, camera.zoom + 0.1)),
                        .x => camera.setZoom(std.math.max(0.1, camera.zoom - 0.1)),
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
        .pos = .{ .x = 400, .y = 300 },
        .scale_w = 2,
        .scale_h = 2,
        .rotate_degree = @floatCast(f32, ctx.tick) * 30,
    }) catch unreachable;
    sprite_batch.drawSprite(sprite, .{
        .pos = .{ .x = 400, .y = 300 },
        .anchor_point = .{ .x = 0.5, .y = 0.5 },
        .rotate_degree = @floatCast(f32, ctx.tick) * 30,
        .scale_w = 4 + 2 * @cos(@floatCast(f32, ctx.tick)),
        .scale_h = 4 + 2 * @sin(@floatCast(f32, ctx.tick)),
        .color = [_]f32{ 1, 0, 0, 1 },
        .depth = 0.6,
    }) catch unreachable;
    sprite_batch.end() catch unreachable;

    // draw fps
    var draw_opt = console.DrawOption{
        .color = [3]f32{ 1, 1, 1 },
    };
    var rect = ctx.drawText("fps: {d:.1}", .{ctx.fps}, draw_opt);
    draw_opt.ypos = rect.next_line_ypos;
    rect = ctx.drawText(
        "camera pos (up/down/left/right): {d:.0},{d:.0}",
        .{ camera.pos_x, camera.pos_y },
        draw_opt,
    );
    draw_opt.ypos = rect.next_line_ypos;
    rect = ctx.drawText(
        "zoom (z/x): {d:.1}",
        .{camera.zoom},
        draw_opt,
    );
    draw_opt.ypos = rect.next_line_ypos;
    rect = ctx.drawText(
        "frustrum: left({d:.0}) right({d:.0}) bottom({d:.0}) top({d:.0})",
        .{
            camera.internal_camera.frustrum.orthographic.left,
            camera.internal_camera.frustrum.orthographic.right,
            camera.internal_camera.frustrum.orthographic.bottom,
            camera.internal_camera.frustrum.orthographic.top,
        },
        draw_opt,
    );
}

fn quit(ctx: *zp.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
    camera.deinit();
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
