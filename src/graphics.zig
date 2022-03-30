/// graphics card types/utilities
pub const gpu = @import("graphics/gpu.zig");

/// generic rendering interface
pub const Renderer = @import("graphics/Renderer.zig");

/// render pipeline, consists of render passes
pub const RenderPipeline = @import("graphics/RenderPipeline.zig");

/// generic camera
pub const Camera = @import("graphics/Camera.zig");

/// generic material
pub const Material = @import("graphics/Material.zig");

/// post-processing effects, dealing with a single texture
pub const post_processing = @import("graphics/post_processing.zig");

/// toolkit for font loading/rendering
pub const font = @import("graphics/font.zig");

/// toolkit for 3d scene
pub const @"3d" = @import("graphics/3d.zig");

/// toolkit for 2d scene
pub const @"2d" = @import("graphics/2d.zig");
