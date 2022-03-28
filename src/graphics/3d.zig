/// 3d mesh
pub const Mesh = @import("3d/Mesh.zig");

/// 3d model (glTF 2.0)
pub const Model = @import("3d/Model.zig");

/// 3d scene
pub const Scene = @import("3d/Scene.zig");

/// 3d light manager
pub const light = @import("3d/light.zig");

/// a simple mesh renderer
pub const SimpleRenderer = @import("3d/SimpleRenderer.zig");

/// skybox
pub const SkyboxRenderer = @import("3d/SkyboxRenderer.zig");

/// environment mapping renderer
pub const EnvMappingRenderer = @import("3d/EnvMappingRenderer.zig");

/// blinn-phong renderer
pub const PhongRenderer = @import("3d/PhongRenderer.zig");

//TODO pbr renderer
