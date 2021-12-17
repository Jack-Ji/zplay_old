pub const struct_NVGcontext = opaque {};
pub const NVGcontext = struct_NVGcontext;
pub const struct_NVGcolor = extern struct {
    r: f32,
    g: f32,
    b: f32,
    a: f32,
};
pub const NVGcolor = struct_NVGcolor;
pub const struct_NVGpaint = extern struct {
    xform: [6]f32,
    extent: [2]f32,
    radius: f32,
    feather: f32,
    innerColor: NVGcolor,
    outerColor: NVGcolor,
    image: c_int,
};
pub const NVGpaint = struct_NVGpaint;
pub const NVG_CCW: c_int = 1;
pub const NVG_CW: c_int = 2;
pub const enum_NVGwinding = c_uint;
pub const NVG_SOLID: c_int = 1;
pub const NVG_HOLE: c_int = 2;
pub const enum_NVGsolidity = c_uint;
pub const NVG_BUTT: c_int = 0;
pub const NVG_ROUND: c_int = 1;
pub const NVG_SQUARE: c_int = 2;
pub const NVG_BEVEL: c_int = 3;
pub const NVG_MITER: c_int = 4;
pub const enum_NVGlineCap = c_uint;
pub const NVG_ALIGN_LEFT: c_int = 1;
pub const NVG_ALIGN_CENTER: c_int = 2;
pub const NVG_ALIGN_RIGHT: c_int = 4;
pub const NVG_ALIGN_TOP: c_int = 8;
pub const NVG_ALIGN_MIDDLE: c_int = 16;
pub const NVG_ALIGN_BOTTOM: c_int = 32;
pub const NVG_ALIGN_BASELINE: c_int = 64;
pub const enum_NVGalign = c_uint;
pub const NVG_ZERO: c_int = 1;
pub const NVG_ONE: c_int = 2;
pub const NVG_SRC_COLOR: c_int = 4;
pub const NVG_ONE_MINUS_SRC_COLOR: c_int = 8;
pub const NVG_DST_COLOR: c_int = 16;
pub const NVG_ONE_MINUS_DST_COLOR: c_int = 32;
pub const NVG_SRC_ALPHA: c_int = 64;
pub const NVG_ONE_MINUS_SRC_ALPHA: c_int = 128;
pub const NVG_DST_ALPHA: c_int = 256;
pub const NVG_ONE_MINUS_DST_ALPHA: c_int = 512;
pub const NVG_SRC_ALPHA_SATURATE: c_int = 1024;
pub const enum_NVGblendFactor = c_uint;
pub const NVG_SOURCE_OVER: c_int = 0;
pub const NVG_SOURCE_IN: c_int = 1;
pub const NVG_SOURCE_OUT: c_int = 2;
pub const NVG_ATOP: c_int = 3;
pub const NVG_DESTINATION_OVER: c_int = 4;
pub const NVG_DESTINATION_IN: c_int = 5;
pub const NVG_DESTINATION_OUT: c_int = 6;
pub const NVG_DESTINATION_ATOP: c_int = 7;
pub const NVG_LIGHTER: c_int = 8;
pub const NVG_COPY: c_int = 9;
pub const NVG_XOR: c_int = 10;
pub const enum_NVGcompositeOperation = c_uint;
pub const struct_NVGcompositeOperationState = extern struct {
    srcRGB: c_int,
    dstRGB: c_int,
    srcAlpha: c_int,
    dstAlpha: c_int,
};
pub const NVGcompositeOperationState = struct_NVGcompositeOperationState;
pub const struct_NVGglyphPosition = extern struct {
    str: [*c]const u8,
    x: f32,
    minx: f32,
    maxx: f32,
};
pub const NVGglyphPosition = struct_NVGglyphPosition;
pub const struct_NVGtextRow = extern struct {
    start: [*c]const u8,
    end: [*c]const u8,
    next: [*c]const u8,
    width: f32,
    minx: f32,
    maxx: f32,
};
pub const NVGtextRow = struct_NVGtextRow;
pub const NVG_IMAGE_GENERATE_MIPMAPS: c_int = 1;
pub const NVG_IMAGE_REPEATX: c_int = 2;
pub const NVG_IMAGE_REPEATY: c_int = 4;
pub const NVG_IMAGE_FLIPY: c_int = 8;
pub const NVG_IMAGE_PREMULTIPLIED: c_int = 16;
pub const NVG_IMAGE_NEAREST: c_int = 32;
pub const enum_NVGimageFlags = c_uint;
pub const NANOVG_H = "";
pub const NVG_PI = @as(f32, 3.14159265358979323846264338327);
pub const NVGwinding = enum_NVGwinding;
pub const NVGsolidity = enum_NVGsolidity;
pub const NVGlineCap = enum_NVGlineCap;
pub const NVGalign = enum_NVGalign;
pub const NVGblendFactor = enum_NVGblendFactor;
pub const NVGcompositeOperation = enum_NVGcompositeOperation;
pub const NVGimageFlags = enum_NVGimageFlags;
pub const NVGtexture = enum_NVGtexture;

pub extern fn nvgBeginFrame(ctx: ?*NVGcontext, windowWidth: f32, windowHeight: f32, devicePixelRatio: f32) void;
pub extern fn nvgCancelFrame(ctx: ?*NVGcontext) void;
pub extern fn nvgEndFrame(ctx: ?*NVGcontext) void;
pub extern fn nvgGlobalCompositeOperation(ctx: ?*NVGcontext, op: c_int) void;
pub extern fn nvgGlobalCompositeBlendFunc(ctx: ?*NVGcontext, sfactor: c_int, dfactor: c_int) void;
pub extern fn nvgGlobalCompositeBlendFuncSeparate(ctx: ?*NVGcontext, srcRGB: c_int, dstRGB: c_int, srcAlpha: c_int, dstAlpha: c_int) void;
pub extern fn nvgRGB(r: u8, g: u8, b: u8) NVGcolor;
pub extern fn nvgRGBf(r: f32, g: f32, b: f32) NVGcolor;
pub extern fn nvgRGBA(r: u8, g: u8, b: u8, a: u8) NVGcolor;
pub extern fn nvgRGBAf(r: f32, g: f32, b: f32, a: f32) NVGcolor;
pub extern fn nvgLerpRGBA(c0: NVGcolor, c1: NVGcolor, u: f32) NVGcolor;
pub extern fn nvgTransRGBA(c0: NVGcolor, a: u8) NVGcolor;
pub extern fn nvgTransRGBAf(c0: NVGcolor, a: f32) NVGcolor;
pub extern fn nvgHSL(h: f32, s: f32, l: f32) NVGcolor;
pub extern fn nvgHSLA(h: f32, s: f32, l: f32, a: u8) NVGcolor;
pub extern fn nvgSave(ctx: ?*NVGcontext) void;
pub extern fn nvgRestore(ctx: ?*NVGcontext) void;
pub extern fn nvgReset(ctx: ?*NVGcontext) void;
pub extern fn nvgShapeAntiAlias(ctx: ?*NVGcontext, enabled: c_int) void;
pub extern fn nvgStrokeColor(ctx: ?*NVGcontext, color: NVGcolor) void;
pub extern fn nvgStrokePaint(ctx: ?*NVGcontext, paint: NVGpaint) void;
pub extern fn nvgFillColor(ctx: ?*NVGcontext, color: NVGcolor) void;
pub extern fn nvgFillPaint(ctx: ?*NVGcontext, paint: NVGpaint) void;
pub extern fn nvgMiterLimit(ctx: ?*NVGcontext, limit: f32) void;
pub extern fn nvgStrokeWidth(ctx: ?*NVGcontext, size: f32) void;
pub extern fn nvgLineCap(ctx: ?*NVGcontext, cap: c_int) void;
pub extern fn nvgLineJoin(ctx: ?*NVGcontext, join: c_int) void;
pub extern fn nvgGlobalAlpha(ctx: ?*NVGcontext, alpha: f32) void;
pub extern fn nvgGlobalTint(ctx: ?*NVGcontext, tint: NVGcolor) void;
pub extern fn nvgGetGlobalTint(ctx: ?*NVGcontext) NVGcolor;
pub extern fn nvgAlpha(ctx: ?*NVGcontext, alpha: f32) void;
pub extern fn nvgTint(ctx: ?*NVGcontext, tint: NVGcolor) void;
pub extern fn nvgResetTransform(ctx: ?*NVGcontext) void;
pub extern fn nvgTransform(ctx: ?*NVGcontext, a: f32, b: f32, c: f32, d: f32, e: f32, f: f32) void;
pub extern fn nvgTranslate(ctx: ?*NVGcontext, x: f32, y: f32) void;
pub extern fn nvgRotate(ctx: ?*NVGcontext, angle: f32) void;
pub extern fn nvgSkewX(ctx: ?*NVGcontext, angle: f32) void;
pub extern fn nvgSkewY(ctx: ?*NVGcontext, angle: f32) void;
pub extern fn nvgScale(ctx: ?*NVGcontext, x: f32, y: f32) void;
pub extern fn nvgCurrentTransform(ctx: ?*NVGcontext, xform: [*c]f32) void;
pub extern fn nvgTransformIdentity(dst: [*c]f32) void;
pub extern fn nvgTransformTranslate(dst: [*c]f32, tx: f32, ty: f32) void;
pub extern fn nvgTransformScale(dst: [*c]f32, sx: f32, sy: f32) void;
pub extern fn nvgTransformRotate(dst: [*c]f32, a: f32) void;
pub extern fn nvgTransformSkewX(dst: [*c]f32, a: f32) void;
pub extern fn nvgTransformSkewY(dst: [*c]f32, a: f32) void;
pub extern fn nvgTransformMultiply(dst: [*c]f32, src: [*c]const f32) void;
pub extern fn nvgTransformPremultiply(dst: [*c]f32, src: [*c]const f32) void;
pub extern fn nvgTransformInverse(dst: [*c]f32, src: [*c]const f32) c_int;
pub extern fn nvgTransformPoint(dstx: [*c]f32, dsty: [*c]f32, xform: [*c]const f32, srcx: f32, srcy: f32) void;
pub extern fn nvgDegToRad(deg: f32) f32;
pub extern fn nvgRadToDeg(rad: f32) f32;
pub extern fn nvgCreateImage(ctx: ?*NVGcontext, filename: [*c]const u8, imageFlags: c_int) c_int;
pub extern fn nvgCreateImageMem(ctx: ?*NVGcontext, imageFlags: c_int, data: [*c]u8, ndata: c_int) c_int;
pub extern fn nvgCreateImageRGBA(ctx: ?*NVGcontext, w: c_int, h: c_int, imageFlags: c_int, data: [*c]const u8) c_int;
pub extern fn nvgUpdateImage(ctx: ?*NVGcontext, image: c_int, data: [*c]const u8) void;
pub extern fn nvgUpdateImageRegion(ctx: ?*NVGcontext, image: c_int, data: [*c]const u8, x: c_int, y: c_int, w: c_int, h: c_int) void;
pub extern fn nvgImageSize(ctx: ?*NVGcontext, image: c_int, w: [*c]c_int, h: [*c]c_int) void;
pub extern fn nvgDeleteImage(ctx: ?*NVGcontext, image: c_int) void;
pub extern fn nvgLinearGradient(ctx: ?*NVGcontext, sx: f32, sy: f32, ex: f32, ey: f32, icol: NVGcolor, ocol: NVGcolor) NVGpaint;
pub extern fn nvgBoxGradient(ctx: ?*NVGcontext, x: f32, y: f32, w: f32, h: f32, r: f32, f: f32, icol: NVGcolor, ocol: NVGcolor) NVGpaint;
pub extern fn nvgRadialGradient(ctx: ?*NVGcontext, cx: f32, cy: f32, inr: f32, outr: f32, icol: NVGcolor, ocol: NVGcolor) NVGpaint;
pub extern fn nvgImagePattern(ctx: ?*NVGcontext, ox: f32, oy: f32, ex: f32, ey: f32, angle: f32, image: c_int, alpha: f32) NVGpaint;
pub extern fn nvgScissor(ctx: ?*NVGcontext, x: f32, y: f32, w: f32, h: f32) void;
pub extern fn nvgIntersectScissor(ctx: ?*NVGcontext, x: f32, y: f32, w: f32, h: f32) void;
pub extern fn nvgResetScissor(ctx: ?*NVGcontext) void;
pub extern fn nvgBeginPath(ctx: ?*NVGcontext) void;
pub extern fn nvgMoveTo(ctx: ?*NVGcontext, x: f32, y: f32) void;
pub extern fn nvgLineTo(ctx: ?*NVGcontext, x: f32, y: f32) void;
pub extern fn nvgBezierTo(ctx: ?*NVGcontext, c1x: f32, c1y: f32, c2x: f32, c2y: f32, x: f32, y: f32) void;
pub extern fn nvgQuadTo(ctx: ?*NVGcontext, cx: f32, cy: f32, x: f32, y: f32) void;
pub extern fn nvgArcTo(ctx: ?*NVGcontext, x1: f32, y1: f32, x2: f32, y2: f32, radius: f32) void;
pub extern fn nvgClosePath(ctx: ?*NVGcontext) void;
pub extern fn nvgPathWinding(ctx: ?*NVGcontext, dir: c_int) void;
pub extern fn nvgArc(ctx: ?*NVGcontext, cx: f32, cy: f32, r: f32, a0: f32, a1: f32, dir: c_int) void;
pub extern fn nvgRect(ctx: ?*NVGcontext, x: f32, y: f32, w: f32, h: f32) void;
pub extern fn nvgRoundedRect(ctx: ?*NVGcontext, x: f32, y: f32, w: f32, h: f32, r: f32) void;
pub extern fn nvgRoundedRectVarying(ctx: ?*NVGcontext, x: f32, y: f32, w: f32, h: f32, radTopLeft: f32, radTopRight: f32, radBottomRight: f32, radBottomLeft: f32) void;
pub extern fn nvgEllipse(ctx: ?*NVGcontext, cx: f32, cy: f32, rx: f32, ry: f32) void;
pub extern fn nvgCircle(ctx: ?*NVGcontext, cx: f32, cy: f32, r: f32) void;
pub extern fn nvgFill(ctx: ?*NVGcontext) void;
pub extern fn nvgStroke(ctx: ?*NVGcontext) void;
pub extern fn nvgCreateFont(ctx: ?*NVGcontext, name: [*c]const u8, filename: [*c]const u8) c_int;
pub extern fn nvgCreateFontAtIndex(ctx: ?*NVGcontext, name: [*c]const u8, filename: [*c]const u8, fontIndex: c_int) c_int;
pub extern fn nvgCreateFontMem(ctx: ?*NVGcontext, name: [*c]const u8, data: [*c]u8, ndata: c_int, freeData: c_int) c_int;
pub extern fn nvgCreateFontMemAtIndex(ctx: ?*NVGcontext, name: [*c]const u8, data: [*c]u8, ndata: c_int, freeData: c_int, fontIndex: c_int) c_int;
pub extern fn nvgFindFont(ctx: ?*NVGcontext, name: [*c]const u8) c_int;
pub extern fn nvgAddFallbackFontId(ctx: ?*NVGcontext, baseFont: c_int, fallbackFont: c_int) c_int;
pub extern fn nvgAddFallbackFont(ctx: ?*NVGcontext, baseFont: [*c]const u8, fallbackFont: [*c]const u8) c_int;
pub extern fn nvgResetFallbackFontsId(ctx: ?*NVGcontext, baseFont: c_int) void;
pub extern fn nvgResetFallbackFonts(ctx: ?*NVGcontext, baseFont: [*c]const u8) void;
pub extern fn nvgFontSize(ctx: ?*NVGcontext, size: f32) void;
pub extern fn nvgFontBlur(ctx: ?*NVGcontext, blur: f32) void;
pub extern fn nvgTextLetterSpacing(ctx: ?*NVGcontext, spacing: f32) void;
pub extern fn nvgTextLineHeight(ctx: ?*NVGcontext, lineHeight: f32) void;
pub extern fn nvgTextAlign(ctx: ?*NVGcontext, @"align": c_int) void;
pub extern fn nvgFontFaceId(ctx: ?*NVGcontext, font: c_int) void;
pub extern fn nvgFontFace(ctx: ?*NVGcontext, font: [*c]const u8) void;
pub extern fn nvgText(ctx: ?*NVGcontext, x: f32, y: f32, string: [*c]const u8, end: [*c]const u8) f32;
pub extern fn nvgTextBox(ctx: ?*NVGcontext, x: f32, y: f32, breakRowWidth: f32, string: [*c]const u8, end: [*c]const u8) void;
pub extern fn nvgTextBounds(ctx: ?*NVGcontext, x: f32, y: f32, string: [*c]const u8, end: [*c]const u8, bounds: [*c]f32) f32;
pub extern fn nvgTextBoxBounds(ctx: ?*NVGcontext, x: f32, y: f32, breakRowWidth: f32, string: [*c]const u8, end: [*c]const u8, bounds: [*c]f32) void;
pub extern fn nvgTextGlyphPositions(ctx: ?*NVGcontext, x: f32, y: f32, string: [*c]const u8, end: [*c]const u8, positions: [*c]NVGglyphPosition, maxPositions: c_int) c_int;
pub extern fn nvgTextMetrics(ctx: ?*NVGcontext, ascender: [*c]f32, descender: [*c]f32, lineh: [*c]f32) void;
pub extern fn nvgTextBreakLines(ctx: ?*NVGcontext, string: [*c]const u8, end: [*c]const u8, breakRowWidth: f32, rows: [*c]NVGtextRow, maxRows: c_int) c_int;
pub extern fn nvgGetDrawCallCount(ctx: ?*NVGcontext) c_int;
pub const NVG_TEXTURE_ALPHA: c_int = 1;
pub const NVG_TEXTURE_RGBA: c_int = 2;
pub const enum_NVGtexture = c_uint;
pub extern fn nvgCreateGL3(flags: c_int) ?*NVGcontext;
pub extern fn nvgDeleteGL3(ctx: ?*NVGcontext) void;
pub const NVG_ANTIALIAS = 1 << 0;
pub const NVG_STENCIL_STROKES = 1 << 1;
pub const NVG_DEBUG = 1 << 2;
