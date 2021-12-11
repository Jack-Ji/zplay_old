pub const NSVG_PAINT_NONE: c_int = 0;
pub const NSVG_PAINT_COLOR: c_int = 1;
pub const NSVG_PAINT_LINEAR_GRADIENT: c_int = 2;
pub const NSVG_PAINT_RADIAL_GRADIENT: c_int = 3;
pub const enum_NSVGpaintType = c_uint;
pub const NSVG_SPREAD_PAD: c_int = 0;
pub const NSVG_SPREAD_REFLECT: c_int = 1;
pub const NSVG_SPREAD_REPEAT: c_int = 2;
pub const enum_NSVGspreadType = c_uint;
pub const NSVG_JOIN_MITER: c_int = 0;
pub const NSVG_JOIN_ROUND: c_int = 1;
pub const NSVG_JOIN_BEVEL: c_int = 2;
pub const enum_NSVGlineJoin = c_uint;
pub const NSVG_CAP_BUTT: c_int = 0;
pub const NSVG_CAP_ROUND: c_int = 1;
pub const NSVG_CAP_SQUARE: c_int = 2;
pub const enum_NSVGlineCap = c_uint;
pub const NSVG_FILLRULE_NONZERO: c_int = 0;
pub const NSVG_FILLRULE_EVENODD: c_int = 1;
pub const enum_NSVGfillRule = c_uint;
pub const NSVG_FLAGS_VISIBLE: c_int = 1;
pub const enum_NSVGflags = c_uint;
pub const NSVGpaintType = enum_NSVGpaintType;
pub const NSVGspreadType = enum_NSVGspreadType;
pub const NSVGlineJoin = enum_NSVGlineJoin;
pub const NSVGlineCap = enum_NSVGlineCap;
pub const NSVGfillRule = enum_NSVGfillRule;
pub const NSVGflags = enum_NSVGflags;
pub const struct_NSVGgradientStop = extern struct {
    color: c_uint,
    offset: f32,
};
pub const NSVGgradientStop = struct_NSVGgradientStop;
pub const struct_NSVGgradient = extern struct {
    xform: [6]f32,
    spread: u8,
    fx: f32,
    fy: f32,
    nstops: c_int,
    stops: [*c]NSVGgradientStop,
};
pub const NSVGgradient = struct_NSVGgradient;
const union_unnamed_1 = extern union {
    color: c_uint,
    gradient: [*c]NSVGgradient,
};
pub const struct_NSVGpaint = extern struct {
    type: u8,
    unnamed_0: union_unnamed_1,
};
pub const NSVGpaint = struct_NSVGpaint;
pub const struct_NSVGpath = extern struct {
    pts: [*c]f32,
    npts: c_int,
    closed: u8,
    bounds: [4]f32,
    next: [*c]struct_NSVGpath,
};
pub const NSVGpath = struct_NSVGpath;
pub const struct_NSVGshape = extern struct {
    id: [64]u8,
    fill: NSVGpaint,
    stroke: NSVGpaint,
    opacity: f32,
    strokeWidth: f32,
    strokeDashOffset: f32,
    strokeDashArray: [8]f32,
    strokeDashCount: u8,
    strokeLineJoin: u8,
    strokeLineCap: u8,
    miterLimit: f32,
    fillRule: u8,
    flags: u8,
    bounds: [4]f32,
    paths: [*c]NSVGpath,
    next: [*c]struct_NSVGshape,
};
pub const NSVGshape = struct_NSVGshape;
pub const struct_NSVGimage = extern struct {
    width: f32,
    height: f32,
    shapes: [*c]NSVGshape,
};
pub const NSVGimage = struct_NSVGimage;
pub extern fn nsvgParseFromFile(filename: [*c]const u8, units: [*c]const u8, dpi: f32) [*c]NSVGimage;
pub extern fn nsvgParse(input: [*c]u8, units: [*c]const u8, dpi: f32) [*c]NSVGimage;
pub extern fn nsvgDuplicatePath(p: [*c]NSVGpath) [*c]NSVGpath;
pub extern fn nsvgDelete(image: [*c]NSVGimage) void;
