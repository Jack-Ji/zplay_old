const imgui = @import("../../imgui.zig");
pub const __time_t = c_long;
pub const time_t = __time_t;
pub const struct_tm = extern struct {
    tm_sec: c_int,
    tm_min: c_int,
    tm_hour: c_int,
    tm_mday: c_int,
    tm_mon: c_int,
    tm_year: c_int,
    tm_wday: c_int,
    tm_yday: c_int,
    tm_isdst: c_int,
    tm_gmtoff: c_long,
    tm_zone: [*c]const u8,
};
pub const tm = struct_tm;
pub const ImPlotMarker = c_int;
pub const struct_ImPlotNextItemData = extern struct {
    Colors: [5]imgui.ImVec4,
    LineWeight: f32,
    Marker: ImPlotMarker,
    MarkerSize: f32,
    MarkerWeight: f32,
    FillAlpha: f32,
    ErrorBarSize: f32,
    ErrorBarWeight: f32,
    DigitalBitHeight: f32,
    DigitalBitGap: f32,
    RenderLine: bool,
    RenderFill: bool,
    RenderMarkerLine: bool,
    RenderMarkerFill: bool,
    HasHidden: bool,
    Hidden: bool,
    HiddenCond: imgui.ImGuiCond,
};
pub const ImPlotNextItemData = struct_ImPlotNextItemData;
pub const ImPlotSubplotFlags = c_int;
pub const struct_ImVector_int = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]c_int,
};
pub const ImVector_int = struct_ImVector_int;
pub const ImPlotLocation = c_int;
pub const ImPlotOrientation = c_int;
pub const struct_ImPlotLegendData = extern struct {
    Indices: ImVector_int,
    Labels: imgui.ImGuiTextBuffer,
    Hovered: bool,
    Outside: bool,
    CanGoInside: bool,
    FlipSideNextFrame: bool,
    Location: ImPlotLocation,
    Orientation: ImPlotOrientation,
    Rect: imgui.ImRect,
};
pub const ImPlotLegendData = struct_ImPlotLegendData;
pub const struct_ImPlotItem = extern struct {
    ID: imgui.ImGuiID,
    Color: imgui.ImU32,
    NameOffset: c_int,
    Show: bool,
    LegendHovered: bool,
    SeenThisFrame: bool,
};
pub const ImPlotItem = struct_ImPlotItem;
pub const struct_ImVector_ImPlotItem = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]ImPlotItem,
};
pub const ImVector_ImPlotItem = struct_ImVector_ImPlotItem;
pub const struct_ImPool_ImPlotItem = extern struct {
    Buf: ImVector_ImPlotItem,
    Map: imgui.ImGuiStorage,
    FreeIdx: imgui.ImPoolIdx,
};
pub const ImPool_ImPlotItem = struct_ImPool_ImPlotItem;
pub const struct_ImPlotItemGroup = extern struct {
    ID: imgui.ImGuiID,
    Legend: ImPlotLegendData,
    ItemPool: ImPool_ImPlotItem,
    ColormapIdx: c_int,
};
pub const ImPlotItemGroup = struct_ImPlotItemGroup;
pub const struct_ImPlotAlignmentData = extern struct {
    Orientation: ImPlotOrientation,
    PadA: f32,
    PadB: f32,
    PadAMax: f32,
    PadBMax: f32,
};
pub const ImPlotAlignmentData = struct_ImPlotAlignmentData;
pub const struct_ImVector_ImPlotAlignmentData = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]ImPlotAlignmentData,
};
pub const ImVector_ImPlotAlignmentData = struct_ImVector_ImPlotAlignmentData;
pub const struct_ImPlotRange = extern struct {
    Min: f64,
    Max: f64,
};
pub const ImPlotRange = struct_ImPlotRange;
pub const struct_ImVector_ImPlotRange = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]ImPlotRange,
};
pub const ImVector_ImPlotRange = struct_ImVector_ImPlotRange;
pub const struct_ImPlotSubplot = extern struct {
    ID: imgui.ImGuiID,
    Flags: ImPlotSubplotFlags,
    PreviousFlags: ImPlotSubplotFlags,
    Items: ImPlotItemGroup,
    Rows: c_int,
    Cols: c_int,
    CurrentIdx: c_int,
    FrameRect: imgui.ImRect,
    GridRect: imgui.ImRect,
    CellSize: imgui.ImVec2,
    RowAlignmentData: ImVector_ImPlotAlignmentData,
    ColAlignmentData: ImVector_ImPlotAlignmentData,
    RowRatios: imgui.ImVector_float,
    ColRatios: imgui.ImVector_float,
    RowLinkData: ImVector_ImPlotRange,
    ColLinkData: ImVector_ImPlotRange,
    TempSizes: [2]f32,
    FrameHovered: bool,
};
pub const ImPlotSubplot = struct_ImPlotSubplot;
pub const struct_ImPlotTick = extern struct {
    PlotPos: f64,
    PixelPos: f32,
    LabelSize: imgui.ImVec2,
    TextOffset: c_int,
    Major: bool,
    ShowLabel: bool,
    Level: c_int,
};
pub const ImPlotTick = struct_ImPlotTick;
pub const struct_ImVector_ImPlotTick = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]ImPlotTick,
};
pub const ImVector_ImPlotTick = struct_ImVector_ImPlotTick;
pub const struct_ImPlotTickCollection = extern struct {
    Ticks: ImVector_ImPlotTick,
    TextBuffer: imgui.ImGuiTextBuffer,
    TotalWidthMax: f32,
    TotalWidth: f32,
    TotalHeight: f32,
    MaxWidth: f32,
    MaxHeight: f32,
    Size: c_int,
};
pub const ImPlotTickCollection = struct_ImPlotTickCollection;
pub const struct_ImPlotAnnotation = extern struct {
    Pos: imgui.ImVec2,
    Offset: imgui.ImVec2,
    ColorBg: imgui.ImU32,
    ColorFg: imgui.ImU32,
    TextOffset: c_int,
    Clamp: bool,
};
pub const ImPlotAnnotation = struct_ImPlotAnnotation;
pub const struct_ImVector_ImPlotAnnotation = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]ImPlotAnnotation,
};
pub const ImVector_ImPlotAnnotation = struct_ImVector_ImPlotAnnotation;
pub const struct_ImPlotAnnotationCollection = extern struct {
    Annotations: ImVector_ImPlotAnnotation,
    TextBuffer: imgui.ImGuiTextBuffer,
    Size: c_int,
};
pub const ImPlotAnnotationCollection = struct_ImPlotAnnotationCollection;
pub const struct_ImPlotPointError = extern struct {
    X: f64,
    Y: f64,
    Neg: f64,
    Pos: f64,
};
pub const ImPlotPointError = struct_ImPlotPointError;
pub const struct_ImVector_bool = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]bool,
};
pub const ImVector_bool = struct_ImVector_bool;
pub const struct_ImPlotColormapData = extern struct {
    Keys: imgui.ImVector_ImU32,
    KeyCounts: ImVector_int,
    KeyOffsets: ImVector_int,
    Tables: imgui.ImVector_ImU32,
    TableSizes: ImVector_int,
    TableOffsets: ImVector_int,
    Text: imgui.ImGuiTextBuffer,
    TextOffsets: ImVector_int,
    Quals: ImVector_bool,
    Map: imgui.ImGuiStorage,
    Count: c_int,
};
pub const ImPlotColormapData = struct_ImPlotColormapData;
pub const struct_ImPlotTime = extern struct {
    S: time_t,
    Us: c_int,
};
pub const ImPlotTime = struct_ImPlotTime;
pub const ImPlotDateFmt = c_int;
pub const ImPlotTimeFmt = c_int;
pub const struct_ImPlotDateTimeFmt = extern struct {
    Date: ImPlotDateFmt,
    Time: ImPlotTimeFmt,
    UseISO8601: bool,
    Use24HourClock: bool,
};
pub const ImPlotDateTimeFmt = struct_ImPlotDateTimeFmt;
pub const struct_ImPlotInputMap = extern struct {
    PanButton: imgui.ImGuiMouseButton,
    PanMod: imgui.ImGuiKeyModFlags,
    FitButton: imgui.ImGuiMouseButton,
    ContextMenuButton: imgui.ImGuiMouseButton,
    BoxSelectButton: imgui.ImGuiMouseButton,
    BoxSelectMod: imgui.ImGuiKeyModFlags,
    BoxSelectCancelButton: imgui.ImGuiMouseButton,
    QueryButton: imgui.ImGuiMouseButton,
    QueryMod: imgui.ImGuiKeyModFlags,
    QueryToggleMod: imgui.ImGuiKeyModFlags,
    HorizontalMod: imgui.ImGuiKeyModFlags,
    VerticalMod: imgui.ImGuiKeyModFlags,
};
pub const ImPlotInputMap = struct_ImPlotInputMap;
pub const struct_ImBufferWriter = extern struct {
    Buffer: [*c]u8,
    Size: c_int,
    Pos: c_int,
};
pub const ImBufferWriter = struct_ImBufferWriter;
pub const struct_ImPlotNextPlotData = extern struct {
    XRangeCond: imgui.ImGuiCond,
    YRangeCond: [3]imgui.ImGuiCond,
    XRange: ImPlotRange,
    YRange: [3]ImPlotRange,
    HasXRange: bool,
    HasYRange: [3]bool,
    ShowDefaultTicksX: bool,
    ShowDefaultTicksY: [3]bool,
    FmtX: [16]u8,
    FmtY: [3][16]u8,
    HasFmtX: bool,
    HasFmtY: [3]bool,
    FitX: bool,
    FitY: [3]bool,
    LinkedXmin: [*c]f64,
    LinkedXmax: [*c]f64,
    LinkedYmin: [3][*c]f64,
    LinkedYmax: [3][*c]f64,
};
pub const ImPlotNextPlotData = struct_ImPlotNextPlotData;
pub const ImPlotFlags = c_int;
pub const ImPlotAxisFlags = c_int;
pub const struct_ImPlotAxis = extern struct {
    Flags: ImPlotAxisFlags,
    PreviousFlags: ImPlotAxisFlags,
    Range: ImPlotRange,
    Pixels: f32,
    Orientation: ImPlotOrientation,
    Dragging: bool,
    ExtHovered: bool,
    AllHovered: bool,
    Present: bool,
    HasRange: bool,
    LinkedMin: [*c]f64,
    LinkedMax: [*c]f64,
    PickerTimeMin: ImPlotTime,
    PickerTimeMax: ImPlotTime,
    PickerLevel: c_int,
    ColorMaj: imgui.ImU32,
    ColorMin: imgui.ImU32,
    ColorTxt: imgui.ImU32,
    RangeCond: imgui.ImGuiCond,
    HoverRect: imgui.ImRect,
};
pub const ImPlotAxis = struct_ImPlotAxis;
pub const struct_ImPlotPlot = extern struct {
    ID: imgui.ImGuiID,
    Flags: ImPlotFlags,
    PreviousFlags: ImPlotFlags,
    XAxis: ImPlotAxis,
    YAxis: [3]ImPlotAxis,
    Items: ImPlotItemGroup,
    SelectStart: imgui.ImVec2,
    SelectRect: imgui.ImRect,
    QueryStart: imgui.ImVec2,
    QueryRect: imgui.ImRect,
    Initialized: bool,
    Selecting: bool,
    Selected: bool,
    ContextLocked: bool,
    Querying: bool,
    Queried: bool,
    DraggingQuery: bool,
    FrameHovered: bool,
    FrameHeld: bool,
    PlotHovered: bool,
    CurrentYAxis: c_int,
    MousePosLocation: ImPlotLocation,
    FrameRect: imgui.ImRect,
    CanvasRect: imgui.ImRect,
    PlotRect: imgui.ImRect,
    AxesRect: imgui.ImRect,
};
pub const ImPlotPlot = struct_ImPlotPlot;
pub const struct_ImPlotAxisColor = opaque {};
pub const ImPlotAxisColor = struct_ImPlotAxisColor;
pub const ImPlotColormap = c_int;
pub const struct_ImPlotStyle = extern struct {
    LineWeight: f32,
    Marker: c_int,
    MarkerSize: f32,
    MarkerWeight: f32,
    FillAlpha: f32,
    ErrorBarSize: f32,
    ErrorBarWeight: f32,
    DigitalBitHeight: f32,
    DigitalBitGap: f32,
    PlotBorderSize: f32,
    MinorAlpha: f32,
    MajorTickLen: imgui.ImVec2,
    MinorTickLen: imgui.ImVec2,
    MajorTickSize: imgui.ImVec2,
    MinorTickSize: imgui.ImVec2,
    MajorGridSize: imgui.ImVec2,
    MinorGridSize: imgui.ImVec2,
    PlotPadding: imgui.ImVec2,
    LabelPadding: imgui.ImVec2,
    LegendPadding: imgui.ImVec2,
    LegendInnerPadding: imgui.ImVec2,
    LegendSpacing: imgui.ImVec2,
    MousePosPadding: imgui.ImVec2,
    AnnotationPadding: imgui.ImVec2,
    FitPadding: imgui.ImVec2,
    PlotDefaultSize: imgui.ImVec2,
    PlotMinSize: imgui.ImVec2,
    Colors: [24]imgui.ImVec4,
    Colormap: ImPlotColormap,
    AntiAliasedLines: bool,
    UseLocalTime: bool,
    UseISO8601: bool,
    Use24HourClock: bool,
};
pub const ImPlotStyle = struct_ImPlotStyle;
pub const struct_ImPlotLimits = extern struct {
    X: ImPlotRange,
    Y: ImPlotRange,
};
pub const ImPlotLimits = struct_ImPlotLimits;
pub const struct_ImPlotPoint = extern struct {
    x: f64,
    y: f64,
};
pub const ImPlotPoint = struct_ImPlotPoint;
pub const struct_ImVector_ImPlotPlot = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]ImPlotPlot,
};
pub const ImVector_ImPlotPlot = struct_ImVector_ImPlotPlot;
pub const struct_ImPool_ImPlotPlot = extern struct {
    Buf: ImVector_ImPlotPlot,
    Map: imgui.ImGuiStorage,
    FreeIdx: imgui.ImPoolIdx,
};
pub const ImPool_ImPlotPlot = struct_ImPool_ImPlotPlot;
pub const struct_ImVector_ImPlotSubplot = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]ImPlotSubplot,
};
pub const ImVector_ImPlotSubplot = struct_ImVector_ImPlotSubplot;
pub const struct_ImPool_ImPlotSubplot = extern struct {
    Buf: ImVector_ImPlotSubplot,
    Map: imgui.ImGuiStorage,
    FreeIdx: imgui.ImPoolIdx,
};
pub const ImPool_ImPlotSubplot = struct_ImPool_ImPlotSubplot;
pub const ImPlotScale = c_int;
pub const struct_ImVector_ImPlotColormap = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]ImPlotColormap,
};
pub const ImVector_ImPlotColormap = struct_ImVector_ImPlotColormap;
pub const struct_ImVector_double = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]f64,
};
pub const ImVector_double = struct_ImVector_double;
pub const struct_ImPool_ImPlotAlignmentData = extern struct {
    Buf: ImVector_ImPlotAlignmentData,
    Map: imgui.ImGuiStorage,
    FreeIdx: imgui.ImPoolIdx,
};
pub const ImPool_ImPlotAlignmentData = struct_ImPool_ImPlotAlignmentData;
pub const struct_ImPlotContext = extern struct {
    Plots: ImPool_ImPlotPlot,
    Subplots: ImPool_ImPlotSubplot,
    CurrentPlot: [*c]ImPlotPlot,
    CurrentSubplot: [*c]ImPlotSubplot,
    CurrentItems: [*c]ImPlotItemGroup,
    CurrentItem: [*c]ImPlotItem,
    PreviousItem: [*c]ImPlotItem,
    CTicks: ImPlotTickCollection,
    XTicks: ImPlotTickCollection,
    YTicks: [3]ImPlotTickCollection,
    YAxisReference: [3]f32,
    Annotations: ImPlotAnnotationCollection,
    Scales: [3]ImPlotScale,
    PixelRange: [3]imgui.ImRect,
    Mx: f64,
    My: [3]f64,
    LogDenX: f64,
    LogDenY: [3]f64,
    ExtentsX: ImPlotRange,
    ExtentsY: [3]ImPlotRange,
    FitThisFrame: bool,
    FitX: bool,
    FitY: [3]bool,
    RenderX: bool,
    RenderY: [3]bool,
    ChildWindowMade: bool,
    Style: ImPlotStyle,
    ColorModifiers: imgui.ImVector_ImGuiColorMod,
    StyleModifiers: imgui.ImVector_ImGuiStyleMod,
    ColormapData: ImPlotColormapData,
    ColormapModifiers: ImVector_ImPlotColormap,
    Tm: tm,
    Temp1: ImVector_double,
    Temp2: ImVector_double,
    DigitalPlotItemCnt: c_int,
    DigitalPlotOffset: c_int,
    NextPlotData: ImPlotNextPlotData,
    NextItemData: ImPlotNextItemData,
    InputMap: ImPlotInputMap,
    MousePos: [3]ImPlotPoint,
    AlignmentData: ImPool_ImPlotAlignmentData,
    CurrentAlignmentH: [*c]ImPlotAlignmentData,
    CurrentAlignmentV: [*c]ImPlotAlignmentData,
};
pub const ImPlotContext = struct_ImPlotContext;
pub const ImPlotCol = c_int;
pub const ImPlotStyleVar = c_int;
pub const ImPlotYAxis = c_int;
pub const ImPlotBin = c_int;
pub extern var GImPlot: [*c]ImPlotContext;
pub const ImPlotTimeUnit = c_int;
pub const struct_ImVector_ImS16 = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]imgui.ImS16,
};
pub const ImVector_ImS16 = struct_ImVector_ImS16;
pub const struct_ImVector_ImS32 = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]imgui.ImS32,
};
pub const ImVector_ImS32 = struct_ImVector_ImS32;
pub const struct_ImVector_ImS64 = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]imgui.ImS64,
};
pub const ImVector_ImS64 = struct_ImVector_ImS64;
pub const struct_ImVector_ImS8 = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]imgui.ImS8,
};
pub const ImVector_ImS8 = struct_ImVector_ImS8;
pub const struct_ImVector_ImU16 = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]imgui.ImU16,
};
pub const ImVector_ImU16 = struct_ImVector_ImU16;
pub const struct_ImVector_ImU64 = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]imgui.ImU64,
};
pub const ImVector_ImU64 = struct_ImVector_ImU64;
pub const struct_ImVector_ImU8 = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]imgui.ImU8,
};
pub const ImVector_ImU8 = struct_ImVector_ImU8;
pub const ImPlotFlags_None: c_int = 0;
pub const ImPlotFlags_NoTitle: c_int = 1;
pub const ImPlotFlags_NoLegend: c_int = 2;
pub const ImPlotFlags_NoMenus: c_int = 4;
pub const ImPlotFlags_NoBoxSelect: c_int = 8;
pub const ImPlotFlags_NoMousePos: c_int = 16;
pub const ImPlotFlags_NoHighlight: c_int = 32;
pub const ImPlotFlags_NoChild: c_int = 64;
pub const ImPlotFlags_Equal: c_int = 128;
pub const ImPlotFlags_YAxis2: c_int = 256;
pub const ImPlotFlags_YAxis3: c_int = 512;
pub const ImPlotFlags_Query: c_int = 1024;
pub const ImPlotFlags_Crosshairs: c_int = 2048;
pub const ImPlotFlags_AntiAliased: c_int = 4096;
pub const ImPlotFlags_CanvasOnly: c_int = 31;
pub const ImPlotFlags_ = c_uint;
pub const ImPlotAxisFlags_None: c_int = 0;
pub const ImPlotAxisFlags_NoLabel: c_int = 1;
pub const ImPlotAxisFlags_NoGridLines: c_int = 2;
pub const ImPlotAxisFlags_NoTickMarks: c_int = 4;
pub const ImPlotAxisFlags_NoTickLabels: c_int = 8;
pub const ImPlotAxisFlags_Foreground: c_int = 16;
pub const ImPlotAxisFlags_LogScale: c_int = 32;
pub const ImPlotAxisFlags_Time: c_int = 64;
pub const ImPlotAxisFlags_Invert: c_int = 128;
pub const ImPlotAxisFlags_NoInitialFit: c_int = 256;
pub const ImPlotAxisFlags_AutoFit: c_int = 512;
pub const ImPlotAxisFlags_RangeFit: c_int = 1024;
pub const ImPlotAxisFlags_LockMin: c_int = 2048;
pub const ImPlotAxisFlags_LockMax: c_int = 4096;
pub const ImPlotAxisFlags_Lock: c_int = 6144;
pub const ImPlotAxisFlags_NoDecorations: c_int = 15;
pub const ImPlotAxisFlags_ = c_uint;
pub const ImPlotSubplotFlags_None: c_int = 0;
pub const ImPlotSubplotFlags_NoTitle: c_int = 1;
pub const ImPlotSubplotFlags_NoLegend: c_int = 2;
pub const ImPlotSubplotFlags_NoMenus: c_int = 4;
pub const ImPlotSubplotFlags_NoResize: c_int = 8;
pub const ImPlotSubplotFlags_NoAlign: c_int = 16;
pub const ImPlotSubplotFlags_ShareItems: c_int = 32;
pub const ImPlotSubplotFlags_LinkRows: c_int = 64;
pub const ImPlotSubplotFlags_LinkCols: c_int = 128;
pub const ImPlotSubplotFlags_LinkAllX: c_int = 256;
pub const ImPlotSubplotFlags_LinkAllY: c_int = 512;
pub const ImPlotSubplotFlags_ColMajor: c_int = 1024;
pub const ImPlotSubplotFlags_ = c_uint;
pub const ImPlotCol_Line: c_int = 0;
pub const ImPlotCol_Fill: c_int = 1;
pub const ImPlotCol_MarkerOutline: c_int = 2;
pub const ImPlotCol_MarkerFill: c_int = 3;
pub const ImPlotCol_ErrorBar: c_int = 4;
pub const ImPlotCol_FrameBg: c_int = 5;
pub const ImPlotCol_PlotBg: c_int = 6;
pub const ImPlotCol_PlotBorder: c_int = 7;
pub const ImPlotCol_LegendBg: c_int = 8;
pub const ImPlotCol_LegendBorder: c_int = 9;
pub const ImPlotCol_LegendText: c_int = 10;
pub const ImPlotCol_TitleText: c_int = 11;
pub const ImPlotCol_InlayText: c_int = 12;
pub const ImPlotCol_XAxis: c_int = 13;
pub const ImPlotCol_XAxisGrid: c_int = 14;
pub const ImPlotCol_YAxis: c_int = 15;
pub const ImPlotCol_YAxisGrid: c_int = 16;
pub const ImPlotCol_YAxis2: c_int = 17;
pub const ImPlotCol_YAxisGrid2: c_int = 18;
pub const ImPlotCol_YAxis3: c_int = 19;
pub const ImPlotCol_YAxisGrid3: c_int = 20;
pub const ImPlotCol_Selection: c_int = 21;
pub const ImPlotCol_Query: c_int = 22;
pub const ImPlotCol_Crosshairs: c_int = 23;
pub const ImPlotCol_COUNT: c_int = 24;
pub const ImPlotCol_ = c_uint;
pub const ImPlotStyleVar_LineWeight: c_int = 0;
pub const ImPlotStyleVar_Marker: c_int = 1;
pub const ImPlotStyleVar_MarkerSize: c_int = 2;
pub const ImPlotStyleVar_MarkerWeight: c_int = 3;
pub const ImPlotStyleVar_FillAlpha: c_int = 4;
pub const ImPlotStyleVar_ErrorBarSize: c_int = 5;
pub const ImPlotStyleVar_ErrorBarWeight: c_int = 6;
pub const ImPlotStyleVar_DigitalBitHeight: c_int = 7;
pub const ImPlotStyleVar_DigitalBitGap: c_int = 8;
pub const ImPlotStyleVar_PlotBorderSize: c_int = 9;
pub const ImPlotStyleVar_MinorAlpha: c_int = 10;
pub const ImPlotStyleVar_MajorTickLen: c_int = 11;
pub const ImPlotStyleVar_MinorTickLen: c_int = 12;
pub const ImPlotStyleVar_MajorTickSize: c_int = 13;
pub const ImPlotStyleVar_MinorTickSize: c_int = 14;
pub const ImPlotStyleVar_MajorGridSize: c_int = 15;
pub const ImPlotStyleVar_MinorGridSize: c_int = 16;
pub const ImPlotStyleVar_PlotPadding: c_int = 17;
pub const ImPlotStyleVar_LabelPadding: c_int = 18;
pub const ImPlotStyleVar_LegendPadding: c_int = 19;
pub const ImPlotStyleVar_LegendInnerPadding: c_int = 20;
pub const ImPlotStyleVar_LegendSpacing: c_int = 21;
pub const ImPlotStyleVar_MousePosPadding: c_int = 22;
pub const ImPlotStyleVar_AnnotationPadding: c_int = 23;
pub const ImPlotStyleVar_FitPadding: c_int = 24;
pub const ImPlotStyleVar_PlotDefaultSize: c_int = 25;
pub const ImPlotStyleVar_PlotMinSize: c_int = 26;
pub const ImPlotStyleVar_COUNT: c_int = 27;
pub const ImPlotStyleVar_ = c_uint;
pub const ImPlotMarker_None: c_int = -1;
pub const ImPlotMarker_Circle: c_int = 0;
pub const ImPlotMarker_Square: c_int = 1;
pub const ImPlotMarker_Diamond: c_int = 2;
pub const ImPlotMarker_Up: c_int = 3;
pub const ImPlotMarker_Down: c_int = 4;
pub const ImPlotMarker_Left: c_int = 5;
pub const ImPlotMarker_Right: c_int = 6;
pub const ImPlotMarker_Cross: c_int = 7;
pub const ImPlotMarker_Plus: c_int = 8;
pub const ImPlotMarker_Asterisk: c_int = 9;
pub const ImPlotMarker_COUNT: c_int = 10;
pub const ImPlotMarker_ = c_int;
pub const ImPlotColormap_Deep: c_int = 0;
pub const ImPlotColormap_Dark: c_int = 1;
pub const ImPlotColormap_Pastel: c_int = 2;
pub const ImPlotColormap_Paired: c_int = 3;
pub const ImPlotColormap_Viridis: c_int = 4;
pub const ImPlotColormap_Plasma: c_int = 5;
pub const ImPlotColormap_Hot: c_int = 6;
pub const ImPlotColormap_Cool: c_int = 7;
pub const ImPlotColormap_Pink: c_int = 8;
pub const ImPlotColormap_Jet: c_int = 9;
pub const ImPlotColormap_Twilight: c_int = 10;
pub const ImPlotColormap_RdBu: c_int = 11;
pub const ImPlotColormap_BrBG: c_int = 12;
pub const ImPlotColormap_PiYG: c_int = 13;
pub const ImPlotColormap_Spectral: c_int = 14;
pub const ImPlotColormap_Greys: c_int = 15;
pub const ImPlotColormap_ = c_uint;
pub const ImPlotLocation_Center: c_int = 0;
pub const ImPlotLocation_North: c_int = 1;
pub const ImPlotLocation_South: c_int = 2;
pub const ImPlotLocation_West: c_int = 4;
pub const ImPlotLocation_East: c_int = 8;
pub const ImPlotLocation_NorthWest: c_int = 5;
pub const ImPlotLocation_NorthEast: c_int = 9;
pub const ImPlotLocation_SouthWest: c_int = 6;
pub const ImPlotLocation_SouthEast: c_int = 10;
pub const ImPlotLocation_ = c_uint;
pub const ImPlotOrientation_Horizontal: c_int = 0;
pub const ImPlotOrientation_Vertical: c_int = 1;
pub const ImPlotOrientation_ = c_uint;
pub const ImPlotYAxis_1: c_int = 0;
pub const ImPlotYAxis_2: c_int = 1;
pub const ImPlotYAxis_3: c_int = 2;
pub const ImPlotYAxis_ = c_uint;
pub const ImPlotBin_Sqrt: c_int = -1;
pub const ImPlotBin_Sturges: c_int = -2;
pub const ImPlotBin_Rice: c_int = -3;
pub const ImPlotBin_Scott: c_int = -4;
pub const ImPlotBin_ = c_int;
pub const ImPlotScale_LinLin: c_int = 0;
pub const ImPlotScale_LogLin: c_int = 1;
pub const ImPlotScale_LinLog: c_int = 2;
pub const ImPlotScale_LogLog: c_int = 3;
pub const ImPlotScale_ = c_uint;
pub const ImPlotTimeUnit_Us: c_int = 0;
pub const ImPlotTimeUnit_Ms: c_int = 1;
pub const ImPlotTimeUnit_S: c_int = 2;
pub const ImPlotTimeUnit_Min: c_int = 3;
pub const ImPlotTimeUnit_Hr: c_int = 4;
pub const ImPlotTimeUnit_Day: c_int = 5;
pub const ImPlotTimeUnit_Mo: c_int = 6;
pub const ImPlotTimeUnit_Yr: c_int = 7;
pub const ImPlotTimeUnit_COUNT: c_int = 8;
pub const ImPlotTimeUnit_ = c_uint;
pub const ImPlotDateFmt_None: c_int = 0;
pub const ImPlotDateFmt_DayMo: c_int = 1;
pub const ImPlotDateFmt_DayMoYr: c_int = 2;
pub const ImPlotDateFmt_MoYr: c_int = 3;
pub const ImPlotDateFmt_Mo: c_int = 4;
pub const ImPlotDateFmt_Yr: c_int = 5;
pub const ImPlotDateFmt_ = c_uint;
pub const ImPlotTimeFmt_None: c_int = 0;
pub const ImPlotTimeFmt_Us: c_int = 1;
pub const ImPlotTimeFmt_SUs: c_int = 2;
pub const ImPlotTimeFmt_SMs: c_int = 3;
pub const ImPlotTimeFmt_S: c_int = 4;
pub const ImPlotTimeFmt_HrMinSMs: c_int = 5;
pub const ImPlotTimeFmt_HrMinS: c_int = 6;
pub const ImPlotTimeFmt_HrMin: c_int = 7;
pub const ImPlotTimeFmt_Hr: c_int = 8;
pub const ImPlotTimeFmt_ = c_uint;
pub extern fn ImPlotPoint_ImPlotPoint_Nil() [*c]ImPlotPoint;
pub extern fn ImPlotPoint_destroy(self: [*c]ImPlotPoint) void;
pub extern fn ImPlotPoint_ImPlotPoint_double(_x: f64, _y: f64) [*c]ImPlotPoint;
pub extern fn ImPlotPoint_ImPlotPoint_Vec2(p: imgui.ImVec2) [*c]ImPlotPoint;
pub extern fn ImPlotRange_ImPlotRange_Nil() [*c]ImPlotRange;
pub extern fn ImPlotRange_destroy(self: [*c]ImPlotRange) void;
pub extern fn ImPlotRange_ImPlotRange_double(_min: f64, _max: f64) [*c]ImPlotRange;
pub extern fn ImPlotRange_Contains(self: [*c]ImPlotRange, value: f64) bool;
pub extern fn ImPlotRange_Size(self: [*c]ImPlotRange) f64;
pub extern fn ImPlotLimits_ImPlotLimits_Nil() [*c]ImPlotLimits;
pub extern fn ImPlotLimits_destroy(self: [*c]ImPlotLimits) void;
pub extern fn ImPlotLimits_ImPlotLimits_double(x_min: f64, x_max: f64, y_min: f64, y_max: f64) [*c]ImPlotLimits;
pub extern fn ImPlotLimits_Contains_PlotPoInt(self: [*c]ImPlotLimits, p: ImPlotPoint) bool;
pub extern fn ImPlotLimits_Contains_double(self: [*c]ImPlotLimits, x: f64, y: f64) bool;
pub extern fn ImPlotLimits_Min(pOut: [*c]ImPlotPoint, self: [*c]ImPlotLimits) void;
pub extern fn ImPlotLimits_Max(pOut: [*c]ImPlotPoint, self: [*c]ImPlotLimits) void;
pub extern fn ImPlotStyle_ImPlotStyle() [*c]ImPlotStyle;
pub extern fn ImPlotStyle_destroy(self: [*c]ImPlotStyle) void;
pub extern fn ImPlot_CreateContext() [*c]ImPlotContext;
pub const createContext = ImPlot_CreateContext;
pub extern fn ImPlot_DestroyContext(ctx: [*c]ImPlotContext) void;
pub const destroyContext = ImPlot_DestroyContext;
pub extern fn ImPlot_GetCurrentContext() [*c]ImPlotContext;
pub const getCurrentContext = ImPlot_GetCurrentContext;
pub extern fn ImPlot_SetCurrentContext(ctx: [*c]ImPlotContext) void;
pub const setCurrentContext = ImPlot_SetCurrentContext;
pub extern fn ImPlot_SetImGuiContext(ctx: [*c]imgui.ImGuiContext) void;
pub const setImGuiContext = ImPlot_SetImGuiContext;
pub extern fn ImPlot_BeginPlot(title_id: [*c]const u8, x_label: [*c]const u8, y_label: [*c]const u8, size: imgui.ImVec2, flags: ImPlotFlags, x_flags: ImPlotAxisFlags, y_flags: ImPlotAxisFlags, y2_flags: ImPlotAxisFlags, y3_flags: ImPlotAxisFlags, y2_label: [*c]const u8, y3_label: [*c]const u8) bool;
pub const beginPlot = ImPlot_BeginPlot;
pub extern fn ImPlot_EndPlot() void;
pub const endPlot = ImPlot_EndPlot;
pub extern fn ImPlot_BeginSubplots(title_id: [*c]const u8, rows: c_int, cols: c_int, size: imgui.ImVec2, flags: ImPlotSubplotFlags, row_ratios: [*c]f32, col_ratios: [*c]f32) bool;
pub const beginSubplots = ImPlot_BeginSubplots;
pub extern fn ImPlot_EndSubplots() void;
pub const endSubplots = ImPlot_EndSubplots;
pub extern fn ImPlot_PlotLine_FloatPtrInt(label_id: [*c]const u8, values: [*c]const f32, count: c_int, xscale: f64, x0: f64, offset: c_int, stride: c_int) void;
pub const plotLine_FloatPtrInt = ImPlot_PlotLine_FloatPtrInt;
pub extern fn ImPlot_PlotLine_doublePtrInt(label_id: [*c]const u8, values: [*c]const f64, count: c_int, xscale: f64, x0: f64, offset: c_int, stride: c_int) void;
pub const plotLine_doublePtrInt = ImPlot_PlotLine_doublePtrInt;
pub extern fn ImPlot_PlotLine_S8PtrInt(label_id: [*c]const u8, values: [*c]const imgui.ImS8, count: c_int, xscale: f64, x0: f64, offset: c_int, stride: c_int) void;
pub const plotLine_S8PtrInt = ImPlot_PlotLine_S8PtrInt;
pub extern fn ImPlot_PlotLine_U8PtrInt(label_id: [*c]const u8, values: [*c]const imgui.ImU8, count: c_int, xscale: f64, x0: f64, offset: c_int, stride: c_int) void;
pub const plotLine_U8PtrInt = ImPlot_PlotLine_U8PtrInt;
pub extern fn ImPlot_PlotLine_S16PtrInt(label_id: [*c]const u8, values: [*c]const imgui.ImS16, count: c_int, xscale: f64, x0: f64, offset: c_int, stride: c_int) void;
pub const plotLine_S16PtrInt = ImPlot_PlotLine_S16PtrInt;
pub extern fn ImPlot_PlotLine_U16PtrInt(label_id: [*c]const u8, values: [*c]const imgui.ImU16, count: c_int, xscale: f64, x0: f64, offset: c_int, stride: c_int) void;
pub const plotLine_U16PtrInt = ImPlot_PlotLine_U16PtrInt;
pub extern fn ImPlot_PlotLine_S32PtrInt(label_id: [*c]const u8, values: [*c]const imgui.ImS32, count: c_int, xscale: f64, x0: f64, offset: c_int, stride: c_int) void;
pub const plotLine_S32PtrInt = ImPlot_PlotLine_S32PtrInt;
pub extern fn ImPlot_PlotLine_U32PtrInt(label_id: [*c]const u8, values: [*c]const imgui.ImU32, count: c_int, xscale: f64, x0: f64, offset: c_int, stride: c_int) void;
pub const plotLine_U32PtrInt = ImPlot_PlotLine_U32PtrInt;
pub extern fn ImPlot_PlotLine_S64PtrInt(label_id: [*c]const u8, values: [*c]const imgui.ImS64, count: c_int, xscale: f64, x0: f64, offset: c_int, stride: c_int) void;
pub const plotLine_S64PtrInt = ImPlot_PlotLine_S64PtrInt;
pub extern fn ImPlot_PlotLine_U64PtrInt(label_id: [*c]const u8, values: [*c]const imgui.ImU64, count: c_int, xscale: f64, x0: f64, offset: c_int, stride: c_int) void;
pub const plotLine_U64PtrInt = ImPlot_PlotLine_U64PtrInt;
pub extern fn ImPlot_PlotLine_FloatPtrFloatPtr(label_id: [*c]const u8, xs: [*c]const f32, ys: [*c]const f32, count: c_int, offset: c_int, stride: c_int) void;
pub const plotLine_FloatPtrFloatPtr = ImPlot_PlotLine_FloatPtrFloatPtr;
pub extern fn ImPlot_PlotLine_doublePtrdoublePtr(label_id: [*c]const u8, xs: [*c]const f64, ys: [*c]const f64, count: c_int, offset: c_int, stride: c_int) void;
pub const plotLine_doublePtrdoublePtr = ImPlot_PlotLine_doublePtrdoublePtr;
pub extern fn ImPlot_PlotLine_S8PtrS8Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImS8, ys: [*c]const imgui.ImS8, count: c_int, offset: c_int, stride: c_int) void;
pub const plotLine_S8PtrS8Ptr = ImPlot_PlotLine_S8PtrS8Ptr;
pub extern fn ImPlot_PlotLine_U8PtrU8Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImU8, ys: [*c]const imgui.ImU8, count: c_int, offset: c_int, stride: c_int) void;
pub const plotLine_U8PtrU8Ptr = ImPlot_PlotLine_U8PtrU8Ptr;
pub extern fn ImPlot_PlotLine_S16PtrS16Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImS16, ys: [*c]const imgui.ImS16, count: c_int, offset: c_int, stride: c_int) void;
pub const plotLine_S16PtrS16Ptr = ImPlot_PlotLine_S16PtrS16Ptr;
pub extern fn ImPlot_PlotLine_U16PtrU16Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImU16, ys: [*c]const imgui.ImU16, count: c_int, offset: c_int, stride: c_int) void;
pub const plotLine_U16PtrU16Ptr = ImPlot_PlotLine_U16PtrU16Ptr;
pub extern fn ImPlot_PlotLine_S32PtrS32Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImS32, ys: [*c]const imgui.ImS32, count: c_int, offset: c_int, stride: c_int) void;
pub const plotLine_S32PtrS32Ptr = ImPlot_PlotLine_S32PtrS32Ptr;
pub extern fn ImPlot_PlotLine_U32PtrU32Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImU32, ys: [*c]const imgui.ImU32, count: c_int, offset: c_int, stride: c_int) void;
pub const plotLine_U32PtrU32Ptr = ImPlot_PlotLine_U32PtrU32Ptr;
pub extern fn ImPlot_PlotLine_S64PtrS64Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImS64, ys: [*c]const imgui.ImS64, count: c_int, offset: c_int, stride: c_int) void;
pub const plotLine_S64PtrS64Ptr = ImPlot_PlotLine_S64PtrS64Ptr;
pub extern fn ImPlot_PlotLine_U64PtrU64Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImU64, ys: [*c]const imgui.ImU64, count: c_int, offset: c_int, stride: c_int) void;
pub const plotLine_U64PtrU64Ptr = ImPlot_PlotLine_U64PtrU64Ptr;
pub extern fn ImPlot_PlotScatter_FloatPtrInt(label_id: [*c]const u8, values: [*c]const f32, count: c_int, xscale: f64, x0: f64, offset: c_int, stride: c_int) void;
pub const plotScatter_FloatPtrInt = ImPlot_PlotScatter_FloatPtrInt;
pub extern fn ImPlot_PlotScatter_doublePtrInt(label_id: [*c]const u8, values: [*c]const f64, count: c_int, xscale: f64, x0: f64, offset: c_int, stride: c_int) void;
pub const plotScatter_doublePtrInt = ImPlot_PlotScatter_doublePtrInt;
pub extern fn ImPlot_PlotScatter_S8PtrInt(label_id: [*c]const u8, values: [*c]const imgui.ImS8, count: c_int, xscale: f64, x0: f64, offset: c_int, stride: c_int) void;
pub const plotScatter_S8PtrInt = ImPlot_PlotScatter_S8PtrInt;
pub extern fn ImPlot_PlotScatter_U8PtrInt(label_id: [*c]const u8, values: [*c]const imgui.ImU8, count: c_int, xscale: f64, x0: f64, offset: c_int, stride: c_int) void;
pub const plotScatter_U8PtrInt = ImPlot_PlotScatter_U8PtrInt;
pub extern fn ImPlot_PlotScatter_S16PtrInt(label_id: [*c]const u8, values: [*c]const imgui.ImS16, count: c_int, xscale: f64, x0: f64, offset: c_int, stride: c_int) void;
pub const plotScatter_S16PtrInt = ImPlot_PlotScatter_S16PtrInt;
pub extern fn ImPlot_PlotScatter_U16PtrInt(label_id: [*c]const u8, values: [*c]const imgui.ImU16, count: c_int, xscale: f64, x0: f64, offset: c_int, stride: c_int) void;
pub const plotScatter_U16PtrInt = ImPlot_PlotScatter_U16PtrInt;
pub extern fn ImPlot_PlotScatter_S32PtrInt(label_id: [*c]const u8, values: [*c]const imgui.ImS32, count: c_int, xscale: f64, x0: f64, offset: c_int, stride: c_int) void;
pub const plotScatter_S32PtrInt = ImPlot_PlotScatter_S32PtrInt;
pub extern fn ImPlot_PlotScatter_U32PtrInt(label_id: [*c]const u8, values: [*c]const imgui.ImU32, count: c_int, xscale: f64, x0: f64, offset: c_int, stride: c_int) void;
pub const plotScatter_U32PtrInt = ImPlot_PlotScatter_U32PtrInt;
pub extern fn ImPlot_PlotScatter_S64PtrInt(label_id: [*c]const u8, values: [*c]const imgui.ImS64, count: c_int, xscale: f64, x0: f64, offset: c_int, stride: c_int) void;
pub const plotScatter_S64PtrInt = ImPlot_PlotScatter_S64PtrInt;
pub extern fn ImPlot_PlotScatter_U64PtrInt(label_id: [*c]const u8, values: [*c]const imgui.ImU64, count: c_int, xscale: f64, x0: f64, offset: c_int, stride: c_int) void;
pub const plotScatter_U64PtrInt = ImPlot_PlotScatter_U64PtrInt;
pub extern fn ImPlot_PlotScatter_FloatPtrFloatPtr(label_id: [*c]const u8, xs: [*c]const f32, ys: [*c]const f32, count: c_int, offset: c_int, stride: c_int) void;
pub const plotScatter_FloatPtrFloatPtr = ImPlot_PlotScatter_FloatPtrFloatPtr;
pub extern fn ImPlot_PlotScatter_doublePtrdoublePtr(label_id: [*c]const u8, xs: [*c]const f64, ys: [*c]const f64, count: c_int, offset: c_int, stride: c_int) void;
pub const plotScatter_doublePtrdoublePtr = ImPlot_PlotScatter_doublePtrdoublePtr;
pub extern fn ImPlot_PlotScatter_S8PtrS8Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImS8, ys: [*c]const imgui.ImS8, count: c_int, offset: c_int, stride: c_int) void;
pub const plotScatter_S8PtrS8Ptr = ImPlot_PlotScatter_S8PtrS8Ptr;
pub extern fn ImPlot_PlotScatter_U8PtrU8Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImU8, ys: [*c]const imgui.ImU8, count: c_int, offset: c_int, stride: c_int) void;
pub const plotScatter_U8PtrU8Ptr = ImPlot_PlotScatter_U8PtrU8Ptr;
pub extern fn ImPlot_PlotScatter_S16PtrS16Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImS16, ys: [*c]const imgui.ImS16, count: c_int, offset: c_int, stride: c_int) void;
pub const plotScatter_S16PtrS16Ptr = ImPlot_PlotScatter_S16PtrS16Ptr;
pub extern fn ImPlot_PlotScatter_U16PtrU16Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImU16, ys: [*c]const imgui.ImU16, count: c_int, offset: c_int, stride: c_int) void;
pub const plotScatter_U16PtrU16Ptr = ImPlot_PlotScatter_U16PtrU16Ptr;
pub extern fn ImPlot_PlotScatter_S32PtrS32Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImS32, ys: [*c]const imgui.ImS32, count: c_int, offset: c_int, stride: c_int) void;
pub const plotScatter_S32PtrS32Ptr = ImPlot_PlotScatter_S32PtrS32Ptr;
pub extern fn ImPlot_PlotScatter_U32PtrU32Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImU32, ys: [*c]const imgui.ImU32, count: c_int, offset: c_int, stride: c_int) void;
pub const plotScatter_U32PtrU32Ptr = ImPlot_PlotScatter_U32PtrU32Ptr;
pub extern fn ImPlot_PlotScatter_S64PtrS64Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImS64, ys: [*c]const imgui.ImS64, count: c_int, offset: c_int, stride: c_int) void;
pub const plotScatter_S64PtrS64Ptr = ImPlot_PlotScatter_S64PtrS64Ptr;
pub extern fn ImPlot_PlotScatter_U64PtrU64Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImU64, ys: [*c]const imgui.ImU64, count: c_int, offset: c_int, stride: c_int) void;
pub const plotScatter_U64PtrU64Ptr = ImPlot_PlotScatter_U64PtrU64Ptr;
pub extern fn ImPlot_PlotStairs_FloatPtrInt(label_id: [*c]const u8, values: [*c]const f32, count: c_int, xscale: f64, x0: f64, offset: c_int, stride: c_int) void;
pub const plotStairs_FloatPtrInt = ImPlot_PlotStairs_FloatPtrInt;
pub extern fn ImPlot_PlotStairs_doublePtrInt(label_id: [*c]const u8, values: [*c]const f64, count: c_int, xscale: f64, x0: f64, offset: c_int, stride: c_int) void;
pub const plotStairs_doublePtrInt = ImPlot_PlotStairs_doublePtrInt;
pub extern fn ImPlot_PlotStairs_S8PtrInt(label_id: [*c]const u8, values: [*c]const imgui.ImS8, count: c_int, xscale: f64, x0: f64, offset: c_int, stride: c_int) void;
pub const plotStairs_S8PtrInt = ImPlot_PlotStairs_S8PtrInt;
pub extern fn ImPlot_PlotStairs_U8PtrInt(label_id: [*c]const u8, values: [*c]const imgui.ImU8, count: c_int, xscale: f64, x0: f64, offset: c_int, stride: c_int) void;
pub const plotStairs_U8PtrInt = ImPlot_PlotStairs_U8PtrInt;
pub extern fn ImPlot_PlotStairs_S16PtrInt(label_id: [*c]const u8, values: [*c]const imgui.ImS16, count: c_int, xscale: f64, x0: f64, offset: c_int, stride: c_int) void;
pub const plotStairs_S16PtrInt = ImPlot_PlotStairs_S16PtrInt;
pub extern fn ImPlot_PlotStairs_U16PtrInt(label_id: [*c]const u8, values: [*c]const imgui.ImU16, count: c_int, xscale: f64, x0: f64, offset: c_int, stride: c_int) void;
pub const plotStairs_U16PtrInt = ImPlot_PlotStairs_U16PtrInt;
pub extern fn ImPlot_PlotStairs_S32PtrInt(label_id: [*c]const u8, values: [*c]const imgui.ImS32, count: c_int, xscale: f64, x0: f64, offset: c_int, stride: c_int) void;
pub const plotStairs_S32PtrInt = ImPlot_PlotStairs_S32PtrInt;
pub extern fn ImPlot_PlotStairs_U32PtrInt(label_id: [*c]const u8, values: [*c]const imgui.ImU32, count: c_int, xscale: f64, x0: f64, offset: c_int, stride: c_int) void;
pub const plotStairs_U32PtrInt = ImPlot_PlotStairs_U32PtrInt;
pub extern fn ImPlot_PlotStairs_S64PtrInt(label_id: [*c]const u8, values: [*c]const imgui.ImS64, count: c_int, xscale: f64, x0: f64, offset: c_int, stride: c_int) void;
pub const plotStairs_S64PtrInt = ImPlot_PlotStairs_S64PtrInt;
pub extern fn ImPlot_PlotStairs_U64PtrInt(label_id: [*c]const u8, values: [*c]const imgui.ImU64, count: c_int, xscale: f64, x0: f64, offset: c_int, stride: c_int) void;
pub const plotStairs_U64PtrInt = ImPlot_PlotStairs_U64PtrInt;
pub extern fn ImPlot_PlotStairs_FloatPtrFloatPtr(label_id: [*c]const u8, xs: [*c]const f32, ys: [*c]const f32, count: c_int, offset: c_int, stride: c_int) void;
pub const plotStairs_FloatPtrFloatPtr = ImPlot_PlotStairs_FloatPtrFloatPtr;
pub extern fn ImPlot_PlotStairs_doublePtrdoublePtr(label_id: [*c]const u8, xs: [*c]const f64, ys: [*c]const f64, count: c_int, offset: c_int, stride: c_int) void;
pub const plotStairs_doublePtrdoublePtr = ImPlot_PlotStairs_doublePtrdoublePtr;
pub extern fn ImPlot_PlotStairs_S8PtrS8Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImS8, ys: [*c]const imgui.ImS8, count: c_int, offset: c_int, stride: c_int) void;
pub const plotStairs_S8PtrS8Ptr = ImPlot_PlotStairs_S8PtrS8Ptr;
pub extern fn ImPlot_PlotStairs_U8PtrU8Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImU8, ys: [*c]const imgui.ImU8, count: c_int, offset: c_int, stride: c_int) void;
pub const plotStairs_U8PtrU8Ptr = ImPlot_PlotStairs_U8PtrU8Ptr;
pub extern fn ImPlot_PlotStairs_S16PtrS16Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImS16, ys: [*c]const imgui.ImS16, count: c_int, offset: c_int, stride: c_int) void;
pub const plotStairs_S16PtrS16Ptr = ImPlot_PlotStairs_S16PtrS16Ptr;
pub extern fn ImPlot_PlotStairs_U16PtrU16Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImU16, ys: [*c]const imgui.ImU16, count: c_int, offset: c_int, stride: c_int) void;
pub const plotStairs_U16PtrU16Ptr = ImPlot_PlotStairs_U16PtrU16Ptr;
pub extern fn ImPlot_PlotStairs_S32PtrS32Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImS32, ys: [*c]const imgui.ImS32, count: c_int, offset: c_int, stride: c_int) void;
pub const plotStairs_S32PtrS32Ptr = ImPlot_PlotStairs_S32PtrS32Ptr;
pub extern fn ImPlot_PlotStairs_U32PtrU32Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImU32, ys: [*c]const imgui.ImU32, count: c_int, offset: c_int, stride: c_int) void;
pub const plotStairs_U32PtrU32Ptr = ImPlot_PlotStairs_U32PtrU32Ptr;
pub extern fn ImPlot_PlotStairs_S64PtrS64Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImS64, ys: [*c]const imgui.ImS64, count: c_int, offset: c_int, stride: c_int) void;
pub const plotStairs_S64PtrS64Ptr = ImPlot_PlotStairs_S64PtrS64Ptr;
pub extern fn ImPlot_PlotStairs_U64PtrU64Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImU64, ys: [*c]const imgui.ImU64, count: c_int, offset: c_int, stride: c_int) void;
pub const plotStairs_U64PtrU64Ptr = ImPlot_PlotStairs_U64PtrU64Ptr;
pub extern fn ImPlot_PlotStairsG(label_id: [*c]const u8, getter: ?fn (?*c_void, c_int) callconv(.C) ImPlotPoint, data: ?*c_void, count: c_int) void;
pub const plotStairsG = ImPlot_PlotStairsG;
pub extern fn ImPlot_PlotShaded_FloatPtrInt(label_id: [*c]const u8, values: [*c]const f32, count: c_int, y_ref: f64, xscale: f64, x0: f64, offset: c_int, stride: c_int) void;
pub const plotShaded_FloatPtrInt = ImPlot_PlotShaded_FloatPtrInt;
pub extern fn ImPlot_PlotShaded_doublePtrInt(label_id: [*c]const u8, values: [*c]const f64, count: c_int, y_ref: f64, xscale: f64, x0: f64, offset: c_int, stride: c_int) void;
pub const plotShaded_doublePtrInt = ImPlot_PlotShaded_doublePtrInt;
pub extern fn ImPlot_PlotShaded_S8PtrInt(label_id: [*c]const u8, values: [*c]const imgui.ImS8, count: c_int, y_ref: f64, xscale: f64, x0: f64, offset: c_int, stride: c_int) void;
pub const plotShaded_S8PtrInt = ImPlot_PlotShaded_S8PtrInt;
pub extern fn ImPlot_PlotShaded_U8PtrInt(label_id: [*c]const u8, values: [*c]const imgui.ImU8, count: c_int, y_ref: f64, xscale: f64, x0: f64, offset: c_int, stride: c_int) void;
pub const plotShaded_U8PtrInt = ImPlot_PlotShaded_U8PtrInt;
pub extern fn ImPlot_PlotShaded_S16PtrInt(label_id: [*c]const u8, values: [*c]const imgui.ImS16, count: c_int, y_ref: f64, xscale: f64, x0: f64, offset: c_int, stride: c_int) void;
pub const plotShaded_S16PtrInt = ImPlot_PlotShaded_S16PtrInt;
pub extern fn ImPlot_PlotShaded_U16PtrInt(label_id: [*c]const u8, values: [*c]const imgui.ImU16, count: c_int, y_ref: f64, xscale: f64, x0: f64, offset: c_int, stride: c_int) void;
pub const plotShaded_U16PtrInt = ImPlot_PlotShaded_U16PtrInt;
pub extern fn ImPlot_PlotShaded_S32PtrInt(label_id: [*c]const u8, values: [*c]const imgui.ImS32, count: c_int, y_ref: f64, xscale: f64, x0: f64, offset: c_int, stride: c_int) void;
pub const plotShaded_S32PtrInt = ImPlot_PlotShaded_S32PtrInt;
pub extern fn ImPlot_PlotShaded_U32PtrInt(label_id: [*c]const u8, values: [*c]const imgui.ImU32, count: c_int, y_ref: f64, xscale: f64, x0: f64, offset: c_int, stride: c_int) void;
pub const plotShaded_U32PtrInt = ImPlot_PlotShaded_U32PtrInt;
pub extern fn ImPlot_PlotShaded_S64PtrInt(label_id: [*c]const u8, values: [*c]const imgui.ImS64, count: c_int, y_ref: f64, xscale: f64, x0: f64, offset: c_int, stride: c_int) void;
pub const plotShaded_S64PtrInt = ImPlot_PlotShaded_S64PtrInt;
pub extern fn ImPlot_PlotShaded_U64PtrInt(label_id: [*c]const u8, values: [*c]const imgui.ImU64, count: c_int, y_ref: f64, xscale: f64, x0: f64, offset: c_int, stride: c_int) void;
pub const plotShaded_U64PtrInt = ImPlot_PlotShaded_U64PtrInt;
pub extern fn ImPlot_PlotShaded_FloatPtrFloatPtrInt(label_id: [*c]const u8, xs: [*c]const f32, ys: [*c]const f32, count: c_int, y_ref: f64, offset: c_int, stride: c_int) void;
pub const plotShaded_FloatPtrFloatPtrInt = ImPlot_PlotShaded_FloatPtrFloatPtrInt;
pub extern fn ImPlot_PlotShaded_doublePtrdoublePtrInt(label_id: [*c]const u8, xs: [*c]const f64, ys: [*c]const f64, count: c_int, y_ref: f64, offset: c_int, stride: c_int) void;
pub const plotShaded_doublePtrdoublePtrInt = ImPlot_PlotShaded_doublePtrdoublePtrInt;
pub extern fn ImPlot_PlotShaded_S8PtrS8PtrInt(label_id: [*c]const u8, xs: [*c]const imgui.ImS8, ys: [*c]const imgui.ImS8, count: c_int, y_ref: f64, offset: c_int, stride: c_int) void;
pub const plotShaded_S8PtrS8PtrInt = ImPlot_PlotShaded_S8PtrS8PtrInt;
pub extern fn ImPlot_PlotShaded_U8PtrU8PtrInt(label_id: [*c]const u8, xs: [*c]const imgui.ImU8, ys: [*c]const imgui.ImU8, count: c_int, y_ref: f64, offset: c_int, stride: c_int) void;
pub const plotShaded_U8PtrU8PtrInt = ImPlot_PlotShaded_U8PtrU8PtrInt;
pub extern fn ImPlot_PlotShaded_S16PtrS16PtrInt(label_id: [*c]const u8, xs: [*c]const imgui.ImS16, ys: [*c]const imgui.ImS16, count: c_int, y_ref: f64, offset: c_int, stride: c_int) void;
pub const plotShaded_S16PtrS16PtrInt = ImPlot_PlotShaded_S16PtrS16PtrInt;
pub extern fn ImPlot_PlotShaded_U16PtrU16PtrInt(label_id: [*c]const u8, xs: [*c]const imgui.ImU16, ys: [*c]const imgui.ImU16, count: c_int, y_ref: f64, offset: c_int, stride: c_int) void;
pub const plotShaded_U16PtrU16PtrInt = ImPlot_PlotShaded_U16PtrU16PtrInt;
pub extern fn ImPlot_PlotShaded_S32PtrS32PtrInt(label_id: [*c]const u8, xs: [*c]const imgui.ImS32, ys: [*c]const imgui.ImS32, count: c_int, y_ref: f64, offset: c_int, stride: c_int) void;
pub const plotShaded_S32PtrS32PtrInt = ImPlot_PlotShaded_S32PtrS32PtrInt;
pub extern fn ImPlot_PlotShaded_U32PtrU32PtrInt(label_id: [*c]const u8, xs: [*c]const imgui.ImU32, ys: [*c]const imgui.ImU32, count: c_int, y_ref: f64, offset: c_int, stride: c_int) void;
pub const plotShaded_U32PtrU32PtrInt = ImPlot_PlotShaded_U32PtrU32PtrInt;
pub extern fn ImPlot_PlotShaded_S64PtrS64PtrInt(label_id: [*c]const u8, xs: [*c]const imgui.ImS64, ys: [*c]const imgui.ImS64, count: c_int, y_ref: f64, offset: c_int, stride: c_int) void;
pub const plotShaded_S64PtrS64PtrInt = ImPlot_PlotShaded_S64PtrS64PtrInt;
pub extern fn ImPlot_PlotShaded_U64PtrU64PtrInt(label_id: [*c]const u8, xs: [*c]const imgui.ImU64, ys: [*c]const imgui.ImU64, count: c_int, y_ref: f64, offset: c_int, stride: c_int) void;
pub const plotShaded_U64PtrU64PtrInt = ImPlot_PlotShaded_U64PtrU64PtrInt;
pub extern fn ImPlot_PlotShaded_FloatPtrFloatPtrFloatPtr(label_id: [*c]const u8, xs: [*c]const f32, ys1: [*c]const f32, ys2: [*c]const f32, count: c_int, offset: c_int, stride: c_int) void;
pub const plotShaded_FloatPtrFloatPtrFloatPtr = ImPlot_PlotShaded_FloatPtrFloatPtrFloatPtr;
pub extern fn ImPlot_PlotShaded_doublePtrdoublePtrdoublePtr(label_id: [*c]const u8, xs: [*c]const f64, ys1: [*c]const f64, ys2: [*c]const f64, count: c_int, offset: c_int, stride: c_int) void;
pub const plotShaded_doublePtrdoublePtrdoublePtr = ImPlot_PlotShaded_doublePtrdoublePtrdoublePtr;
pub extern fn ImPlot_PlotShaded_S8PtrS8PtrS8Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImS8, ys1: [*c]const imgui.ImS8, ys2: [*c]const imgui.ImS8, count: c_int, offset: c_int, stride: c_int) void;
pub const plotShaded_S8PtrS8PtrS8Ptr = ImPlot_PlotShaded_S8PtrS8PtrS8Ptr;
pub extern fn ImPlot_PlotShaded_U8PtrU8PtrU8Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImU8, ys1: [*c]const imgui.ImU8, ys2: [*c]const imgui.ImU8, count: c_int, offset: c_int, stride: c_int) void;
pub const plotShaded_U8PtrU8PtrU8Ptr = ImPlot_PlotShaded_U8PtrU8PtrU8Ptr;
pub extern fn ImPlot_PlotShaded_S16PtrS16PtrS16Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImS16, ys1: [*c]const imgui.ImS16, ys2: [*c]const imgui.ImS16, count: c_int, offset: c_int, stride: c_int) void;
pub const plotShaded_S16PtrS16PtrS16Ptr = ImPlot_PlotShaded_S16PtrS16PtrS16Ptr;
pub extern fn ImPlot_PlotShaded_U16PtrU16PtrU16Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImU16, ys1: [*c]const imgui.ImU16, ys2: [*c]const imgui.ImU16, count: c_int, offset: c_int, stride: c_int) void;
pub const plotShaded_U16PtrU16PtrU16Ptr = ImPlot_PlotShaded_U16PtrU16PtrU16Ptr;
pub extern fn ImPlot_PlotShaded_S32PtrS32PtrS32Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImS32, ys1: [*c]const imgui.ImS32, ys2: [*c]const imgui.ImS32, count: c_int, offset: c_int, stride: c_int) void;
pub const plotShaded_S32PtrS32PtrS32Ptr = ImPlot_PlotShaded_S32PtrS32PtrS32Ptr;
pub extern fn ImPlot_PlotShaded_U32PtrU32PtrU32Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImU32, ys1: [*c]const imgui.ImU32, ys2: [*c]const imgui.ImU32, count: c_int, offset: c_int, stride: c_int) void;
pub const plotShaded_U32PtrU32PtrU32Ptr = ImPlot_PlotShaded_U32PtrU32PtrU32Ptr;
pub extern fn ImPlot_PlotShaded_S64PtrS64PtrS64Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImS64, ys1: [*c]const imgui.ImS64, ys2: [*c]const imgui.ImS64, count: c_int, offset: c_int, stride: c_int) void;
pub const plotShaded_S64PtrS64PtrS64Ptr = ImPlot_PlotShaded_S64PtrS64PtrS64Ptr;
pub extern fn ImPlot_PlotShaded_U64PtrU64PtrU64Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImU64, ys1: [*c]const imgui.ImU64, ys2: [*c]const imgui.ImU64, count: c_int, offset: c_int, stride: c_int) void;
pub const plotShaded_U64PtrU64PtrU64Ptr = ImPlot_PlotShaded_U64PtrU64PtrU64Ptr;
pub extern fn ImPlot_PlotBars_FloatPtrInt(label_id: [*c]const u8, values: [*c]const f32, count: c_int, width: f64, shift: f64, offset: c_int, stride: c_int) void;
pub const plotBars_FloatPtrInt = ImPlot_PlotBars_FloatPtrInt;
pub extern fn ImPlot_PlotBars_doublePtrInt(label_id: [*c]const u8, values: [*c]const f64, count: c_int, width: f64, shift: f64, offset: c_int, stride: c_int) void;
pub const plotBars_doublePtrInt = ImPlot_PlotBars_doublePtrInt;
pub extern fn ImPlot_PlotBars_S8PtrInt(label_id: [*c]const u8, values: [*c]const imgui.ImS8, count: c_int, width: f64, shift: f64, offset: c_int, stride: c_int) void;
pub const plotBars_S8PtrInt = ImPlot_PlotBars_S8PtrInt;
pub extern fn ImPlot_PlotBars_U8PtrInt(label_id: [*c]const u8, values: [*c]const imgui.ImU8, count: c_int, width: f64, shift: f64, offset: c_int, stride: c_int) void;
pub const plotBars_U8PtrInt = ImPlot_PlotBars_U8PtrInt;
pub extern fn ImPlot_PlotBars_S16PtrInt(label_id: [*c]const u8, values: [*c]const imgui.ImS16, count: c_int, width: f64, shift: f64, offset: c_int, stride: c_int) void;
pub const plotBars_S16PtrInt = ImPlot_PlotBars_S16PtrInt;
pub extern fn ImPlot_PlotBars_U16PtrInt(label_id: [*c]const u8, values: [*c]const imgui.ImU16, count: c_int, width: f64, shift: f64, offset: c_int, stride: c_int) void;
pub const plotBars_U16PtrInt = ImPlot_PlotBars_U16PtrInt;
pub extern fn ImPlot_PlotBars_S32PtrInt(label_id: [*c]const u8, values: [*c]const imgui.ImS32, count: c_int, width: f64, shift: f64, offset: c_int, stride: c_int) void;
pub const plotBars_S32PtrInt = ImPlot_PlotBars_S32PtrInt;
pub extern fn ImPlot_PlotBars_U32PtrInt(label_id: [*c]const u8, values: [*c]const imgui.ImU32, count: c_int, width: f64, shift: f64, offset: c_int, stride: c_int) void;
pub const plotBars_U32PtrInt = ImPlot_PlotBars_U32PtrInt;
pub extern fn ImPlot_PlotBars_S64PtrInt(label_id: [*c]const u8, values: [*c]const imgui.ImS64, count: c_int, width: f64, shift: f64, offset: c_int, stride: c_int) void;
pub const plotBars_S64PtrInt = ImPlot_PlotBars_S64PtrInt;
pub extern fn ImPlot_PlotBars_U64PtrInt(label_id: [*c]const u8, values: [*c]const imgui.ImU64, count: c_int, width: f64, shift: f64, offset: c_int, stride: c_int) void;
pub const plotBars_U64PtrInt = ImPlot_PlotBars_U64PtrInt;
pub extern fn ImPlot_PlotBars_FloatPtrFloatPtr(label_id: [*c]const u8, xs: [*c]const f32, ys: [*c]const f32, count: c_int, width: f64, offset: c_int, stride: c_int) void;
pub const plotBars_FloatPtrFloatPtr = ImPlot_PlotBars_FloatPtrFloatPtr;
pub extern fn ImPlot_PlotBars_doublePtrdoublePtr(label_id: [*c]const u8, xs: [*c]const f64, ys: [*c]const f64, count: c_int, width: f64, offset: c_int, stride: c_int) void;
pub const plotBars_doublePtrdoublePtr = ImPlot_PlotBars_doublePtrdoublePtr;
pub extern fn ImPlot_PlotBars_S8PtrS8Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImS8, ys: [*c]const imgui.ImS8, count: c_int, width: f64, offset: c_int, stride: c_int) void;
pub const plotBars_S8PtrS8Ptr = ImPlot_PlotBars_S8PtrS8Ptr;
pub extern fn ImPlot_PlotBars_U8PtrU8Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImU8, ys: [*c]const imgui.ImU8, count: c_int, width: f64, offset: c_int, stride: c_int) void;
pub const plotBars_U8PtrU8Ptr = ImPlot_PlotBars_U8PtrU8Ptr;
pub extern fn ImPlot_PlotBars_S16PtrS16Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImS16, ys: [*c]const imgui.ImS16, count: c_int, width: f64, offset: c_int, stride: c_int) void;
pub const plotBars_S16PtrS16Ptr = ImPlot_PlotBars_S16PtrS16Ptr;
pub extern fn ImPlot_PlotBars_U16PtrU16Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImU16, ys: [*c]const imgui.ImU16, count: c_int, width: f64, offset: c_int, stride: c_int) void;
pub const plotBars_U16PtrU16Ptr = ImPlot_PlotBars_U16PtrU16Ptr;
pub extern fn ImPlot_PlotBars_S32PtrS32Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImS32, ys: [*c]const imgui.ImS32, count: c_int, width: f64, offset: c_int, stride: c_int) void;
pub const plotBars_S32PtrS32Ptr = ImPlot_PlotBars_S32PtrS32Ptr;
pub extern fn ImPlot_PlotBars_U32PtrU32Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImU32, ys: [*c]const imgui.ImU32, count: c_int, width: f64, offset: c_int, stride: c_int) void;
pub const plotBars_U32PtrU32Ptr = ImPlot_PlotBars_U32PtrU32Ptr;
pub extern fn ImPlot_PlotBars_S64PtrS64Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImS64, ys: [*c]const imgui.ImS64, count: c_int, width: f64, offset: c_int, stride: c_int) void;
pub const plotBars_S64PtrS64Ptr = ImPlot_PlotBars_S64PtrS64Ptr;
pub extern fn ImPlot_PlotBars_U64PtrU64Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImU64, ys: [*c]const imgui.ImU64, count: c_int, width: f64, offset: c_int, stride: c_int) void;
pub const plotBars_U64PtrU64Ptr = ImPlot_PlotBars_U64PtrU64Ptr;
pub extern fn ImPlot_PlotBarsH_FloatPtrInt(label_id: [*c]const u8, values: [*c]const f32, count: c_int, height: f64, shift: f64, offset: c_int, stride: c_int) void;
pub const plotBarsH_FloatPtrInt = ImPlot_PlotBarsH_FloatPtrInt;
pub extern fn ImPlot_PlotBarsH_doublePtrInt(label_id: [*c]const u8, values: [*c]const f64, count: c_int, height: f64, shift: f64, offset: c_int, stride: c_int) void;
pub const plotBarsH_doublePtrInt = ImPlot_PlotBarsH_doublePtrInt;
pub extern fn ImPlot_PlotBarsH_S8PtrInt(label_id: [*c]const u8, values: [*c]const imgui.ImS8, count: c_int, height: f64, shift: f64, offset: c_int, stride: c_int) void;
pub const plotBarsH_S8PtrInt = ImPlot_PlotBarsH_S8PtrInt;
pub extern fn ImPlot_PlotBarsH_U8PtrInt(label_id: [*c]const u8, values: [*c]const imgui.ImU8, count: c_int, height: f64, shift: f64, offset: c_int, stride: c_int) void;
pub const plotBarsH_U8PtrInt = ImPlot_PlotBarsH_U8PtrInt;
pub extern fn ImPlot_PlotBarsH_S16PtrInt(label_id: [*c]const u8, values: [*c]const imgui.ImS16, count: c_int, height: f64, shift: f64, offset: c_int, stride: c_int) void;
pub const plotBarsH_S16PtrInt = ImPlot_PlotBarsH_S16PtrInt;
pub extern fn ImPlot_PlotBarsH_U16PtrInt(label_id: [*c]const u8, values: [*c]const imgui.ImU16, count: c_int, height: f64, shift: f64, offset: c_int, stride: c_int) void;
pub const plotBarsH_U16PtrInt = ImPlot_PlotBarsH_U16PtrInt;
pub extern fn ImPlot_PlotBarsH_S32PtrInt(label_id: [*c]const u8, values: [*c]const imgui.ImS32, count: c_int, height: f64, shift: f64, offset: c_int, stride: c_int) void;
pub const plotBarsH_S32PtrInt = ImPlot_PlotBarsH_S32PtrInt;
pub extern fn ImPlot_PlotBarsH_U32PtrInt(label_id: [*c]const u8, values: [*c]const imgui.ImU32, count: c_int, height: f64, shift: f64, offset: c_int, stride: c_int) void;
pub const plotBarsH_U32PtrInt = ImPlot_PlotBarsH_U32PtrInt;
pub extern fn ImPlot_PlotBarsH_S64PtrInt(label_id: [*c]const u8, values: [*c]const imgui.ImS64, count: c_int, height: f64, shift: f64, offset: c_int, stride: c_int) void;
pub const plotBarsH_S64PtrInt = ImPlot_PlotBarsH_S64PtrInt;
pub extern fn ImPlot_PlotBarsH_U64PtrInt(label_id: [*c]const u8, values: [*c]const imgui.ImU64, count: c_int, height: f64, shift: f64, offset: c_int, stride: c_int) void;
pub const plotBarsH_U64PtrInt = ImPlot_PlotBarsH_U64PtrInt;
pub extern fn ImPlot_PlotBarsH_FloatPtrFloatPtr(label_id: [*c]const u8, xs: [*c]const f32, ys: [*c]const f32, count: c_int, height: f64, offset: c_int, stride: c_int) void;
pub const plotBarsH_FloatPtrFloatPtr = ImPlot_PlotBarsH_FloatPtrFloatPtr;
pub extern fn ImPlot_PlotBarsH_doublePtrdoublePtr(label_id: [*c]const u8, xs: [*c]const f64, ys: [*c]const f64, count: c_int, height: f64, offset: c_int, stride: c_int) void;
pub const plotBarsH_doublePtrdoublePtr = ImPlot_PlotBarsH_doublePtrdoublePtr;
pub extern fn ImPlot_PlotBarsH_S8PtrS8Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImS8, ys: [*c]const imgui.ImS8, count: c_int, height: f64, offset: c_int, stride: c_int) void;
pub const plotBarsH_S8PtrS8Ptr = ImPlot_PlotBarsH_S8PtrS8Ptr;
pub extern fn ImPlot_PlotBarsH_U8PtrU8Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImU8, ys: [*c]const imgui.ImU8, count: c_int, height: f64, offset: c_int, stride: c_int) void;
pub const plotBarsH_U8PtrU8Ptr = ImPlot_PlotBarsH_U8PtrU8Ptr;
pub extern fn ImPlot_PlotBarsH_S16PtrS16Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImS16, ys: [*c]const imgui.ImS16, count: c_int, height: f64, offset: c_int, stride: c_int) void;
pub const plotBarsH_S16PtrS16Ptr = ImPlot_PlotBarsH_S16PtrS16Ptr;
pub extern fn ImPlot_PlotBarsH_U16PtrU16Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImU16, ys: [*c]const imgui.ImU16, count: c_int, height: f64, offset: c_int, stride: c_int) void;
pub const plotBarsH_U16PtrU16Ptr = ImPlot_PlotBarsH_U16PtrU16Ptr;
pub extern fn ImPlot_PlotBarsH_S32PtrS32Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImS32, ys: [*c]const imgui.ImS32, count: c_int, height: f64, offset: c_int, stride: c_int) void;
pub const plotBarsH_S32PtrS32Ptr = ImPlot_PlotBarsH_S32PtrS32Ptr;
pub extern fn ImPlot_PlotBarsH_U32PtrU32Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImU32, ys: [*c]const imgui.ImU32, count: c_int, height: f64, offset: c_int, stride: c_int) void;
pub const plotBarsH_U32PtrU32Ptr = ImPlot_PlotBarsH_U32PtrU32Ptr;
pub extern fn ImPlot_PlotBarsH_S64PtrS64Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImS64, ys: [*c]const imgui.ImS64, count: c_int, height: f64, offset: c_int, stride: c_int) void;
pub const plotBarsH_S64PtrS64Ptr = ImPlot_PlotBarsH_S64PtrS64Ptr;
pub extern fn ImPlot_PlotBarsH_U64PtrU64Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImU64, ys: [*c]const imgui.ImU64, count: c_int, height: f64, offset: c_int, stride: c_int) void;
pub const plotBarsH_U64PtrU64Ptr = ImPlot_PlotBarsH_U64PtrU64Ptr;
pub extern fn ImPlot_PlotErrorBars_FloatPtrFloatPtrFloatPtrInt(label_id: [*c]const u8, xs: [*c]const f32, ys: [*c]const f32, err: [*c]const f32, count: c_int, offset: c_int, stride: c_int) void;
pub const plotErrorBars_FloatPtrFloatPtrFloatPtrInt = ImPlot_PlotErrorBars_FloatPtrFloatPtrFloatPtrInt;
pub extern fn ImPlot_PlotErrorBars_doublePtrdoublePtrdoublePtrInt(label_id: [*c]const u8, xs: [*c]const f64, ys: [*c]const f64, err: [*c]const f64, count: c_int, offset: c_int, stride: c_int) void;
pub const plotErrorBars_doublePtrdoublePtrdoublePtrInt = ImPlot_PlotErrorBars_doublePtrdoublePtrdoublePtrInt;
pub extern fn ImPlot_PlotErrorBars_S8PtrS8PtrS8PtrInt(label_id: [*c]const u8, xs: [*c]const imgui.ImS8, ys: [*c]const imgui.ImS8, err: [*c]const imgui.ImS8, count: c_int, offset: c_int, stride: c_int) void;
pub const plotErrorBars_S8PtrS8PtrS8PtrInt = ImPlot_PlotErrorBars_S8PtrS8PtrS8PtrInt;
pub extern fn ImPlot_PlotErrorBars_U8PtrU8PtrU8PtrInt(label_id: [*c]const u8, xs: [*c]const imgui.ImU8, ys: [*c]const imgui.ImU8, err: [*c]const imgui.ImU8, count: c_int, offset: c_int, stride: c_int) void;
pub const plotErrorBars_U8PtrU8PtrU8PtrInt = ImPlot_PlotErrorBars_U8PtrU8PtrU8PtrInt;
pub extern fn ImPlot_PlotErrorBars_S16PtrS16PtrS16PtrInt(label_id: [*c]const u8, xs: [*c]const imgui.ImS16, ys: [*c]const imgui.ImS16, err: [*c]const imgui.ImS16, count: c_int, offset: c_int, stride: c_int) void;
pub const plotErrorBars_S16PtrS16PtrS16PtrInt = ImPlot_PlotErrorBars_S16PtrS16PtrS16PtrInt;
pub extern fn ImPlot_PlotErrorBars_U16PtrU16PtrU16PtrInt(label_id: [*c]const u8, xs: [*c]const imgui.ImU16, ys: [*c]const imgui.ImU16, err: [*c]const imgui.ImU16, count: c_int, offset: c_int, stride: c_int) void;
pub const plotErrorBars_U16PtrU16PtrU16PtrInt = ImPlot_PlotErrorBars_U16PtrU16PtrU16PtrInt;
pub extern fn ImPlot_PlotErrorBars_S32PtrS32PtrS32PtrInt(label_id: [*c]const u8, xs: [*c]const imgui.ImS32, ys: [*c]const imgui.ImS32, err: [*c]const imgui.ImS32, count: c_int, offset: c_int, stride: c_int) void;
pub const plotErrorBars_S32PtrS32PtrS32PtrInt = ImPlot_PlotErrorBars_S32PtrS32PtrS32PtrInt;
pub extern fn ImPlot_PlotErrorBars_U32PtrU32PtrU32PtrInt(label_id: [*c]const u8, xs: [*c]const imgui.ImU32, ys: [*c]const imgui.ImU32, err: [*c]const imgui.ImU32, count: c_int, offset: c_int, stride: c_int) void;
pub const plotErrorBars_U32PtrU32PtrU32PtrInt = ImPlot_PlotErrorBars_U32PtrU32PtrU32PtrInt;
pub extern fn ImPlot_PlotErrorBars_S64PtrS64PtrS64PtrInt(label_id: [*c]const u8, xs: [*c]const imgui.ImS64, ys: [*c]const imgui.ImS64, err: [*c]const imgui.ImS64, count: c_int, offset: c_int, stride: c_int) void;
pub const plotErrorBars_S64PtrS64PtrS64PtrInt = ImPlot_PlotErrorBars_S64PtrS64PtrS64PtrInt;
pub extern fn ImPlot_PlotErrorBars_U64PtrU64PtrU64PtrInt(label_id: [*c]const u8, xs: [*c]const imgui.ImU64, ys: [*c]const imgui.ImU64, err: [*c]const imgui.ImU64, count: c_int, offset: c_int, stride: c_int) void;
pub const plotErrorBars_U64PtrU64PtrU64PtrInt = ImPlot_PlotErrorBars_U64PtrU64PtrU64PtrInt;
pub extern fn ImPlot_PlotErrorBars_FloatPtrFloatPtrFloatPtrFloatPtr(label_id: [*c]const u8, xs: [*c]const f32, ys: [*c]const f32, neg: [*c]const f32, pos: [*c]const f32, count: c_int, offset: c_int, stride: c_int) void;
pub const plotErrorBars_FloatPtrFloatPtrFloatPtrFloatPtr = ImPlot_PlotErrorBars_FloatPtrFloatPtrFloatPtrFloatPtr;
pub extern fn ImPlot_PlotErrorBars_doublePtrdoublePtrdoublePtrdoublePtr(label_id: [*c]const u8, xs: [*c]const f64, ys: [*c]const f64, neg: [*c]const f64, pos: [*c]const f64, count: c_int, offset: c_int, stride: c_int) void;
pub const plotErrorBars_doublePtrdoublePtrdoublePtrdoublePtr = ImPlot_PlotErrorBars_doublePtrdoublePtrdoublePtrdoublePtr;
pub extern fn ImPlot_PlotErrorBars_S8PtrS8PtrS8PtrS8Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImS8, ys: [*c]const imgui.ImS8, neg: [*c]const imgui.ImS8, pos: [*c]const imgui.ImS8, count: c_int, offset: c_int, stride: c_int) void;
pub const plotErrorBars_S8PtrS8PtrS8PtrS8Ptr = ImPlot_PlotErrorBars_S8PtrS8PtrS8PtrS8Ptr;
pub extern fn ImPlot_PlotErrorBars_U8PtrU8PtrU8PtrU8Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImU8, ys: [*c]const imgui.ImU8, neg: [*c]const imgui.ImU8, pos: [*c]const imgui.ImU8, count: c_int, offset: c_int, stride: c_int) void;
pub const plotErrorBars_U8PtrU8PtrU8PtrU8Ptr = ImPlot_PlotErrorBars_U8PtrU8PtrU8PtrU8Ptr;
pub extern fn ImPlot_PlotErrorBars_S16PtrS16PtrS16PtrS16Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImS16, ys: [*c]const imgui.ImS16, neg: [*c]const imgui.ImS16, pos: [*c]const imgui.ImS16, count: c_int, offset: c_int, stride: c_int) void;
pub const plotErrorBars_S16PtrS16PtrS16PtrS16Ptr = ImPlot_PlotErrorBars_S16PtrS16PtrS16PtrS16Ptr;
pub extern fn ImPlot_PlotErrorBars_U16PtrU16PtrU16PtrU16Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImU16, ys: [*c]const imgui.ImU16, neg: [*c]const imgui.ImU16, pos: [*c]const imgui.ImU16, count: c_int, offset: c_int, stride: c_int) void;
pub const plotErrorBars_U16PtrU16PtrU16PtrU16Ptr = ImPlot_PlotErrorBars_U16PtrU16PtrU16PtrU16Ptr;
pub extern fn ImPlot_PlotErrorBars_S32PtrS32PtrS32PtrS32Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImS32, ys: [*c]const imgui.ImS32, neg: [*c]const imgui.ImS32, pos: [*c]const imgui.ImS32, count: c_int, offset: c_int, stride: c_int) void;
pub const plotErrorBars_S32PtrS32PtrS32PtrS32Ptr = ImPlot_PlotErrorBars_S32PtrS32PtrS32PtrS32Ptr;
pub extern fn ImPlot_PlotErrorBars_U32PtrU32PtrU32PtrU32Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImU32, ys: [*c]const imgui.ImU32, neg: [*c]const imgui.ImU32, pos: [*c]const imgui.ImU32, count: c_int, offset: c_int, stride: c_int) void;
pub const plotErrorBars_U32PtrU32PtrU32PtrU32Ptr = ImPlot_PlotErrorBars_U32PtrU32PtrU32PtrU32Ptr;
pub extern fn ImPlot_PlotErrorBars_S64PtrS64PtrS64PtrS64Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImS64, ys: [*c]const imgui.ImS64, neg: [*c]const imgui.ImS64, pos: [*c]const imgui.ImS64, count: c_int, offset: c_int, stride: c_int) void;
pub const plotErrorBars_S64PtrS64PtrS64PtrS64Ptr = ImPlot_PlotErrorBars_S64PtrS64PtrS64PtrS64Ptr;
pub extern fn ImPlot_PlotErrorBars_U64PtrU64PtrU64PtrU64Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImU64, ys: [*c]const imgui.ImU64, neg: [*c]const imgui.ImU64, pos: [*c]const imgui.ImU64, count: c_int, offset: c_int, stride: c_int) void;
pub const plotErrorBars_U64PtrU64PtrU64PtrU64Ptr = ImPlot_PlotErrorBars_U64PtrU64PtrU64PtrU64Ptr;
pub extern fn ImPlot_PlotErrorBarsH_FloatPtrFloatPtrFloatPtrInt(label_id: [*c]const u8, xs: [*c]const f32, ys: [*c]const f32, err: [*c]const f32, count: c_int, offset: c_int, stride: c_int) void;
pub const plotErrorBarsH_FloatPtrFloatPtrFloatPtrInt = ImPlot_PlotErrorBarsH_FloatPtrFloatPtrFloatPtrInt;
pub extern fn ImPlot_PlotErrorBarsH_doublePtrdoublePtrdoublePtrInt(label_id: [*c]const u8, xs: [*c]const f64, ys: [*c]const f64, err: [*c]const f64, count: c_int, offset: c_int, stride: c_int) void;
pub const plotErrorBarsH_doublePtrdoublePtrdoublePtrInt = ImPlot_PlotErrorBarsH_doublePtrdoublePtrdoublePtrInt;
pub extern fn ImPlot_PlotErrorBarsH_S8PtrS8PtrS8PtrInt(label_id: [*c]const u8, xs: [*c]const imgui.ImS8, ys: [*c]const imgui.ImS8, err: [*c]const imgui.ImS8, count: c_int, offset: c_int, stride: c_int) void;
pub const plotErrorBarsH_S8PtrS8PtrS8PtrInt = ImPlot_PlotErrorBarsH_S8PtrS8PtrS8PtrInt;
pub extern fn ImPlot_PlotErrorBarsH_U8PtrU8PtrU8PtrInt(label_id: [*c]const u8, xs: [*c]const imgui.ImU8, ys: [*c]const imgui.ImU8, err: [*c]const imgui.ImU8, count: c_int, offset: c_int, stride: c_int) void;
pub const plotErrorBarsH_U8PtrU8PtrU8PtrInt = ImPlot_PlotErrorBarsH_U8PtrU8PtrU8PtrInt;
pub extern fn ImPlot_PlotErrorBarsH_S16PtrS16PtrS16PtrInt(label_id: [*c]const u8, xs: [*c]const imgui.ImS16, ys: [*c]const imgui.ImS16, err: [*c]const imgui.ImS16, count: c_int, offset: c_int, stride: c_int) void;
pub const plotErrorBarsH_S16PtrS16PtrS16PtrInt = ImPlot_PlotErrorBarsH_S16PtrS16PtrS16PtrInt;
pub extern fn ImPlot_PlotErrorBarsH_U16PtrU16PtrU16PtrInt(label_id: [*c]const u8, xs: [*c]const imgui.ImU16, ys: [*c]const imgui.ImU16, err: [*c]const imgui.ImU16, count: c_int, offset: c_int, stride: c_int) void;
pub const plotErrorBarsH_U16PtrU16PtrU16PtrInt = ImPlot_PlotErrorBarsH_U16PtrU16PtrU16PtrInt;
pub extern fn ImPlot_PlotErrorBarsH_S32PtrS32PtrS32PtrInt(label_id: [*c]const u8, xs: [*c]const imgui.ImS32, ys: [*c]const imgui.ImS32, err: [*c]const imgui.ImS32, count: c_int, offset: c_int, stride: c_int) void;
pub const plotErrorBarsH_S32PtrS32PtrS32PtrInt = ImPlot_PlotErrorBarsH_S32PtrS32PtrS32PtrInt;
pub extern fn ImPlot_PlotErrorBarsH_U32PtrU32PtrU32PtrInt(label_id: [*c]const u8, xs: [*c]const imgui.ImU32, ys: [*c]const imgui.ImU32, err: [*c]const imgui.ImU32, count: c_int, offset: c_int, stride: c_int) void;
pub const plotErrorBarsH_U32PtrU32PtrU32PtrInt = ImPlot_PlotErrorBarsH_U32PtrU32PtrU32PtrInt;
pub extern fn ImPlot_PlotErrorBarsH_S64PtrS64PtrS64PtrInt(label_id: [*c]const u8, xs: [*c]const imgui.ImS64, ys: [*c]const imgui.ImS64, err: [*c]const imgui.ImS64, count: c_int, offset: c_int, stride: c_int) void;
pub const plotErrorBarsH_S64PtrS64PtrS64PtrInt = ImPlot_PlotErrorBarsH_S64PtrS64PtrS64PtrInt;
pub extern fn ImPlot_PlotErrorBarsH_U64PtrU64PtrU64PtrInt(label_id: [*c]const u8, xs: [*c]const imgui.ImU64, ys: [*c]const imgui.ImU64, err: [*c]const imgui.ImU64, count: c_int, offset: c_int, stride: c_int) void;
pub const plotErrorBarsH_U64PtrU64PtrU64PtrInt = ImPlot_PlotErrorBarsH_U64PtrU64PtrU64PtrInt;
pub extern fn ImPlot_PlotErrorBarsH_FloatPtrFloatPtrFloatPtrFloatPtr(label_id: [*c]const u8, xs: [*c]const f32, ys: [*c]const f32, neg: [*c]const f32, pos: [*c]const f32, count: c_int, offset: c_int, stride: c_int) void;
pub const plotErrorBarsH_FloatPtrFloatPtrFloatPtrFloatPtr = ImPlot_PlotErrorBarsH_FloatPtrFloatPtrFloatPtrFloatPtr;
pub extern fn ImPlot_PlotErrorBarsH_doublePtrdoublePtrdoublePtrdoublePtr(label_id: [*c]const u8, xs: [*c]const f64, ys: [*c]const f64, neg: [*c]const f64, pos: [*c]const f64, count: c_int, offset: c_int, stride: c_int) void;
pub const plotErrorBarsH_doublePtrdoublePtrdoublePtrdoublePtr = ImPlot_PlotErrorBarsH_doublePtrdoublePtrdoublePtrdoublePtr;
pub extern fn ImPlot_PlotErrorBarsH_S8PtrS8PtrS8PtrS8Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImS8, ys: [*c]const imgui.ImS8, neg: [*c]const imgui.ImS8, pos: [*c]const imgui.ImS8, count: c_int, offset: c_int, stride: c_int) void;
pub const plotErrorBarsH_S8PtrS8PtrS8PtrS8Ptr = ImPlot_PlotErrorBarsH_S8PtrS8PtrS8PtrS8Ptr;
pub extern fn ImPlot_PlotErrorBarsH_U8PtrU8PtrU8PtrU8Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImU8, ys: [*c]const imgui.ImU8, neg: [*c]const imgui.ImU8, pos: [*c]const imgui.ImU8, count: c_int, offset: c_int, stride: c_int) void;
pub const plotErrorBarsH_U8PtrU8PtrU8PtrU8Ptr = ImPlot_PlotErrorBarsH_U8PtrU8PtrU8PtrU8Ptr;
pub extern fn ImPlot_PlotErrorBarsH_S16PtrS16PtrS16PtrS16Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImS16, ys: [*c]const imgui.ImS16, neg: [*c]const imgui.ImS16, pos: [*c]const imgui.ImS16, count: c_int, offset: c_int, stride: c_int) void;
pub const plotErrorBarsH_S16PtrS16PtrS16PtrS16Ptr = ImPlot_PlotErrorBarsH_S16PtrS16PtrS16PtrS16Ptr;
pub extern fn ImPlot_PlotErrorBarsH_U16PtrU16PtrU16PtrU16Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImU16, ys: [*c]const imgui.ImU16, neg: [*c]const imgui.ImU16, pos: [*c]const imgui.ImU16, count: c_int, offset: c_int, stride: c_int) void;
pub const plotErrorBarsH_U16PtrU16PtrU16PtrU16Ptr = ImPlot_PlotErrorBarsH_U16PtrU16PtrU16PtrU16Ptr;
pub extern fn ImPlot_PlotErrorBarsH_S32PtrS32PtrS32PtrS32Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImS32, ys: [*c]const imgui.ImS32, neg: [*c]const imgui.ImS32, pos: [*c]const imgui.ImS32, count: c_int, offset: c_int, stride: c_int) void;
pub const plotErrorBarsH_S32PtrS32PtrS32PtrS32Ptr = ImPlot_PlotErrorBarsH_S32PtrS32PtrS32PtrS32Ptr;
pub extern fn ImPlot_PlotErrorBarsH_U32PtrU32PtrU32PtrU32Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImU32, ys: [*c]const imgui.ImU32, neg: [*c]const imgui.ImU32, pos: [*c]const imgui.ImU32, count: c_int, offset: c_int, stride: c_int) void;
pub const plotErrorBarsH_U32PtrU32PtrU32PtrU32Ptr = ImPlot_PlotErrorBarsH_U32PtrU32PtrU32PtrU32Ptr;
pub extern fn ImPlot_PlotErrorBarsH_S64PtrS64PtrS64PtrS64Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImS64, ys: [*c]const imgui.ImS64, neg: [*c]const imgui.ImS64, pos: [*c]const imgui.ImS64, count: c_int, offset: c_int, stride: c_int) void;
pub const plotErrorBarsH_S64PtrS64PtrS64PtrS64Ptr = ImPlot_PlotErrorBarsH_S64PtrS64PtrS64PtrS64Ptr;
pub extern fn ImPlot_PlotErrorBarsH_U64PtrU64PtrU64PtrU64Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImU64, ys: [*c]const imgui.ImU64, neg: [*c]const imgui.ImU64, pos: [*c]const imgui.ImU64, count: c_int, offset: c_int, stride: c_int) void;
pub const plotErrorBarsH_U64PtrU64PtrU64PtrU64Ptr = ImPlot_PlotErrorBarsH_U64PtrU64PtrU64PtrU64Ptr;
pub extern fn ImPlot_PlotStems_FloatPtrInt(label_id: [*c]const u8, values: [*c]const f32, count: c_int, y_ref: f64, xscale: f64, x0: f64, offset: c_int, stride: c_int) void;
pub const plotStems_FloatPtrInt = ImPlot_PlotStems_FloatPtrInt;
pub extern fn ImPlot_PlotStems_doublePtrInt(label_id: [*c]const u8, values: [*c]const f64, count: c_int, y_ref: f64, xscale: f64, x0: f64, offset: c_int, stride: c_int) void;
pub const plotStems_doublePtrInt = ImPlot_PlotStems_doublePtrInt;
pub extern fn ImPlot_PlotStems_S8PtrInt(label_id: [*c]const u8, values: [*c]const imgui.ImS8, count: c_int, y_ref: f64, xscale: f64, x0: f64, offset: c_int, stride: c_int) void;
pub const plotStems_S8PtrInt = ImPlot_PlotStems_S8PtrInt;
pub extern fn ImPlot_PlotStems_U8PtrInt(label_id: [*c]const u8, values: [*c]const imgui.ImU8, count: c_int, y_ref: f64, xscale: f64, x0: f64, offset: c_int, stride: c_int) void;
pub const plotStems_U8PtrInt = ImPlot_PlotStems_U8PtrInt;
pub extern fn ImPlot_PlotStems_S16PtrInt(label_id: [*c]const u8, values: [*c]const imgui.ImS16, count: c_int, y_ref: f64, xscale: f64, x0: f64, offset: c_int, stride: c_int) void;
pub const plotStems_S16PtrInt = ImPlot_PlotStems_S16PtrInt;
pub extern fn ImPlot_PlotStems_U16PtrInt(label_id: [*c]const u8, values: [*c]const imgui.ImU16, count: c_int, y_ref: f64, xscale: f64, x0: f64, offset: c_int, stride: c_int) void;
pub const plotStems_U16PtrInt = ImPlot_PlotStems_U16PtrInt;
pub extern fn ImPlot_PlotStems_S32PtrInt(label_id: [*c]const u8, values: [*c]const imgui.ImS32, count: c_int, y_ref: f64, xscale: f64, x0: f64, offset: c_int, stride: c_int) void;
pub const plotStems_S32PtrInt = ImPlot_PlotStems_S32PtrInt;
pub extern fn ImPlot_PlotStems_U32PtrInt(label_id: [*c]const u8, values: [*c]const imgui.ImU32, count: c_int, y_ref: f64, xscale: f64, x0: f64, offset: c_int, stride: c_int) void;
pub const plotStems_U32PtrInt = ImPlot_PlotStems_U32PtrInt;
pub extern fn ImPlot_PlotStems_S64PtrInt(label_id: [*c]const u8, values: [*c]const imgui.ImS64, count: c_int, y_ref: f64, xscale: f64, x0: f64, offset: c_int, stride: c_int) void;
pub const plotStems_S64PtrInt = ImPlot_PlotStems_S64PtrInt;
pub extern fn ImPlot_PlotStems_U64PtrInt(label_id: [*c]const u8, values: [*c]const imgui.ImU64, count: c_int, y_ref: f64, xscale: f64, x0: f64, offset: c_int, stride: c_int) void;
pub const plotStems_U64PtrInt = ImPlot_PlotStems_U64PtrInt;
pub extern fn ImPlot_PlotStems_FloatPtrFloatPtr(label_id: [*c]const u8, xs: [*c]const f32, ys: [*c]const f32, count: c_int, y_ref: f64, offset: c_int, stride: c_int) void;
pub const plotStems_FloatPtrFloatPtr = ImPlot_PlotStems_FloatPtrFloatPtr;
pub extern fn ImPlot_PlotStems_doublePtrdoublePtr(label_id: [*c]const u8, xs: [*c]const f64, ys: [*c]const f64, count: c_int, y_ref: f64, offset: c_int, stride: c_int) void;
pub const plotStems_doublePtrdoublePtr = ImPlot_PlotStems_doublePtrdoublePtr;
pub extern fn ImPlot_PlotStems_S8PtrS8Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImS8, ys: [*c]const imgui.ImS8, count: c_int, y_ref: f64, offset: c_int, stride: c_int) void;
pub const plotStems_S8PtrS8Ptr = ImPlot_PlotStems_S8PtrS8Ptr;
pub extern fn ImPlot_PlotStems_U8PtrU8Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImU8, ys: [*c]const imgui.ImU8, count: c_int, y_ref: f64, offset: c_int, stride: c_int) void;
pub const plotStems_U8PtrU8Ptr = ImPlot_PlotStems_U8PtrU8Ptr;
pub extern fn ImPlot_PlotStems_S16PtrS16Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImS16, ys: [*c]const imgui.ImS16, count: c_int, y_ref: f64, offset: c_int, stride: c_int) void;
pub const plotStems_S16PtrS16Ptr = ImPlot_PlotStems_S16PtrS16Ptr;
pub extern fn ImPlot_PlotStems_U16PtrU16Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImU16, ys: [*c]const imgui.ImU16, count: c_int, y_ref: f64, offset: c_int, stride: c_int) void;
pub const plotStems_U16PtrU16Ptr = ImPlot_PlotStems_U16PtrU16Ptr;
pub extern fn ImPlot_PlotStems_S32PtrS32Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImS32, ys: [*c]const imgui.ImS32, count: c_int, y_ref: f64, offset: c_int, stride: c_int) void;
pub const plotStems_S32PtrS32Ptr = ImPlot_PlotStems_S32PtrS32Ptr;
pub extern fn ImPlot_PlotStems_U32PtrU32Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImU32, ys: [*c]const imgui.ImU32, count: c_int, y_ref: f64, offset: c_int, stride: c_int) void;
pub const plotStems_U32PtrU32Ptr = ImPlot_PlotStems_U32PtrU32Ptr;
pub extern fn ImPlot_PlotStems_S64PtrS64Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImS64, ys: [*c]const imgui.ImS64, count: c_int, y_ref: f64, offset: c_int, stride: c_int) void;
pub const plotStems_S64PtrS64Ptr = ImPlot_PlotStems_S64PtrS64Ptr;
pub extern fn ImPlot_PlotStems_U64PtrU64Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImU64, ys: [*c]const imgui.ImU64, count: c_int, y_ref: f64, offset: c_int, stride: c_int) void;
pub const plotStems_U64PtrU64Ptr = ImPlot_PlotStems_U64PtrU64Ptr;
pub extern fn ImPlot_PlotVLines_FloatPtr(label_id: [*c]const u8, xs: [*c]const f32, count: c_int, offset: c_int, stride: c_int) void;
pub const plotVLines_FloatPtr = ImPlot_PlotVLines_FloatPtr;
pub extern fn ImPlot_PlotVLines_doublePtr(label_id: [*c]const u8, xs: [*c]const f64, count: c_int, offset: c_int, stride: c_int) void;
pub const plotVLines_doublePtr = ImPlot_PlotVLines_doublePtr;
pub extern fn ImPlot_PlotVLines_S8Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImS8, count: c_int, offset: c_int, stride: c_int) void;
pub const plotVLines_S8Ptr = ImPlot_PlotVLines_S8Ptr;
pub extern fn ImPlot_PlotVLines_U8Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImU8, count: c_int, offset: c_int, stride: c_int) void;
pub const plotVLines_U8Ptr = ImPlot_PlotVLines_U8Ptr;
pub extern fn ImPlot_PlotVLines_S16Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImS16, count: c_int, offset: c_int, stride: c_int) void;
pub const plotVLines_S16Ptr = ImPlot_PlotVLines_S16Ptr;
pub extern fn ImPlot_PlotVLines_U16Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImU16, count: c_int, offset: c_int, stride: c_int) void;
pub const plotVLines_U16Ptr = ImPlot_PlotVLines_U16Ptr;
pub extern fn ImPlot_PlotVLines_S32Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImS32, count: c_int, offset: c_int, stride: c_int) void;
pub const plotVLines_S32Ptr = ImPlot_PlotVLines_S32Ptr;
pub extern fn ImPlot_PlotVLines_U32Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImU32, count: c_int, offset: c_int, stride: c_int) void;
pub const plotVLines_U32Ptr = ImPlot_PlotVLines_U32Ptr;
pub extern fn ImPlot_PlotVLines_S64Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImS64, count: c_int, offset: c_int, stride: c_int) void;
pub const plotVLines_S64Ptr = ImPlot_PlotVLines_S64Ptr;
pub extern fn ImPlot_PlotVLines_U64Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImU64, count: c_int, offset: c_int, stride: c_int) void;
pub const plotVLines_U64Ptr = ImPlot_PlotVLines_U64Ptr;
pub extern fn ImPlot_PlotHLines_FloatPtr(label_id: [*c]const u8, ys: [*c]const f32, count: c_int, offset: c_int, stride: c_int) void;
pub const plotHLines_FloatPtr = ImPlot_PlotHLines_FloatPtr;
pub extern fn ImPlot_PlotHLines_doublePtr(label_id: [*c]const u8, ys: [*c]const f64, count: c_int, offset: c_int, stride: c_int) void;
pub const plotHLines_doublePtr = ImPlot_PlotHLines_doublePtr;
pub extern fn ImPlot_PlotHLines_S8Ptr(label_id: [*c]const u8, ys: [*c]const imgui.ImS8, count: c_int, offset: c_int, stride: c_int) void;
pub const plotHLines_S8Ptr = ImPlot_PlotHLines_S8Ptr;
pub extern fn ImPlot_PlotHLines_U8Ptr(label_id: [*c]const u8, ys: [*c]const imgui.ImU8, count: c_int, offset: c_int, stride: c_int) void;
pub const plotHLines_U8Ptr = ImPlot_PlotHLines_U8Ptr;
pub extern fn ImPlot_PlotHLines_S16Ptr(label_id: [*c]const u8, ys: [*c]const imgui.ImS16, count: c_int, offset: c_int, stride: c_int) void;
pub const plotHLines_S16Ptr = ImPlot_PlotHLines_S16Ptr;
pub extern fn ImPlot_PlotHLines_U16Ptr(label_id: [*c]const u8, ys: [*c]const imgui.ImU16, count: c_int, offset: c_int, stride: c_int) void;
pub const plotHLines_U16Ptr = ImPlot_PlotHLines_U16Ptr;
pub extern fn ImPlot_PlotHLines_S32Ptr(label_id: [*c]const u8, ys: [*c]const imgui.ImS32, count: c_int, offset: c_int, stride: c_int) void;
pub const plotHLines_S32Ptr = ImPlot_PlotHLines_S32Ptr;
pub extern fn ImPlot_PlotHLines_U32Ptr(label_id: [*c]const u8, ys: [*c]const imgui.ImU32, count: c_int, offset: c_int, stride: c_int) void;
pub const plotHLines_U32Ptr = ImPlot_PlotHLines_U32Ptr;
pub extern fn ImPlot_PlotHLines_S64Ptr(label_id: [*c]const u8, ys: [*c]const imgui.ImS64, count: c_int, offset: c_int, stride: c_int) void;
pub const plotHLines_S64Ptr = ImPlot_PlotHLines_S64Ptr;
pub extern fn ImPlot_PlotHLines_U64Ptr(label_id: [*c]const u8, ys: [*c]const imgui.ImU64, count: c_int, offset: c_int, stride: c_int) void;
pub const plotHLines_U64Ptr = ImPlot_PlotHLines_U64Ptr;
pub extern fn ImPlot_PlotPieChart_FloatPtr(label_ids: [*c]const [*c]const u8, values: [*c]const f32, count: c_int, x: f64, y: f64, radius: f64, normalize: bool, label_fmt: [*c]const u8, angle0: f64) void;
pub const plotPieChart_FloatPtr = ImPlot_PlotPieChart_FloatPtr;
pub extern fn ImPlot_PlotPieChart_doublePtr(label_ids: [*c]const [*c]const u8, values: [*c]const f64, count: c_int, x: f64, y: f64, radius: f64, normalize: bool, label_fmt: [*c]const u8, angle0: f64) void;
pub const plotPieChart_doublePtr = ImPlot_PlotPieChart_doublePtr;
pub extern fn ImPlot_PlotPieChart_S8Ptr(label_ids: [*c]const [*c]const u8, values: [*c]const imgui.ImS8, count: c_int, x: f64, y: f64, radius: f64, normalize: bool, label_fmt: [*c]const u8, angle0: f64) void;
pub const plotPieChart_S8Ptr = ImPlot_PlotPieChart_S8Ptr;
pub extern fn ImPlot_PlotPieChart_U8Ptr(label_ids: [*c]const [*c]const u8, values: [*c]const imgui.ImU8, count: c_int, x: f64, y: f64, radius: f64, normalize: bool, label_fmt: [*c]const u8, angle0: f64) void;
pub const plotPieChart_U8Ptr = ImPlot_PlotPieChart_U8Ptr;
pub extern fn ImPlot_PlotPieChart_S16Ptr(label_ids: [*c]const [*c]const u8, values: [*c]const imgui.ImS16, count: c_int, x: f64, y: f64, radius: f64, normalize: bool, label_fmt: [*c]const u8, angle0: f64) void;
pub const plotPieChart_S16Ptr = ImPlot_PlotPieChart_S16Ptr;
pub extern fn ImPlot_PlotPieChart_U16Ptr(label_ids: [*c]const [*c]const u8, values: [*c]const imgui.ImU16, count: c_int, x: f64, y: f64, radius: f64, normalize: bool, label_fmt: [*c]const u8, angle0: f64) void;
pub const plotPieChart_U16Ptr = ImPlot_PlotPieChart_U16Ptr;
pub extern fn ImPlot_PlotPieChart_S32Ptr(label_ids: [*c]const [*c]const u8, values: [*c]const imgui.ImS32, count: c_int, x: f64, y: f64, radius: f64, normalize: bool, label_fmt: [*c]const u8, angle0: f64) void;
pub const plotPieChart_S32Ptr = ImPlot_PlotPieChart_S32Ptr;
pub extern fn ImPlot_PlotPieChart_U32Ptr(label_ids: [*c]const [*c]const u8, values: [*c]const imgui.ImU32, count: c_int, x: f64, y: f64, radius: f64, normalize: bool, label_fmt: [*c]const u8, angle0: f64) void;
pub const plotPieChart_U32Ptr = ImPlot_PlotPieChart_U32Ptr;
pub extern fn ImPlot_PlotPieChart_S64Ptr(label_ids: [*c]const [*c]const u8, values: [*c]const imgui.ImS64, count: c_int, x: f64, y: f64, radius: f64, normalize: bool, label_fmt: [*c]const u8, angle0: f64) void;
pub const plotPieChart_S64Ptr = ImPlot_PlotPieChart_S64Ptr;
pub extern fn ImPlot_PlotPieChart_U64Ptr(label_ids: [*c]const [*c]const u8, values: [*c]const imgui.ImU64, count: c_int, x: f64, y: f64, radius: f64, normalize: bool, label_fmt: [*c]const u8, angle0: f64) void;
pub const plotPieChart_U64Ptr = ImPlot_PlotPieChart_U64Ptr;
pub extern fn ImPlot_PlotHeatmap_FloatPtr(label_id: [*c]const u8, values: [*c]const f32, rows: c_int, cols: c_int, scale_min: f64, scale_max: f64, label_fmt: [*c]const u8, bounds_min: ImPlotPoint, bounds_max: ImPlotPoint) void;
pub const plotHeatmap_FloatPtr = ImPlot_PlotHeatmap_FloatPtr;
pub extern fn ImPlot_PlotHeatmap_doublePtr(label_id: [*c]const u8, values: [*c]const f64, rows: c_int, cols: c_int, scale_min: f64, scale_max: f64, label_fmt: [*c]const u8, bounds_min: ImPlotPoint, bounds_max: ImPlotPoint) void;
pub const plotHeatmap_doublePtr = ImPlot_PlotHeatmap_doublePtr;
pub extern fn ImPlot_PlotHeatmap_S8Ptr(label_id: [*c]const u8, values: [*c]const imgui.ImS8, rows: c_int, cols: c_int, scale_min: f64, scale_max: f64, label_fmt: [*c]const u8, bounds_min: ImPlotPoint, bounds_max: ImPlotPoint) void;
pub const plotHeatmap_S8Ptr = ImPlot_PlotHeatmap_S8Ptr;
pub extern fn ImPlot_PlotHeatmap_U8Ptr(label_id: [*c]const u8, values: [*c]const imgui.ImU8, rows: c_int, cols: c_int, scale_min: f64, scale_max: f64, label_fmt: [*c]const u8, bounds_min: ImPlotPoint, bounds_max: ImPlotPoint) void;
pub const plotHeatmap_U8Ptr = ImPlot_PlotHeatmap_U8Ptr;
pub extern fn ImPlot_PlotHeatmap_S16Ptr(label_id: [*c]const u8, values: [*c]const imgui.ImS16, rows: c_int, cols: c_int, scale_min: f64, scale_max: f64, label_fmt: [*c]const u8, bounds_min: ImPlotPoint, bounds_max: ImPlotPoint) void;
pub const plotHeatmap_S16Ptr = ImPlot_PlotHeatmap_S16Ptr;
pub extern fn ImPlot_PlotHeatmap_U16Ptr(label_id: [*c]const u8, values: [*c]const imgui.ImU16, rows: c_int, cols: c_int, scale_min: f64, scale_max: f64, label_fmt: [*c]const u8, bounds_min: ImPlotPoint, bounds_max: ImPlotPoint) void;
pub const plotHeatmap_U16Ptr = ImPlot_PlotHeatmap_U16Ptr;
pub extern fn ImPlot_PlotHeatmap_S32Ptr(label_id: [*c]const u8, values: [*c]const imgui.ImS32, rows: c_int, cols: c_int, scale_min: f64, scale_max: f64, label_fmt: [*c]const u8, bounds_min: ImPlotPoint, bounds_max: ImPlotPoint) void;
pub const plotHeatmap_S32Ptr = ImPlot_PlotHeatmap_S32Ptr;
pub extern fn ImPlot_PlotHeatmap_U32Ptr(label_id: [*c]const u8, values: [*c]const imgui.ImU32, rows: c_int, cols: c_int, scale_min: f64, scale_max: f64, label_fmt: [*c]const u8, bounds_min: ImPlotPoint, bounds_max: ImPlotPoint) void;
pub const plotHeatmap_U32Ptr = ImPlot_PlotHeatmap_U32Ptr;
pub extern fn ImPlot_PlotHeatmap_S64Ptr(label_id: [*c]const u8, values: [*c]const imgui.ImS64, rows: c_int, cols: c_int, scale_min: f64, scale_max: f64, label_fmt: [*c]const u8, bounds_min: ImPlotPoint, bounds_max: ImPlotPoint) void;
pub const plotHeatmap_S64Ptr = ImPlot_PlotHeatmap_S64Ptr;
pub extern fn ImPlot_PlotHeatmap_U64Ptr(label_id: [*c]const u8, values: [*c]const imgui.ImU64, rows: c_int, cols: c_int, scale_min: f64, scale_max: f64, label_fmt: [*c]const u8, bounds_min: ImPlotPoint, bounds_max: ImPlotPoint) void;
pub const plotHeatmap_U64Ptr = ImPlot_PlotHeatmap_U64Ptr;
pub extern fn ImPlot_PlotHistogram_FloatPtr(label_id: [*c]const u8, values: [*c]const f32, count: c_int, bins: c_int, cumulative: bool, density: bool, range: ImPlotRange, outliers: bool, bar_scale: f64) f64;
pub const plotHistogram_FloatPtr = ImPlot_PlotHistogram_FloatPtr;
pub extern fn ImPlot_PlotHistogram_doublePtr(label_id: [*c]const u8, values: [*c]const f64, count: c_int, bins: c_int, cumulative: bool, density: bool, range: ImPlotRange, outliers: bool, bar_scale: f64) f64;
pub const plotHistogram_doublePtr = ImPlot_PlotHistogram_doublePtr;
pub extern fn ImPlot_PlotHistogram_S8Ptr(label_id: [*c]const u8, values: [*c]const imgui.ImS8, count: c_int, bins: c_int, cumulative: bool, density: bool, range: ImPlotRange, outliers: bool, bar_scale: f64) f64;
pub const plotHistogram_S8Ptr = ImPlot_PlotHistogram_S8Ptr;
pub extern fn ImPlot_PlotHistogram_U8Ptr(label_id: [*c]const u8, values: [*c]const imgui.ImU8, count: c_int, bins: c_int, cumulative: bool, density: bool, range: ImPlotRange, outliers: bool, bar_scale: f64) f64;
pub const plotHistogram_U8Ptr = ImPlot_PlotHistogram_U8Ptr;
pub extern fn ImPlot_PlotHistogram_S16Ptr(label_id: [*c]const u8, values: [*c]const imgui.ImS16, count: c_int, bins: c_int, cumulative: bool, density: bool, range: ImPlotRange, outliers: bool, bar_scale: f64) f64;
pub const plotHistogram_S16Ptr = ImPlot_PlotHistogram_S16Ptr;
pub extern fn ImPlot_PlotHistogram_U16Ptr(label_id: [*c]const u8, values: [*c]const imgui.ImU16, count: c_int, bins: c_int, cumulative: bool, density: bool, range: ImPlotRange, outliers: bool, bar_scale: f64) f64;
pub const plotHistogram_U16Ptr = ImPlot_PlotHistogram_U16Ptr;
pub extern fn ImPlot_PlotHistogram_S32Ptr(label_id: [*c]const u8, values: [*c]const imgui.ImS32, count: c_int, bins: c_int, cumulative: bool, density: bool, range: ImPlotRange, outliers: bool, bar_scale: f64) f64;
pub const plotHistogram_S32Ptr = ImPlot_PlotHistogram_S32Ptr;
pub extern fn ImPlot_PlotHistogram_U32Ptr(label_id: [*c]const u8, values: [*c]const imgui.ImU32, count: c_int, bins: c_int, cumulative: bool, density: bool, range: ImPlotRange, outliers: bool, bar_scale: f64) f64;
pub const plotHistogram_U32Ptr = ImPlot_PlotHistogram_U32Ptr;
pub extern fn ImPlot_PlotHistogram_S64Ptr(label_id: [*c]const u8, values: [*c]const imgui.ImS64, count: c_int, bins: c_int, cumulative: bool, density: bool, range: ImPlotRange, outliers: bool, bar_scale: f64) f64;
pub const plotHistogram_S64Ptr = ImPlot_PlotHistogram_S64Ptr;
pub extern fn ImPlot_PlotHistogram_U64Ptr(label_id: [*c]const u8, values: [*c]const imgui.ImU64, count: c_int, bins: c_int, cumulative: bool, density: bool, range: ImPlotRange, outliers: bool, bar_scale: f64) f64;
pub const plotHistogram_U64Ptr = ImPlot_PlotHistogram_U64Ptr;
pub extern fn ImPlot_PlotHistogram2D_FloatPtr(label_id: [*c]const u8, xs: [*c]const f32, ys: [*c]const f32, count: c_int, x_bins: c_int, y_bins: c_int, density: bool, range: ImPlotLimits, outliers: bool) f64;
pub const plotHistogram2D_FloatPtr = ImPlot_PlotHistogram2D_FloatPtr;
pub extern fn ImPlot_PlotHistogram2D_doublePtr(label_id: [*c]const u8, xs: [*c]const f64, ys: [*c]const f64, count: c_int, x_bins: c_int, y_bins: c_int, density: bool, range: ImPlotLimits, outliers: bool) f64;
pub const plotHistogram2D_doublePtr = ImPlot_PlotHistogram2D_doublePtr;
pub extern fn ImPlot_PlotHistogram2D_S8Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImS8, ys: [*c]const imgui.ImS8, count: c_int, x_bins: c_int, y_bins: c_int, density: bool, range: ImPlotLimits, outliers: bool) f64;
pub const plotHistogram2D_S8Ptr = ImPlot_PlotHistogram2D_S8Ptr;
pub extern fn ImPlot_PlotHistogram2D_U8Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImU8, ys: [*c]const imgui.ImU8, count: c_int, x_bins: c_int, y_bins: c_int, density: bool, range: ImPlotLimits, outliers: bool) f64;
pub const plotHistogram2D_U8Ptr = ImPlot_PlotHistogram2D_U8Ptr;
pub extern fn ImPlot_PlotHistogram2D_S16Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImS16, ys: [*c]const imgui.ImS16, count: c_int, x_bins: c_int, y_bins: c_int, density: bool, range: ImPlotLimits, outliers: bool) f64;
pub const plotHistogram2D_S16Ptr = ImPlot_PlotHistogram2D_S16Ptr;
pub extern fn ImPlot_PlotHistogram2D_U16Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImU16, ys: [*c]const imgui.ImU16, count: c_int, x_bins: c_int, y_bins: c_int, density: bool, range: ImPlotLimits, outliers: bool) f64;
pub const plotHistogram2D_U16Ptr = ImPlot_PlotHistogram2D_U16Ptr;
pub extern fn ImPlot_PlotHistogram2D_S32Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImS32, ys: [*c]const imgui.ImS32, count: c_int, x_bins: c_int, y_bins: c_int, density: bool, range: ImPlotLimits, outliers: bool) f64;
pub const plotHistogram2D_S32Ptr = ImPlot_PlotHistogram2D_S32Ptr;
pub extern fn ImPlot_PlotHistogram2D_U32Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImU32, ys: [*c]const imgui.ImU32, count: c_int, x_bins: c_int, y_bins: c_int, density: bool, range: ImPlotLimits, outliers: bool) f64;
pub const plotHistogram2D_U32Ptr = ImPlot_PlotHistogram2D_U32Ptr;
pub extern fn ImPlot_PlotHistogram2D_S64Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImS64, ys: [*c]const imgui.ImS64, count: c_int, x_bins: c_int, y_bins: c_int, density: bool, range: ImPlotLimits, outliers: bool) f64;
pub const plotHistogram2D_S64Ptr = ImPlot_PlotHistogram2D_S64Ptr;
pub extern fn ImPlot_PlotHistogram2D_U64Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImU64, ys: [*c]const imgui.ImU64, count: c_int, x_bins: c_int, y_bins: c_int, density: bool, range: ImPlotLimits, outliers: bool) f64;
pub const plotHistogram2D_U64Ptr = ImPlot_PlotHistogram2D_U64Ptr;
pub extern fn ImPlot_PlotDigital_FloatPtr(label_id: [*c]const u8, xs: [*c]const f32, ys: [*c]const f32, count: c_int, offset: c_int, stride: c_int) void;
pub const plotDigital_FloatPtr = ImPlot_PlotDigital_FloatPtr;
pub extern fn ImPlot_PlotDigital_doublePtr(label_id: [*c]const u8, xs: [*c]const f64, ys: [*c]const f64, count: c_int, offset: c_int, stride: c_int) void;
pub const plotDigital_doublePtr = ImPlot_PlotDigital_doublePtr;
pub extern fn ImPlot_PlotDigital_S8Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImS8, ys: [*c]const imgui.ImS8, count: c_int, offset: c_int, stride: c_int) void;
pub const plotDigital_S8Ptr = ImPlot_PlotDigital_S8Ptr;
pub extern fn ImPlot_PlotDigital_U8Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImU8, ys: [*c]const imgui.ImU8, count: c_int, offset: c_int, stride: c_int) void;
pub const plotDigital_U8Ptr = ImPlot_PlotDigital_U8Ptr;
pub extern fn ImPlot_PlotDigital_S16Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImS16, ys: [*c]const imgui.ImS16, count: c_int, offset: c_int, stride: c_int) void;
pub const plotDigital_S16Ptr = ImPlot_PlotDigital_S16Ptr;
pub extern fn ImPlot_PlotDigital_U16Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImU16, ys: [*c]const imgui.ImU16, count: c_int, offset: c_int, stride: c_int) void;
pub const plotDigital_U16Ptr = ImPlot_PlotDigital_U16Ptr;
pub extern fn ImPlot_PlotDigital_S32Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImS32, ys: [*c]const imgui.ImS32, count: c_int, offset: c_int, stride: c_int) void;
pub const plotDigital_S32Ptr = ImPlot_PlotDigital_S32Ptr;
pub extern fn ImPlot_PlotDigital_U32Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImU32, ys: [*c]const imgui.ImU32, count: c_int, offset: c_int, stride: c_int) void;
pub const plotDigital_U32Ptr = ImPlot_PlotDigital_U32Ptr;
pub extern fn ImPlot_PlotDigital_S64Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImS64, ys: [*c]const imgui.ImS64, count: c_int, offset: c_int, stride: c_int) void;
pub const plotDigital_S64Ptr = ImPlot_PlotDigital_S64Ptr;
pub extern fn ImPlot_PlotDigital_U64Ptr(label_id: [*c]const u8, xs: [*c]const imgui.ImU64, ys: [*c]const imgui.ImU64, count: c_int, offset: c_int, stride: c_int) void;
pub const plotDigital_U64Ptr = ImPlot_PlotDigital_U64Ptr;
pub extern fn ImPlot_PlotImage(label_id: [*c]const u8, user_texture_id: imgui.ImTextureID, bounds_min: ImPlotPoint, bounds_max: ImPlotPoint, uv0: imgui.ImVec2, uv1: imgui.ImVec2, tint_col: imgui.ImVec4) void;
pub const plotImage = ImPlot_PlotImage;
pub extern fn ImPlot_PlotText(text: [*c]const u8, x: f64, y: f64, vertical: bool, pix_offset: imgui.ImVec2) void;
pub const plotText = ImPlot_PlotText;
pub extern fn ImPlot_PlotDummy(label_id: [*c]const u8) void;
pub const plotDummy = ImPlot_PlotDummy;
pub extern fn ImPlot_SetNextPlotLimits(xmin: f64, xmax: f64, ymin: f64, ymax: f64, cond: imgui.ImGuiCond) void;
pub const setNextPlotLimits = ImPlot_SetNextPlotLimits;
pub extern fn ImPlot_SetNextPlotLimitsX(xmin: f64, xmax: f64, cond: imgui.ImGuiCond) void;
pub const setNextPlotLimitsX = ImPlot_SetNextPlotLimitsX;
pub extern fn ImPlot_SetNextPlotLimitsY(ymin: f64, ymax: f64, cond: imgui.ImGuiCond, y_axis: ImPlotYAxis) void;
pub const setNextPlotLimitsY = ImPlot_SetNextPlotLimitsY;
pub extern fn ImPlot_LinkNextPlotLimits(xmin: [*c]f64, xmax: [*c]f64, ymin: [*c]f64, ymax: [*c]f64, ymin2: [*c]f64, ymax2: [*c]f64, ymin3: [*c]f64, ymax3: [*c]f64) void;
pub const linkNextPlotLimits = ImPlot_LinkNextPlotLimits;
pub extern fn ImPlot_FitNextPlotAxes(x: bool, y: bool, y2: bool, y3: bool) void;
pub const fitNextPlotAxes = ImPlot_FitNextPlotAxes;
pub extern fn ImPlot_SetNextPlotTicksX_doublePtr(values: [*c]const f64, n_ticks: c_int, labels: [*c]const [*c]const u8, keep_default: bool) void;
pub const setNextPlotTicksX_doublePtr = ImPlot_SetNextPlotTicksX_doublePtr;
pub extern fn ImPlot_SetNextPlotTicksX_double(x_min: f64, x_max: f64, n_ticks: c_int, labels: [*c]const [*c]const u8, keep_default: bool) void;
pub const setNextPlotTicksX_double = ImPlot_SetNextPlotTicksX_double;
pub extern fn ImPlot_SetNextPlotTicksY_doublePtr(values: [*c]const f64, n_ticks: c_int, labels: [*c]const [*c]const u8, keep_default: bool, y_axis: ImPlotYAxis) void;
pub const setNextPlotTicksY_doublePtr = ImPlot_SetNextPlotTicksY_doublePtr;
pub extern fn ImPlot_SetNextPlotTicksY_double(y_min: f64, y_max: f64, n_ticks: c_int, labels: [*c]const [*c]const u8, keep_default: bool, y_axis: ImPlotYAxis) void;
pub const setNextPlotTicksY_double = ImPlot_SetNextPlotTicksY_double;
pub extern fn ImPlot_SetNextPlotFormatX(fmt: [*c]const u8) void;
pub const setNextPlotFormatX = ImPlot_SetNextPlotFormatX;
pub extern fn ImPlot_SetNextPlotFormatY(fmt: [*c]const u8, y_axis: ImPlotYAxis) void;
pub const setNextPlotFormatY = ImPlot_SetNextPlotFormatY;
pub extern fn ImPlot_SetPlotYAxis(y_axis: ImPlotYAxis) void;
pub const setPlotYAxis = ImPlot_SetPlotYAxis;
pub extern fn ImPlot_HideNextItem(hidden: bool, cond: imgui.ImGuiCond) void;
pub const hideNextItem = ImPlot_HideNextItem;
pub extern fn ImPlot_PixelsToPlot_Vec2(pOut: [*c]ImPlotPoint, pix: imgui.ImVec2, y_axis: ImPlotYAxis) void;
pub const pixelsToPlot_Vec2 = ImPlot_PixelsToPlot_Vec2;
pub extern fn ImPlot_PixelsToPlot_Float(pOut: [*c]ImPlotPoint, x: f32, y: f32, y_axis: ImPlotYAxis) void;
pub const pixelsToPlot_Float = ImPlot_PixelsToPlot_Float;
pub extern fn ImPlot_PlotToPixels_PlotPoInt(pOut: [*c]imgui.ImVec2, plt: ImPlotPoint, y_axis: ImPlotYAxis) void;
pub const plotToPixels_PlotPoInt = ImPlot_PlotToPixels_PlotPoInt;
pub extern fn ImPlot_PlotToPixels_double(pOut: [*c]imgui.ImVec2, x: f64, y: f64, y_axis: ImPlotYAxis) void;
pub const plotToPixels_double = ImPlot_PlotToPixels_double;
pub extern fn ImPlot_GetPlotPos(pOut: [*c]imgui.ImVec2) void;
pub const getPlotPos = ImPlot_GetPlotPos;
pub extern fn ImPlot_GetPlotSize(pOut: [*c]imgui.ImVec2) void;
pub const getPlotSize = ImPlot_GetPlotSize;
pub extern fn ImPlot_IsPlotHovered() bool;
pub const isPlotHovered = ImPlot_IsPlotHovered;
pub extern fn ImPlot_IsPlotXAxisHovered() bool;
pub const isPlotXAxisHovered = ImPlot_IsPlotXAxisHovered;
pub extern fn ImPlot_IsPlotYAxisHovered(y_axis: ImPlotYAxis) bool;
pub const isPlotYAxisHovered = ImPlot_IsPlotYAxisHovered;
pub extern fn ImPlot_GetPlotMousePos(pOut: [*c]ImPlotPoint, y_axis: ImPlotYAxis) void;
pub const getPlotMousePos = ImPlot_GetPlotMousePos;
pub extern fn ImPlot_GetPlotLimits(pOut: [*c]ImPlotLimits, y_axis: ImPlotYAxis) void;
pub const getPlotLimits = ImPlot_GetPlotLimits;
pub extern fn ImPlot_IsPlotSelected() bool;
pub const isPlotSelected = ImPlot_IsPlotSelected;
pub extern fn ImPlot_GetPlotSelection(pOut: [*c]ImPlotLimits, y_axis: ImPlotYAxis) void;
pub const getPlotSelection = ImPlot_GetPlotSelection;
pub extern fn ImPlot_IsPlotQueried() bool;
pub const isPlotQueried = ImPlot_IsPlotQueried;
pub extern fn ImPlot_GetPlotQuery(pOut: [*c]ImPlotLimits, y_axis: ImPlotYAxis) void;
pub const getPlotQuery = ImPlot_GetPlotQuery;
pub extern fn ImPlot_SetPlotQuery(query: ImPlotLimits, y_axis: ImPlotYAxis) void;
pub const setPlotQuery = ImPlot_SetPlotQuery;
pub extern fn ImPlot_IsSubplotsHovered() bool;
pub const isSubplotsHovered = ImPlot_IsSubplotsHovered;
pub extern fn ImPlot_BeginAlignedPlots(group_id: [*c]const u8, orientation: ImPlotOrientation) bool;
pub const beginAlignedPlots = ImPlot_BeginAlignedPlots;
pub extern fn ImPlot_EndAlignedPlots() void;
pub const endAlignedPlots = ImPlot_EndAlignedPlots;
pub extern fn ImPlot_Annotate_Str(x: f64, y: f64, pix_offset: imgui.ImVec2, fmt: [*c]const u8, ...) void;
pub const annotate_Str = ImPlot_Annotate_Str;
pub extern fn ImPlot_Annotate_Vec4(x: f64, y: f64, pix_offset: imgui.ImVec2, color: imgui.ImVec4, fmt: [*c]const u8, ...) void;
pub const annotate_Vec4 = ImPlot_Annotate_Vec4;
pub extern fn ImPlot_AnnotateClamped_Str(x: f64, y: f64, pix_offset: imgui.ImVec2, fmt: [*c]const u8, ...) void;
pub const annotateClamped_Str = ImPlot_AnnotateClamped_Str;
pub extern fn ImPlot_AnnotateClamped_Vec4(x: f64, y: f64, pix_offset: imgui.ImVec2, color: imgui.ImVec4, fmt: [*c]const u8, ...) void;
pub const annotateClamped_Vec4 = ImPlot_AnnotateClamped_Vec4;
pub extern fn ImPlot_DragLineX(id: [*c]const u8, x_value: [*c]f64, show_label: bool, col: imgui.ImVec4, thickness: f32) bool;
pub const dragLineX = ImPlot_DragLineX;
pub extern fn ImPlot_DragLineY(id: [*c]const u8, y_value: [*c]f64, show_label: bool, col: imgui.ImVec4, thickness: f32) bool;
pub const dragLineY = ImPlot_DragLineY;
pub extern fn ImPlot_DragPoint(id: [*c]const u8, x: [*c]f64, y: [*c]f64, show_label: bool, col: imgui.ImVec4, radius: f32) bool;
pub const dragPoint = ImPlot_DragPoint;
pub extern fn ImPlot_SetLegendLocation(location: ImPlotLocation, orientation: ImPlotOrientation, outside: bool) void;
pub const setLegendLocation = ImPlot_SetLegendLocation;
pub extern fn ImPlot_SetMousePosLocation(location: ImPlotLocation) void;
pub const setMousePosLocation = ImPlot_SetMousePosLocation;
pub extern fn ImPlot_IsLegendEntryHovered(label_id: [*c]const u8) bool;
pub const isLegendEntryHovered = ImPlot_IsLegendEntryHovered;
pub extern fn ImPlot_BeginLegendPopup(label_id: [*c]const u8, mouse_button: imgui.ImGuiMouseButton) bool;
pub const beginLegendPopup = ImPlot_BeginLegendPopup;
pub extern fn ImPlot_EndLegendPopup() void;
pub const endLegendPopup = ImPlot_EndLegendPopup;
pub extern fn ImPlot_BeginDragDropTarget() bool;
pub const beginDragDropTarget = ImPlot_BeginDragDropTarget;
pub extern fn ImPlot_BeginDragDropTargetX() bool;
pub const beginDragDropTargetX = ImPlot_BeginDragDropTargetX;
pub extern fn ImPlot_BeginDragDropTargetY(axis: ImPlotYAxis) bool;
pub const beginDragDropTargetY = ImPlot_BeginDragDropTargetY;
pub extern fn ImPlot_BeginDragDropTargetLegend() bool;
pub const beginDragDropTargetLegend = ImPlot_BeginDragDropTargetLegend;
pub extern fn ImPlot_EndDragDropTarget() void;
pub const endDragDropTarget = ImPlot_EndDragDropTarget;
pub extern fn ImPlot_BeginDragDropSource(key_mods: imgui.ImGuiKeyModFlags, flags: imgui.ImGuiDragDropFlags) bool;
pub const beginDragDropSource = ImPlot_BeginDragDropSource;
pub extern fn ImPlot_BeginDragDropSourceX(key_mods: imgui.ImGuiKeyModFlags, flags: imgui.ImGuiDragDropFlags) bool;
pub const beginDragDropSourceX = ImPlot_BeginDragDropSourceX;
pub extern fn ImPlot_BeginDragDropSourceY(axis: ImPlotYAxis, key_mods: imgui.ImGuiKeyModFlags, flags: imgui.ImGuiDragDropFlags) bool;
pub const beginDragDropSourceY = ImPlot_BeginDragDropSourceY;
pub extern fn ImPlot_BeginDragDropSourceItem(label_id: [*c]const u8, flags: imgui.ImGuiDragDropFlags) bool;
pub const beginDragDropSourceItem = ImPlot_BeginDragDropSourceItem;
pub extern fn ImPlot_EndDragDropSource() void;
pub const endDragDropSource = ImPlot_EndDragDropSource;
pub extern fn ImPlot_GetStyle() [*c]ImPlotStyle;
pub const getStyle = ImPlot_GetStyle;
pub extern fn ImPlot_StyleColorsAuto(dst: [*c]ImPlotStyle) void;
pub const styleColorsAuto = ImPlot_StyleColorsAuto;
pub extern fn ImPlot_StyleColorsClassic(dst: [*c]ImPlotStyle) void;
pub const styleColorsClassic = ImPlot_StyleColorsClassic;
pub extern fn ImPlot_StyleColorsDark(dst: [*c]ImPlotStyle) void;
pub const styleColorsDark = ImPlot_StyleColorsDark;
pub extern fn ImPlot_StyleColorsLight(dst: [*c]ImPlotStyle) void;
pub const styleColorsLight = ImPlot_StyleColorsLight;
pub extern fn ImPlot_PushStyleColor_U32(idx: ImPlotCol, col: imgui.ImU32) void;
pub const pushStyleColor_U32 = ImPlot_PushStyleColor_U32;
pub extern fn ImPlot_PushStyleColor_Vec4(idx: ImPlotCol, col: imgui.ImVec4) void;
pub const pushStyleColor_Vec4 = ImPlot_PushStyleColor_Vec4;
pub extern fn ImPlot_PopStyleColor(count: c_int) void;
pub const popStyleColor = ImPlot_PopStyleColor;
pub extern fn ImPlot_PushStyleVar_Float(idx: ImPlotStyleVar, val: f32) void;
pub const pushStyleVar_Float = ImPlot_PushStyleVar_Float;
pub extern fn ImPlot_PushStyleVar_Int(idx: ImPlotStyleVar, val: c_int) void;
pub const pushStyleVar_Int = ImPlot_PushStyleVar_Int;
pub extern fn ImPlot_PushStyleVar_Vec2(idx: ImPlotStyleVar, val: imgui.ImVec2) void;
pub const pushStyleVar_Vec2 = ImPlot_PushStyleVar_Vec2;
pub extern fn ImPlot_PopStyleVar(count: c_int) void;
pub const popStyleVar = ImPlot_PopStyleVar;
pub extern fn ImPlot_SetNextLineStyle(col: imgui.ImVec4, weight: f32) void;
pub const setNextLineStyle = ImPlot_SetNextLineStyle;
pub extern fn ImPlot_SetNextFillStyle(col: imgui.ImVec4, alpha_mod: f32) void;
pub const setNextFillStyle = ImPlot_SetNextFillStyle;
pub extern fn ImPlot_SetNextMarkerStyle(marker: ImPlotMarker, size: f32, fill: imgui.ImVec4, weight: f32, outline: imgui.ImVec4) void;
pub const setNextMarkerStyle = ImPlot_SetNextMarkerStyle;
pub extern fn ImPlot_SetNextErrorBarStyle(col: imgui.ImVec4, size: f32, weight: f32) void;
pub const setNextErrorBarStyle = ImPlot_SetNextErrorBarStyle;
pub extern fn ImPlot_GetLastItemColor(pOut: [*c]imgui.ImVec4) void;
pub const getLastItemColor = ImPlot_GetLastItemColor;
pub extern fn ImPlot_GetStyleColorName(idx: ImPlotCol) [*c]const u8;
pub const getStyleColorName = ImPlot_GetStyleColorName;
pub extern fn ImPlot_GetMarkerName(idx: ImPlotMarker) [*c]const u8;
pub const getMarkerName = ImPlot_GetMarkerName;
pub extern fn ImPlot_AddColormap_Vec4Ptr(name: [*c]const u8, cols: [*c]const imgui.ImVec4, size: c_int, qual: bool) ImPlotColormap;
pub const addColormap_Vec4Ptr = ImPlot_AddColormap_Vec4Ptr;
pub extern fn ImPlot_AddColormap_U32Ptr(name: [*c]const u8, cols: [*c]const imgui.ImU32, size: c_int, qual: bool) ImPlotColormap;
pub const addColormap_U32Ptr = ImPlot_AddColormap_U32Ptr;
pub extern fn ImPlot_GetColormapCount() c_int;
pub const getColormapCount = ImPlot_GetColormapCount;
pub extern fn ImPlot_GetColormapName(cmap: ImPlotColormap) [*c]const u8;
pub const getColormapName = ImPlot_GetColormapName;
pub extern fn ImPlot_GetColormapIndex(name: [*c]const u8) ImPlotColormap;
pub const getColormapIndex = ImPlot_GetColormapIndex;
pub extern fn ImPlot_PushColormap_PlotColormap(cmap: ImPlotColormap) void;
pub const pushColormap_PlotColormap = ImPlot_PushColormap_PlotColormap;
pub extern fn ImPlot_PushColormap_Str(name: [*c]const u8) void;
pub const pushColormap_Str = ImPlot_PushColormap_Str;
pub extern fn ImPlot_PopColormap(count: c_int) void;
pub const popColormap = ImPlot_PopColormap;
pub extern fn ImPlot_NextColormapColor(pOut: [*c]imgui.ImVec4) void;
pub const nextColormapColor = ImPlot_NextColormapColor;
pub extern fn ImPlot_GetColormapSize(cmap: ImPlotColormap) c_int;
pub const getColormapSize = ImPlot_GetColormapSize;
pub extern fn ImPlot_GetColormapColor(pOut: [*c]imgui.ImVec4, idx: c_int, cmap: ImPlotColormap) void;
pub const getColormapColor = ImPlot_GetColormapColor;
pub extern fn ImPlot_SampleColormap(pOut: [*c]imgui.ImVec4, t: f32, cmap: ImPlotColormap) void;
pub const sampleColormap = ImPlot_SampleColormap;
pub extern fn ImPlot_ColormapScale(label: [*c]const u8, scale_min: f64, scale_max: f64, size: imgui.ImVec2, cmap: ImPlotColormap, fmt: [*c]const u8) void;
pub const colormapScale = ImPlot_ColormapScale;
pub extern fn ImPlot_ColormapSlider(label: [*c]const u8, t: [*c]f32, out: [*c]imgui.ImVec4, format: [*c]const u8, cmap: ImPlotColormap) bool;
pub const colormapSlider = ImPlot_ColormapSlider;
pub extern fn ImPlot_ColormapButton(label: [*c]const u8, size: imgui.ImVec2, cmap: ImPlotColormap) bool;
pub const colormapButton = ImPlot_ColormapButton;
pub extern fn ImPlot_BustColorCache(plot_title_id: [*c]const u8) void;
pub const bustColorCache = ImPlot_BustColorCache;
pub extern fn ImPlot_ItemIcon_Vec4(col: imgui.ImVec4) void;
pub const itemIcon_Vec4 = ImPlot_ItemIcon_Vec4;
pub extern fn ImPlot_ItemIcon_U32(col: imgui.ImU32) void;
pub const itemIcon_U32 = ImPlot_ItemIcon_U32;
pub extern fn ImPlot_ColormapIcon(cmap: ImPlotColormap) void;
pub const colormapIcon = ImPlot_ColormapIcon;
pub extern fn ImPlot_GetPlotDrawList() [*c]imgui.ImDrawList;
pub const getPlotDrawList = ImPlot_GetPlotDrawList;
pub extern fn ImPlot_PushPlotClipRect(expand: f32) void;
pub const pushPlotClipRect = ImPlot_PushPlotClipRect;
pub extern fn ImPlot_PopPlotClipRect() void;
pub const popPlotClipRect = ImPlot_PopPlotClipRect;
pub extern fn ImPlot_ShowStyleSelector(label: [*c]const u8) bool;
pub const showStyleSelector = ImPlot_ShowStyleSelector;
pub extern fn ImPlot_ShowColormapSelector(label: [*c]const u8) bool;
pub const showColormapSelector = ImPlot_ShowColormapSelector;
pub extern fn ImPlot_ShowStyleEditor(ref: [*c]ImPlotStyle) void;
pub const showStyleEditor = ImPlot_ShowStyleEditor;
pub extern fn ImPlot_ShowUserGuide() void;
pub const showUserGuide = ImPlot_ShowUserGuide;
pub extern fn ImPlot_ShowMetricsWindow(p_popen: [*c]bool) void;
pub const showMetricsWindow = ImPlot_ShowMetricsWindow;
pub extern fn ImPlot_ShowDemoWindow(p_open: [*c]bool) void;
pub const showDemoWindow = ImPlot_ShowDemoWindow;
pub extern fn ImPlot_ImLog10_Float(x: f32) f32;
pub const imLog10_Float = ImPlot_ImLog10_Float;
pub extern fn ImPlot_ImLog10_double(x: f64) f64;
pub const imLog10_double = ImPlot_ImLog10_double;
pub extern fn ImPlot_ImRemap_Float(x: f32, x0: f32, x1: f32, y0: f32, y1: f32) f32;
pub const imRemap_Float = ImPlot_ImRemap_Float;
pub extern fn ImPlot_ImRemap_double(x: f64, x0: f64, x1: f64, y0: f64, y1: f64) f64;
pub const imRemap_double = ImPlot_ImRemap_double;
pub extern fn ImPlot_ImRemap_S8(x: imgui.ImS8, x0: imgui.ImS8, x1: imgui.ImS8, y0: imgui.ImS8, y1: imgui.ImS8) imgui.ImS8;
pub const imRemap_S8 = ImPlot_ImRemap_S8;
pub extern fn ImPlot_ImRemap_U8(x: imgui.ImU8, x0: imgui.ImU8, x1: imgui.ImU8, y0: imgui.ImU8, y1: imgui.ImU8) imgui.ImU8;
pub const imRemap_U8 = ImPlot_ImRemap_U8;
pub extern fn ImPlot_ImRemap_S16(x: imgui.ImS16, x0: imgui.ImS16, x1: imgui.ImS16, y0: imgui.ImS16, y1: imgui.ImS16) imgui.ImS16;
pub const imRemap_S16 = ImPlot_ImRemap_S16;
pub extern fn ImPlot_ImRemap_U16(x: imgui.ImU16, x0: imgui.ImU16, x1: imgui.ImU16, y0: imgui.ImU16, y1: imgui.ImU16) imgui.ImU16;
pub const imRemap_U16 = ImPlot_ImRemap_U16;
pub extern fn ImPlot_ImRemap_S32(x: imgui.ImS32, x0: imgui.ImS32, x1: imgui.ImS32, y0: imgui.ImS32, y1: imgui.ImS32) imgui.ImS32;
pub const imRemap_S32 = ImPlot_ImRemap_S32;
pub extern fn ImPlot_ImRemap_U32(x: imgui.ImU32, x0: imgui.ImU32, x1: imgui.ImU32, y0: imgui.ImU32, y1: imgui.ImU32) imgui.ImU32;
pub const imRemap_U32 = ImPlot_ImRemap_U32;
pub extern fn ImPlot_ImRemap_S64(x: imgui.ImS64, x0: imgui.ImS64, x1: imgui.ImS64, y0: imgui.ImS64, y1: imgui.ImS64) imgui.ImS64;
pub const imRemap_S64 = ImPlot_ImRemap_S64;
pub extern fn ImPlot_ImRemap_U64(x: imgui.ImU64, x0: imgui.ImU64, x1: imgui.ImU64, y0: imgui.ImU64, y1: imgui.ImU64) imgui.ImU64;
pub const imRemap_U64 = ImPlot_ImRemap_U64;
pub extern fn ImPlot_ImRemap01_Float(x: f32, x0: f32, x1: f32) f32;
pub const imRemap01_Float = ImPlot_ImRemap01_Float;
pub extern fn ImPlot_ImRemap01_double(x: f64, x0: f64, x1: f64) f64;
pub const imRemap01_double = ImPlot_ImRemap01_double;
pub extern fn ImPlot_ImRemap01_S8(x: imgui.ImS8, x0: imgui.ImS8, x1: imgui.ImS8) imgui.ImS8;
pub const imRemap01_S8 = ImPlot_ImRemap01_S8;
pub extern fn ImPlot_ImRemap01_U8(x: imgui.ImU8, x0: imgui.ImU8, x1: imgui.ImU8) imgui.ImU8;
pub const imRemap01_U8 = ImPlot_ImRemap01_U8;
pub extern fn ImPlot_ImRemap01_S16(x: imgui.ImS16, x0: imgui.ImS16, x1: imgui.ImS16) imgui.ImS16;
pub const imRemap01_S16 = ImPlot_ImRemap01_S16;
pub extern fn ImPlot_ImRemap01_U16(x: imgui.ImU16, x0: imgui.ImU16, x1: imgui.ImU16) imgui.ImU16;
pub const imRemap01_U16 = ImPlot_ImRemap01_U16;
pub extern fn ImPlot_ImRemap01_S32(x: imgui.ImS32, x0: imgui.ImS32, x1: imgui.ImS32) imgui.ImS32;
pub const imRemap01_S32 = ImPlot_ImRemap01_S32;
pub extern fn ImPlot_ImRemap01_U32(x: imgui.ImU32, x0: imgui.ImU32, x1: imgui.ImU32) imgui.ImU32;
pub const imRemap01_U32 = ImPlot_ImRemap01_U32;
pub extern fn ImPlot_ImRemap01_S64(x: imgui.ImS64, x0: imgui.ImS64, x1: imgui.ImS64) imgui.ImS64;
pub const imRemap01_S64 = ImPlot_ImRemap01_S64;
pub extern fn ImPlot_ImRemap01_U64(x: imgui.ImU64, x0: imgui.ImU64, x1: imgui.ImU64) imgui.ImU64;
pub const imRemap01_U64 = ImPlot_ImRemap01_U64;
pub extern fn ImPlot_ImPosMod(l: c_int, r: c_int) c_int;
pub const imPosMod = ImPlot_ImPosMod;
pub extern fn ImPlot_ImNanOrInf(val: f64) bool;
pub const imNanOrInf = ImPlot_ImNanOrInf;
pub extern fn ImPlot_ImConstrainNan(val: f64) f64;
pub const imConstrainNan = ImPlot_ImConstrainNan;
pub extern fn ImPlot_ImConstrainInf(val: f64) f64;
pub const imConstrainInf = ImPlot_ImConstrainInf;
pub extern fn ImPlot_ImConstrainLog(val: f64) f64;
pub const imConstrainLog = ImPlot_ImConstrainLog;
pub extern fn ImPlot_ImConstrainTime(val: f64) f64;
pub const imConstrainTime = ImPlot_ImConstrainTime;
pub extern fn ImPlot_ImAlmostEqual(v1: f64, v2: f64, ulp: c_int) bool;
pub const imAlmostEqual = ImPlot_ImAlmostEqual;
pub extern fn ImPlot_ImMinArray_FloatPtr(values: [*c]const f32, count: c_int) f32;
pub const imMinArray_FloatPtr = ImPlot_ImMinArray_FloatPtr;
pub extern fn ImPlot_ImMinArray_doublePtr(values: [*c]const f64, count: c_int) f64;
pub const imMinArray_doublePtr = ImPlot_ImMinArray_doublePtr;
pub extern fn ImPlot_ImMinArray_S8Ptr(values: [*c]const imgui.ImS8, count: c_int) imgui.ImS8;
pub const imMinArray_S8Ptr = ImPlot_ImMinArray_S8Ptr;
pub extern fn ImPlot_ImMinArray_U8Ptr(values: [*c]const imgui.ImU8, count: c_int) imgui.ImU8;
pub const imMinArray_U8Ptr = ImPlot_ImMinArray_U8Ptr;
pub extern fn ImPlot_ImMinArray_S16Ptr(values: [*c]const imgui.ImS16, count: c_int) imgui.ImS16;
pub const imMinArray_S16Ptr = ImPlot_ImMinArray_S16Ptr;
pub extern fn ImPlot_ImMinArray_U16Ptr(values: [*c]const imgui.ImU16, count: c_int) imgui.ImU16;
pub const imMinArray_U16Ptr = ImPlot_ImMinArray_U16Ptr;
pub extern fn ImPlot_ImMinArray_S32Ptr(values: [*c]const imgui.ImS32, count: c_int) imgui.ImS32;
pub const imMinArray_S32Ptr = ImPlot_ImMinArray_S32Ptr;
pub extern fn ImPlot_ImMinArray_U32Ptr(values: [*c]const imgui.ImU32, count: c_int) imgui.ImU32;
pub const imMinArray_U32Ptr = ImPlot_ImMinArray_U32Ptr;
pub extern fn ImPlot_ImMinArray_S64Ptr(values: [*c]const imgui.ImS64, count: c_int) imgui.ImS64;
pub const imMinArray_S64Ptr = ImPlot_ImMinArray_S64Ptr;
pub extern fn ImPlot_ImMinArray_U64Ptr(values: [*c]const imgui.ImU64, count: c_int) imgui.ImU64;
pub const imMinArray_U64Ptr = ImPlot_ImMinArray_U64Ptr;
pub extern fn ImPlot_ImMaxArray_FloatPtr(values: [*c]const f32, count: c_int) f32;
pub const imMaxArray_FloatPtr = ImPlot_ImMaxArray_FloatPtr;
pub extern fn ImPlot_ImMaxArray_doublePtr(values: [*c]const f64, count: c_int) f64;
pub const imMaxArray_doublePtr = ImPlot_ImMaxArray_doublePtr;
pub extern fn ImPlot_ImMaxArray_S8Ptr(values: [*c]const imgui.ImS8, count: c_int) imgui.ImS8;
pub const imMaxArray_S8Ptr = ImPlot_ImMaxArray_S8Ptr;
pub extern fn ImPlot_ImMaxArray_U8Ptr(values: [*c]const imgui.ImU8, count: c_int) imgui.ImU8;
pub const imMaxArray_U8Ptr = ImPlot_ImMaxArray_U8Ptr;
pub extern fn ImPlot_ImMaxArray_S16Ptr(values: [*c]const imgui.ImS16, count: c_int) imgui.ImS16;
pub const imMaxArray_S16Ptr = ImPlot_ImMaxArray_S16Ptr;
pub extern fn ImPlot_ImMaxArray_U16Ptr(values: [*c]const imgui.ImU16, count: c_int) imgui.ImU16;
pub const imMaxArray_U16Ptr = ImPlot_ImMaxArray_U16Ptr;
pub extern fn ImPlot_ImMaxArray_S32Ptr(values: [*c]const imgui.ImS32, count: c_int) imgui.ImS32;
pub const imMaxArray_S32Ptr = ImPlot_ImMaxArray_S32Ptr;
pub extern fn ImPlot_ImMaxArray_U32Ptr(values: [*c]const imgui.ImU32, count: c_int) imgui.ImU32;
pub const imMaxArray_U32Ptr = ImPlot_ImMaxArray_U32Ptr;
pub extern fn ImPlot_ImMaxArray_S64Ptr(values: [*c]const imgui.ImS64, count: c_int) imgui.ImS64;
pub const imMaxArray_S64Ptr = ImPlot_ImMaxArray_S64Ptr;
pub extern fn ImPlot_ImMaxArray_U64Ptr(values: [*c]const imgui.ImU64, count: c_int) imgui.ImU64;
pub const imMaxArray_U64Ptr = ImPlot_ImMaxArray_U64Ptr;
pub extern fn ImPlot_ImMinMaxArray_FloatPtr(values: [*c]const f32, count: c_int, min_out: [*c]f32, max_out: [*c]f32) void;
pub const imMinMaxArray_FloatPtr = ImPlot_ImMinMaxArray_FloatPtr;
pub extern fn ImPlot_ImMinMaxArray_doublePtr(values: [*c]const f64, count: c_int, min_out: [*c]f64, max_out: [*c]f64) void;
pub const imMinMaxArray_doublePtr = ImPlot_ImMinMaxArray_doublePtr;
pub extern fn ImPlot_ImMinMaxArray_S8Ptr(values: [*c]const imgui.ImS8, count: c_int, min_out: [*c]imgui.ImS8, max_out: [*c]imgui.ImS8) void;
pub const imMinMaxArray_S8Ptr = ImPlot_ImMinMaxArray_S8Ptr;
pub extern fn ImPlot_ImMinMaxArray_U8Ptr(values: [*c]const imgui.ImU8, count: c_int, min_out: [*c]imgui.ImU8, max_out: [*c]imgui.ImU8) void;
pub const imMinMaxArray_U8Ptr = ImPlot_ImMinMaxArray_U8Ptr;
pub extern fn ImPlot_ImMinMaxArray_S16Ptr(values: [*c]const imgui.ImS16, count: c_int, min_out: [*c]imgui.ImS16, max_out: [*c]imgui.ImS16) void;
pub const imMinMaxArray_S16Ptr = ImPlot_ImMinMaxArray_S16Ptr;
pub extern fn ImPlot_ImMinMaxArray_U16Ptr(values: [*c]const imgui.ImU16, count: c_int, min_out: [*c]imgui.ImU16, max_out: [*c]imgui.ImU16) void;
pub const imMinMaxArray_U16Ptr = ImPlot_ImMinMaxArray_U16Ptr;
pub extern fn ImPlot_ImMinMaxArray_S32Ptr(values: [*c]const imgui.ImS32, count: c_int, min_out: [*c]imgui.ImS32, max_out: [*c]imgui.ImS32) void;
pub const imMinMaxArray_S32Ptr = ImPlot_ImMinMaxArray_S32Ptr;
pub extern fn ImPlot_ImMinMaxArray_U32Ptr(values: [*c]const imgui.ImU32, count: c_int, min_out: [*c]imgui.ImU32, max_out: [*c]imgui.ImU32) void;
pub const imMinMaxArray_U32Ptr = ImPlot_ImMinMaxArray_U32Ptr;
pub extern fn ImPlot_ImMinMaxArray_S64Ptr(values: [*c]const imgui.ImS64, count: c_int, min_out: [*c]imgui.ImS64, max_out: [*c]imgui.ImS64) void;
pub const imMinMaxArray_S64Ptr = ImPlot_ImMinMaxArray_S64Ptr;
pub extern fn ImPlot_ImMinMaxArray_U64Ptr(values: [*c]const imgui.ImU64, count: c_int, min_out: [*c]imgui.ImU64, max_out: [*c]imgui.ImU64) void;
pub const imMinMaxArray_U64Ptr = ImPlot_ImMinMaxArray_U64Ptr;
pub extern fn ImPlot_ImSum_FloatPtr(values: [*c]const f32, count: c_int) f32;
pub const imSum_FloatPtr = ImPlot_ImSum_FloatPtr;
pub extern fn ImPlot_ImSum_doublePtr(values: [*c]const f64, count: c_int) f64;
pub const imSum_doublePtr = ImPlot_ImSum_doublePtr;
pub extern fn ImPlot_ImSum_S8Ptr(values: [*c]const imgui.ImS8, count: c_int) imgui.ImS8;
pub const imSum_S8Ptr = ImPlot_ImSum_S8Ptr;
pub extern fn ImPlot_ImSum_U8Ptr(values: [*c]const imgui.ImU8, count: c_int) imgui.ImU8;
pub const imSum_U8Ptr = ImPlot_ImSum_U8Ptr;
pub extern fn ImPlot_ImSum_S16Ptr(values: [*c]const imgui.ImS16, count: c_int) imgui.ImS16;
pub const imSum_S16Ptr = ImPlot_ImSum_S16Ptr;
pub extern fn ImPlot_ImSum_U16Ptr(values: [*c]const imgui.ImU16, count: c_int) imgui.ImU16;
pub const imSum_U16Ptr = ImPlot_ImSum_U16Ptr;
pub extern fn ImPlot_ImSum_S32Ptr(values: [*c]const imgui.ImS32, count: c_int) imgui.ImS32;
pub const imSum_S32Ptr = ImPlot_ImSum_S32Ptr;
pub extern fn ImPlot_ImSum_U32Ptr(values: [*c]const imgui.ImU32, count: c_int) imgui.ImU32;
pub const imSum_U32Ptr = ImPlot_ImSum_U32Ptr;
pub extern fn ImPlot_ImSum_S64Ptr(values: [*c]const imgui.ImS64, count: c_int) imgui.ImS64;
pub const imSum_S64Ptr = ImPlot_ImSum_S64Ptr;
pub extern fn ImPlot_ImSum_U64Ptr(values: [*c]const imgui.ImU64, count: c_int) imgui.ImU64;
pub const imSum_U64Ptr = ImPlot_ImSum_U64Ptr;
pub extern fn ImPlot_ImMean_FloatPtr(values: [*c]const f32, count: c_int) f64;
pub const imMean_FloatPtr = ImPlot_ImMean_FloatPtr;
pub extern fn ImPlot_ImMean_doublePtr(values: [*c]const f64, count: c_int) f64;
pub const imMean_doublePtr = ImPlot_ImMean_doublePtr;
pub extern fn ImPlot_ImMean_S8Ptr(values: [*c]const imgui.ImS8, count: c_int) f64;
pub const imMean_S8Ptr = ImPlot_ImMean_S8Ptr;
pub extern fn ImPlot_ImMean_U8Ptr(values: [*c]const imgui.ImU8, count: c_int) f64;
pub const imMean_U8Ptr = ImPlot_ImMean_U8Ptr;
pub extern fn ImPlot_ImMean_S16Ptr(values: [*c]const imgui.ImS16, count: c_int) f64;
pub const imMean_S16Ptr = ImPlot_ImMean_S16Ptr;
pub extern fn ImPlot_ImMean_U16Ptr(values: [*c]const imgui.ImU16, count: c_int) f64;
pub const imMean_U16Ptr = ImPlot_ImMean_U16Ptr;
pub extern fn ImPlot_ImMean_S32Ptr(values: [*c]const imgui.ImS32, count: c_int) f64;
pub const imMean_S32Ptr = ImPlot_ImMean_S32Ptr;
pub extern fn ImPlot_ImMean_U32Ptr(values: [*c]const imgui.ImU32, count: c_int) f64;
pub const imMean_U32Ptr = ImPlot_ImMean_U32Ptr;
pub extern fn ImPlot_ImMean_S64Ptr(values: [*c]const imgui.ImS64, count: c_int) f64;
pub const imMean_S64Ptr = ImPlot_ImMean_S64Ptr;
pub extern fn ImPlot_ImMean_U64Ptr(values: [*c]const imgui.ImU64, count: c_int) f64;
pub const imMean_U64Ptr = ImPlot_ImMean_U64Ptr;
pub extern fn ImPlot_ImStdDev_FloatPtr(values: [*c]const f32, count: c_int) f64;
pub const imStdDev_FloatPtr = ImPlot_ImStdDev_FloatPtr;
pub extern fn ImPlot_ImStdDev_doublePtr(values: [*c]const f64, count: c_int) f64;
pub const imStdDev_doublePtr = ImPlot_ImStdDev_doublePtr;
pub extern fn ImPlot_ImStdDev_S8Ptr(values: [*c]const imgui.ImS8, count: c_int) f64;
pub const imStdDev_S8Ptr = ImPlot_ImStdDev_S8Ptr;
pub extern fn ImPlot_ImStdDev_U8Ptr(values: [*c]const imgui.ImU8, count: c_int) f64;
pub const imStdDev_U8Ptr = ImPlot_ImStdDev_U8Ptr;
pub extern fn ImPlot_ImStdDev_S16Ptr(values: [*c]const imgui.ImS16, count: c_int) f64;
pub const imStdDev_S16Ptr = ImPlot_ImStdDev_S16Ptr;
pub extern fn ImPlot_ImStdDev_U16Ptr(values: [*c]const imgui.ImU16, count: c_int) f64;
pub const imStdDev_U16Ptr = ImPlot_ImStdDev_U16Ptr;
pub extern fn ImPlot_ImStdDev_S32Ptr(values: [*c]const imgui.ImS32, count: c_int) f64;
pub const imStdDev_S32Ptr = ImPlot_ImStdDev_S32Ptr;
pub extern fn ImPlot_ImStdDev_U32Ptr(values: [*c]const imgui.ImU32, count: c_int) f64;
pub const imStdDev_U32Ptr = ImPlot_ImStdDev_U32Ptr;
pub extern fn ImPlot_ImStdDev_S64Ptr(values: [*c]const imgui.ImS64, count: c_int) f64;
pub const imStdDev_S64Ptr = ImPlot_ImStdDev_S64Ptr;
pub extern fn ImPlot_ImStdDev_U64Ptr(values: [*c]const imgui.ImU64, count: c_int) f64;
pub const imStdDev_U64Ptr = ImPlot_ImStdDev_U64Ptr;
pub extern fn ImPlot_ImMixU32(a: imgui.ImU32, b: imgui.ImU32, s: imgui.ImU32) imgui.ImU32;
pub const imMixU32 = ImPlot_ImMixU32;
pub extern fn ImPlot_ImLerpU32(colors: [*c]const imgui.ImU32, size: c_int, t: f32) imgui.ImU32;
pub const imLerpU32 = ImPlot_ImLerpU32;
pub extern fn ImPlot_ImAlphaU32(col: imgui.ImU32, alpha: f32) imgui.ImU32;
pub const imAlphaU32 = ImPlot_ImAlphaU32;
pub extern fn ImBufferWriter_ImBufferWriter(buffer: [*c]u8, size: c_int) [*c]ImBufferWriter;
pub extern fn ImBufferWriter_destroy(self: [*c]ImBufferWriter) void;
pub extern fn ImBufferWriter_Write(self: [*c]ImBufferWriter, fmt: [*c]const u8, ...) void;
pub extern fn ImPlotInputMap_ImPlotInputMap() [*c]ImPlotInputMap;
pub extern fn ImPlotInputMap_destroy(self: [*c]ImPlotInputMap) void;
pub extern fn ImPlotDateTimeFmt_ImPlotDateTimeFmt(date_fmt: ImPlotDateFmt, time_fmt: ImPlotTimeFmt, use_24_hr_clk: bool, use_iso_8601: bool) [*c]ImPlotDateTimeFmt;
pub extern fn ImPlotDateTimeFmt_destroy(self: [*c]ImPlotDateTimeFmt) void;
pub extern fn ImPlotTime_ImPlotTime_Nil() [*c]ImPlotTime;
pub extern fn ImPlotTime_destroy(self: [*c]ImPlotTime) void;
pub extern fn ImPlotTime_ImPlotTime_time_t(s: time_t, us: c_int) [*c]ImPlotTime;
pub extern fn ImPlotTime_RollOver(self: [*c]ImPlotTime) void;
pub extern fn ImPlotTime_ToDouble(self: [*c]ImPlotTime) f64;
pub extern fn ImPlotTime_FromDouble(pOut: [*c]ImPlotTime, t: f64) void;
pub extern fn ImPlotColormapData_ImPlotColormapData() [*c]ImPlotColormapData;
pub extern fn ImPlotColormapData_destroy(self: [*c]ImPlotColormapData) void;
pub extern fn ImPlotColormapData_Append(self: [*c]ImPlotColormapData, name: [*c]const u8, keys: [*c]const imgui.ImU32, count: c_int, qual: bool) c_int;
pub extern fn ImPlotColormapData__AppendTable(self: [*c]ImPlotColormapData, cmap: ImPlotColormap) void;
pub extern fn ImPlotColormapData_RebuildTables(self: [*c]ImPlotColormapData) void;
pub extern fn ImPlotColormapData_IsQual(self: [*c]ImPlotColormapData, cmap: ImPlotColormap) bool;
pub extern fn ImPlotColormapData_GetName(self: [*c]ImPlotColormapData, cmap: ImPlotColormap) [*c]const u8;
pub extern fn ImPlotColormapData_GetIndex(self: [*c]ImPlotColormapData, name: [*c]const u8) ImPlotColormap;
pub extern fn ImPlotColormapData_GetKeys(self: [*c]ImPlotColormapData, cmap: ImPlotColormap) [*c]const imgui.ImU32;
pub extern fn ImPlotColormapData_GetKeyCount(self: [*c]ImPlotColormapData, cmap: ImPlotColormap) c_int;
pub extern fn ImPlotColormapData_GetKeyColor(self: [*c]ImPlotColormapData, cmap: ImPlotColormap, idx: c_int) imgui.ImU32;
pub extern fn ImPlotColormapData_SetKeyColor(self: [*c]ImPlotColormapData, cmap: ImPlotColormap, idx: c_int, value: imgui.ImU32) void;
pub extern fn ImPlotColormapData_GetTable(self: [*c]ImPlotColormapData, cmap: ImPlotColormap) [*c]const imgui.ImU32;
pub extern fn ImPlotColormapData_GetTableSize(self: [*c]ImPlotColormapData, cmap: ImPlotColormap) c_int;
pub extern fn ImPlotColormapData_GetTableColor(self: [*c]ImPlotColormapData, cmap: ImPlotColormap, idx: c_int) imgui.ImU32;
pub extern fn ImPlotColormapData_LerpTable(self: [*c]ImPlotColormapData, cmap: ImPlotColormap, t: f32) imgui.ImU32;
pub extern fn ImPlotPointError_ImPlotPointError(x: f64, y: f64, neg: f64, pos: f64) [*c]ImPlotPointError;
pub extern fn ImPlotPointError_destroy(self: [*c]ImPlotPointError) void;
pub extern fn ImPlotAnnotationCollection_ImPlotAnnotationCollection() [*c]ImPlotAnnotationCollection;
pub extern fn ImPlotAnnotationCollection_destroy(self: [*c]ImPlotAnnotationCollection) void;
pub extern fn ImPlotAnnotationCollection_Append(self: [*c]ImPlotAnnotationCollection, pos: imgui.ImVec2, off: imgui.ImVec2, bg: imgui.ImU32, fg: imgui.ImU32, clamp: bool, fmt: [*c]const u8, ...) void;
pub extern fn ImPlotAnnotationCollection_GetText(self: [*c]ImPlotAnnotationCollection, idx: c_int) [*c]const u8;
pub extern fn ImPlotAnnotationCollection_Reset(self: [*c]ImPlotAnnotationCollection) void;
pub extern fn ImPlotTick_ImPlotTick(value: f64, major: bool, show_label: bool) [*c]ImPlotTick;
pub extern fn ImPlotTick_destroy(self: [*c]ImPlotTick) void;
pub extern fn ImPlotTickCollection_ImPlotTickCollection() [*c]ImPlotTickCollection;
pub extern fn ImPlotTickCollection_destroy(self: [*c]ImPlotTickCollection) void;
pub extern fn ImPlotTickCollection_Append_PlotTick(self: [*c]ImPlotTickCollection, tick: ImPlotTick) [*c]const ImPlotTick;
pub extern fn ImPlotTickCollection_Append_double(self: [*c]ImPlotTickCollection, value: f64, major: bool, show_label: bool, fmt: [*c]const u8) [*c]const ImPlotTick;
pub extern fn ImPlotTickCollection_GetText(self: [*c]ImPlotTickCollection, idx: c_int) [*c]const u8;
pub extern fn ImPlotTickCollection_Reset(self: [*c]ImPlotTickCollection) void;
pub extern fn ImPlotAxis_ImPlotAxis() [*c]ImPlotAxis;
pub extern fn ImPlotAxis_destroy(self: [*c]ImPlotAxis) void;
pub extern fn ImPlotAxis_SetMin(self: [*c]ImPlotAxis, _min: f64, force: bool) bool;
pub extern fn ImPlotAxis_SetMax(self: [*c]ImPlotAxis, _max: f64, force: bool) bool;
pub extern fn ImPlotAxis_SetRange_double(self: [*c]ImPlotAxis, _min: f64, _max: f64) void;
pub extern fn ImPlotAxis_SetRange_PlotRange(self: [*c]ImPlotAxis, range: ImPlotRange) void;
pub extern fn ImPlotAxis_SetAspect(self: [*c]ImPlotAxis, unit_per_pix: f64) void;
pub extern fn ImPlotAxis_GetAspect(self: [*c]ImPlotAxis) f64;
pub extern fn ImPlotAxis_Constrain(self: [*c]ImPlotAxis) void;
pub extern fn ImPlotAxis_IsLabeled(self: [*c]ImPlotAxis) bool;
pub extern fn ImPlotAxis_IsInverted(self: [*c]ImPlotAxis) bool;
pub extern fn ImPlotAxis_IsAutoFitting(self: [*c]ImPlotAxis) bool;
pub extern fn ImPlotAxis_IsRangeLocked(self: [*c]ImPlotAxis) bool;
pub extern fn ImPlotAxis_IsLockedMin(self: [*c]ImPlotAxis) bool;
pub extern fn ImPlotAxis_IsLockedMax(self: [*c]ImPlotAxis) bool;
pub extern fn ImPlotAxis_IsLocked(self: [*c]ImPlotAxis) bool;
pub extern fn ImPlotAxis_IsInputLockedMin(self: [*c]ImPlotAxis) bool;
pub extern fn ImPlotAxis_IsInputLockedMax(self: [*c]ImPlotAxis) bool;
pub extern fn ImPlotAxis_IsInputLocked(self: [*c]ImPlotAxis) bool;
pub extern fn ImPlotAxis_IsTime(self: [*c]ImPlotAxis) bool;
pub extern fn ImPlotAxis_IsLog(self: [*c]ImPlotAxis) bool;
pub extern fn ImPlotAlignmentData_ImPlotAlignmentData() [*c]ImPlotAlignmentData;
pub extern fn ImPlotAlignmentData_destroy(self: [*c]ImPlotAlignmentData) void;
pub extern fn ImPlotAlignmentData_Begin(self: [*c]ImPlotAlignmentData) void;
pub extern fn ImPlotAlignmentData_Update(self: [*c]ImPlotAlignmentData, pad_a: [*c]f32, pad_b: [*c]f32) void;
pub extern fn ImPlotAlignmentData_End(self: [*c]ImPlotAlignmentData) void;
pub extern fn ImPlotAlignmentData_Reset(self: [*c]ImPlotAlignmentData) void;
pub extern fn ImPlotItem_ImPlotItem() [*c]ImPlotItem;
pub extern fn ImPlotItem_destroy(self: [*c]ImPlotItem) void;
pub extern fn ImPlotLegendData_ImPlotLegendData() [*c]ImPlotLegendData;
pub extern fn ImPlotLegendData_destroy(self: [*c]ImPlotLegendData) void;
pub extern fn ImPlotLegendData_Reset(self: [*c]ImPlotLegendData) void;
pub extern fn ImPlotItemGroup_ImPlotItemGroup() [*c]ImPlotItemGroup;
pub extern fn ImPlotItemGroup_destroy(self: [*c]ImPlotItemGroup) void;
pub extern fn ImPlotItemGroup_GetItemCount(self: [*c]ImPlotItemGroup) c_int;
pub extern fn ImPlotItemGroup_GetItemID(self: [*c]ImPlotItemGroup, label_id: [*c]const u8) imgui.ImGuiID;
pub extern fn ImPlotItemGroup_GetItem_ID(self: [*c]ImPlotItemGroup, id: imgui.ImGuiID) [*c]ImPlotItem;
pub extern fn ImPlotItemGroup_GetItem_Str(self: [*c]ImPlotItemGroup, label_id: [*c]const u8) [*c]ImPlotItem;
pub extern fn ImPlotItemGroup_GetOrAddItem(self: [*c]ImPlotItemGroup, id: imgui.ImGuiID) [*c]ImPlotItem;
pub extern fn ImPlotItemGroup_GetItemByIndex(self: [*c]ImPlotItemGroup, i: c_int) [*c]ImPlotItem;
pub extern fn ImPlotItemGroup_GetItemIndex(self: [*c]ImPlotItemGroup, item: [*c]ImPlotItem) c_int;
pub extern fn ImPlotItemGroup_GetLegendCount(self: [*c]ImPlotItemGroup) c_int;
pub extern fn ImPlotItemGroup_GetLegendItem(self: [*c]ImPlotItemGroup, i: c_int) [*c]ImPlotItem;
pub extern fn ImPlotItemGroup_GetLegendLabel(self: [*c]ImPlotItemGroup, i: c_int) [*c]const u8;
pub extern fn ImPlotItemGroup_Reset(self: [*c]ImPlotItemGroup) void;
pub extern fn ImPlotPlot_ImPlotPlot() [*c]ImPlotPlot;
pub extern fn ImPlotPlot_destroy(self: [*c]ImPlotPlot) void;
pub extern fn ImPlotPlot_AnyYInputLocked(self: [*c]ImPlotPlot) bool;
pub extern fn ImPlotPlot_AllYInputLocked(self: [*c]ImPlotPlot) bool;
pub extern fn ImPlotPlot_IsInputLocked(self: [*c]ImPlotPlot) bool;
pub extern fn ImPlotSubplot_ImPlotSubplot() [*c]ImPlotSubplot;
pub extern fn ImPlotSubplot_destroy(self: [*c]ImPlotSubplot) void;
pub extern fn ImPlotNextPlotData_ImPlotNextPlotData() [*c]ImPlotNextPlotData;
pub extern fn ImPlotNextPlotData_destroy(self: [*c]ImPlotNextPlotData) void;
pub extern fn ImPlotNextPlotData_Reset(self: [*c]ImPlotNextPlotData) void;
pub extern fn ImPlotNextItemData_ImPlotNextItemData() [*c]ImPlotNextItemData;
pub extern fn ImPlotNextItemData_destroy(self: [*c]ImPlotNextItemData) void;
pub extern fn ImPlotNextItemData_Reset(self: [*c]ImPlotNextItemData) void;
pub extern fn ImPlot_Initialize(ctx: [*c]ImPlotContext) void;
pub const initialize = ImPlot_Initialize;
pub extern fn ImPlot_ResetCtxForNextPlot(ctx: [*c]ImPlotContext) void;
pub const resetCtxForNextPlot = ImPlot_ResetCtxForNextPlot;
pub extern fn ImPlot_ResetCtxForNextAlignedPlots(ctx: [*c]ImPlotContext) void;
pub const resetCtxForNextAlignedPlots = ImPlot_ResetCtxForNextAlignedPlots;
pub extern fn ImPlot_ResetCtxForNextSubplot(ctx: [*c]ImPlotContext) void;
pub const resetCtxForNextSubplot = ImPlot_ResetCtxForNextSubplot;
pub extern fn ImPlot_GetInputMap() [*c]ImPlotInputMap;
pub const getInputMap = ImPlot_GetInputMap;
pub extern fn ImPlot_GetPlot(title: [*c]const u8) [*c]ImPlotPlot;
pub const getPlot = ImPlot_GetPlot;
pub extern fn ImPlot_GetCurrentPlot() [*c]ImPlotPlot;
pub const getCurrentPlot = ImPlot_GetCurrentPlot;
pub extern fn ImPlot_BustPlotCache() void;
pub const bustPlotCache = ImPlot_BustPlotCache;
pub extern fn ImPlot_ShowPlotContextMenu(plot: [*c]ImPlotPlot) void;
pub const showPlotContextMenu = ImPlot_ShowPlotContextMenu;
pub extern fn ImPlot_SubplotNextCell() void;
pub const subplotNextCell = ImPlot_SubplotNextCell;
pub extern fn ImPlot_ShowSubplotsContextMenu(subplot: [*c]ImPlotSubplot) void;
pub const showSubplotsContextMenu = ImPlot_ShowSubplotsContextMenu;
pub extern fn ImPlot_BeginItem(label_id: [*c]const u8, recolor_from: ImPlotCol) bool;
pub const beginItem = ImPlot_BeginItem;
pub extern fn ImPlot_EndItem() void;
pub const endItem = ImPlot_EndItem;
pub extern fn ImPlot_RegisterOrGetItem(label_id: [*c]const u8, just_created: [*c]bool) [*c]ImPlotItem;
pub const registerOrGetItem = ImPlot_RegisterOrGetItem;
pub extern fn ImPlot_GetItem(label_id: [*c]const u8) [*c]ImPlotItem;
pub const getItem = ImPlot_GetItem;
pub extern fn ImPlot_GetCurrentItem() [*c]ImPlotItem;
pub const getCurrentItem = ImPlot_GetCurrentItem;
pub extern fn ImPlot_BustItemCache() void;
pub const bustItemCache = ImPlot_BustItemCache;
pub extern fn ImPlot_GetCurrentYAxis() c_int;
pub const getCurrentYAxis = ImPlot_GetCurrentYAxis;
pub extern fn ImPlot_UpdateAxisColors(axis_flag: c_int, axis: [*c]ImPlotAxis) void;
pub const updateAxisColors = ImPlot_UpdateAxisColors;
pub extern fn ImPlot_UpdateTransformCache() void;
pub const updateTransformCache = ImPlot_UpdateTransformCache;
pub extern fn ImPlot_GetCurrentScale() ImPlotScale;
pub const getCurrentScale = ImPlot_GetCurrentScale;
pub extern fn ImPlot_FitThisFrame() bool;
pub const fitThisFrame = ImPlot_FitThisFrame;
pub extern fn ImPlot_FitPointAxis(axis: [*c]ImPlotAxis, ext: [*c]ImPlotRange, v: f64) void;
pub const fitPointAxis = ImPlot_FitPointAxis;
pub extern fn ImPlot_FitPointMultiAxis(axis: [*c]ImPlotAxis, alt: [*c]ImPlotAxis, ext: [*c]ImPlotRange, v: f64, v_alt: f64) void;
pub const fitPointMultiAxis = ImPlot_FitPointMultiAxis;
pub extern fn ImPlot_FitPointX(x: f64) void;
pub const fitPointX = ImPlot_FitPointX;
pub extern fn ImPlot_FitPointY(y: f64) void;
pub const fitPointY = ImPlot_FitPointY;
pub extern fn ImPlot_FitPoint(p: ImPlotPoint) void;
pub const fitPoint = ImPlot_FitPoint;
pub extern fn ImPlot_RangesOverlap(r1: ImPlotRange, r2: ImPlotRange) bool;
pub const rangesOverlap = ImPlot_RangesOverlap;
pub extern fn ImPlot_PushLinkedAxis(axis: [*c]ImPlotAxis) void;
pub const pushLinkedAxis = ImPlot_PushLinkedAxis;
pub extern fn ImPlot_PullLinkedAxis(axis: [*c]ImPlotAxis) void;
pub const pullLinkedAxis = ImPlot_PullLinkedAxis;
pub extern fn ImPlot_ShowAxisContextMenu(axis: [*c]ImPlotAxis, equal_axis: [*c]ImPlotAxis, time_allowed: bool) void;
pub const showAxisContextMenu = ImPlot_ShowAxisContextMenu;
pub extern fn ImPlot_GetFormatX() [*c]const u8;
pub const getFormatX = ImPlot_GetFormatX;
pub extern fn ImPlot_GetFormatY(y: ImPlotYAxis) [*c]const u8;
pub const getFormatY = ImPlot_GetFormatY;
pub extern fn ImPlot_GetLocationPos(pOut: [*c]imgui.ImVec2, outer_rect: imgui.ImRect, inner_size: imgui.ImVec2, location: ImPlotLocation, pad: imgui.ImVec2) void;
pub const getLocationPos = ImPlot_GetLocationPos;
pub extern fn ImPlot_CalcLegendSize(pOut: [*c]imgui.ImVec2, items: [*c]ImPlotItemGroup, pad: imgui.ImVec2, spacing: imgui.ImVec2, orientation: ImPlotOrientation) void;
pub const calcLegendSize = ImPlot_CalcLegendSize;
pub extern fn ImPlot_ShowLegendEntries(items: [*c]ImPlotItemGroup, legend_bb: imgui.ImRect, interactable: bool, pad: imgui.ImVec2, spacing: imgui.ImVec2, orientation: ImPlotOrientation, DrawList: [*c]imgui.ImDrawList) bool;
pub const showLegendEntries = ImPlot_ShowLegendEntries;
pub extern fn ImPlot_ShowAltLegend(title_id: [*c]const u8, orientation: ImPlotOrientation, size: imgui.ImVec2, interactable: bool) void;
pub const showAltLegend = ImPlot_ShowAltLegend;
pub extern fn ImPlot_ShowLegendContextMenu(legend: [*c]ImPlotLegendData, visible: bool) bool;
pub const showLegendContextMenu = ImPlot_ShowLegendContextMenu;
pub extern fn ImPlot_LabelTickTime(tick: [*c]ImPlotTick, buffer: [*c]imgui.ImGuiTextBuffer, t: ImPlotTime, fmt: ImPlotDateTimeFmt) void;
pub const labelTickTime = ImPlot_LabelTickTime;
pub extern fn ImPlot_AddTicksDefault(range: ImPlotRange, pix: f32, orn: ImPlotOrientation, ticks: [*c]ImPlotTickCollection, fmt: [*c]const u8) void;
pub const addTicksDefault = ImPlot_AddTicksDefault;
pub extern fn ImPlot_AddTicksLogarithmic(range: ImPlotRange, pix: f32, orn: ImPlotOrientation, ticks: [*c]ImPlotTickCollection, fmt: [*c]const u8) void;
pub const addTicksLogarithmic = ImPlot_AddTicksLogarithmic;
pub extern fn ImPlot_AddTicksTime(range: ImPlotRange, plot_width: f32, ticks: [*c]ImPlotTickCollection) void;
pub const addTicksTime = ImPlot_AddTicksTime;
pub extern fn ImPlot_AddTicksCustom(values: [*c]const f64, labels: [*c]const [*c]const u8, n: c_int, ticks: [*c]ImPlotTickCollection, fmt: [*c]const u8) void;
pub const addTicksCustom = ImPlot_AddTicksCustom;
pub extern fn ImPlot_LabelAxisValue(axis: ImPlotAxis, ticks: ImPlotTickCollection, value: f64, buff: [*c]u8, size: c_int) c_int;
pub const labelAxisValue = ImPlot_LabelAxisValue;
pub extern fn ImPlot_GetItemData() [*c]const ImPlotNextItemData;
pub const getItemData = ImPlot_GetItemData;
pub extern fn ImPlot_IsColorAuto_Vec4(col: imgui.ImVec4) bool;
pub const isColorAuto_Vec4 = ImPlot_IsColorAuto_Vec4;
pub extern fn ImPlot_IsColorAuto_PlotCol(idx: ImPlotCol) bool;
pub const isColorAuto_PlotCol = ImPlot_IsColorAuto_PlotCol;
pub extern fn ImPlot_GetAutoColor(pOut: [*c]imgui.ImVec4, idx: ImPlotCol) void;
pub const getAutoColor = ImPlot_GetAutoColor;
pub extern fn ImPlot_GetStyleColorVec4(pOut: [*c]imgui.ImVec4, idx: ImPlotCol) void;
pub const getStyleColorVec4 = ImPlot_GetStyleColorVec4;
pub extern fn ImPlot_GetStyleColorU32(idx: ImPlotCol) imgui.ImU32;
pub const getStyleColorU32 = ImPlot_GetStyleColorU32;
pub extern fn ImPlot_AddTextVertical(DrawList: [*c]imgui.ImDrawList, pos: imgui.ImVec2, col: imgui.ImU32, text_begin: [*c]const u8, text_end: [*c]const u8) void;
pub const addTextVertical = ImPlot_AddTextVertical;
pub extern fn ImPlot_AddTextCentered(DrawList: [*c]imgui.ImDrawList, top_center: imgui.ImVec2, col: imgui.ImU32, text_begin: [*c]const u8, text_end: [*c]const u8) void;
pub const addTextCentered = ImPlot_AddTextCentered;
pub extern fn ImPlot_CalcTextSizeVertical(pOut: [*c]imgui.ImVec2, text: [*c]const u8) void;
pub const calcTextSizeVertical = ImPlot_CalcTextSizeVertical;
pub extern fn ImPlot_CalcTextColor_Vec4(bg: imgui.ImVec4) imgui.ImU32;
pub const calcTextColor_Vec4 = ImPlot_CalcTextColor_Vec4;
pub extern fn ImPlot_CalcTextColor_U32(bg: imgui.ImU32) imgui.ImU32;
pub const calcTextColor_U32 = ImPlot_CalcTextColor_U32;
pub extern fn ImPlot_CalcHoverColor(col: imgui.ImU32) imgui.ImU32;
pub const calcHoverColor = ImPlot_CalcHoverColor;
pub extern fn ImPlot_ClampLabelPos(pOut: [*c]imgui.ImVec2, pos: imgui.ImVec2, size: imgui.ImVec2, Min: imgui.ImVec2, Max: imgui.ImVec2) void;
pub const clampLabelPos = ImPlot_ClampLabelPos;
pub extern fn ImPlot_GetColormapColorU32(idx: c_int, cmap: ImPlotColormap) imgui.ImU32;
pub const getColormapColorU32 = ImPlot_GetColormapColorU32;
pub extern fn ImPlot_NextColormapColorU32() imgui.ImU32;
pub const nextColormapColorU32 = ImPlot_NextColormapColorU32;
pub extern fn ImPlot_SampleColormapU32(t: f32, cmap: ImPlotColormap) imgui.ImU32;
pub const sampleColormapU32 = ImPlot_SampleColormapU32;
pub extern fn ImPlot_RenderColorBar(colors: [*c]const imgui.ImU32, size: c_int, DrawList: [*c]imgui.ImDrawList, bounds: imgui.ImRect, vert: bool, reversed: bool, continuous: bool) void;
pub const renderColorBar = ImPlot_RenderColorBar;
pub extern fn ImPlot_NiceNum(x: f64, round: bool) f64;
pub const niceNum = ImPlot_NiceNum;
pub extern fn ImPlot_OrderOfMagnitude(val: f64) c_int;
pub const orderOfMagnitude = ImPlot_OrderOfMagnitude;
pub extern fn ImPlot_OrderToPrecision(order: c_int) c_int;
pub const orderToPrecision = ImPlot_OrderToPrecision;
pub extern fn ImPlot_Precision(val: f64) c_int;
pub const precision = ImPlot_Precision;
pub extern fn ImPlot_RoundTo(val: f64, prec: c_int) f64;
pub const roundTo = ImPlot_RoundTo;
pub extern fn ImPlot_Intersection(pOut: [*c]imgui.ImVec2, a1: imgui.ImVec2, a2: imgui.ImVec2, b1: imgui.ImVec2, b2: imgui.ImVec2) void;
pub const intersection = ImPlot_Intersection;
pub extern fn ImPlot_FillRange_Vector_FloatPtr(buffer: [*c]imgui.ImVector_float, n: c_int, vmin: f32, vmax: f32) void;
pub const fillRange_Vector_FloatPtr = ImPlot_FillRange_Vector_FloatPtr;
pub extern fn ImPlot_FillRange_Vector_doublePtr(buffer: [*c]ImVector_double, n: c_int, vmin: f64, vmax: f64) void;
pub const fillRange_Vector_doublePtr = ImPlot_FillRange_Vector_doublePtr;
pub extern fn ImPlot_FillRange_Vector_S8Ptr(buffer: [*c]ImVector_ImS8, n: c_int, vmin: imgui.ImS8, vmax: imgui.ImS8) void;
pub const fillRange_Vector_S8Ptr = ImPlot_FillRange_Vector_S8Ptr;
pub extern fn ImPlot_FillRange_Vector_U8Ptr(buffer: [*c]ImVector_ImU8, n: c_int, vmin: imgui.ImU8, vmax: imgui.ImU8) void;
pub const fillRange_Vector_U8Ptr = ImPlot_FillRange_Vector_U8Ptr;
pub extern fn ImPlot_FillRange_Vector_S16Ptr(buffer: [*c]ImVector_ImS16, n: c_int, vmin: imgui.ImS16, vmax: imgui.ImS16) void;
pub const fillRange_Vector_S16Ptr = ImPlot_FillRange_Vector_S16Ptr;
pub extern fn ImPlot_FillRange_Vector_U16Ptr(buffer: [*c]ImVector_ImU16, n: c_int, vmin: imgui.ImU16, vmax: imgui.ImU16) void;
pub const fillRange_Vector_U16Ptr = ImPlot_FillRange_Vector_U16Ptr;
pub extern fn ImPlot_FillRange_Vector_S32Ptr(buffer: [*c]ImVector_ImS32, n: c_int, vmin: imgui.ImS32, vmax: imgui.ImS32) void;
pub const fillRange_Vector_S32Ptr = ImPlot_FillRange_Vector_S32Ptr;
pub extern fn ImPlot_FillRange_Vector_U32Ptr(buffer: [*c]imgui.ImVector_ImU32, n: c_int, vmin: imgui.ImU32, vmax: imgui.ImU32) void;
pub const fillRange_Vector_U32Ptr = ImPlot_FillRange_Vector_U32Ptr;
pub extern fn ImPlot_FillRange_Vector_S64Ptr(buffer: [*c]ImVector_ImS64, n: c_int, vmin: imgui.ImS64, vmax: imgui.ImS64) void;
pub const fillRange_Vector_S64Ptr = ImPlot_FillRange_Vector_S64Ptr;
pub extern fn ImPlot_FillRange_Vector_U64Ptr(buffer: [*c]ImVector_ImU64, n: c_int, vmin: imgui.ImU64, vmax: imgui.ImU64) void;
pub const fillRange_Vector_U64Ptr = ImPlot_FillRange_Vector_U64Ptr;
pub extern fn ImPlot_CalculateBins_FloatPtr(values: [*c]const f32, count: c_int, meth: ImPlotBin, range: ImPlotRange, bins_out: [*c]c_int, width_out: [*c]f64) void;
pub const calculateBins_FloatPtr = ImPlot_CalculateBins_FloatPtr;
pub extern fn ImPlot_CalculateBins_doublePtr(values: [*c]const f64, count: c_int, meth: ImPlotBin, range: ImPlotRange, bins_out: [*c]c_int, width_out: [*c]f64) void;
pub const calculateBins_doublePtr = ImPlot_CalculateBins_doublePtr;
pub extern fn ImPlot_CalculateBins_S8Ptr(values: [*c]const imgui.ImS8, count: c_int, meth: ImPlotBin, range: ImPlotRange, bins_out: [*c]c_int, width_out: [*c]f64) void;
pub const calculateBins_S8Ptr = ImPlot_CalculateBins_S8Ptr;
pub extern fn ImPlot_CalculateBins_U8Ptr(values: [*c]const imgui.ImU8, count: c_int, meth: ImPlotBin, range: ImPlotRange, bins_out: [*c]c_int, width_out: [*c]f64) void;
pub const calculateBins_U8Ptr = ImPlot_CalculateBins_U8Ptr;
pub extern fn ImPlot_CalculateBins_S16Ptr(values: [*c]const imgui.ImS16, count: c_int, meth: ImPlotBin, range: ImPlotRange, bins_out: [*c]c_int, width_out: [*c]f64) void;
pub const calculateBins_S16Ptr = ImPlot_CalculateBins_S16Ptr;
pub extern fn ImPlot_CalculateBins_U16Ptr(values: [*c]const imgui.ImU16, count: c_int, meth: ImPlotBin, range: ImPlotRange, bins_out: [*c]c_int, width_out: [*c]f64) void;
pub const calculateBins_U16Ptr = ImPlot_CalculateBins_U16Ptr;
pub extern fn ImPlot_CalculateBins_S32Ptr(values: [*c]const imgui.ImS32, count: c_int, meth: ImPlotBin, range: ImPlotRange, bins_out: [*c]c_int, width_out: [*c]f64) void;
pub const calculateBins_S32Ptr = ImPlot_CalculateBins_S32Ptr;
pub extern fn ImPlot_CalculateBins_U32Ptr(values: [*c]const imgui.ImU32, count: c_int, meth: ImPlotBin, range: ImPlotRange, bins_out: [*c]c_int, width_out: [*c]f64) void;
pub const calculateBins_U32Ptr = ImPlot_CalculateBins_U32Ptr;
pub extern fn ImPlot_CalculateBins_S64Ptr(values: [*c]const imgui.ImS64, count: c_int, meth: ImPlotBin, range: ImPlotRange, bins_out: [*c]c_int, width_out: [*c]f64) void;
pub const calculateBins_S64Ptr = ImPlot_CalculateBins_S64Ptr;
pub extern fn ImPlot_CalculateBins_U64Ptr(values: [*c]const imgui.ImU64, count: c_int, meth: ImPlotBin, range: ImPlotRange, bins_out: [*c]c_int, width_out: [*c]f64) void;
pub const calculateBins_U64Ptr = ImPlot_CalculateBins_U64Ptr;
pub extern fn ImPlot_IsLeapYear(year: c_int) bool;
pub const isLeapYear = ImPlot_IsLeapYear;
pub extern fn ImPlot_GetDaysInMonth(year: c_int, month: c_int) c_int;
pub const getDaysInMonth = ImPlot_GetDaysInMonth;
pub extern fn ImPlot_MkGmtTime(pOut: [*c]ImPlotTime, ptm: [*c]struct_tm) void;
pub const mkGmtTime = ImPlot_MkGmtTime;
pub extern fn ImPlot_GetGmtTime(t: ImPlotTime, ptm: [*c]tm) [*c]tm;
pub const getGmtTime = ImPlot_GetGmtTime;
pub extern fn ImPlot_MkLocTime(pOut: [*c]ImPlotTime, ptm: [*c]struct_tm) void;
pub const mkLocTime = ImPlot_MkLocTime;
pub extern fn ImPlot_GetLocTime(t: ImPlotTime, ptm: [*c]tm) [*c]tm;
pub const getLocTime = ImPlot_GetLocTime;
pub extern fn ImPlot_MakeTime(pOut: [*c]ImPlotTime, year: c_int, month: c_int, day: c_int, hour: c_int, min: c_int, sec: c_int, us: c_int) void;
pub const makeTime = ImPlot_MakeTime;
pub extern fn ImPlot_GetYear(t: ImPlotTime) c_int;
pub const getYear = ImPlot_GetYear;
pub extern fn ImPlot_AddTime(pOut: [*c]ImPlotTime, t: ImPlotTime, unit: ImPlotTimeUnit, count: c_int) void;
pub const addTime = ImPlot_AddTime;
pub extern fn ImPlot_FloorTime(pOut: [*c]ImPlotTime, t: ImPlotTime, unit: ImPlotTimeUnit) void;
pub const floorTime = ImPlot_FloorTime;
pub extern fn ImPlot_CeilTime(pOut: [*c]ImPlotTime, t: ImPlotTime, unit: ImPlotTimeUnit) void;
pub const ceilTime = ImPlot_CeilTime;
pub extern fn ImPlot_RoundTime(pOut: [*c]ImPlotTime, t: ImPlotTime, unit: ImPlotTimeUnit) void;
pub const roundTime = ImPlot_RoundTime;
pub extern fn ImPlot_CombineDateTime(pOut: [*c]ImPlotTime, date_part: ImPlotTime, time_part: ImPlotTime) void;
pub const combineDateTime = ImPlot_CombineDateTime;
pub extern fn ImPlot_FormatTime(t: ImPlotTime, buffer: [*c]u8, size: c_int, fmt: ImPlotTimeFmt, use_24_hr_clk: bool) c_int;
pub const formatTime = ImPlot_FormatTime;
pub extern fn ImPlot_FormatDate(t: ImPlotTime, buffer: [*c]u8, size: c_int, fmt: ImPlotDateFmt, use_iso_8601: bool) c_int;
pub const formatDate = ImPlot_FormatDate;
pub extern fn ImPlot_FormatDateTime(t: ImPlotTime, buffer: [*c]u8, size: c_int, fmt: ImPlotDateTimeFmt) c_int;
pub const formatDateTime = ImPlot_FormatDateTime;
pub extern fn ImPlot_ShowDatePicker(id: [*c]const u8, level: [*c]c_int, t: [*c]ImPlotTime, t1: [*c]const ImPlotTime, t2: [*c]const ImPlotTime) bool;
pub const showDatePicker = ImPlot_ShowDatePicker;
pub extern fn ImPlot_ShowTimePicker(id: [*c]const u8, t: [*c]ImPlotTime) bool;
pub const showTimePicker = ImPlot_ShowTimePicker;
pub const ImPlotPoint_getter = ?fn (?*c_void, c_int, [*c]ImPlotPoint) callconv(.C) ?*c_void;
pub extern fn ImPlot_PlotLineG(label_id: [*c]const u8, getter: ImPlotPoint_getter, data: ?*c_void, count: c_int) void;
pub const plotLineG = ImPlot_PlotLineG;
pub extern fn ImPlot_PlotScatterG(label_id: [*c]const u8, getter: ImPlotPoint_getter, data: ?*c_void, count: c_int) void;
pub const plotScatterG = ImPlot_PlotScatterG;
pub extern fn ImPlot_PlotShadedG(label_id: [*c]const u8, getter1: ImPlotPoint_getter, data1: ?*c_void, getter2: ImPlotPoint_getter, data2: ?*c_void, count: c_int) void;
pub const plotShadedG = ImPlot_PlotShadedG;
pub extern fn ImPlot_PlotBarsG(label_id: [*c]const u8, getter: ImPlotPoint_getter, data: ?*c_void, count: c_int, width: f64) void;
pub const plotBarsG = ImPlot_PlotBarsG;
pub extern fn ImPlot_PlotBarsHG(label_id: [*c]const u8, getter: ImPlotPoint_getter, data: ?*c_void, count: c_int, height: f64) void;
pub const plotBarsHG = ImPlot_PlotBarsHG;
pub extern fn ImPlot_PlotDigitalG(label_id: [*c]const u8, getter: ImPlotPoint_getter, data: ?*c_void, count: c_int) void;
pub const plotDigitalG = ImPlot_PlotDigitalG;
