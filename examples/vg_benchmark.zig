const std = @import("std");
const math = std.math;
const zp = @import("zplay");
const alg = zp.deps.alg;
const Vec2 = alg.Vec2;
const dig = zp.deps.dig;
const nvg = zp.deps.nvg;
const nsvg = zp.deps.nsvg;

var rng: std.rand.DefaultPrng = undefined;
var rg: std.rand.Random = undefined;
var tiger: nsvg.SVG = undefined;

fn init(ctx: *zp.Context) anyerror!void {
    std.log.info("game init", .{});

    // random generator allocation
    rng = std.rand.DefaultPrng.init(@intCast(u64, std.time.timestamp()));
    rg = rng.random();

    // init imgui
    try dig.init(ctx);

    // init nanovg context
    try nvg.init(nvg.c.NVG_ANTIALIAS | nvg.c.NVG_STENCIL_STROKES);

    tiger = nsvg.loadFile("assets/23.svg", null, null) orelse unreachable;
}

fn loop(ctx: *zp.Context) void {
    while (ctx.pollEvent()) |e| {
        _ = dig.processEvent(e);
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

    var wsize = ctx.getWindowSize();
    ctx.graphics.clear(true, true, true, [_]f32{ 0.3, 0.3, 0.32, 1.0 });

    const S = struct {
        var positions = std.ArrayList(Vec2).init(std.testing.allocator);
    };

    dig.beginFrame();
    {
        dig.setNextWindowPos(
            .{ .x = @intToFloat(f32, ctx.graphics.viewport.w) - 30, .y = 50 },
            .{
                .cond = dig.c.ImGuiCond_Always,
                .pivot = .{ .x = 1, .y = 0 },
            },
        );
        if (dig.begin(
            "control",
            null,
            dig.c.ImGuiWindowFlags_NoMove |
                dig.c.ImGuiWindowFlags_NoResize |
                dig.c.ImGuiWindowFlags_AlwaysAutoResize,
        )) {
            var buf: [32]u8 = undefined;
            dig.text(std.fmt.bufPrintZ(&buf, "FPS: {d:.02}", .{dig.getIO().*.Framerate}) catch unreachable);
            dig.text(std.fmt.bufPrintZ(&buf, "ms/frame: {d:.02}", .{ctx.delta_tick * 1000}) catch unreachable);
            dig.text(std.fmt.bufPrintZ(&buf, "drawcall count: {d}", .{nvg.getDrawCallCount()}) catch unreachable);
            dig.text(std.fmt.bufPrintZ(&buf, "tigers: {d}", .{S.positions.items.len}) catch unreachable);
            dig.text(std.fmt.bufPrintZ(&buf, "shapes: {d}", .{S.positions.items.len * tiger.nshape}) catch unreachable);
            dig.text(std.fmt.bufPrintZ(&buf, "strokes: {d}", .{S.positions.items.len * tiger.nstroke}) catch unreachable);
            dig.text(std.fmt.bufPrintZ(&buf, "fills: {d}", .{S.positions.items.len * tiger.nfill}) catch unreachable);
            dig.text(std.fmt.bufPrintZ(&buf, "paths: {d}", .{S.positions.items.len * tiger.npath}) catch unreachable);
            dig.separator();

            // add tigers
            var count: u32 = 0;
            if (dig.button("add 1 tiger", null)) count = 1;
            if (dig.button("add 10 tiger", null)) count = 10;
            if (dig.button("clear", null)) S.positions.shrinkRetainingCapacity(0);
            while (count > 0) : (count -= 1) {
                S.positions.append(Vec2.new(
                    rg.float(f32) * @intToFloat(f32, wsize.w - 200),
                    rg.float(f32) * @intToFloat(f32, wsize.h),
                )) catch unreachable;
            }
        }
        dig.end();
    }
    dig.endFrame();

    nvg.beginFrame(
        @intToFloat(f32, wsize.w),
        @intToFloat(f32, wsize.h),
        ctx.getPixelRatio(),
    );
    {
        // draw tigers
        for (S.positions.items) |pos| {
            nvg.save();
            nvg.translate(pos.x(), pos.y());
            nvg.scale(0.3, 0.3);
            nvg.rotate(nvg.degToRad(@floatCast(f32, ctx.tick) * 30));
            nvg.translate(-tiger.image.width / 2, -tiger.image.height / 2);
            nvg.svg(tiger);
            nvg.restore();
        }
    }
    nvg.endFrame();

    // draw fps
    _ = ctx.drawText("fps: {d:.1}", .{ctx.fps}, .{
        .color = .{ 1, 1, 1 },
    });
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
        .width = 1000,
        .height = 600,
        .enable_vsync = false,
        .enable_console = true,
    });
}
