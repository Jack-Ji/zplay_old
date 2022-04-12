const std = @import("std");
const zp = @import("zplay");
const cp = zp.deps.cp;
const CPWorld = zp.physics.CPWorld;

var world: CPWorld = undefined;

fn init(ctx: *zp.Context) anyerror!void {
    std.log.info("game init", .{});

    var width: u32 = undefined;
    var height: u32 = undefined;
    ctx.graphics.getDrawableSize(&width, &height);

    world = try CPWorld.init(std.testing.allocator, .{
        .gravity = .{ .x = 0, .y = 600 },
    });
    _ = try world.addObject(.{
        .body = .{
            .dynamic = .{
                .position = .{
                    .x = @intToFloat(cp.Float, width) / 2,
                    .y = 10,
                },
            },
        },
        .shapes = &.{
            .{ .circle = .{ .radius = 10, .physics = .{ .weight = .{ .mass = 1 } } } },
        },
    });
    _ = try world.addObject(.{
        .body = .{
            .global_static = 1,
        },
        .shapes = &.{
            .{
                .segment = .{
                    .a = .{ .x = 50, .y = 450 },
                    .b = .{ .x = 500, .y = 350 },
                    .radius = 10,
                },
            },
        },
    });
}

fn loop(ctx: *zp.Context) void {
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

    ctx.graphics.clear(true, false, false, [_]f32{ 0.3, 0.3, 0.3, 1.0 });
    world.update(ctx.delta_tick);
    world.debugDraw(&ctx.graphics, null);

    // draw fps
    _ = ctx.drawText("fps: {d:.2}", .{1 / ctx.delta_tick}, .{
        .color = [3]f32{ 1, 1, 1 },
    });
}

fn quit(ctx: *zp.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
    world.deinit();
}

pub fn main() anyerror!void {
    try zp.run(.{
        .initFn = init,
        .loopFn = loop,
        .quitFn = quit,
        .enable_console = true,
    });
}
