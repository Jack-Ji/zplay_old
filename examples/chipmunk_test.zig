const std = @import("std");
const zp = @import("zplay");
const CPWorld = zp.physics.CPWorld;

var world: CPWorld = undefined;

fn init(ctx: *zp.Context) anyerror!void {
    _ = ctx;
    std.log.info("game init", .{});

    world = try CPWorld.init(std.testing.allocator, .{});
    _ = try world.addObject(.{
        .body = .{ .static = null },
        .shapes = &.{
            .{ .circle = .{ .radius = 10 } },
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

    world.update(ctx.delta_tick);
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
    });
}
