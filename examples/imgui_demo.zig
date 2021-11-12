const std = @import("std");
const zp = @import("zplay");
const dig = zp.dig;
const gl = zp.gl;

fn init(ctx: *zp.Context) anyerror!void {
    _ = ctx;

    std.log.info("game init", .{});
}

fn loop(ctx: *zp.Context) void {
    while (ctx.pollEvent()) |e| {
        _ = dig.processEvent(e);

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

    const S = struct {
        var f: f32 = 0.0;
        var counter: i32 = 0;
        var show_demo_window = true;
        var show_another_window = true;
        var clear_color = [4]f32{ 0.45, 0.55, 0.6, 1.0 };
    };

    gl.util.clear(true, false, false, S.clear_color);

    {
        dig.beginFrame();
        defer dig.endFrame();

        if (S.show_demo_window) dig.igShowDemoWindow(&S.show_demo_window);
        if (dig.igBegin("Hello, world!", null, 0)) {
            dig.igText("This is some useful text");
            _ = dig.igCheckbox("Demo Window", &S.show_demo_window);
            _ = dig.igCheckbox("Another Window", &S.show_another_window);
            _ = dig.igSliderFloat("float", &S.f, 0, 1, null, 0);
            _ = dig.igColorEdit3("clear color", &S.clear_color, 0);
            if (dig.igButton("Button", .{ .x = 0, .y = 0 }))
                S.counter += 1;
            dig.igSameLine(0, 0);
            dig.igText("count = %d", S.counter);

            const io = @ptrCast(*dig.ImGuiIO, dig.igGetIO());
            dig.custom.text(
                "Application average {d:.3} ms/frame ({d:.1} FPS)",
                .{ 1000 / io.Framerate, io.Framerate },
            );
            dig.igEnd();
        }

        if (S.show_another_window) {
            if (dig.igBegin("Another Window", &S.show_another_window, 0)) {
                dig.igText("Hello from another window!");
                if (dig.igButton("Close Me", .{ .x = 0, .y = 0 }))
                    S.show_another_window = false;
                dig.igEnd();
            }
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
        .enable_resizable = true,
        .enable_dear_imgui = true,
    });
}
