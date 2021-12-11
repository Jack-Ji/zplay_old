// export core definitions
pub usingnamespace @import("core.zig");

/// system events
pub const event = @import("event.zig");

/// rendering facilities
pub const graphics = @import("graphics.zig");

/// 3rd party libraries
pub const deps = struct {
    pub const sdl = @import("sdl"); // sdl2
    pub const gl = @import("deps/gl/gl.zig"); // opengl 3.3 core definitions
    pub const alg = @import("deps/alg/src/main.zig"); // algebra calculation
    pub const stb = @import("deps/stb/stb.zig"); // stb utilities
    pub const dig = @import("deps/imgui/imgui.zig"); // dear-imgui
    pub const nvg = @import("deps/nanovg/nanovg.zig"); // nanovg
    pub const nsvg = @import("deps/nanosvg/nanosvg.zig"); // nanosvg
    pub const gltf = @import("deps/gltf/gltf.zig"); // gltf
    pub const kf = @import("deps/known_folders/known-folders.zig"); // known sys dir
};
