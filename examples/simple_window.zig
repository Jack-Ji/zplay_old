const std = @import("std");
const zp = @import("zplay");

fn init(ctx: *zp.Context) anyerror!void {
    _ = ctx;

    std.log.info("game init", .{});
}

fn event(ctx: *zp.Context, e: zp.Event) void {
    _ = ctx;

    switch (e) {
        .keyboard_event => |key| {
            if (key.trigger_type == .down) {
                return;
            }
            switch (key.scan_code) {
                .escape => ctx.kill(),
                .f1 => ctx.toggleFullscreeen(),
                else => {},
            }
        },
        .quit_event => ctx.kill(),
        else => {},
    }
}

fn loop(ctx: *zp.Context) void {
    _ = ctx;
}

fn quit(ctx: *zp.Context) void {
    _ = ctx;

    std.log.info("game quit", .{});
}

pub fn main() anyerror!void {
    try zp.run(.{
        .init_fn = init,
        .event_fn = event,
        .loop_fn = loop,
        .quit_fn = quit,
    });
}
