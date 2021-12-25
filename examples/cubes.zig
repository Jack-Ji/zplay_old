const std = @import("std");
const zp = @import("zplay");
const dig = zp.deps.dig;
const alg = zp.deps.alg;
const Vec3 = alg.Vec3;
const Vec4 = alg.Vec4;
const Mat4 = alg.Mat4;
const Framebuffer = zp.graphics.common.Framebuffer;
const TextureUnit = zp.graphics.common.Texture.TextureUnit;
const Texture2D = zp.graphics.texture.Texture2D;
const TextureCube = zp.graphics.texture.TextureCube;
const Skybox = zp.graphics.@"3d".Skybox;
const Renderer = zp.graphics.@"3d".Renderer;
const SimpleRenderer = zp.graphics.@"3d".SimpleRenderer;
const Mesh = zp.graphics.@"3d".Mesh;
const Material = zp.graphics.@"3d".Material;
const Camera = zp.graphics.@"3d".Camera;

var skybox: Skybox = undefined;
var cubemap: TextureCube = undefined;
var skybox_material: Material = undefined;
var simple_renderer: SimpleRenderer = undefined;
var fb: Framebuffer = undefined;
var fb_texture: Texture2D = undefined;
var fb_material: Material = undefined;
var quad: Mesh = undefined;
var cube: Mesh = undefined;
var cube_material: Material = undefined;
var color_material: Material = undefined;
var wireframe_mode = false;
var outlined = false;
var rotate_scene_fb = false;
var camera = Camera.fromPositionAndTarget(
    Vec3.new(0, 0, 3),
    Vec3.zero(),
    null,
);

const cube_positions = [_]Vec3{
    Vec3.new(0.0, 0.0, 0.0),
    Vec3.new(2.0, 5.0, -15.0),
    Vec3.new(-1.5, -2.2, -2.5),
    Vec3.new(-3.8, -2.0, -12.3),
    Vec3.new(2.4, -0.4, -3.5),
    Vec3.new(-1.7, 3.0, -7.5),
    Vec3.new(1.3, -2.0, -2.5),
    Vec3.new(1.5, 2.0, -2.5),
    Vec3.new(1.5, 0.2, -1.5),
    Vec3.new(-1.3, 1.0, -1.5),
};

fn init(ctx: *zp.Context) anyerror!void {
    std.log.info("game init", .{});

    // init imgui
    try dig.init(ctx.window);

    // allocate skybox
    skybox = Skybox.init();

    // allocate framebuffer
    var width: u32 = undefined;
    var height: u32 = undefined;
    ctx.graphics.getDrawableSize(ctx.window, &width, &height);
    fb_texture = try Texture2D.init(
        std.testing.allocator,
        null,
        .rgba,
        width,
        height,
        .{},
    );
    fb = try Framebuffer.fromTexture(fb_texture.tex, .{});
    fb_material = Material.init(.{
        .single_texture = fb_texture,
    });

    // simple renderer
    simple_renderer = SimpleRenderer.init();

    // generate mesh
    quad = try Mesh.genQuad(std.testing.allocator, 2, 2, null);
    cube = try Mesh.genCube(std.testing.allocator, 1, 1, 1, null);

    // load texture
    cubemap = try TextureCube.fromFilePath(
        std.testing.allocator,
        "assets/skybox/right.jpg",
        "assets/skybox/left.jpg",
        "assets/skybox/top.jpg",
        "assets/skybox/bottom.jpg",
        "assets/skybox/front.jpg",
        "assets/skybox/back.jpg",
    );
    skybox_material = Material.init(.{
        .single_cubemap = cubemap,
    });
    cube_material = Material.init(.{
        .single_texture = try Texture2D.fromFilePath(
            std.testing.allocator,
            "assets/wall.jpg",
            false,
            .{},
        ),
    });
    color_material = Material.init(.{
        .single_color = alg.Vec4.new(0, 1, 0, 1),
    });

    // alloc texture unit
    var unit = fb_material.allocTextureUnit(0);
    unit = cube_material.allocTextureUnit(unit);
    _ = skybox_material.allocTextureUnit(unit);
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
    ctx.graphics.getDrawableSize(ctx.window, &width, &height);

    // settings
    dig.beginFrame();
    defer dig.endFrame();
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
            _ = dig.checkbox("wireframe", &wireframe_mode);
            if (dig.checkbox("outlined", &outlined)) {
                ctx.graphics.toggleCapability(.stencil_test, outlined);
            }
            if (dig.checkbox("rotate scene", &rotate_scene_fb)) {
                if (rotate_scene_fb) S.frame = 0;
            }
        }
        dig.end();
    }

    // render to custom framebuffer
    ctx.graphics.useFramebuffer(fb);
    {
        ctx.graphics.toggleCapability(.depth_test, true);
        ctx.graphics.clear(true, true, true, [4]f32{ 0.2, 0.3, 0.3, 1.0 });
        const projection = alg.Mat4.perspective(
            45,
            @intToFloat(f32, width) / @intToFloat(f32, height),
            0.1,
            100,
        );

        // draw boxes
        ctx.graphics.setPolygonMode(if (wireframe_mode) .line else .fill);
        renderBoxes(ctx, projection, S.frame);

        // draw skybox
        skybox.draw(&ctx.graphics, projection, camera, skybox_material);
    }

    // draw framebuffer's color texture
    ctx.graphics.useFramebuffer(null);
    {
        ctx.graphics.setPolygonMode(.fill);
        ctx.graphics.toggleCapability(.depth_test, false);
        ctx.graphics.clear(true, false, false, [4]f32{ 0.3, 0.2, 0.3, 1.0 });
        var model = Mat4.identity();
        if (rotate_scene_fb) {
            model = Mat4.fromRotation(S.frame, Vec3.up());
        }
        simple_renderer.renderer().begin();
        simple_renderer.renderer().renderMesh(
            quad,
            model,
            Mat4.identity(),
            null,
            fb_material,
            null,
        ) catch unreachable;
        simple_renderer.renderer().end();
    }
}

fn renderBoxes(ctx: *zp.Context, projection: alg.Mat4, frame: f32) void {
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
            Vec3.new(1, 0.3, 0.5),
        ).translate(pos);
        simple_renderer.renderer().renderMesh(
            cube,
            model,
            projection,
            camera,
            cube_material,
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
                Vec3.new(1, 0.3, 0.5),
            ).translate(pos);
            simple_renderer.renderer().renderMesh(
                cube,
                model.mult(alg.Mat4.fromScale(Vec3.set(1.01))),
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
    });
}
