// export core definitions
pub usingnamespace @import("core.zig");

/// system events
pub const event = @import("event.zig");

/// graphics module
pub const graphics = @import("graphics.zig");

/// physics module
pub const physics = @import("physics.zig");

/// audio module
pub const audio = @import("audio.zig");

/// helper utilities built on top of above basic modules
pub const utils = @import("utils.zig");

/// 3rd party libraries
pub const deps = struct {
    /// required dependencies
    pub const sdl = @import("sdl"); // sdl2
    pub const gl = @import("deps/gl/gl.zig"); // opengl 3.3 core definitions
    pub const alg = @import("deps/alg/src/main.zig"); // algebra calculation
    pub const miniaudio = @import("deps/miniaudio/miniaudio.zig"); // audio library
    pub const gltf = @import("deps/gltf/gltf.zig"); // gltf loader
    pub const stb = @import("deps/stb/stb.zig"); // stb utilities
    pub const kf = @import("deps/known_folders/known-folders.zig"); // known folders

    /// optional dependencies
    pub const nfd = @import("deps/nfd/nfd.zig"); // native file dialog
    pub const dig = @import("deps/imgui/imgui.zig"); // dear-imgui
    pub const nvg = @import("deps/nanovg/nanovg.zig"); // nanovg: vector graphics
    pub const nsvg = @import("deps/nanosvg/nanosvg.zig"); // nanosvg: svg parser
    pub const bt = @import("deps/bullet/bullet.zig"); // 3d physics
    pub const cp = @import("deps/chipmunk/chipmunk.zig"); // 2d physics
};
