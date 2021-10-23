// export core definitions
pub usingnamespace @import("core.zig");

/// well known folders on various os
pub const known_folders = @import("known_folders/known-folders.zig");

/// opengl 3.3 core definitions
pub const gl = @import("gl/gl.zig");

/// vector/matrix functions
pub const zlm = @import("zlm/zlm.zig");
