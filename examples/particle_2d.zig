const std = @import("std");
const zp = @import("zplay");
const alg = zp.deps.alg;
const Vec2 = alg.Vec2;
const Vec4 = alg.Vec4;
const gfx = zp.graphics;
const SpriteSheet = gfx.@"2d".SpriteSheet;
const SpriteBatch = gfx.@"2d".SpriteBatch;
const ParticleSystem = gfx.@"2d".ParticleSystem;

var rd: std.rand.DefaultPrng = undefined;
var sheet: *SpriteSheet = undefined;
var sb: *SpriteBatch = undefined;
var ps: *ParticleSystem = undefined;

// fire effect
const emitter1 = ParticleSystem.Effect.FireEmitter(
    50,
    3,
    Vec4.new(1, 0, 0, 1),
    Vec4.new(1, 1, 0.01, 1),
    2.75,
);
const emitter2 = ParticleSystem.Effect.FireEmitter(
    50,
    3,
    Vec4.new(1, 0, 0, 1),
    Vec4.new(0, 1, 0, 1),
    2.75,
);

fn init(ctx: *zp.Context) anyerror!void {
    _ = ctx;
    std.log.info("game init", .{});

    rd = std.rand.DefaultPrng.init(@intCast(u64, std.time.timestamp()));
    sheet = try SpriteSheet.init(
        std.testing.allocator,
        &[_]SpriteSheet.ImageSource{
            .{
                .name = "particle",
                .image = .{
                    .file_path = "assets/images/white-circle.png",
                },
            },
        },
        4096,
        4096,
    );
    sb = try SpriteBatch.init(
        std.testing.allocator,
        &ctx.graphics,
        1,
        10000,
    );
    ps = try ParticleSystem.init(std.testing.allocator);
    emitter1.sprite = try sheet.createSprite("particle");
    emitter2.sprite = try sheet.createSprite("particle");
    try ps.addEffect(
        rd.random(),
        8000,
        emitter1.emit,
        Vec2.new(400, 500),
        60,
        40,
        0.016,
    );
    try ps.addEffect(
        rd.random(),
        2000,
        emitter2.emit,
        Vec2.new(200, 500),
        60,
        10,
        0.016,
    );
}

fn loop(ctx: *zp.Context) void {
    if (ctx.isKeyPressed(.up)) ps.effects.items[0].origin = ps.effects.items[0].origin.add(Vec2.new(0, -10));
    if (ctx.isKeyPressed(.down)) ps.effects.items[0].origin = ps.effects.items[0].origin.add(Vec2.new(0, 10));
    if (ctx.isKeyPressed(.left)) ps.effects.items[0].origin = ps.effects.items[0].origin.add(Vec2.new(-10, 0));
    if (ctx.isKeyPressed(.right)) ps.effects.items[0].origin = ps.effects.items[0].origin.add(Vec2.new(10, 0));

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
            .quit_event => ctx.kill(),
            else => {},
        }
    }

    ctx.graphics.clear(true, false, false, null);
    ps.update(ctx.delta_tick);
    sb.begin(.{ .blend = .additive });
    ps.draw(sb) catch unreachable;
    sb.end() catch unreachable;

    _ = ctx.drawText("fps: {d:.1}", .{ctx.fps}, .{
        .color = [3]f32{ 1, 1, 1 },
    });
}

fn quit(ctx: *zp.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
    sheet.deinit();
    sb.deinit();
    ps.deinit();
}

pub fn main() anyerror!void {
    try zp.run(.{
        .initFn = init,
        .loopFn = loop,
        .quitFn = quit,
        .enable_console = true,
    });
}
