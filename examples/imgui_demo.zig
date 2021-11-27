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
        var show_plot_demo_window = true;
        var show_nodes_demo_window = true;
        var clear_color = [4]f32{ 0.45, 0.55, 0.6, 1.0 };
    };

    gl.util.clear(true, false, false, S.clear_color);

    {
        dig.beginFrame();
        defer dig.endFrame();

        if (dig.begin("Hello, world!", null, 0)) {
            dig.text("This is some useful text");
            _ = dig.checkbox("Demo Window", &S.show_demo_window);
            _ = dig.checkbox("Another Window", &S.show_another_window);
            _ = dig.checkbox("Plot Demo Window", &S.show_plot_demo_window);
            _ = dig.checkbox("Nodes Demo Window", &S.show_nodes_demo_window);
            _ = dig.sliderFloat("float", &S.f, 0, 1, null, 0);
            _ = dig.colorEdit3("clear color", &S.clear_color, 0);
            if (dig.button("Button", .{ .x = 0, .y = 0 }))
                S.counter += 1;
            dig.sameLine(0, 0);
            dig.text("count = %d", S.counter);

            const io = @ptrCast(*dig.ImGuiIO, dig.getIO());
            dig.custom.text(
                "Application average {d:.3} ms/frame ({d:.1} FPS)",
                .{ 1000 / io.Framerate, io.Framerate },
            );
            dig.end();
        }

        if (S.show_demo_window) {
            dig.showDemoWindow(&S.show_demo_window);
        }

        if (S.show_another_window) {
            if (dig.begin("Another Window", &S.show_another_window, 0)) {
                dig.text("Hello from another window!");
                if (dig.button("Close Me", .{ .x = 0, .y = 0 }))
                    S.show_another_window = false;
                dig.end();
            }
        }

        if (S.show_plot_demo_window) {
            dig.ext.plot.showDemoWindow(&S.show_plot_demo_window);
        }

        if (S.show_nodes_demo_window) {
            if (dig.begin("Nodes Demo Window", &S.show_nodes_demo_window, 0)) {
                dig.ext.nodes.beginNodeEditor();
                dig.ext.nodes.beginNode(-1);
                dig.dummy(.{ .x = 80, .y = 45 });
                dig.ext.nodes.endNode();
                dig.ext.nodes.endNodeEditor();
                dig.end();
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
        .enable_maximized = true,
        .enable_dear_imgui = true,
    });
}
