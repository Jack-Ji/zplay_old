const std = @import("std");
const zp = @import("zplay");
const cp = zp.deps.cp;
const CPWorld = zp.physics.CPWorld;

var rng: std.rand.Xoshiro256 = std.rand.DefaultPrng.init(333);
var world: CPWorld = undefined;

fn init(ctx: *zp.Context) anyerror!void {
    std.log.info("game init", .{});

    const size = ctx.graphics.getDrawableSize();

    world = try CPWorld.init(std.testing.allocator, .{
        .gravity = .{ .x = 0, .y = 600 },
    });

    const dynamic_body: CPWorld.ObjectOption.BodyProperty = .{
        .dynamic = .{
            .position = .{
                .x = @intToFloat(f32, size.w) / 2,
                .y = 10,
            },
        },
    };
    const physics: CPWorld.ObjectOption.ShapeProperty.Physics = .{
        .weight = .{ .mass = 1 },
        .elasticity = 0.5,
    };
    var i: u32 = 0;
    while (i < 100) : (i += 1) {
        const t = rng.random().intRangeAtMost(u32, 0, 30);
        if (t < 10) {
            _ = try world.addObject(.{
                .body = dynamic_body,
                .shapes = &.{
                    .{
                        .circle = .{
                            .radius = 15,
                            .physics = physics,
                        },
                    },
                },
            });
        } else if (t < 20) {
            _ = try world.addObject(.{
                .body = dynamic_body,
                .shapes = &.{
                    .{
                        .box = .{
                            .width = 30,
                            .height = 30,
                            .physics = physics,
                        },
                    },
                },
            });
        } else {
            _ = try world.addObject(.{
                .body = dynamic_body,
                .shapes = &.{
                    .{
                        .polygon = .{
                            .verts = &[_]cp.Vect{
                                .{ .x = 0, .y = 0 },
                                .{ .x = 30, .y = 0 },
                                .{ .x = 35, .y = 25 },
                                .{ .x = 30, .y = 50 },
                            },
                            .physics = physics,
                        },
                    },
                },
            });
        }
    }
    _ = try world.addObject(.{
        .body = .{
            .global_static = 1,
        },
        .shapes = &[_]CPWorld.ObjectOption.ShapeProperty{
            .{
                .segment = .{
                    .a = .{ .x = 50, .y = 200 },
                    .b = .{ .x = 400, .y = 250 },
                    .radius = 10,
                    .physics = .{
                        .elasticity = 1.0,
                    },
                },
            },
            .{
                .segment = .{
                    .a = .{ .x = 250, .y = 450 },
                    .b = .{ .x = 700, .y = 350 },
                    .radius = 10,
                    .physics = .{
                        .elasticity = 1.0,
                    },
                },
            },
            .{
                .segment = .{
                    .a = .{ .x = 0, .y = 0 },
                    .b = .{ .x = 0, .y = @intToFloat(f32, size.h) },
                    .physics = .{
                        .elasticity = 1.0,
                    },
                },
            },
            .{
                .segment = .{
                    .a = .{ .x = 0, .y = @intToFloat(f32, size.h) },
                    .b = .{ .x = @intToFloat(f32, size.w), .y = @intToFloat(f32, size.h) },
                    .physics = .{
                        .elasticity = 1.0,
                    },
                },
            },
            .{
                .segment = .{
                    .a = .{ .x = @intToFloat(f32, size.w), .y = 0 },
                    .b = .{ .x = @intToFloat(f32, size.w), .y = @intToFloat(f32, size.h) },
                    .physics = .{
                        .elasticity = 1.0,
                    },
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
    _ = ctx.drawText("fps: {d:.1}", .{ctx.fps}, .{
        .color = .{ 1, 1, 1 },
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
