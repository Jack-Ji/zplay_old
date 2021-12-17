const std = @import("std");
const zp = @import("zplay");
const alg = zp.deps.alg;
const dig = zp.deps.dig;
const Texture2D = zp.graphics.texture.Texture2D;
const Renderer = zp.graphics.@"3d".Renderer;
const SimpleRenderer = zp.graphics.@"3d".SimpleRenderer;
const Mesh = zp.graphics.@"3d".Mesh;
const Material = zp.graphics.@"3d".Material;
const Camera = zp.graphics.@"3d".Camera;

var simple_renderer: SimpleRenderer = undefined;
var cube: Mesh = undefined;
var texture_material: Material = undefined;
var color_material: Material = undefined;
var wireframe_mode = false;
var outlined = false;
var camera = Camera.fromPositionAndTarget(
    alg.Vec3.new(0, 0, 3),
    alg.Vec3.zero(),
    null,
);

const cube_positions = [_]alg.Vec3{
    alg.Vec3.new(0.0, 0.0, 0.0),
    alg.Vec3.new(2.0, 5.0, -15.0),
    alg.Vec3.new(-1.5, -2.2, -2.5),
    alg.Vec3.new(-3.8, -2.0, -12.3),
    alg.Vec3.new(2.4, -0.4, -3.5),
    alg.Vec3.new(-1.7, 3.0, -7.5),
    alg.Vec3.new(1.3, -2.0, -2.5),
    alg.Vec3.new(1.5, 2.0, -2.5),
    alg.Vec3.new(1.5, 0.2, -1.5),
    alg.Vec3.new(-1.3, 1.0, -1.5),
};

fn init(ctx: *zp.Context) anyerror!void {
    std.log.info("game init", .{});

    // init imgui
    try dig.init(ctx.window);

    // simple renderer
    simple_renderer = SimpleRenderer.init();

    // generate mesh
    cube = try Mesh.genCube(std.testing.allocator, 1, 1, 1, null);

    // load texture
    texture_material = Material.init(.{
        .single_texture = try Texture2D.fromFilePath(
            std.testing.allocator,
            "assets/wall.jpg",
            false,
        ),
    });
    _ = texture_material.allocTextureUnit(0);
    color_material = Material.init(.{
        .single_color = alg.Vec4.new(0, 1, 0, 1),
    });

    // enable depth test
    ctx.graphics.toggleCapability(.depth_test, true);
}

fn loop(ctx: *zp.Context) void {
    const S = struct {
        var frame: f32 = 0;
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
    if (ctx.isKeyPressed(.left)) {
        camera.rotate(0, -1);
    }
    if (ctx.isKeyPressed(.right)) {
        camera.rotate(0, 1);
    }
    if (ctx.isKeyPressed(.up)) {
        camera.rotate(1, 0);
    }
    if (ctx.isKeyPressed(.down)) {
        camera.rotate(-1, 0);
    }

    while (ctx.pollEvent()) |e| {
        _ = dig.processEvent(e);
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
                        else => {},
                    }
                }
            },
            .quit_event => ctx.kill(),
            else => {},
        }
    }

    var width: u32 = undefined;
    var height: u32 = undefined;
    ctx.getWindowSize(&width, &height);

    ctx.graphics.clear(true, true, true, [4]f32{ 0.2, 0.3, 0.3, 1.0 });

    const projection = alg.Mat4.perspective(
        45,
        @intToFloat(f32, width) / @intToFloat(f32, height),
        0.1,
        100,
    );
    render_boxes(ctx, projection, S.frame);

    // settings
    dig.beginFrame();
    {
        dig.setNextWindowPos(
            .{ .x = @intToFloat(f32, width) - 10, .y = 50 },
            .{
                .cond = dig.c.ImGuiCond_Always,
                .pivot = .{ .x = 1, .y = 0 },
            },
        );
        if (dig.begin(
            "settings",
            null,
            dig.c.ImGuiWindowFlags_NoMove |
                dig.c.ImGuiWindowFlags_NoResize |
                dig.c.ImGuiWindowFlags_AlwaysAutoResize,
        )) {
            if (dig.checkbox("wireframe", &wireframe_mode)) {
                ctx.graphics.setPolygonMode(if (wireframe_mode) .line else .fill);
            }
            if (dig.checkbox("outlined", &outlined)) {
                ctx.graphics.toggleCapability(.stencil_test, outlined);
            }
        }
        dig.end();
    }
    dig.endFrame();
}

fn render_boxes(ctx: *zp.Context, projection: alg.Mat4, frame: f32) void {
    simple_renderer.renderer().begin();
    defer simple_renderer.renderer().end();

    // update stencil buffers
    if (outlined) {
        ctx.graphics.setStencilOption(.{
            .test_func = .always,
            .test_ref = 1,
            .action_dppass = .replace,
        });
    }
    for (cube_positions) |pos, i| {
        var model = alg.Mat4.fromRotation(
            20 * @intToFloat(f32, i) + frame,
            alg.Vec3.new(1, 0.3, 0.5),
        ).translate(pos);
        simple_renderer.renderer().renderMesh(
            cube,
            model,
            projection,
            camera,
            texture_material,
            null,
        ) catch unreachable;
    }

    // outline cubes
    // draw scaled up cubes, using single color
    if (outlined) {
        ctx.graphics.setStencilOption(.{
            .test_func = .not_equal,
            .test_ref = 1,
        });
        for (cube_positions) |pos, i| {
            var model = alg.Mat4.fromRotation(
                20 * @intToFloat(f32, i) + frame,
                alg.Vec3.new(1, 0.3, 0.5),
            ).translate(pos);
            simple_renderer.renderer().renderMesh(
                cube,
                model.mult(alg.Mat4.fromScale(alg.Vec3.set(1.01))),
                projection,
                camera,
                color_material,
                null,
            ) catch unreachable;
        }
    }
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
        .enable_resizable = true,
    });
}
