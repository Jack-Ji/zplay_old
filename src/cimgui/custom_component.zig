const std = @import("std");
const zp = @import("../lib.zig");
const alg = zp.alg;
const allocator = @import("allocators.zig");
const api = @import("api.zig");

/// You can't remove the background from this, but you can make it invisible with
/// style.Colors.
pub fn viewPort() api.ImGuiID {
    const dockNodeFlags = api.ImGuiDockNodeFlags_PassthruCentralNode;
    const windowFlags =
        api.ImGuiWindowFlags_NoCollapse |
        api.ImGuiWindowFlags_NoDecoration |
        api.ImGuiWindowFlags_NoDocking |
        api.ImGuiWindowFlags_NoMove |
        api.ImGuiWindowFlags_NoResize |
        api.ImGuiWindowFlags_NoScrollbar |
        api.ImGuiWindowFlags_NoTitleBar |
        api.ImGuiWindowFlags_NoNavFocus |
        api.ImGuiWindowFlags_NoBackground |
        api.ImGuiWindowFlags_NoFocusOnAppearing |
        api.ImGuiWindowFlags_NoMouseInputs |
        api.ImGuiWindowFlags_NoInputs |
        api.ImGuiWindowFlags_NoBringToFrontOnFocus;

    var mainView = api.igGetMainViewport();

    var pos: api.ImVec2 = mainView.*.WorkPos;
    var size: api.ImVec2 = mainView.*.WorkSize;

    api.igSetNextWindowPos(pos, api.ImGuiCond_Always, .{});
    api.igSetNextWindowSize(size, api.ImGuiCond_Always);

    api.igPushStyleVar_Vec2(api.ImGuiStyleVar_WindowPadding, .{});
    _ = api.igBegin("###DockSpace", null, windowFlags);
    var id = api.igGetID_Str("DefaultDockingViewport");
    _ = api.igDockSpace(id, .{}, dockNodeFlags, api.ImGuiWindowClass_ImGuiWindowClass());

    api.igEnd();
    api.igPopStyleVar(1);

    return id;
}

/// If you ever need to format a string for use inside api, this will work the same as any format function.
pub inline fn fmtTextForImgui(comptime fmt: []const u8, args: anytype) []const u8 {
    var alloc = allocator.ring();
    return alloc.dupeZ(u8, std.fmt.allocPrint(alloc, fmt, args) catch unreachable) catch unreachable;
}
/// Uses a ring allocator to spit out api text using zig.api's formatting library.
pub fn text(comptime fmt: []const u8, args: anytype) void {
    var txt = fmtTextForImgui(fmt, args);
    api.igText(txt.ptr);
}
/// Uses a ring allocator to spit out api text using zig's formatting library, wrapping if needed.
pub fn textWrap(comptime fmt: []const u8, args: anytype) void {
    var txt = fmtTextForImgui(fmt, args);
    api.igTextWrapped(txt.ptr);
}
/// Uses a ring allocator to spit out api text using zig's formatting library, in the disabled color.
pub fn textDisabled(comptime fmt: []const u8, args: anytype) void {
    var txt = fmtTextForImgui(fmt, args);
    api.igTextDisabled(txt.ptr);
}
/// Uses a ring allocator to spit out api text using zig's formatting library with a custom color.
pub fn textColor(comptime fmt: []const u8, color: api.ImVec4, args: anytype) void {
    var txt = fmtTextForImgui(fmt, args);
    api.igTextColored(color, txt.ptr);
}

/// Attempts to create a general editor for most structs, including math structs. This isnt always what you want, and in
/// those cases its always better to layout your own editor. This is biased towards creating drag inputs.
pub fn editDrag(label: []const u8, speed: f32, ptr: anytype) bool {
    // Array buffers are weird. Lets sort them out first.
    const ti: std.builtin.TypeInfo = @typeInfo(@TypeOf(ptr.*));
    if (ti == .Array) {
        if (ti.Array.child == u8) {
            return api.igInputText(label.ptr, ptr, @intCast(usize, ti.Array.len), api.ImGuiInputTextFlags_None, null, null);
        }
    }
    const fmax = std.math.f32_max;
    switch (@TypeOf(ptr)) {
        *bool => {
            return api.igCheckbox(label.ptr, ptr);
        },
        *i32 => {
            const imin = std.math.minInt(i32);
            const imax = std.math.maxInt(i32);
            return api.igDragInt(label.ptr, ptr, speed, @intCast(c_int, imin), @intCast(c_int, imax), "%i", api.ImGuiSliderFlags_NoRoundToFormat);
        },
        *f32 => {
            return api.igDragFloat(label.ptr, ptr, speed, -fmax, fmax, "%.2f", api.ImGuiSliderFlags_NoRoundToFormat);
        },
        *usize => {
            var cast = @intCast(c_int, ptr.*);
            var result = api.igInputInt(label.ptr, &cast, 1, 5, api.ImGuiInputTextFlags_None);
            if (result) {
                ptr.* = @intCast(usize, std.math.max(0, cast));
            }
            return result;
        },
        *alg.Vec2 => {
            var cast: [2]f32 = .{ ptr.*.x, ptr.*.y };
            var result = api.igDragFloat2(label.ptr, &cast, speed, -fmax, fmax, "%.2f", api.ImGuiSliderFlags_NoRoundToFormat);
            if (result) {
                ptr.* = alg.Vec2.new(cast[0], cast[1]);
            }
            return result;
        },
        *alg.Vec3 => {
            var cast: [3]f32 = .{ ptr.*.x, ptr.*.y, ptr.*.z };
            var result = api.igDragFloat3(label.ptr, &cast, speed, -fmax, fmax, "%.2f", api.ImGuiSliderFlags_NoRoundToFormat);
            if (result) {
                ptr.* = alg.Vec3.new(cast[0], cast[1], cast[2]);
            }
            return result;
        },
        *alg.Vec4 => {
            var cast: [4]f32 = .{ ptr.*.x, ptr.*.y, ptr.*.z, ptr.*.w };
            var result = api.igColorEdit4(label.ptr, &cast, api.ImGuiColorEditFlags_Float);
            if (result) {
                ptr.* = alg.Vec4.new(cast[0], cast[1], cast[2], cast[3]);
            }
            return result;
        },
        else => {
            std.debug.warn("No editor found for type {s}\n", .{@typeName(@TypeOf(ptr))});
            return false;
        },
    }
}

pub fn edit(label: []const u8, ptr: anytype) bool {
    // Array buffers are weird. Lets sort them out first.
    const ti: std.builtin.TypeInfo = @typeInfo(@TypeOf(ptr.*));
    if (ti == .Array) {
        if (ti.Array.child == u8) {
            return api.igInputText(label.ptr, ptr, @intCast(usize, ti.Array.len), api.ImGuiInputTextFlags_None, null, null);
        }
    }
    switch (@TypeOf(ptr)) {
        *bool => {
            return api.igCheckbox(label.ptr, ptr);
        },
        *i32 => {
            return api.igInputInt(label.ptr, ptr, 1, 3, api.ImGuiInputTextFlags_None);
        },
        *f32 => {
            return api.igInputFloat(label.ptr, ptr, 1, 3, "%.2f", api.ImGuiInputTextFlags_None);
        },
        *usize => {
            var cast = @intCast(c_int, ptr.*);
            var result = api.igInputInt(label.ptr, &cast, 1, 5, api.ImGuiInputTextFlags_None);
            if (result) {
                ptr.* = @intCast(usize, std.math.max(0, cast));
            }
            return result;
        },
        *alg.Vec2 => {
            var cast: [2]f32 = .{ ptr.*.x, ptr.*.y };
            var result = api.igInputFloat2(label.ptr, &cast, "%.2f", api.ImGuiInputTextFlags_None);
            if (result) {
                ptr.* = alg.Vec2.new(cast[0], cast[1]);
            }
            return result;
        },
        *alg.Vec3 => {
            var cast: [3]f32 = .{ ptr.*.x, ptr.*.y, ptr.*.z };
            var result = api.igInputFloat3(label.ptr, &cast, "%.2f", api.ImGuiInputTextFlags_None);
            if (result) {
                ptr.* = alg.Vec3.new(cast[0], cast[1], cast[2]);
            }
            return result;
        },
        *alg.Vec4 => {
            var cast: [4]f32 = .{ ptr.*.x, ptr.*.y, ptr.*.z, ptr.*.w };
            var result = api.igColorEdit4(label.ptr, &cast, api.ImGuiColorEditFlags_Float);
            if (result) {
                ptr.* = alg.Vec4.new(cast[0], cast[1], cast[2], cast[3]);
            }
            return result;
        },
        else => {
            std.debug.warn("No editor found for type {s}\n", .{@typeName(@TypeOf(ptr))});
            return false;
        },
    }
}
