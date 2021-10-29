const sdl = @import("sdl");
const c = sdl.c;
const Self = @This();

const Button = enum(c_int) {
    left = c.SDL_BUTTON_LEFT,
    right = c.SDL_BUTTON_RIGHT,
    middle = c.SDL_BUTTON_MIDDLE,
};

const Data = union(enum) {
    motion: struct {
        x: i32, // current horizontal coordinate, relative to window
        y: i32, // current vertical coordinate, relative to window
        xrel: i32, // relative to last event
        yrel: i32, // relative to last event
    },
    button: struct {
        x: i32, // current horizontal coordinate, relative to window
        y: i32, // current vertical coordinate, relative to window
        btn: Button, // pressed/released button
        clicked: bool, // false means released
        double_clicked: bool, // double clicks
    },
    wheel: struct {
        scroll_x: i32, // positive to the right, negative to the left
        scroll_y: i32, // positive away from user, negative towards user
    },
};

/// timestamp of event
timestamp: u32 = undefined,

/// mouse event data
data: Data = undefined,

pub fn fromMotionEvent(e: c.SDL_MouseMotionEvent) Self {
    return .{
        .timestamp = e.timestamp,
        .data = .{
            .motion = .{
                .x = e.x,
                .y = e.y,
                .xrel = e.xrel,
                .yrel = e.yrel,
            },
        },
    };
}

pub fn fromButtonEvent(e: c.SDL_MouseButtonEvent) Self {
    return .{
        .timestamp = e.timestamp,
        .data = .{
            .button = .{
                .x = e.x,
                .y = e.y,
                .btn = @intToEnum(Button, @as(c_int, e.button)),
                .clicked = e.state == c.SDL_PRESSED,
                .double_clicked = e.clicks > 1,
            },
        },
    };
}

pub fn fromWheelEvent(e: c.SDL_MouseWheelEvent) Self {
    return .{
        .timestamp = e.timestamp,
        .data = .{
            .wheel = .{
                .scroll_x = if (e.direction == c.SDL_MOUSEWHEEL_FLIPPED) -e.x else e.x,
                .scroll_y = if (e.direction == c.SDL_MOUSEWHEEL_FLIPPED) -e.y else e.y,
            },
        },
    };
}
