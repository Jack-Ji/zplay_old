const sdl = @import("sdl");
const c = sdl.c;
const Self = @This();

pub const Position = struct {
    x: i32,
    y: i32,
};

/// timestamp of event
timestamp: u32,

pub fn fromMotionEvent(e: c.SDL_MouseMotionEvent) Self {
    return .{
        .timestamp = e.timestamp,
    };
}

pub fn fromButtonEvent(e: c.SDL_MouseButtonEvent) Self {
    return .{
        .timestamp = e.timestamp,
    };
}

pub fn fromWheelEvent(e: c.SDL_MouseWheelEvent) Self {
    return .{
        .timestamp = e.timestamp,
    };
}
