/// nanovg original api
pub const api = @import("api.zig");

/// nanovg backend implementation
pub const backend = @import("gl_impl.zig");

/// helper context struct
pub const Context = struct {
    const Self = @This();

    ctx: *api.NVGcontext = undefined,

    pub fn init(flags: backend.CreateFlags) Self {
        return .{
            .ctx = backend.createContext(flags),
        };
    }

    pub fn deinit(self: Self) void {
        backend.deleteContext(self.ctx);
    }

    pub fn beginFrame(self: Self, windowWidth: f32, windowHeight: f32, devicePixelRatio: f32) void {
        return api.nvgBeginFrame(self.ctx, windowWidth, windowHeight, devicePixelRatio);
    }

    pub fn cancelFrame(self: Self) void {
        return api.nvgCancelFrame(self.ctx);
    }

    pub fn endFrame(self: Self) void {
        return api.nvgEndFrame(self.ctx);
    }

    pub fn globalCompositeOperation(self: Self, op: c_int) void {
        return api.nvgGlobalCompositeOperation(self.ctx, op);
    }

    pub fn globalCompositeBlendFunc(self: Self, sfactor: c_int, dfactor: c_int) void {
        return api.nvgGlobalCompositeBlendFunc(self.ctx, sfactor, dfactor);
    }

    pub fn globalCompositeBlendFuncSeparate(self: Self, srcRGB: c_int, dstRGB: c_int, srcAlpha: c_int, dstAlpha: c_int) void {
        return api.nvgGlobalCompositeBlendFuncSeparate(self.ctx, srcRGB, dstRGB, srcAlpha, dstAlpha);
    }

    pub fn save(self: Self) void {
        return api.nvgSave(self.ctx);
    }

    pub fn restore(self: Self) void {
        return api.nvgRestore(self.ctx);
    }

    pub fn reset(self: Self) void {
        return api.nvgReset(self.ctx);
    }

    pub fn shapeAntiAlias(self: Self, enabled: c_int) void {
        return api.nvgShapeAntiAlias(self.ctx, enabled);
    }

    pub fn strokeColor(self: Self, color: api.NVGcolor) void {
        return api.nvgStrokeColor(self.ctx, color);
    }

    pub fn strokePaint(self: Self, paint: api.NVGpaint) void {
        return api.nvgStrokePaint(self.ctx, paint);
    }

    pub fn fillColor(self: Self, color: api.NVGcolor) void {
        return api.nvgFillColor(self.ctx, color);
    }

    pub fn fillPaint(self: Self, paint: api.NVGpaint) void {
        return api.nvgFillPaint(self.ctx, paint);
    }

    pub fn miterLimit(self: Self, limit: f32) void {
        return api.nvgMiterLimit(self.ctx, limit);
    }

    pub fn strokeWidth(self: Self, size: f32) void {
        return api.nvgStrokeWidth(self.ctx, size);
    }

    pub fn lineCap(self: Self, cap: c_int) void {
        return api.nvgLineCap(self.ctx, cap);
    }

    pub fn lineJoin(self: Self, join: c_int) void {
        return api.nvgLineJoin(self.ctx, join);
    }

    pub fn globalAlpha(self: Self, alpha: f32) void {
        return api.nvgGlobalAlpha(self.ctx, alpha);
    }

    pub fn resetTransform(self: Self) void {
        return api.nvgResetTransform(self.ctx);
    }

    pub fn transform(self: Self, a: f32, b: f32, c: f32, d: f32, e: f32, f: f32) void {
        return api.nvgTransform(self.ctx, a, b, c, d, e, f);
    }

    pub fn translate(self: Self, x: f32, y: f32) void {
        return api.nvgTranslate(self.ctx, x, y);
    }

    pub fn rotate(self: Self, angle: f32) void {
        return api.nvgRotate(self.ctx, angle);
    }

    pub fn skewX(self: Self, angle: f32) void {
        return api.nvgSkewX(self.ctx, angle);
    }

    pub fn skewY(self: Self, angle: f32) void {
        return api.nvgSkewY(self.ctx, angle);
    }

    pub fn scale(self: Self, x: f32, y: f32) void {
        return api.nvgScale(self.ctx, x, y);
    }

    pub fn currentTransform(self: Self, xform: [*c]f32) void {
        return api.nvgCurrentTransform(self.ctx, xform);
    }

    pub fn createImage(self: Self, filename: [*c]const u8, imageFlags: c_int) c_int {
        return api.nvgCreateImage(self.ctx, filename, imageFlags);
    }

    pub fn createImageMem(self: Self, imageFlags: c_int, data: [*c]u8, ndata: c_int) c_int {
        return api.nvgCreateImageMem(self.ctx, imageFlags, data, ndata);
    }

    pub fn createImageRGBA(self: Self, w: c_int, h: c_int, imageFlags: c_int, data: [*c]const u8) c_int {
        return api.nvgCreateImageRGBA(self.ctx, w, h, imageFlags, data);
    }

    pub fn updateImage(self: Self, image: c_int, data: [*c]const u8) void {
        return api.nvgUpdateImage(self.ctx, image, data);
    }

    pub fn imageSize(self: Self, image: c_int, w: [*c]c_int, h: [*c]c_int) void {
        return api.nvgImageSize(self.ctx, image, w, h);
    }

    pub fn deleteImage(self: Self, image: c_int) void {
        return api.nvgDeleteImage(self.ctx, image);
    }

    pub fn linearGradient(self: Self, sx: f32, sy: f32, ex: f32, ey: f32, icol: api.NVGcolor, ocol: api.NVGcolor) api.NVGpaint {
        return api.nvgLinearGradient(self.ctx, sx, sy, ex, ey, icol, ocol);
    }

    pub fn boxGradient(self: Self, x: f32, y: f32, w: f32, h: f32, r: f32, f: f32, icol: api.NVGcolor, ocol: api.NVGcolor) api.NVGpaint {
        return api.nvgBoxGradient(self.ctx, x, y, w, h, r, f, icol, ocol);
    }

    pub fn radialGradient(self: Self, cx: f32, cy: f32, inr: f32, outr: f32, icol: api.NVGcolor, ocol: api.NVGcolor) api.NVGpaint {
        return api.nvgRadialGradient(self.ctx, cx, cy, inr, outr, icol, ocol);
    }

    pub fn imagePattern(self: Self, ox: f32, oy: f32, ex: f32, ey: f32, angle: f32, image: c_int, alpha: f32) api.NVGpaint {
        return api.nvgImagePattern(self.ctx, ox, oy, ex, ey, angle, image, alpha);
    }

    pub fn scissor(self: Self, x: f32, y: f32, w: f32, h: f32) void {
        return api.nvgScissor(self.ctx, x, y, w, h);
    }

    pub fn intersectScissor(self: Self, x: f32, y: f32, w: f32, h: f32) void {
        return api.nvgIntersectScissor(self.ctx, x, y, w, h);
    }

    pub fn resetScissor(self: Self) void {
        return api.nvgResetScissor(self.ctx);
    }

    pub fn beginPath(self: Self) void {
        return api.nvgBeginPath(self.ctx);
    }

    pub fn moveTo(self: Self, x: f32, y: f32) void {
        return api.nvgMoveTo(self.ctx, x, y);
    }

    pub fn lineTo(self: Self, x: f32, y: f32) void {
        return api.nvgLineTo(self.ctx, x, y);
    }

    pub fn bezierTo(self: Self, c1x: f32, c1y: f32, c2x: f32, c2y: f32, x: f32, y: f32) void {
        return api.nvgBezierTo(self.ctx, c1x, c1y, c2x, c2y, x, y);
    }

    pub fn quadTo(self: Self, cx: f32, cy: f32, x: f32, y: f32) void {
        return api.nvgQuadTo(self.ctx, cx, cy, x, y);
    }

    pub fn arcTo(self: Self, x1: f32, y1: f32, x2: f32, y2: f32, radius: f32) void {
        return api.nvgArcTo(self.ctx, x1, y1, x2, y2, radius);
    }

    pub fn closePath(self: Self) void {
        return api.nvgClosePath(self.ctx);
    }

    pub fn pathWinding(self: Self, dir: c_int) void {
        return api.nvgPathWinding(self.ctx, dir);
    }

    pub fn arc(self: Self, cx: f32, cy: f32, r: f32, a0: f32, a1: f32, dir: c_int) void {
        return api.nvgArc(self.ctx, cx, cy, r, a0, a1, dir);
    }

    pub fn rect(self: Self, x: f32, y: f32, w: f32, h: f32) void {
        return api.nvgRect(self.ctx, x, y, w, h);
    }

    pub fn roundedRect(self: Self, x: f32, y: f32, w: f32, h: f32, r: f32) void {
        return api.nvgRoundedRect(self.ctx, x, y, w, h, r);
    }

    pub fn roundedRectVarying(self: Self, x: f32, y: f32, w: f32, h: f32, radTopLeft: f32, radTopRight: f32, radBottomRight: f32, radBottomLeft: f32) void {
        return api.nvgRoundedRectVarying(self.ctx, x, y, w, h, radTopLeft, radTopRight, radBottomRight, radBottomLeft);
    }

    pub fn ellipse(self: Self, cx: f32, cy: f32, rx: f32, ry: f32) void {
        return api.nvgEllipse(self.ctx, cx, cy, rx, ry);
    }

    pub fn circle(self: Self, cx: f32, cy: f32, r: f32) void {
        return api.nvgCircle(self.ctx, cx, cy, r);
    }

    pub fn fill(self: Self) void {
        return api.nvgFill(self.ctx);
    }

    pub fn stroke(self: Self) void {
        return api.nvgStroke(self.ctx);
    }

    pub fn createFont(self: Self, name: [*c]const u8, filename: [*c]const u8) c_int {
        return api.nvgCreateFont(self.ctx, name, filename);
    }

    pub fn createFontAtIndex(self: Self, name: [*c]const u8, filename: [*c]const u8, fontIndex: c_int) c_int {
        return api.nvgCreateFontAtIndex(self.ctx, name, filename, fontIndex);
    }

    pub fn createFontMem(self: Self, name: [*c]const u8, data: [*c]u8, ndata: c_int, freeData: c_int) c_int {
        return api.nvgCreateFontMem(self.ctx, name, data, ndata, freeData);
    }

    pub fn createFontMemAtIndex(self: Self, name: [*c]const u8, data: [*c]u8, ndata: c_int, freeData: c_int, fontIndex: c_int) c_int {
        return api.nvgCreateFontMemAtIndex(self.ctx, name, data, ndata, freeData, fontIndex);
    }

    pub fn findFont(self: Self, name: [*c]const u8) c_int {
        return api.nvgFindFont(self.ctx, name);
    }

    pub fn addFallbackFontId(self: Self, baseFont: c_int, fallbackFont: c_int) c_int {
        return api.nvgAddFallbackFontId(self.ctx, baseFont, fallbackFont);
    }

    pub fn addFallbackFont(self: Self, baseFont: [*c]const u8, fallbackFont: [*c]const u8) c_int {
        return api.nvgAddFallbackFont(self.ctx, baseFont, fallbackFont);
    }

    pub fn resetFallbackFontsId(self: Self, baseFont: c_int) void {
        return api.nvgResetFallbackFontsId(self.ctx, baseFont);
    }

    pub fn resetFallbackFonts(self: Self, baseFont: [*c]const u8) void {
        return api.nvgResetFallbackFonts(self.ctx, baseFont);
    }

    pub fn fontSize(self: Self, size: f32) void {
        return api.nvgFontSize(self.ctx, size);
    }

    pub fn fontBlur(self: Self, blur: f32) void {
        return api.nvgFontBlur(self.ctx, blur);
    }

    pub fn textLetterSpacing(self: Self, spacing: f32) void {
        return api.nvgTextLetterSpacing(self.ctx, spacing);
    }

    pub fn textLineHeight(self: Self, lineHeight: f32) void {
        return api.nvgTextLineHeight(self.ctx, lineHeight);
    }

    pub fn textAlign(self: Self, @"align": c_int) void {
        return api.nvgTextAlign(self.ctx, @"align");
    }

    pub fn fontFaceId(self: Self, font: c_int) void {
        return api.nvgFontFaceId(self.ctx, font);
    }

    pub fn fontFace(self: Self, font: [*c]const u8) void {
        return api.nvgFontFace(self.ctx, font);
    }

    pub fn text(self: Self, x: f32, y: f32, string: [*c]const u8, end: [*c]const u8) f32 {
        return api.nvgText(self.ctx, x, y, string, end);
    }

    pub fn textBox(self: Self, x: f32, y: f32, breakRowWidth: f32, string: [*c]const u8, end: [*c]const u8) void {
        return api.nvgTextBox(self.ctx, x, y, breakRowWidth, string, end);
    }

    pub fn textBounds(self: Self, x: f32, y: f32, string: [*c]const u8, end: [*c]const u8, bounds: [*c]f32) f32 {
        return api.nvgTextBounds(self.ctx, x, y, string, end, bounds);
    }

    pub fn textBoxBounds(self: Self, x: f32, y: f32, breakRowWidth: f32, string: [*c]const u8, end: [*c]const u8, bounds: [*c]f32) void {
        return api.nvgTextBoxBounds(self.ctx, x, y, breakRowWidth, string, end, bounds);
    }

    pub fn textGlyphPositions(self: Self, x: f32, y: f32, string: [*c]const u8, end: [*c]const u8, positions: [*c]api.NVGglyphPosition, maxPositions: c_int) c_int {
        return api.nvgTextGlyphPositions(self.ctx, x, y, string, end, positions, maxPositions);
    }

    pub fn textMetrics(self: Self, ascender: [*c]f32, descender: [*c]f32, lineh: [*c]f32) void {
        return api.nvgTextMetrics(self.ctx, ascender, descender, lineh);
    }

    pub fn textBreakLines(self: Self, string: [*c]const u8, end: [*c]const u8, breakRowWidth: f32, rows: [*c]api.NVGtextRow, maxRows: c_int) c_int {
        return api.nvgTextBreakLines(self.ctx, string, end, breakRowWidth, rows, maxRows);
    }
};
