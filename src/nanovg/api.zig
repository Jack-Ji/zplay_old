pub const struct_NVGcontext = opaque {};
pub const NVGcontext = struct_NVGcontext;
const struct_unnamed_2 = extern struct {
    r: f32,
    g: f32,
    b: f32,
    a: f32,
};
const union_unnamed_1 = extern union {
    rgba: [4]f32,
    unnamed_0: struct_unnamed_2,
};
pub const struct_NVGcolor = extern struct {
    unnamed_0: union_unnamed_1,
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

extern fn nvgBeginFrame(ctx: ?*NVGcontext, windowWidth: f32, windowHeight: f32, devicePixelRatio: f32) void;
pub fn beginFrame(ctx: ?*NVGcontext, windowWidth: f32, windowHeight: f32, devicePixelRatio: f32) void {
    return nvgBeginFrame(ctx, windowWidth, windowHeight, devicePixelRatio);
}

extern fn nvgCancelFrame(ctx: ?*NVGcontext) void;
pub fn cancelFrame(ctx: ?*NVGcontext) void {
    return nvgCancelFrame(ctx);
}

extern fn nvgEndFrame(ctx: ?*NVGcontext) void;
pub fn endFrame(ctx: ?*NVGcontext) void {
    return nvgEndFrame(ctx);
}

extern fn nvgGlobalCompositeOperation(ctx: ?*NVGcontext, op: c_int) void;
pub fn globalCompositeOperation(ctx: ?*NVGcontext, op: c_int) void {
    return nvgGlobalCompositeOperation(ctx, op);
}

extern fn nvgGlobalCompositeBlendFunc(ctx: ?*NVGcontext, sfactor: c_int, dfactor: c_int) void;
pub fn globalCompositeBlendFunc(ctx: ?*NVGcontext, sfactor: c_int, dfactor: c_int) void {
    return nvgGlobalCompositeBlendFunc(ctx, sfactor, dfactor);
}

extern fn nvgGlobalCompositeBlendFuncSeparate(ctx: ?*NVGcontext, srcRGB: c_int, dstRGB: c_int, srcAlpha: c_int, dstAlpha: c_int) void;
pub fn globalCompositeBlendFuncSeparate(ctx: ?*NVGcontext, srcRGB: c_int, dstRGB: c_int, srcAlpha: c_int, dstAlpha: c_int) void {
    return nvgGlobalCompositeBlendFuncSeparate(ctx, srcRGB, dstRGB, srcAlpha, dstAlpha);
}

extern fn nvgRGB(r: u8, g: u8, b: u8) NVGcolor;
pub fn rGB(r: u8, g: u8, b: u8) NVGcolor {
    return nvgRGB(r, g, b);
}

extern fn nvgRGBf(r: f32, g: f32, b: f32) NVGcolor;
pub fn rGBf(r: f32, g: f32, b: f32) NVGcolor {
    return nvgRGBf(r, g, b);
}

extern fn nvgRGBA(r: u8, g: u8, b: u8, a: u8) NVGcolor;
pub fn rGBA(r: u8, g: u8, b: u8, a: u8) NVGcolor {
    return nvgRGBA(r, g, b, a);
}

extern fn nvgRGBAf(r: f32, g: f32, b: f32, a: f32) NVGcolor;
pub fn rGBAf(r: f32, g: f32, b: f32, a: f32) NVGcolor {
    return nvgRGBAf(r, g, b, a);
}

extern fn nvgLerpRGBA(c0: NVGcolor, c1: NVGcolor, u: f32) NVGcolor;
pub fn lerpRGBA(c0: NVGcolor, c1: NVGcolor, u: f32) NVGcolor {
    return nvgLerpRGBA(c0, c1, u);
}

extern fn nvgTransRGBA(c0: NVGcolor, a: u8) NVGcolor;
pub fn transRGBA(c0: NVGcolor, a: u8) NVGcolor {
    return nvgTransRGBA(c0, a);
}

extern fn nvgTransRGBAf(c0: NVGcolor, a: f32) NVGcolor;
pub fn transRGBAf(c0: NVGcolor, a: f32) NVGcolor {
    return nvgTransRGBAf(c0, a);
}

extern fn nvgHSL(h: f32, s: f32, l: f32) NVGcolor;
pub fn hSL(h: f32, s: f32, l: f32) NVGcolor {
    return nvgHSL(h, s, l);
}

extern fn nvgHSLA(h: f32, s: f32, l: f32, a: u8) NVGcolor;
pub fn hSLA(h: f32, s: f32, l: f32, a: u8) NVGcolor {
    return nvgHSLA(h, s, l, a);
}

extern fn nvgSave(ctx: ?*NVGcontext) void;
pub fn save(ctx: ?*NVGcontext) void {
    return nvgSave(ctx);
}

extern fn nvgRestore(ctx: ?*NVGcontext) void;
pub fn restore(ctx: ?*NVGcontext) void {
    return nvgRestore(ctx);
}

extern fn nvgReset(ctx: ?*NVGcontext) void;
pub fn reset(ctx: ?*NVGcontext) void {
    return nvgReset(ctx);
}

extern fn nvgShapeAntiAlias(ctx: ?*NVGcontext, enabled: c_int) void;
pub fn shapeAntiAlias(ctx: ?*NVGcontext, enabled: c_int) void {
    return nvgShapeAntiAlias(ctx, enabled);
}

extern fn nvgStrokeColor(ctx: ?*NVGcontext, color: NVGcolor) void;
pub fn strokeColor(ctx: ?*NVGcontext, color: NVGcolor) void {
    return nvgStrokeColor(ctx, color);
}

extern fn nvgStrokePaint(ctx: ?*NVGcontext, paint: NVGpaint) void;
pub fn strokePaint(ctx: ?*NVGcontext, paint: NVGpaint) void {
    return nvgStrokePaint(ctx, paint);
}

extern fn nvgFillColor(ctx: ?*NVGcontext, color: NVGcolor) void;
pub fn fillColor(ctx: ?*NVGcontext, color: NVGcolor) void {
    return nvgFillColor(ctx, color);
}

extern fn nvgFillPaint(ctx: ?*NVGcontext, paint: NVGpaint) void;
pub fn fillPaint(ctx: ?*NVGcontext, paint: NVGpaint) void {
    return nvgFillPaint(ctx, paint);
}

extern fn nvgMiterLimit(ctx: ?*NVGcontext, limit: f32) void;
pub fn miterLimit(ctx: ?*NVGcontext, limit: f32) void {
    return nvgMiterLimit(ctx, limit);
}

extern fn nvgStrokeWidth(ctx: ?*NVGcontext, size: f32) void;
pub fn strokeWidth(ctx: ?*NVGcontext, size: f32) void {
    return nvgStrokeWidth(ctx, size);
}

extern fn nvgLineCap(ctx: ?*NVGcontext, cap: c_int) void;
pub fn lineCap(ctx: ?*NVGcontext, cap: c_int) void {
    return nvgLineCap(ctx, cap);
}

extern fn nvgLineJoin(ctx: ?*NVGcontext, join: c_int) void;
pub fn lineJoin(ctx: ?*NVGcontext, join: c_int) void {
    return nvgLineJoin(ctx, join);
}

extern fn nvgGlobalAlpha(ctx: ?*NVGcontext, alpha: f32) void;
pub fn globalAlpha(ctx: ?*NVGcontext, alpha: f32) void {
    return nvgGlobalAlpha(ctx, alpha);
}

extern fn nvgResetTransform(ctx: ?*NVGcontext) void;
pub fn resetTransform(ctx: ?*NVGcontext) void {
    return nvgResetTransform(ctx);
}

extern fn nvgTransform(ctx: ?*NVGcontext, a: f32, b: f32, c: f32, d: f32, e: f32, f: f32) void;
pub fn transform(ctx: ?*NVGcontext, a: f32, b: f32, c: f32, d: f32, e: f32, f: f32) void {
    return nvgTransform(ctx, a, b, c, d, e, f);
}

extern fn nvgTranslate(ctx: ?*NVGcontext, x: f32, y: f32) void;
pub fn translate(ctx: ?*NVGcontext, x: f32, y: f32) void {
    return nvgTranslate(ctx, x, y);
}

extern fn nvgRotate(ctx: ?*NVGcontext, angle: f32) void;
pub fn rotate(ctx: ?*NVGcontext, angle: f32) void {
    return nvgRotate(ctx, angle);
}

extern fn nvgSkewX(ctx: ?*NVGcontext, angle: f32) void;
pub fn skewX(ctx: ?*NVGcontext, angle: f32) void {
    return nvgSkewX(ctx, angle);
}

extern fn nvgSkewY(ctx: ?*NVGcontext, angle: f32) void;
pub fn skewY(ctx: ?*NVGcontext, angle: f32) void {
    return nvgSkewY(ctx, angle);
}

extern fn nvgScale(ctx: ?*NVGcontext, x: f32, y: f32) void;
pub fn scale(ctx: ?*NVGcontext, x: f32, y: f32) void {
    return nvgScale(ctx, x, y);
}

extern fn nvgCurrentTransform(ctx: ?*NVGcontext, xform: [*c]f32) void;
pub fn currentTransform(ctx: ?*NVGcontext, xform: [*c]f32) void {
    return nvgCurrentTransform(ctx, xform);
}

extern fn nvgTransformIdentity(dst: [*c]f32) void;
pub fn transformIdentity(dst: [*c]f32) void {
    return nvgTransformIdentity(dst);
}

extern fn nvgTransformTranslate(dst: [*c]f32, tx: f32, ty: f32) void;
pub fn transformTranslate(dst: [*c]f32, tx: f32, ty: f32) void {
    return nvgTransformTranslate(dst, tx, ty);
}

extern fn nvgTransformScale(dst: [*c]f32, sx: f32, sy: f32) void;
pub fn transformScale(dst: [*c]f32, sx: f32, sy: f32) void {
    return nvgTransformScale(dst, sx, sy);
}

extern fn nvgTransformRotate(dst: [*c]f32, a: f32) void;
pub fn transformRotate(dst: [*c]f32, a: f32) void {
    return nvgTransformRotate(dst, a);
}

extern fn nvgTransformSkewX(dst: [*c]f32, a: f32) void;
pub fn transformSkewX(dst: [*c]f32, a: f32) void {
    return nvgTransformSkewX(dst, a);
}

extern fn nvgTransformSkewY(dst: [*c]f32, a: f32) void;
pub fn transformSkewY(dst: [*c]f32, a: f32) void {
    return nvgTransformSkewY(dst, a);
}

extern fn nvgTransformMultiply(dst: [*c]f32, src: [*c]const f32) void;
pub fn transformMultiply(dst: [*c]f32, src: [*c]const f32) void {
    return nvgTransformMultiply(dst, src);
}

extern fn nvgTransformPremultiply(dst: [*c]f32, src: [*c]const f32) void;
pub fn transformPremultiply(dst: [*c]f32, src: [*c]const f32) void {
    return nvgTransformPremultiply(dst, src);
}

extern fn nvgTransformInverse(dst: [*c]f32, src: [*c]const f32) c_int;
pub fn transformInverse(dst: [*c]f32, src: [*c]const f32) c_int {
    return nvgTransformInverse(dst, src);
}

extern fn nvgTransformPoint(dstx: [*c]f32, dsty: [*c]f32, xform: [*c]const f32, srcx: f32, srcy: f32) void;
pub fn transformPoint(dstx: [*c]f32, dsty: [*c]f32, xform: [*c]const f32, srcx: f32, srcy: f32) void {
    return nvgTransformPoint(dstx, dsty, xform, srcx, srcy);
}

extern fn nvgDegToRad(deg: f32) f32;
pub fn degToRad(deg: f32) f32 {
    return nvgDegToRad(deg);
}

extern fn nvgRadToDeg(rad: f32) f32;
pub fn radToDeg(rad: f32) f32 {
    return nvgRadToDeg(rad);
}

extern fn nvgCreateImage(ctx: ?*NVGcontext, filename: [*c]const u8, imageFlags: c_int) c_int;
pub fn createImage(ctx: ?*NVGcontext, filename: [*c]const u8, imageFlags: c_int) c_int {
    return nvgCreateImage(ctx, filename, imageFlags);
}

extern fn nvgCreateImageMem(ctx: ?*NVGcontext, imageFlags: c_int, data: [*c]u8, ndata: c_int) c_int;
pub fn createImageMem(ctx: ?*NVGcontext, imageFlags: c_int, data: [*c]u8, ndata: c_int) c_int {
    return nvgCreateImageMem(ctx, imageFlags, data, ndata);
}

extern fn nvgCreateImageRGBA(ctx: ?*NVGcontext, w: c_int, h: c_int, imageFlags: c_int, data: [*c]const u8) c_int;
pub fn createImageRGBA(ctx: ?*NVGcontext, w: c_int, h: c_int, imageFlags: c_int, data: [*c]const u8) c_int {
    return nvgCreateImageRGBA(ctx, w, h, imageFlags, data);
}

extern fn nvgUpdateImage(ctx: ?*NVGcontext, image: c_int, data: [*c]const u8) void;
pub fn updateImage(ctx: ?*NVGcontext, image: c_int, data: [*c]const u8) void {
    return nvgUpdateImage(ctx, image, data);
}

extern fn nvgImageSize(ctx: ?*NVGcontext, image: c_int, w: [*c]c_int, h: [*c]c_int) void;
pub fn imageSize(ctx: ?*NVGcontext, image: c_int, w: [*c]c_int, h: [*c]c_int) void {
    return nvgImageSize(ctx, image, w, h);
}

extern fn nvgDeleteImage(ctx: ?*NVGcontext, image: c_int) void;
pub fn deleteImage(ctx: ?*NVGcontext, image: c_int) void {
    return nvgDeleteImage(ctx, image);
}

extern fn nvgLinearGradient(ctx: ?*NVGcontext, sx: f32, sy: f32, ex: f32, ey: f32, icol: NVGcolor, ocol: NVGcolor) NVGpaint;
pub fn linearGradient(ctx: ?*NVGcontext, sx: f32, sy: f32, ex: f32, ey: f32, icol: NVGcolor, ocol: NVGcolor) NVGpaint {
    return nvgLinearGradient(ctx, sx, sy, ex, ey, icol, ocol);
}

extern fn nvgBoxGradient(ctx: ?*NVGcontext, x: f32, y: f32, w: f32, h: f32, r: f32, f: f32, icol: NVGcolor, ocol: NVGcolor) NVGpaint;
pub fn boxGradient(ctx: ?*NVGcontext, x: f32, y: f32, w: f32, h: f32, r: f32, f: f32, icol: NVGcolor, ocol: NVGcolor) NVGpaint {
    return nvgBoxGradient(ctx, x, y, w, h, r, f, icol, ocol);
}

extern fn nvgRadialGradient(ctx: ?*NVGcontext, cx: f32, cy: f32, inr: f32, outr: f32, icol: NVGcolor, ocol: NVGcolor) NVGpaint;
pub fn radialGradient(ctx: ?*NVGcontext, cx: f32, cy: f32, inr: f32, outr: f32, icol: NVGcolor, ocol: NVGcolor) NVGpaint {
    return nvgRadialGradient(ctx, cx, cy, inr, outr, icol, ocol);
}

extern fn nvgImagePattern(ctx: ?*NVGcontext, ox: f32, oy: f32, ex: f32, ey: f32, angle: f32, image: c_int, alpha: f32) NVGpaint;
pub fn imagePattern(ctx: ?*NVGcontext, ox: f32, oy: f32, ex: f32, ey: f32, angle: f32, image: c_int, alpha: f32) NVGpaint {
    return nvgImagePattern(ctx, ox, oy, ex, ey, angle, image, alpha);
}

extern fn nvgScissor(ctx: ?*NVGcontext, x: f32, y: f32, w: f32, h: f32) void;
pub fn scissor(ctx: ?*NVGcontext, x: f32, y: f32, w: f32, h: f32) void {
    return nvgScissor(ctx, x, y, w, h);
}

extern fn nvgIntersectScissor(ctx: ?*NVGcontext, x: f32, y: f32, w: f32, h: f32) void;
pub fn intersectScissor(ctx: ?*NVGcontext, x: f32, y: f32, w: f32, h: f32) void {
    return nvgIntersectScissor(ctx, x, y, w, h);
}

extern fn nvgResetScissor(ctx: ?*NVGcontext) void;
pub fn resetScissor(ctx: ?*NVGcontext) void {
    return nvgResetScissor(ctx);
}

extern fn nvgBeginPath(ctx: ?*NVGcontext) void;
pub fn beginPath(ctx: ?*NVGcontext) void {
    return nvgBeginPath(ctx);
}

extern fn nvgMoveTo(ctx: ?*NVGcontext, x: f32, y: f32) void;
pub fn moveTo(ctx: ?*NVGcontext, x: f32, y: f32) void {
    return nvgMoveTo(ctx, x, y);
}

extern fn nvgLineTo(ctx: ?*NVGcontext, x: f32, y: f32) void;
pub fn lineTo(ctx: ?*NVGcontext, x: f32, y: f32) void {
    return nvgLineTo(ctx, x, y);
}

extern fn nvgBezierTo(ctx: ?*NVGcontext, c1x: f32, c1y: f32, c2x: f32, c2y: f32, x: f32, y: f32) void;
pub fn bezierTo(ctx: ?*NVGcontext, c1x: f32, c1y: f32, c2x: f32, c2y: f32, x: f32, y: f32) void {
    return nvgBezierTo(ctx, c1x, c1y, c2x, c2y, x, y);
}

extern fn nvgQuadTo(ctx: ?*NVGcontext, cx: f32, cy: f32, x: f32, y: f32) void;
pub fn quadTo(ctx: ?*NVGcontext, cx: f32, cy: f32, x: f32, y: f32) void {
    return nvgQuadTo(ctx, cx, cy, x, y);
}

extern fn nvgArcTo(ctx: ?*NVGcontext, x1: f32, y1: f32, x2: f32, y2: f32, radius: f32) void;
pub fn arcTo(ctx: ?*NVGcontext, x1: f32, y1: f32, x2: f32, y2: f32, radius: f32) void {
    return nvgArcTo(ctx, x1, y1, x2, y2, radius);
}

extern fn nvgClosePath(ctx: ?*NVGcontext) void;
pub fn closePath(ctx: ?*NVGcontext) void {
    return nvgClosePath(ctx);
}

extern fn nvgPathWinding(ctx: ?*NVGcontext, dir: c_int) void;
pub fn pathWinding(ctx: ?*NVGcontext, dir: c_int) void {
    return nvgPathWinding(ctx, dir);
}

extern fn nvgArc(ctx: ?*NVGcontext, cx: f32, cy: f32, r: f32, a0: f32, a1: f32, dir: c_int) void;
pub fn arc(ctx: ?*NVGcontext, cx: f32, cy: f32, r: f32, a0: f32, a1: f32, dir: c_int) void {
    return nvgArc(ctx, cx, cy, r, a0, a1, dir);
}

extern fn nvgRect(ctx: ?*NVGcontext, x: f32, y: f32, w: f32, h: f32) void;
pub fn rect(ctx: ?*NVGcontext, x: f32, y: f32, w: f32, h: f32) void {
    return nvgRect(ctx, x, y, w, h);
}

extern fn nvgRoundedRect(ctx: ?*NVGcontext, x: f32, y: f32, w: f32, h: f32, r: f32) void;
pub fn roundedRect(ctx: ?*NVGcontext, x: f32, y: f32, w: f32, h: f32, r: f32) void {
    return nvgRoundedRect(ctx, x, y, w, h, r);
}

extern fn nvgRoundedRectVarying(ctx: ?*NVGcontext, x: f32, y: f32, w: f32, h: f32, radTopLeft: f32, radTopRight: f32, radBottomRight: f32, radBottomLeft: f32) void;
pub fn roundedRectVarying(ctx: ?*NVGcontext, x: f32, y: f32, w: f32, h: f32, radTopLeft: f32, radTopRight: f32, radBottomRight: f32, radBottomLeft: f32) void {
    return nvgRoundedRectVarying(ctx, x, y, w, h, radTopLeft, radTopRight, radBottomRight, radBottomLeft);
}

extern fn nvgEllipse(ctx: ?*NVGcontext, cx: f32, cy: f32, rx: f32, ry: f32) void;
pub fn ellipse(ctx: ?*NVGcontext, cx: f32, cy: f32, rx: f32, ry: f32) void {
    return nvgEllipse(ctx, cx, cy, rx, ry);
}

extern fn nvgCircle(ctx: ?*NVGcontext, cx: f32, cy: f32, r: f32) void;
pub fn circle(ctx: ?*NVGcontext, cx: f32, cy: f32, r: f32) void {
    return nvgCircle(ctx, cx, cy, r);
}

extern fn nvgFill(ctx: ?*NVGcontext) void;
pub fn fill(ctx: ?*NVGcontext) void {
    return nvgFill(ctx);
}

extern fn nvgStroke(ctx: ?*NVGcontext) void;
pub fn stroke(ctx: ?*NVGcontext) void {
    return nvgStroke(ctx);
}

extern fn nvgCreateFont(ctx: ?*NVGcontext, name: [*c]const u8, filename: [*c]const u8) c_int;
pub fn createFont(ctx: ?*NVGcontext, name: [*c]const u8, filename: [*c]const u8) c_int {
    return nvgCreateFont(ctx, name, filename);
}

extern fn nvgCreateFontAtIndex(ctx: ?*NVGcontext, name: [*c]const u8, filename: [*c]const u8, fontIndex: c_int) c_int;
pub fn createFontAtIndex(ctx: ?*NVGcontext, name: [*c]const u8, filename: [*c]const u8, fontIndex: c_int) c_int {
    return nvgCreateFontAtIndex(ctx, name, filename, fontIndex);
}

extern fn nvgCreateFontMem(ctx: ?*NVGcontext, name: [*c]const u8, data: [*c]u8, ndata: c_int, freeData: c_int) c_int;
pub fn createFontMem(ctx: ?*NVGcontext, name: [*c]const u8, data: [*c]u8, ndata: c_int, freeData: c_int) c_int {
    return nvgCreateFontMem(ctx, name, data, ndata, freeData);
}

extern fn nvgCreateFontMemAtIndex(ctx: ?*NVGcontext, name: [*c]const u8, data: [*c]u8, ndata: c_int, freeData: c_int, fontIndex: c_int) c_int;
pub fn createFontMemAtIndex(ctx: ?*NVGcontext, name: [*c]const u8, data: [*c]u8, ndata: c_int, freeData: c_int, fontIndex: c_int) c_int {
    return nvgCreateFontMemAtIndex(ctx, name, data, ndata, freeData, fontIndex);
}

extern fn nvgFindFont(ctx: ?*NVGcontext, name: [*c]const u8) c_int;
pub fn findFont(ctx: ?*NVGcontext, name: [*c]const u8) c_int {
    return nvgFindFont(ctx, name);
}

extern fn nvgAddFallbackFontId(ctx: ?*NVGcontext, baseFont: c_int, fallbackFont: c_int) c_int;
pub fn addFallbackFontId(ctx: ?*NVGcontext, baseFont: c_int, fallbackFont: c_int) c_int {
    return nvgAddFallbackFontId(ctx, baseFont, fallbackFont);
}

extern fn nvgAddFallbackFont(ctx: ?*NVGcontext, baseFont: [*c]const u8, fallbackFont: [*c]const u8) c_int;
pub fn addFallbackFont(ctx: ?*NVGcontext, baseFont: [*c]const u8, fallbackFont: [*c]const u8) c_int {
    return nvgAddFallbackFont(ctx, baseFont, fallbackFont);
}

extern fn nvgResetFallbackFontsId(ctx: ?*NVGcontext, baseFont: c_int) void;
pub fn resetFallbackFontsId(ctx: ?*NVGcontext, baseFont: c_int) void {
    return nvgResetFallbackFontsId(ctx, baseFont);
}

extern fn nvgResetFallbackFonts(ctx: ?*NVGcontext, baseFont: [*c]const u8) void;
pub fn resetFallbackFonts(ctx: ?*NVGcontext, baseFont: [*c]const u8) void {
    return nvgResetFallbackFonts(ctx, baseFont);
}

extern fn nvgFontSize(ctx: ?*NVGcontext, size: f32) void;
pub fn fontSize(ctx: ?*NVGcontext, size: f32) void {
    return nvgFontSize(ctx, size);
}

extern fn nvgFontBlur(ctx: ?*NVGcontext, blur: f32) void;
pub fn fontBlur(ctx: ?*NVGcontext, blur: f32) void {
    return nvgFontBlur(ctx, blur);
}

extern fn nvgTextLetterSpacing(ctx: ?*NVGcontext, spacing: f32) void;
pub fn textLetterSpacing(ctx: ?*NVGcontext, spacing: f32) void {
    return nvgTextLetterSpacing(ctx, spacing);
}

extern fn nvgTextLineHeight(ctx: ?*NVGcontext, lineHeight: f32) void;
pub fn textLineHeight(ctx: ?*NVGcontext, lineHeight: f32) void {
    return nvgTextLineHeight(ctx, lineHeight);
}

extern fn nvgTextAlign(ctx: ?*NVGcontext, @"align": c_int) void;
pub fn textAlign(ctx: ?*NVGcontext, @"align": c_int) void {
    return nvgTextAlign(ctx, @"align");
}

extern fn nvgFontFaceId(ctx: ?*NVGcontext, font: c_int) void;
pub fn fontFaceId(ctx: ?*NVGcontext, font: c_int) void {
    return nvgFontFaceId(ctx, font);
}

extern fn nvgFontFace(ctx: ?*NVGcontext, font: [*c]const u8) void;
pub fn fontFace(ctx: ?*NVGcontext, font: [*c]const u8) void {
    return nvgFontFace(ctx, font);
}

extern fn nvgText(ctx: ?*NVGcontext, x: f32, y: f32, string: [*c]const u8, end: [*c]const u8) f32;
pub fn text(ctx: ?*NVGcontext, x: f32, y: f32, string: [*c]const u8, end: [*c]const u8) f32 {
    return nvgText(ctx, x, y, string, end);
}

extern fn nvgTextBox(ctx: ?*NVGcontext, x: f32, y: f32, breakRowWidth: f32, string: [*c]const u8, end: [*c]const u8) void;
pub fn textBox(ctx: ?*NVGcontext, x: f32, y: f32, breakRowWidth: f32, string: [*c]const u8, end: [*c]const u8) void {
    return nvgTextBox(ctx, x, y, breakRowWidth, string, end);
}

extern fn nvgTextBounds(ctx: ?*NVGcontext, x: f32, y: f32, string: [*c]const u8, end: [*c]const u8, bounds: [*c]f32) f32;
pub fn textBounds(ctx: ?*NVGcontext, x: f32, y: f32, string: [*c]const u8, end: [*c]const u8, bounds: [*c]f32) f32 {
    return nvgTextBounds(ctx, x, y, string, end, bounds);
}

extern fn nvgTextBoxBounds(ctx: ?*NVGcontext, x: f32, y: f32, breakRowWidth: f32, string: [*c]const u8, end: [*c]const u8, bounds: [*c]f32) void;
pub fn textBoxBounds(ctx: ?*NVGcontext, x: f32, y: f32, breakRowWidth: f32, string: [*c]const u8, end: [*c]const u8, bounds: [*c]f32) void {
    return nvgTextBoxBounds(ctx, x, y, breakRowWidth, string, end, bounds);
}

extern fn nvgTextGlyphPositions(ctx: ?*NVGcontext, x: f32, y: f32, string: [*c]const u8, end: [*c]const u8, positions: [*c]NVGglyphPosition, maxPositions: c_int) c_int;
pub fn textGlyphPositions(ctx: ?*NVGcontext, x: f32, y: f32, string: [*c]const u8, end: [*c]const u8, positions: [*c]NVGglyphPosition, maxPositions: c_int) c_int {
    return nvgTextGlyphPositions(ctx, x, y, string, end, positions, maxPositions);
}

extern fn nvgTextMetrics(ctx: ?*NVGcontext, ascender: [*c]f32, descender: [*c]f32, lineh: [*c]f32) void;
pub fn textMetrics(ctx: ?*NVGcontext, ascender: [*c]f32, descender: [*c]f32, lineh: [*c]f32) void {
    return nvgTextMetrics(ctx, ascender, descender, lineh);
}

extern fn nvgTextBreakLines(ctx: ?*NVGcontext, string: [*c]const u8, end: [*c]const u8, breakRowWidth: f32, rows: [*c]NVGtextRow, maxRows: c_int) c_int;
pub fn textBreakLines(ctx: ?*NVGcontext, string: [*c]const u8, end: [*c]const u8, breakRowWidth: f32, rows: [*c]NVGtextRow, maxRows: c_int) c_int {
    return nvgTextBreakLines(ctx, string, end, breakRowWidth, rows, maxRows);
}
pub const NVG_TEXTURE_ALPHA: c_int = 1;
pub const NVG_TEXTURE_RGBA: c_int = 2;
pub const enum_NVGtexture = c_uint;
pub const struct_NVGscissor = extern struct {
    xform: [6]f32,
    extent: [2]f32,
};
pub const NVGscissor = struct_NVGscissor;
pub const struct_NVGvertex = extern struct {
    x: f32,
    y: f32,
    u: f32,
    v: f32,
};
pub const NVGvertex = struct_NVGvertex;
pub const struct_NVGpath = extern struct {
    first: c_int,
    count: c_int,
    closed: u8,
    nbevel: c_int,
    fill: [*c]NVGvertex,
    nfill: c_int,
    stroke: [*c]NVGvertex,
    nstroke: c_int,
    winding: c_int,
    convex: c_int,
};
pub const NVGpath = struct_NVGpath;
pub const struct_NVGparams = extern struct {
    userPtr: ?*c_void,
    edgeAntiAlias: c_int,
    renderCreate: ?fn (?*c_void) callconv(.C) c_int,
    renderCreateTexture: ?fn (?*c_void, c_int, c_int, c_int, c_int, [*c]const u8) callconv(.C) c_int,
    renderDeleteTexture: ?fn (?*c_void, c_int) callconv(.C) c_int,
    renderUpdateTexture: ?fn (?*c_void, c_int, c_int, c_int, c_int, c_int, [*c]const u8) callconv(.C) c_int,
    renderGetTextureSize: ?fn (?*c_void, c_int, [*c]c_int, [*c]c_int) callconv(.C) c_int,
    renderViewport: ?fn (?*c_void, f32, f32, f32) callconv(.C) void,
    renderCancel: ?fn (?*c_void) callconv(.C) void,
    renderFlush: ?fn (?*c_void) callconv(.C) void,
    renderFill: ?fn (?*c_void, [*c]NVGpaint, NVGcompositeOperationState, [*c]NVGscissor, f32, [*c]const f32, [*c]const NVGpath, c_int) callconv(.C) void,
    renderStroke: ?fn (?*c_void, [*c]NVGpaint, NVGcompositeOperationState, [*c]NVGscissor, f32, f32, [*c]const NVGpath, c_int) callconv(.C) void,
    renderTriangles: ?fn (?*c_void, [*c]NVGpaint, NVGcompositeOperationState, [*c]NVGscissor, [*c]const NVGvertex, c_int, f32) callconv(.C) void,
    renderDelete: ?fn (?*c_void) callconv(.C) void,
};
pub const NVGparams = struct_NVGparams;

extern fn nvgCreateInternal(params: [*c]NVGparams) ?*NVGcontext;
pub fn createInternal(params: [*c]NVGparams) ?*NVGcontext {
    return nvgCreateInternal(params);
}

extern fn nvgDeleteInternal(ctx: ?*NVGcontext) void;
pub fn deleteInternal(ctx: ?*NVGcontext) void {
    return nvgDeleteInternal(ctx);
}

extern fn nvgInternalParams(ctx: ?*NVGcontext) [*c]NVGparams;
pub fn internalParams(ctx: ?*NVGcontext) [*c]NVGparams {
    return nvgInternalParams(ctx);
}

extern fn nvgDebugDumpPathCache(ctx: ?*NVGcontext) void;
pub fn debugDumpPathCache(ctx: ?*NVGcontext) void {
    return nvgDebugDumpPathCache(ctx);
}
