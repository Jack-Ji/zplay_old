const std = @import("std");
const zp = @import("zplay");
const dig = zp.deps.dig;
const alg = zp.deps.alg;
const Vec2 = alg.Vec2;
const Vec3 = alg.Vec3;
const Vec4 = alg.Vec4;
const Mat4 = alg.Mat4;
const gfx = zp.graphics;
const Context = gfx.gpu.Context;
const Texture = gfx.gpu.Texture;
const Camera = gfx.Camera;
const Material = gfx.Material;
const Renderer = gfx.Renderer;
const SimpleRenderer = gfx.SimpleRenderer;
const render_pass = gfx.render_pass;
const Model = gfx.@"3d".Model;

var renderer: SimpleRenderer = undefined;
var helmet: Model = undefined;
var color_mr: Material = undefined;
var camera = Camera.fromPositionAndTarget(
    Vec3.new(0, 0, 3),
    Vec3.zero(),
    null,
);
var render_data_wireframe: Renderer.Input = undefined;
var render_data_raster: Renderer.Input = undefined;
var render_pipeline: render_pass.Pipeline = undefined;
var raster_speed: u32 = 4;

fn init(ctx: *zp.Context) anyerror!void {
    std.log.info("game init", .{});

    // init imgui
    try dig.init(ctx.window);

    // create renderer
    renderer = SimpleRenderer.init(.{});

    // load models
    helmet = Model.fromGLTF(
        std.testing.allocator,
        "assets/SciFiHelmet/SciFiHelmet.gltf",
        false,
        null,
    ) catch unreachable;
    color_mr = Material.init(.{
        .single_texture = try Texture.init2DFromPixels(
            std.testing.allocator,
            &[_]u8{ 255, 255, 255 },
            .rgb,
            1,
            1,
            .{},
        ),
    }, true);

    // compose rendere pipeline
    var width: u32 = undefined;
    var height: u32 = undefined;
    ctx.graphics.getDrawableSize(&width, &height);
    const projection = Mat4.perspective(
        camera.zoom,
        @intToFloat(f32, width) / @intToFloat(f32, height),
        0.1,
        100,
    );
    render_data_wireframe = Renderer.Input.init(
        std.testing.allocator,
        &.{},
        projection,
        &camera,
        null,
        null,
    ) catch unreachable;
    helmet.appendVertexData(
        &render_data_wireframe,
        Mat4.fromScale(Vec3.set(0.7)).rotate(90, Vec3.up()),
        null,
    ) catch unreachable;
    render_data_raster = try render_data_wireframe.clone(std.testing.allocator);
    render_data_wireframe.vds.?.items[0].material = &color_mr;
    render_pipeline = try render_pass.Pipeline.init(
        std.testing.allocator,
        &[_]render_pass.RenderPass{
            .{
                .beforeFn = beforeWireframeRendering,
                .rd = renderer.renderer(),
                .data = &render_data_wireframe,
            },
            .{
                .beforeFn = beforeRasterRendering,
                .rd = renderer.renderer(),
                .data = &render_data_raster,
            },
        },
    );
}

fn beforeWireframeRendering(ctx: *Context, custom: ?*anyopaque) void {
    _ = custom;
    ctx.setPolygonMode(.line);
    ctx.toggleCapability(.depth_test, false);
    ctx.clear(true, true, false, [_]f32{ 0.2, 0.4, 0.8, 1.0 });
}

fn beforeRasterRendering(ctx: *Context, custom: ?*anyopaque) void {
    _ = custom;
    ctx.toggleCapability(.depth_test, true);
    ctx.setPolygonMode(.fill);
}

fn loop(ctx: *zp.Context) void {
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
        if (e == .mouse_event and dig.getIO().*.WantCaptureMouse) {
            _ = dig.processEvent(e);
            continue;
        }
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
                        else => {},
                    }
                }
            },
            .quit_event => ctx.kill(),
            else => {},
        }
    }

    // start drawing
    render_data_raster.vds.?.items[0].count =
        std.math.mod(
        u32,
        @intCast(u32, render_data_raster.vds.?.items[0].count + raster_speed),
        @intCast(u32, helmet.meshes.items[0].indices.items.len),
    ) catch unreachable;
    render_pipeline.run(&ctx.graphics) catch unreachable;

    // settings
    dig.beginFrame();
    {
        var width: u32 = undefined;
        var height: u32 = undefined;
        ctx.graphics.getDrawableSize(&width, &height);
        dig.setNextWindowPos(
            .{ .x = @intToFloat(f32, width) - 30, .y = 50 },
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
            dig.text("Press WASD and up/down/left/right key to move around");
            dig.ztext("Current camera's position: {d:.2}, {d:.2}, {d:.2}", .{
                camera.position.x(),
                camera.position.y(),
                camera.position.z(),
            });
            dig.ztext("Current camera's euler angles: {d:.2}, {d:.2}, {d:.2}", .{
                camera.euler.x(),
                camera.euler.y() + 90,
                camera.euler.z(),
            });

            dig.separator();
            _ = dig.dragInt("rasterization speed", @ptrCast(*c_int, &raster_speed), .{
                .v_min = 1,
                .v_max = 100,
            });
        }
        dig.end();
    }
    dig.endFrame();
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
        .width = 1600,
        .height = 900,
    });
}
