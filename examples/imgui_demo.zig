const std = @import("std");
const zp = @import("zplay");
const dig = zp.deps.dig;

fn init(ctx: *zp.Context) anyerror!void {
    std.log.info("game init", .{});

    // init imgui
    try dig.init(ctx);
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

    const S = struct {
        var f: f32 = 0.0;
        var counter: i32 = 0;
        var show_demo_window = true;
        var show_another_window = true;
        var show_plot_demo_window = true;
        var show_nodes_demo_window = true;
        var clear_color = [4]f32{ 0.45, 0.55, 0.6, 1.0 };
    };

    ctx.graphics.clear(true, false, false, S.clear_color);
    dig.beginFrame();
    defer dig.endFrame();

    var mouse_state = ctx.getMouseState();
    dig.setNextWindowPos(.{
        .x = @intToFloat(f32, mouse_state.x + 10),
        .y = @intToFloat(f32, mouse_state.y + 10),
    }, .{});
    if (dig.begin("mouse context", null, dig.c.ImGuiWindowFlags_NoTitleBar)) {
        dig.text("You're here!");
    }
    dig.end();

    if (dig.begin("Hello, world!", null, null)) {
        dig.text("This is some useful text");
        dig.textUnformatted("some useful text");
        _ = dig.checkbox("Demo Window", &S.show_demo_window);
        _ = dig.checkbox("Another Window", &S.show_another_window);
        _ = dig.checkbox("Plot Demo Window", &S.show_plot_demo_window);
        _ = dig.checkbox("Nodes Demo Window", &S.show_nodes_demo_window);
        _ = dig.sliderFloat("float", &S.f, 0, 1, .{});
        _ = dig.colorEdit4("clear color", &S.clear_color, null);
        if (dig.button("Button", null))
            S.counter += 1;
        dig.sameLine(.{});
        dig.text("count = %d", S.counter);
    }
    dig.end();

    if (S.show_demo_window) {
        dig.showDemoWindow(&S.show_demo_window);
    }

    if (S.show_another_window) {
        if (dig.begin("Another Window", &S.show_another_window, null)) {
            dig.text("Hello from another window!");
            if (dig.button("Close Me", null))
                S.show_another_window = false;
        }
        dig.end();
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
        }
        dig.end();
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
        .width = 1600,
        .height = 900,
        .enable_resizable = true,
    });
}
