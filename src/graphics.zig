/// common graphics types/utilities
pub const common = @import("graphics/common.zig");

/// generic rendering interface
pub const Renderer = @import("graphics/Renderer.zig");

/// generic camera
pub const Camera = @import("graphics/Camera.zig");

/// generic mesh object
pub const Mesh = @import("graphics/Mesh.zig");

/// generic material types
pub const Material = @import("graphics/Material.zig");

/// various post-processing effects
pub const post_processing = @import("graphics/post_processing.zig");

/// various texture types
pub const texture = @import("graphics/texture.zig");

/// toolkit for 3d scene
pub const @"3d" = @import("graphics/3d.zig");

/// toolkit for 2d scene
pub const @"2d" = @import("graphics/2d.zig");
