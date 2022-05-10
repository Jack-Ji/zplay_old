const std = @import("std");
const zp = @import("zplay");
const dig = zp.deps.dig;
const nfd = zp.deps.nfd;

var font: *dig.Font = undefined;
var default_path: [64]u8 = undefined;
var single_file: ?nfd.FilePath = null;
var multiple_file: ?nfd.MultipleFilePath = null;

fn init(ctx: *zp.Context) anyerror!void {
    std.log.info("game init", .{});

    // init default path
    _ = try std.fs.cwd().realpathZ("", &default_path);

    try dig.init(ctx);
    font = try dig.loadTTF(
        "assets/msyh.ttf",
        22,
        dig.c.ImFontAtlas_GetGlyphRangesChineseFull(dig.getIO().*.Fonts),
    );
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

    ctx.graphics.clear(true, false, false, null);

    dig.beginFrame();
    defer dig.endFrame();
    dig.pushFont(font);
    defer dig.popFont();

    if (dig.begin("file dialog invoke", null, null)) {
        if (dig.button("default directory", null)) {
            var path = nfd.openDirectoryDialog(
                std.mem.sliceTo(@ptrCast([*c]u8, &default_path), 0),
            ) catch unreachable;
            if (path) |p| {
                defer p.deinit();
                std.mem.set(u8, &default_path, 0);
                std.mem.copy(u8, &default_path, p.path);
            }
        }
        dig.sameLine(.{});
        dig.text(&default_path);

        dig.separator();
        if (dig.button("select single file", null)) {
            single_file = nfd.openFileDialog(
                null,
                std.mem.sliceTo(@ptrCast([*c]u8, &default_path), 0),
            ) catch unreachable;
        }
        if (single_file) |path| {
            dig.indent(20);
            defer dig.unindent(20);
            dig.ztext("{s}", .{path.path});
        }

        dig.separator();
        if (dig.button("select multiple file", null)) {
            multiple_file = nfd.openMultipleFileDialog(
                null,
                std.mem.sliceTo(@ptrCast([*c]u8, &default_path), 0),
            ) catch unreachable;
        }
        if (multiple_file) |pathset| {
            dig.indent(20);
            defer dig.unindent(20);
            var idx: u32 = 0;
            while (idx < pathset.getCount()) : (idx += 1) {
                dig.ztext("{s}", .{pathset.getPath(idx)});
            }
        }
    }
    dig.end();
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
