const std = @import("std");
const zp = @import("zplay");
const gl = zp.gl;
const nvg = zp.nvg;

var vctx: nvg.Context = undefined;

fn init(ctx: *zp.Context) anyerror!void {
    _ = ctx;

    // init vector graphics context
    vctx = nvg.Context.init(.{});

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

    gl.util.clear(true, true, true, [_]f32{ 0.3, 0.3, 0.2, 1.0 });

    var fwidth = @intToFloat(f32, width);
    var fheight = @intToFloat(f32, height);
    vctx.beginFrame(fwidth, fheight, fwidth / fheight);
    vctx.beginPath();
    vctx.rect(100, 100, 120, 30);
    vctx.fillColor(nvg.api.nvgRGB(255, 192, 0));
    vctx.fill();
    vctx.endFrame();
}

fn quit(ctx: *zp.Context) void {
    _ = ctx;

    vctx.deinit();

    std.log.info("game quit", .{});
}

pub fn main() anyerror!void {
    try zp.run(.{
        .initFn = init,
        .loopFn = loop,
        .quitFn = quit,
    });
}
