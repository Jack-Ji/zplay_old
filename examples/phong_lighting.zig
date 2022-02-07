const std = @import("std");
const zp = @import("zplay");
const dig = zp.deps.dig;
const alg = zp.deps.alg;
const Vec2 = alg.Vec2;
const Vec3 = alg.Vec3;
const Vec4 = alg.Vec4;
const Mat4 = alg.Mat4;
const gfx = zp.graphics;
const Texture2D = gfx.texture.Texture2D;
const Renderer = gfx.Renderer;
const Camera = gfx.Camera;
const Mesh = gfx.Mesh;
const Material = gfx.Material;
const Light = gfx.@"3d".Light;
const SimpleRenderer = gfx.@"3d".SimpleRenderer;
const PhongRenderer = gfx.@"3d".PhongRenderer;
const BlinnPhongRenderer = gfx.@"3d".BlinnPhongRenderer;

var simple_renderer: SimpleRenderer = undefined;
var phong_renderer: PhongRenderer = undefined;
var blinn_phong_renderer: BlinnPhongRenderer = undefined;
var cube: Mesh = undefined;
var light_mesh: Mesh = undefined;
var light_material: Material = undefined;
var phong_material: Material = undefined;
var camera = Camera.fromPositionAndEulerAngles(
    Vec3.new(2.61, 2.68, -0.65),
    -35.93,
    -48.81,
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

    try dig.init(ctx.window);

    // simple renderer
    simple_renderer = SimpleRenderer.init();

    // phong renderer
    var dir_light = Light.init(.{
        .directional = .{
            .ambient = Vec3.new(0.1, 0.1, 0.1),
            .diffuse = Vec3.new(0.1, 0.1, 0.1),
            .specular = Vec3.new(0.1, 0.1, 0.1),
            .direction = Vec3.down(),
        },
    });
    var point_light = Light.init(.{
        .point = .{
            .ambient = Vec3.new(0.2, 0.2, 0.2),
            .diffuse = Vec3.new(0.5, 0.5, 0.5),
            .position = Vec3.new(1.2, 1, -2),
            .linear = 1.09,
            .quadratic = 1.032,
        },
    });
    var spot_light = Light.init(.{
        .spot = .{
            .ambient = Vec3.new(0.2, 0.2, 0.2),
            .diffuse = Vec3.new(0.8, 0.1, 0.1),
            .position = Vec3.new(1.2, 1, 2),
            .direction = Vec3.new(1.2, 1, 2).negate(),
            .linear = 1.09,
            .quadratic = 1.032,
            .cutoff = 12.5,
            .outer_cutoff = 14.5,
        },
    });
    phong_renderer = PhongRenderer.init(std.testing.allocator);
    phong_renderer.setDirLight(dir_light);
    _ = try phong_renderer.addLight(point_light);
    _ = try phong_renderer.addLight(spot_light);
    blinn_phong_renderer = BlinnPhongRenderer.init(std.testing.allocator);
    blinn_phong_renderer.setDirLight(dir_light);
    _ = try blinn_phong_renderer.addLight(point_light);
    _ = try blinn_phong_renderer.addLight(spot_light);

    // generate a cube
    cube = try Mesh.genCube(std.testing.allocator, 1, 1, 1);
    light_mesh = try Mesh.genSphere(std.testing.allocator, 0.5, 20, 20);

    // material init
    var diffuse_texture = try Texture2D.fromFilePath(
        std.testing.allocator,
        "assets/container2.png",
        false,
        .{},
    );
    var specular_texture = try Texture2D.fromFilePath(
        std.testing.allocator,
        "assets/container2_specular.png",
        false,
        .{},
    );
    light_material = Material.init(.{
        .single_texture = try Texture2D.fromPixelData(
            std.testing.allocator,
            &.{ 255, 255, 255 },
            3,
            1,
            1,
            .{},
        ),
    });
    phong_material = Material.init(.{
        .phong = .{
            .diffuse_map = diffuse_texture,
            .specular_map = specular_texture,
            .shiness = 10,
        },
    });
    var unit = phong_material.allocTextureUnit(0);
    _ = light_material.allocTextureUnit(unit);

    // enable depth test
    ctx.graphics.toggleCapability(.depth_test, true);
    ctx.graphics.toggleCapability(.blend, true);
    ctx.graphics.toggleCapability(.cull_face, true);
}

fn loop(ctx: *zp.Context) void {
    const S = struct {
        var current_renderer: c_int = 0;
        var rd = phong_renderer.renderer();
    };

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

    // clear frame
    ctx.graphics.clear(true, true, false, [_]f32{ 0.2, 0.2, 0.2, 1.0 });

    // lighting scene
    const projection = Mat4.perspective(
        camera.zoom,
        @intToFloat(f32, width) / @intToFloat(f32, height),
        0.1,
        100,
    );
    S.rd.begin(false);
    for (cube_positions) |pos, i| {
        const model = Mat4.fromRotation(
            20 * @intToFloat(f32, i),
            Vec3.new(1, 0.3, 0.5),
        ).translate(pos);
        cube.render(
            S.rd,
            model,
            projection,
            camera,
            phong_material,
        ) catch unreachable;
    }
    S.rd.end();

    // draw lights
    var rd = simple_renderer.renderer();
    rd.begin(false);
    {
        var old_blend_option = ctx.graphics.blend_option;
        defer ctx.graphics.setBlendOption(old_blend_option);
        ctx.graphics.setBlendOption(.{
            .src_rgb = .constant_alpha,
            .dst_rgb = .one_minus_constant_alpha,
            .constant_color = [4]f32{ 0, 0, 0, 0.8 },
        });
        for (phong_renderer.point_lights.items) |light| {
            const model = Mat4.fromScale(Vec3.set(0.1)).translate(light.getPosition().?);
            light_mesh.render(
                rd,
                model,
                projection,
                camera,
                light_material,
            ) catch unreachable;
        }
        for (phong_renderer.spot_lights.items) |light| {
            const model = Mat4.fromScale(Vec3.set(0.1)).translate(light.getPosition().?);
            light_mesh.render(
                rd,
                model,
                projection,
                camera,
                light_material,
            ) catch unreachable;
        }
    }
    rd.end();

    dig.beginFrame();
    {
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
            if (dig.combo_Str(
                "current renderer",
                &S.current_renderer,
                "phong\x00blinn-phong\x00",
                null,
            )) {
                S.rd = if (S.current_renderer == 0)
                    phong_renderer.renderer()
                else
                    blinn_phong_renderer.renderer();
            }
            _ = dig.dragFloat(
                "shiness of box",
                &phong_material.data.phong.shiness,
                .{
                    .v_min = 0.01,
                    .v_max = 100,
                },
            );
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
        .enable_maximized = true,
        .enable_msaa = true,
    });
}
