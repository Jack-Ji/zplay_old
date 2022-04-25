const std = @import("std");
const zp = @import("zplay");
const audio = zp.audio;

var sound: *audio.Sound = undefined;

fn init(ctx: *zp.Context) anyerror!void {
    _ = ctx;
    std.log.info("game init", .{});

    sound = try ctx.audio.createSoundFromFile(
        "assets/song18.mp3",
        null,
        .{},
    );
    sound.setLooping(true);
    sound.start();
}

fn loop(ctx: *zp.Context) void {
    const S = struct {
        var runtime: f32 = 0;
        var cur_ms: u64 = 0;
        var total_ms: u64 = 0;
        var pan: f32 = -1;
        var pan_delta: f32 = 0.2;
    };
    if (S.total_ms == 0) {
        S.total_ms = sound.getLengthInMilliseconds();
    }

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

    S.runtime += ctx.delta_tick;
    if (S.runtime > 1) {
        S.runtime -= 1;
        S.cur_ms = sound.getCursorInMilliseconds();
        S.pan += S.pan_delta;
        if (S.pan_delta > 0 and S.pan > 1) {
            S.pan = 1;
            S.pan_delta = -S.pan_delta;
        }
        if (S.pan_delta < 0 and S.pan < -1) {
            S.pan = -1;
            S.pan_delta = -S.pan_delta;
        }
        sound.setPan(S.pan);
    }
    _ = ctx.drawText("progress: {d}/{d}", .{ S.cur_ms / 1000, S.total_ms / 1000 }, .{
        .color = [3]f32{ 1, 1, 1 },
        .ypos = 18,
    });
}

fn quit(ctx: *zp.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
    sound.destroy();
}

pub fn main() anyerror!void {
    try zp.run(.{
        .initFn = init,
        .loopFn = loop,
        .quitFn = quit,
        .enable_console = true,
    });
}
