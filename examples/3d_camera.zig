const std = @import("std");
const zp = @import("zplay");
const alg = zp.deps.alg;
const VertexArray = zp.graphics.common.VertexArray;
const Texture2D = zp.graphics.texture.Texture2D;
const Renderer = zp.graphics.@"3d".Renderer;
const SimpleRenderer = zp.graphics.@"3d".SimpleRenderer;
const Material = zp.graphics.@"3d".Material;
const Camera = zp.graphics.@"3d".Camera;

var simple_renderer: SimpleRenderer = undefined;
var vertex_array: VertexArray = undefined;
var material: Material = undefined;
var camera = Camera.fromPositionAndTarget(
    alg.Vec3.new(0, 0, 3),
    alg.Vec3.zero(),
    null,
);

const vertices = [_]f32{
    // positions, texture
    -0.5, -0.5, -0.5, 0.0, 0.0,
    0.5,  -0.5, -0.5, 1.0, 0.0,
    0.5,  0.5,  -0.5, 1.0, 1.0,
    0.5,  0.5,  -0.5, 1.0, 1.0,
    -0.5, 0.5,  -0.5, 0.0, 1.0,
    -0.5, -0.5, -0.5, 0.0, 0.0,

    -0.5, -0.5, 0.5,  0.0, 0.0,
    0.5,  -0.5, 0.5,  1.0, 0.0,
    0.5,  0.5,  0.5,  1.0, 1.0,
    0.5,  0.5,  0.5,  1.0, 1.0,
    -0.5, 0.5,  0.5,  0.0, 1.0,
    -0.5, -0.5, 0.5,  0.0, 0.0,

    -0.5, 0.5,  0.5,  1.0, 0.0,
    -0.5, 0.5,  -0.5, 1.0, 1.0,
    -0.5, -0.5, -0.5, 0.0, 1.0,
    -0.5, -0.5, -0.5, 0.0, 1.0,
    -0.5, -0.5, 0.5,  0.0, 0.0,
    -0.5, 0.5,  0.5,  1.0, 0.0,

    0.5,  0.5,  0.5,  1.0, 0.0,
    0.5,  0.5,  -0.5, 1.0, 1.0,
    0.5,  -0.5, -0.5, 0.0, 1.0,
    0.5,  -0.5, -0.5, 0.0, 1.0,
    0.5,  -0.5, 0.5,  0.0, 0.0,
    0.5,  0.5,  0.5,  1.0, 0.0,

    -0.5, -0.5, -0.5, 0.0, 1.0,
    0.5,  -0.5, -0.5, 1.0, 1.0,
    0.5,  -0.5, 0.5,  1.0, 0.0,
    0.5,  -0.5, 0.5,  1.0, 0.0,
    -0.5, -0.5, 0.5,  0.0, 0.0,
    -0.5, -0.5, -0.5, 0.0, 1.0,

    -0.5, 0.5,  -0.5, 0.0, 1.0,
    0.5,  0.5,  -0.5, 1.0, 1.0,
    0.5,  0.5,  0.5,  1.0, 0.0,
    0.5,  0.5,  0.5,  1.0, 0.0,
    -0.5, 0.5,  0.5,  0.0, 0.0,
    -0.5, 0.5,  -0.5, 0.0, 1.0,
};

fn init(ctx: *zp.Context) anyerror!void {
    std.log.info("game init", .{});

    // simple renderer
    simple_renderer = SimpleRenderer.init();

    // vertex array
    vertex_array = VertexArray.init(5);
    vertex_array.use();
    defer vertex_array.disuse();
    vertex_array.bufferData(0, f32, &vertices, .array_buffer, .static_draw);
    vertex_array.setAttribute(0, SimpleRenderer.ATTRIB_LOCATION_POS, 3, f32, false, 5 * @sizeOf(f32), 0);
    vertex_array.setAttribute(0, SimpleRenderer.ATTRIB_LOCATION_TEX, 2, f32, false, 5 * @sizeOf(f32), 3 * @sizeOf(f32));

    // load texture
    material = Material.init(.{
        .single_texture = try Texture2D.fromFilePath(std.testing.allocator, "assets/wall.jpg", false),
    });
    _ = material.allocTextureUnit(0);

    // enable depth test
    ctx.graphics.toggleCapability(.depth_test, true);
}

fn loop(ctx: *zp.Context) void {
    const S = struct {
        var frame: f32 = 0;
        var axis = alg.Vec4.new(1, 1, 1, 0);
        var last_tick: ?f32 = null;
    };
    S.frame += 1;

    // camera movement
    const distance = ctx.delta_tick * camera.move_speed;
    if (ctx.isKeyPressed(.w)) {
        camera.move(.forward, distance);
    }
    if (ctx.isKeyPressed(.s)) {
        camera.move(.backward, distance);
    }
    if (ctx.isKeyPressed(.a)) {
        camera.move(.left, distance);
    }
    if (ctx.isKeyPressed(.d)) {
        camera.move(.right, distance);
    }

    while (ctx.pollEvent()) |e| {
        switch (e) {
            .window_event => |we| {
                switch (we.data) {
                    .resized => |size| {
                        ctx.graphics.setViewport(0, 0, size.width, size.height);
                    },
                    else => {},
                }
            },
            .keyboard_event => |key| {
                if (key.trigger_type == .up) {
                    switch (key.scan_code) {
                        .escape => ctx.kill(),
                        .f1 => ctx.toggleFullscreeen(null),
                        .m => ctx.toggleRelativeMouseMode(null),
                        else => {},
                    }
                }
            },
            .mouse_event => |me| {
                switch (me.data) {
                    .motion => |motion| {
                        // camera rotation
                        camera.rotate(
                            camera.mouse_sensitivity * @intToFloat(f32, -motion.yrel),
                            camera.mouse_sensitivity * @intToFloat(f32, motion.xrel),
                        );
                    },
                    .wheel => |scroll| {
                        camera.zoom -= @intToFloat(f32, scroll.scroll_y);
                        if (camera.zoom < 1) {
                            camera.zoom = 1;
                        }
                        if (camera.zoom > 45) {
                            camera.zoom = 45;
                        }
                    },
                    else => {},
                }
            },
            .quit_event => ctx.kill(),
            else => {},
        }
    }

    var width: u32 = undefined;
    var height: u32 = undefined;
    ctx.getWindowSize(&width, &height);

    // start drawing
    ctx.graphics.clear(true, true, false, [_]f32{ 0.2, 0.3, 0.3, 1.0 });

    const projection = alg.Mat4.perspective(
        camera.zoom,
        @intToFloat(f32, width) / @intToFloat(f32, height),
        0.1,
        100,
    );
    S.axis = alg.Mat4.fromRotation(1, alg.Vec3.new(-1, 1, -1)).multByVec4(S.axis);
    const model = alg.Mat4.fromRotation(
        S.frame,
        alg.Vec3.new(S.axis.x, S.axis.y, S.axis.z),
    );

    simple_renderer.renderer().begin();
    simple_renderer.renderer().render(
        vertex_array,
        false,
        .triangles,
        0,
        36,
        model,
        projection,
        camera,
        material,
        null,
    ) catch unreachable;
    simple_renderer.renderer().end();
}

fn quit(ctx: *zp.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
}

pub fn main() anyerror!void {
    try zp.run(.{
        .initFn = init,
        .loopFn = loop,
        .quitFn = quit,
        .enable_relative_mouse_mode = true,
    });
}
