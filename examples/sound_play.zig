const std = @import("std");
const zp = @import("zplay");
const audio = zp.audio;

fn init(ctx: *zp.Context) anyerror!void {
    _ = ctx;
    std.log.info("game init", .{});

    _ = try ctx.audio.playSoundWithFile(
        "assets/song18.mp3",
        null,
    );
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
