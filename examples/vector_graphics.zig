const std = @import("std");
const math = std.math;
const zp = @import("zplay");
const gl = zp.gl;
const nvg = zp.nvg;

var font_normal: i32 = undefined;
var font_bold: i32 = undefined;
var font_icons: i32 = undefined;
var font_emoji: i32 = undefined;
var images: [12]nvg.Image = undefined;

fn init(ctx: *zp.Context) anyerror!void {
    _ = ctx;

    var i: usize = 0;
    var buf: [128]u8 = undefined;
    while (i < 12) : (i += 1) {
        var path = try std.fmt.bufPrintZ(&buf, "assets/images/image{d}.jpg", .{i + 1});
        images[i] = nvg.createImage(path, .{});
        if (images[i].handle == 0) {
            std.debug.panic("load image({s}) failed!", .{buf});
        }
    }

    font_icons = nvg.createFont("icons", "assets/entypo.ttf");
    if (font_icons == -1) {
        std.debug.panic("load font failed!", .{});
    }

    font_normal = nvg.createFont("sans", "assets/Roboto-Regular.ttf");
    if (font_normal == -1) {
        std.debug.panic("load font failed!", .{});
    }

    font_bold = nvg.createFont("sans", "assets/Roboto-Bold.ttf");
    if (font_bold == -1) {
        std.debug.panic("load font failed!", .{});
    }

    font_emoji = nvg.createFont("emoji", "assets/NotoEmoji-Regular.ttf");
    if (font_emoji == -1) {
        std.debug.panic("load font failed!", .{});
    }

    _ = nvg.addFallbackFontId(font_normal, font_emoji);
    _ = nvg.addFallbackFontId(font_bold, font_emoji);

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
    var fwidth: i32 = undefined;
    var fheight: i32 = undefined;
    ctx.getWindowSize(&width, &height);
    ctx.getFramebufferSize(&fwidth, &fheight);
    var mouse_state = ctx.getMouseState();
    var xpos = @intToFloat(f32, mouse_state.x);
    var ypos = @intToFloat(f32, mouse_state.y);

    gl.util.clear(true, true, true, [_]f32{ 0.3, 0.3, 0.32, 1.0 });

    nvg.beginFrame(
        @intToFloat(f32, width),
        @intToFloat(f32, height),
        @intToFloat(f32, fwidth) / @intToFloat(f32, width),
    );
    defer nvg.endFrame();

    drawEyes(@intToFloat(f32, fwidth) - 250, 50, 150, 100, xpos, ypos, ctx.tick);
    drawGraph(0, @intToFloat(f32, fheight) / 2, @intToFloat(f32, fwidth), @intToFloat(f32, fheight) / 2, ctx.tick);
    drawColorwheel(@intToFloat(f32, fwidth) - 300, @intToFloat(f32, fheight) - 300, 250, 250, ctx.tick);
    drawLines(120, @intToFloat(f32, fheight) - 50, 600, 50, ctx.tick);
    drawWidths(10, 50, 30);
    drawCaps(10, 300, 30);
    drawScissor(50, @intToFloat(f32, fheight) - 80, ctx.tick);

    // Form
    var x: f32 = 60;
    var y: f32 = 95;
    drawLabel("Login", x, y, 280, 20);
    y += 25;
    drawLabel("Diameter", x, y, 280, 20);
}

fn drawEyes(x: f32, y: f32, w: f32, h: f32, mx: f32, my: f32, t: f32) void {
    var gloss: nvg.Paint = undefined;
    var bg: nvg.Paint = undefined;
    var dx: f32 = undefined;
    var dy: f32 = undefined;
    var d: f32 = undefined;
    const ex = w * 0.23;
    const ey = h * 0.5;
    const lx = x + ex;
    const ly = y + ey;
    const rx = x + w - ex;
    const ry = y + ey;
    const br = if (ex < ey) ex * 0.5 else ey * 0.5;
    const blink = 1 - math.pow(f32, math.sin(t * 0.5), 200) * 0.8;

    bg = nvg.linearGradient(x, y + h * 0.5, x + w * 0.1, y + h, nvg.rgba(0, 0, 0, 32), nvg.rgba(0, 0, 0, 16));
    nvg.beginPath();
    nvg.ellipse(lx + 3.0, ly + 16.0, ex, ey);
    nvg.ellipse(rx + 3.0, ry + 16.0, ex, ey);
    nvg.fillPaint(bg);
    nvg.fill();

    bg = nvg.linearGradient(x, y + h * 0.25, x + w * 0.1, y + h, nvg.rgba(220, 220, 220, 255), nvg.rgba(128, 128, 128, 255));
    nvg.beginPath();
    nvg.ellipse(lx, ly, ex, ey);
    nvg.ellipse(rx, ry, ex, ey);
    nvg.fillPaint(bg);
    nvg.fill();

    dx = (mx - rx) / (ex * 10);
    dy = (my - ry) / (ey * 10);
    d = math.sqrt(dx * dx + dy * dy);
    if (d > 1.0) {
        dx /= d;
        dy /= d;
    }
    dx *= ex * 0.4;
    dy *= ey * 0.5;
    nvg.beginPath();
    nvg.ellipse(lx + dx, ly + dy + ey * 0.25 * (1 - blink), br, br * blink);
    nvg.fillColor(nvg.rgba(32, 32, 32, 255));
    nvg.fill();

    dx = (mx - rx) / (ex * 10);
    dy = (my - ry) / (ey * 10);
    d = math.sqrt(dx * dx + dy * dy);
    if (d > 1.0) {
        dx /= d;
        dy /= d;
    }
    dx *= ex * 0.4;
    dy *= ey * 0.5;
    nvg.beginPath();
    nvg.ellipse(rx + dx, ry + dy + ey * 0.25 * (1 - blink), br, br * blink);
    nvg.fillColor(nvg.rgba(32, 32, 32, 255));
    nvg.fill();

    gloss = nvg.radialGradient(lx - ex * 0.25, ly - ey * 0.5, ex * 0.1, ex * 0.75, nvg.rgba(255, 255, 255, 128), nvg.rgba(255, 255, 255, 0));
    nvg.beginPath();
    nvg.ellipse(lx, ly, ex, ey);
    nvg.fillPaint(gloss);
    nvg.fill();

    gloss = nvg.radialGradient(rx - ex * 0.25, ry - ey * 0.5, ex * 0.1, ex * 0.75, nvg.rgba(255, 255, 255, 128), nvg.rgba(255, 255, 255, 0));
    nvg.beginPath();
    nvg.ellipse(rx, ry, ex, ey);
    nvg.fillPaint(gloss);
    nvg.fill();
}

fn drawGraph(x: f32, y: f32, w: f32, h: f32, t: f32) void {
    var bg: nvg.Paint = undefined;
    var samples: [6]f32 = undefined;
    var sx: [6]f32 = undefined;
    var sy: [6]f32 = undefined;
    var dx = w / 5.0;
    var i: usize = undefined;

    samples[0] = (1 + math.sin(t * 1.2345 + math.cos(t * 0.33457) * 0.44)) * 0.5;
    samples[1] = (1 + math.sin(t * 0.68363 + math.cos(t * 1.3) * 1.55)) * 0.5;
    samples[2] = (1 + math.sin(t * 1.1642 + math.cos(t * 0.33457) * 1.24)) * 0.5;
    samples[3] = (1 + math.sin(t * 0.56345 + math.cos(t * 1.63) * 0.14)) * 0.5;
    samples[4] = (1 + math.sin(t * 1.6245 + math.cos(t * 0.254) * 0.3)) * 0.5;
    samples[5] = (1 + math.sin(t * 0.345 + math.cos(t * 0.03) * 0.6)) * 0.5;

    i = 0;
    while (i < 6) : (i += 1) {
        sx[i] = x + @intToFloat(f32, i) * dx;
        sy[i] = y + h * samples[i] * 0.8;
    }

    // Graph background
    bg = nvg.linearGradient(x, y, x, y + h, nvg.rgba(0, 160, 192, 0), nvg.rgba(0, 160, 192, 64));
    nvg.beginPath();
    nvg.moveTo(sx[0], sy[0]);
    i = 1;
    while (i < 6) : (i += 1) {
        nvg.bezierTo(sx[i - 1] + dx * 0.5, sy[i - 1], sx[i] - dx * 0.5, sy[i], sx[i], sy[i]);
    }
    nvg.lineTo(x + w, y + h);
    nvg.lineTo(x, y + h);
    nvg.fillPaint(bg);
    nvg.fill();

    // Graph line
    nvg.beginPath();
    nvg.moveTo(sx[0], sy[0] + 2);
    i = 1;
    while (i < 6) : (i += 1) {
        nvg.bezierTo(sx[i - 1] + dx * 0.5, sy[i - 1] + 2, sx[i] - dx * 0.5, sy[i] + 2, sx[i], sy[i] + 2);
    }
    nvg.strokeColor(nvg.rgba(0, 0, 0, 32));
    nvg.strokeWidth(3.0);
    nvg.stroke();

    nvg.beginPath();
    nvg.moveTo(sx[0], sy[0]);
    i = 1;
    while (i < 6) : (i += 1) {
        nvg.bezierTo(sx[i - 1] + dx * 0.5, sy[i - 1], sx[i] - dx * 0.5, sy[i], sx[i], sy[i]);
    }
    nvg.strokeColor(nvg.rgba(0, 160, 192, 255));
    nvg.strokeWidth(3.0);
    nvg.stroke();

    // Graph sample pos
    i = 0;
    while (i < 6) : (i += 1) {
        bg = nvg.radialGradient(sx[i], sy[i] + 2, 3.0, 8.0, nvg.rgba(0, 0, 0, 32), nvg.rgba(0, 0, 0, 0));
        nvg.beginPath();
        nvg.rect(sx[i] - 10, sy[i] - 10 + 2, 20, 20);
        nvg.fillPaint(bg);
        nvg.fill();
    }

    nvg.beginPath();
    i = 0;
    while (i < 6) : (i += 1) {
        nvg.circle(sx[i], sy[i], 4.0);
    }
    nvg.fillColor(nvg.rgba(0, 160, 192, 255));
    nvg.fill();
    nvg.beginPath();
    i = 0;
    while (i < 6) : (i += 1) {
        nvg.circle(sx[i], sy[i], 2.0);
    }
    nvg.fillColor(nvg.rgba(220, 220, 220, 255));
    nvg.fill();

    nvg.strokeWidth(1.0);
}

fn drawColorwheel(x: f32, y: f32, w: f32, h: f32, t: f32) void {
    var i: i32 = undefined;
    var r0: f32 = undefined;
    var r1: f32 = undefined;
    var ax: f32 = undefined;
    var ay: f32 = undefined;
    var bx: f32 = undefined;
    var by: f32 = undefined;
    var cx: f32 = undefined;
    var cy: f32 = undefined;
    var aeps: f32 = undefined;
    var r: f32 = undefined;
    var hue: f32 = math.sin(t * 0.12);
    var paint: nvg.Paint = undefined;

    nvg.save();

    cx = x + w * 0.5;
    cy = y + h * 0.5;
    r1 = (if (w < h) w * 0.5 else h * 0.5) - 5.0;
    r0 = r1 - 20.0;
    aeps = 0.5 / r1; // half a pixel arc length in radians (2pi cancels out).

    i = 0;
    while (i < 6) : (i += 1) {
        var a0: f32 = @intToFloat(f32, i) / 6.0 * math.pi * 2.0 - aeps;
        var a1: f32 = (@intToFloat(f32, i) + 1.0) / 6.0 * math.pi * 2.0 + aeps;
        nvg.beginPath();
        nvg.arc(cx, cy, r0, a0, a1, .cw);
        nvg.arc(cx, cy, r1, a1, a0, .ccw);
        nvg.closePath();
        ax = cx + math.cos(a0) * (r0 + r1) * 0.5;
        ay = cy + math.sin(a0) * (r0 + r1) * 0.5;
        bx = cx + math.cos(a1) * (r0 + r1) * 0.5;
        by = cy + math.sin(a1) * (r0 + r1) * 0.5;
        paint = nvg.linearGradient(ax, ay, bx, by, nvg.hsla(a0 / (math.pi * 2.0), 1.0, 0.55, 255), nvg.hsla(a1 / (math.pi * 2.0), 1.0, 0.55, 255));
        nvg.fillPaint(paint);
        nvg.fill();
    }

    nvg.beginPath();
    nvg.circle(cx, cy, r0 - 0.5);
    nvg.circle(cx, cy, r1 + 0.5);
    nvg.strokeColor(nvg.rgba(0, 0, 0, 64));
    nvg.strokeWidth(1.0);
    nvg.stroke();

    // Selector
    nvg.save();
    nvg.translate(cx, cy);
    nvg.rotate(hue * math.pi * 2);

    // Marker on
    nvg.strokeWidth(2.0);
    nvg.beginPath();
    nvg.rect(r0 - 1, -3, r1 - r0 + 2, 6);
    nvg.strokeColor(nvg.rgba(255, 255, 255, 192));
    nvg.stroke();

    paint = nvg.boxGradient(r0 - 3, -5, r1 - r0 + 6, 10, 2, 4, nvg.rgba(0, 0, 0, 128), nvg.rgba(0, 0, 0, 0));
    nvg.beginPath();
    nvg.rect(r0 - 2 - 10, -4 - 10, r1 - r0 + 4 + 20, 8 + 20);
    nvg.rect(r0 - 2, -4, r1 - r0 + 4, 8);
    nvg.pathWinding(.cw);
    nvg.fillPaint(paint);
    nvg.fill();

    // Center triangle
    r = r0 - 6;
    ax = math.cos(120.0 / 180.0 * @as(f32, math.pi)) * r;
    ay = math.sin(120.0 / 180.0 * @as(f32, math.pi)) * r;
    bx = math.cos(-120.0 / 180.0 * @as(f32, math.pi)) * r;
    by = math.sin(-120.0 / 180.0 * @as(f32, math.pi)) * r;
    nvg.beginPath();
    nvg.moveTo(r, 0);
    nvg.lineTo(ax, ay);
    nvg.lineTo(bx, by);
    nvg.closePath();
    paint = nvg.linearGradient(r, 0, ax, ay, nvg.hsla(hue, 1.0, 0.5, 255), nvg.rgba(255, 255, 255, 255));
    nvg.fillPaint(paint);
    nvg.fill();
    paint = nvg.linearGradient((r + ax) * 0.5, (0 + ay) * 0.5, bx, by, nvg.rgba(0, 0, 0, 0), nvg.rgba(0, 0, 0, 255));
    nvg.fillPaint(paint);
    nvg.fill();
    nvg.strokeColor(nvg.rgba(0, 0, 0, 64));
    nvg.stroke();

    // Select circle on triangle
    ax = math.cos(120.0 / 180.0 * @as(f32, math.pi)) * r * 0.3;
    ay = math.sin(120.0 / 180.0 * @as(f32, math.pi)) * r * 0.4;
    nvg.strokeWidth(2.0);
    nvg.beginPath();
    nvg.circle(ax, ay, 5);
    nvg.strokeColor(nvg.rgba(255, 255, 255, 192));
    nvg.stroke();

    paint = nvg.radialGradient(ax, ay, 7, 9, nvg.rgba(0, 0, 0, 64), nvg.rgba(0, 0, 0, 0));
    nvg.beginPath();
    nvg.rect(ax - 20, ay - 20, 40, 40);
    nvg.circle(ax, ay, 7);
    nvg.pathWinding(.cw);
    nvg.fillPaint(paint);
    nvg.fill();

    nvg.restore();

    nvg.restore();
}

fn drawLines(x: f32, y: f32, w: f32, h: f32, t: f32) void {
    _ = h;
    var i: i32 = undefined;
    var j: i32 = undefined;
    var pad: f32 = 5.0;
    var s: f32 = w / 9.0 - pad * 2;
    var pts: [4 * 2]f32 = undefined;
    var fx: f32 = undefined;
    var fy: f32 = undefined;
    var joins: [3]nvg.LineJoin = .{ .miter, .round, .bevel };
    var caps: [3]nvg.LineCap = .{ .butt, .round, .square };

    nvg.save();
    pts[0] = -s * 0.25 + math.cos(t * 0.3) * s * 0.5;
    pts[1] = math.sin(t * 0.3) * s * 0.5;
    pts[2] = -s * 0.25;
    pts[3] = 0;
    pts[4] = s * 0.25;
    pts[5] = 0;
    pts[6] = s * 0.25 + math.cos(-t * 0.3) * s * 0.5;
    pts[7] = math.sin(-t * 0.3) * s * 0.5;

    i = 0;
    while (i < 3) : (i += 1) {
        j = 0;
        while (j < 3) : (j += 1) {
            fx = x + s * 0.5 + @intToFloat(f32, i * 3 + j) / 9.0 * w + pad;
            fy = y - s * 0.5 + pad;

            nvg.lineCap(caps[@intCast(usize, i)]);
            nvg.lineJoin(joins[@intCast(usize, j)]);

            nvg.strokeWidth(s * 0.3);
            nvg.strokeColor(nvg.rgba(0, 0, 0, 160));
            nvg.beginPath();
            nvg.moveTo(fx + pts[0], fy + pts[1]);
            nvg.lineTo(fx + pts[2], fy + pts[3]);
            nvg.lineTo(fx + pts[4], fy + pts[5]);
            nvg.lineTo(fx + pts[6], fy + pts[7]);
            nvg.stroke();

            nvg.lineCap(.butt);
            nvg.lineJoin(.bevel);

            nvg.strokeWidth(1.0);
            nvg.strokeColor(nvg.rgba(0, 192, 255, 255));
            nvg.beginPath();
            nvg.moveTo(fx + pts[0], fy + pts[1]);
            nvg.lineTo(fx + pts[2], fy + pts[3]);
            nvg.lineTo(fx + pts[4], fy + pts[5]);
            nvg.lineTo(fx + pts[6], fy + pts[7]);
            nvg.stroke();
        }
    }

    nvg.restore();
}

fn drawWidths(x: f32, y: f32, width: f32) void {
    var i: i32 = undefined;

    nvg.save();

    nvg.strokeColor(nvg.rgba(0, 0, 0, 255));

    i = 0;
    var oy = y;
    while (i < 20) : (i += 1) {
        var w: f32 = (@intToFloat(f32, i) + 0.5) * 0.1;
        nvg.strokeWidth(w);
        nvg.beginPath();
        nvg.moveTo(x, oy);
        nvg.lineTo(x + width, oy + width * 0.3);
        nvg.stroke();
        oy += 10;
    }

    nvg.restore();
}

fn drawCaps(x: f32, y: f32, width: f32) void {
    var i: i32 = undefined;
    var caps: [3]nvg.LineCap = .{ .butt, .round, .square };
    var line_width: f32 = 8.0;

    nvg.save();

    nvg.beginPath();
    nvg.rect(x - line_width / 2, y, width + line_width, 40);
    nvg.fillColor(nvg.rgba(255, 255, 255, 32));
    nvg.fill();

    nvg.beginPath();
    nvg.rect(x, y, width, 40);
    nvg.fillColor(nvg.rgba(255, 255, 255, 32));
    nvg.fill();

    nvg.strokeWidth(line_width);
    i = 0;
    while (i < 3) : (i += 1) {
        nvg.lineCap(caps[@intCast(usize, i)]);
        nvg.strokeColor(nvg.rgba(0, 0, 0, 255));
        nvg.beginPath();
        nvg.moveTo(x, y + @intToFloat(f32, i * 10) + 5);
        nvg.lineTo(x + width, y + @intToFloat(f32, i * 10) + 5);
        nvg.stroke();
    }

    nvg.restore();
}

fn drawScissor(x: f32, y: f32, t: f32) void {
    nvg.save();

    // Draw first rect and set scissor to it's area.
    nvg.translate(x, y);
    nvg.rotate(nvg.degToRad(5));
    nvg.beginPath();
    nvg.rect(-20, -20, 60, 40);
    nvg.fillColor(nvg.rgba(255, 0, 0, 255));
    nvg.fill();
    nvg.scissor(-20, -20, 60, 40);

    // Draw second rectangle with offset and rotation.
    nvg.translate(40, 0);
    nvg.rotate(t);

    // Draw the intended second rectangle without any scissoring.
    nvg.save();
    nvg.resetScissor();
    nvg.beginPath();
    nvg.rect(-20, -10, 60, 30);
    nvg.fillColor(nvg.rgba(255, 128, 0, 64));
    nvg.fill();
    nvg.restore();

    // Draw second rectangle with combined scissoring.
    nvg.intersectScissor(-20, -10, 60, 30);
    nvg.beginPath();
    nvg.rect(-20, -10, 60, 30);
    nvg.fillColor(nvg.rgba(255, 128, 0, 255));
    nvg.fill();

    nvg.restore();
}

fn drawLabel(text: []const u8, x: f32, y: f32, w: f32, h: f32) void {
    _ = w;

    nvg.fontSize(15.0);
    nvg.fontFace("sans");
    nvg.fillColor(nvg.rgba(255, 255, 255, 128));

    nvg.textAlign(.{ .horizontal = .left, .vertical = .middle });
    _ = nvg.text(x, y + h * 0.5, text);
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
        .width = 1000,
        .height = 600,
    });
}
