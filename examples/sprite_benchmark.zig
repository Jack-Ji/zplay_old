const std = @import("std");
const zp = @import("zplay");
const alg = zp.deps.alg;
const Vec2 = alg.Vec2;
const gfx = zp.graphics;
const SpriteSheet = gfx.@"2d".SpriteSheet;
const Sprite = gfx.@"2d".Sprite;
const SpriteBatch = gfx.@"2d".SpriteBatch;

const Actor = struct {
    sprite: Sprite,
    velocity: Sprite.Point,
};

var sprite_sheet: *SpriteSheet = undefined;
var characters: std.ArrayList(Actor) = undefined;
var sprite_batch: SpriteBatch = undefined;
var all_names: std.ArrayList([]const u8) = undefined;
var rand_gen: std.rand.DefaultPrng = undefined;
var delta_tick: f32 = 0;

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
        .{ .accept_jpg = false },
    );
    characters = try std.ArrayList(Actor).initCapacity(
        std.testing.allocator,
        1000000,
    );
    sprite_batch = try SpriteBatch.init(
        std.testing.allocator,
        10,
        1000000,
    );
    all_names = try std.ArrayList([]const u8).initCapacity(
        std.testing.allocator,
        10000,
    );
    var it = sprite_sheet.search_tree.iterator();
    while (it.next()) |k| {
        try all_names.append(k.key_ptr.*);
    }
    rand_gen = std.rand.DefaultPrng.init(@intCast(u64, std.time.timestamp()));
}

fn loop(ctx: *zp.Context) void {
    delta_tick = (delta_tick + ctx.delta_tick) / 2;

    while (ctx.pollEvent()) |e| {
        switch (e) {
            .keyboard_event => |key| {
                if (key.trigger_type == .up) {
                    switch (key.scan_code) {
                        .escape => ctx.kill(),
                        else => {},
                    }
                }
            },
            .mouse_event => |me| {
                switch (me.data) {
                    .button => |click| {
                        if (click.btn != .left) {
                            continue;
                        }
                        var rd = rand_gen.random();
                        if (click.clicked) {
                            const pos = Sprite.Point{
                                .x = @intToFloat(f32, click.x),
                                .y = @intToFloat(f32, click.y),
                            };
                            var i: u32 = 0;
                            while (i < 1000) : (i += 1) {
                                const index = rd.uintLessThan(usize, all_names.items.len);
                                const angle = rd.float(f32) * 2 * std.math.pi;
                                const name = all_names.items[index];
                                characters.append(.{
                                    .sprite = sprite_sheet.createSprite(
                                        name,
                                        pos,
                                    ) catch unreachable,
                                    .velocity = .{
                                        .x = 5 * std.math.cos(angle),
                                        .y = 5 * std.math.sin(angle),
                                    },
                                }) catch unreachable;
                            }
                        }
                    },
                    else => {},
                }
            },
            .quit_event => ctx.kill(),
            else => {},
        }
    }

    var width: u32 = undefined;
    var height: u32 = undefined;
    ctx.graphics.getDrawableSize(&width, &height);
    for (characters.items) |*c| {
        const curpos = c.sprite.pos;
        if (curpos.x < 0 or curpos.x + c.sprite.width > @intToFloat(f32, width))
            c.velocity.x = -c.velocity.x;
        if (curpos.y < 0 or curpos.y + c.sprite.height > @intToFloat(f32, height))
            c.velocity.y = -c.velocity.y;
        c.sprite.moveBy(.{
            .x = c.velocity.x,
            .y = c.velocity.y,
        });
    }

    ctx.graphics.clear(true, true, false, [_]f32{ 0.3, 0.3, 0.3, 1.0 });
    sprite_batch.clear();
    for (characters.items) |c| {
        sprite_batch.drawSprite(c.sprite) catch unreachable;
    }
    sprite_batch.submitAndRender(&ctx.graphics) catch unreachable;

    // draw fps
    var opt = gfx.font.console.DrawOption{
        .color = [3]f32{ 1, 1, 1 },
    };
    const metric = ctx.drawText("fps: {d:.2}", .{1 / delta_tick}, opt);
    opt.ypos = metric.next_line_ypos;
    _ = ctx.drawText("sprites number: {d}", .{characters.items.len}, opt);
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
        .width = 1600,
        .height = 900,
        .enable_console = true,
    });
}
