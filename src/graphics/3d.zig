/// model (glTF 2.0)
pub const Model = @import("3d/Model.zig");

/// 3d scene
pub const Scene = @import("3d/Scene.zig");

/// 3d light manager
pub const light = @import("3d/light.zig");

/// skybox
pub const Skybox = @import("3d/Skybox.zig");

/// simple renderer
pub const SimpleRenderer = @import("3d/SimpleRenderer.zig");

/// blinn-phong lighting renderer
pub const PhongRenderer = @import("3d/PhongRenderer.zig");

/// environment mapping renderer
pub const EnvMappingRenderer = @import("3d/EnvMappingRenderer.zig");

//TODO pbr lighting renderer
