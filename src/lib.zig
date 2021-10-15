// export core definitions
pub usingnamespace @import("core.zig");

// opengl 3.3 core
pub const gl = @import("gl/gl.zig");

// vector/matrix functions
pub const zlm = @import("zlm/zlm.zig");

// well known folders on various os
pub const known_folders = @import("known_folders/known-folders.zig");
