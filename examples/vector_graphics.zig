const std = @import("std");
const zp = @import("zplay");
const gl = zp.gl;
const nvg = zp.nvg;

fn init(ctx: *zp.Context) anyerror!void {
    _ = ctx;

    std.log.info("game init", .{});
}

fn loop(ctx: *zp.Context) void {
    while (ctx.pollEvent()) |e| {
        switch (e) {
            .keyboard_event => |key| {
                if (key.trigger_type == .down) {
                    return;
                }
                switch (key.scan_code) {
                    .escape => ctx.kill(),
                    .f1 => ctx.toggleFullscreeen(null),
                    else => {},
                }
            },
            .quit_event => ctx.kill(),
            else => {},
        }
    }

    var width: i32 = undefined;
    var height: i32 = undefined;
    ctx.getSize(&width, &height);

    gl.util.clear(true, true, true, [_]f32{ 0.2, 0.2, 0.2, 1.0 });

    var fwidth = @intToFloat(f32, width);
    var fheight = @intToFloat(f32, height);
    nvg.beginFrame(fwidth, fheight, fwidth / fheight);
    defer nvg.endFrame();
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
        .enable_nanovg = true,
    });
}
