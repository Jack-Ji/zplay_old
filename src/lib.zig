// export core definitions
pub usingnamespace @import("core.zig");

/// event definitions
pub const event = @import("event.zig");

/// well known folders on various os
pub const known_folders = @import("known_folders/known-folders.zig");

/// opengl 3.3 core definitions
pub const gl = @import("gl/gl.zig");

/// algebra types: vector/matrix/quaternion
pub const alg = @import("alg/src/main.zig");

/// stb utilities
pub const stb = @import("stb/stb.zig");

/// dear imgui
pub const dig = @import("cimgui/imgui.zig");

/// nanovg
/// BUG: not usable because zig isn't fully compliant with C ABI yet
/// https://github.com/ziglang/zig/issues/1481
pub const nvg = @import("nanovg/nanovg.zig");

/// cgltf
pub const cgltf = @import("cgltf/cgltf.zig");

/// texture types
pub const texture = @import("texture.zig");

/// 3d toolkit
pub const @"3d" = @import("3d.zig");
