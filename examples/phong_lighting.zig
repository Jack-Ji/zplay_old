const std = @import("std");
const zp = @import("zplay");
const dig = zp.deps.dig;
const alg = zp.deps.alg;
const Vec2 = alg.Vec2;
const Vec3 = alg.Vec3;
const Vec4 = alg.Vec4;
const Mat4 = alg.Mat4;
const gfx = zp.graphics;
const Framebuffer = gfx.common.Framebuffer;
const Texture2D = gfx.texture.Texture2D;
const Renderer = gfx.Renderer;
const Camera = gfx.Camera;
const Mesh = gfx.Mesh;
const Material = gfx.Material;
const Light = gfx.@"3d".Light;
const SimpleRenderer = gfx.@"3d".SimpleRenderer;
const PhongRenderer = gfx.@"3d".PhongRenderer;
const BlinnPhongRenderer = gfx.@"3d".BlinnPhongRenderer;
const GammaCorrection = gfx.post_processing.GammaCorrection;

var fb: Framebuffer = undefined;
var fb_texture: Texture2D = undefined;
var fb_material: Material = undefined;
var gamma_correction: GammaCorrection = undefined;
var simple_renderer: SimpleRenderer = undefined;
var phong_renderer: PhongRenderer = undefined;
var blinn_phong_renderer: BlinnPhongRenderer = undefined;
var plane: Mesh = undefined;
var cube: Mesh = undefined;
var point_light_mesh: Mesh = undefined;
var spot_light_mesh: Mesh = undefined;
var light_material: Material = undefined;
var box_material: Material = undefined;
var floor_material: Material = undefined;
var camera = Camera.fromPositionAndEulerAngles(
    Vec3.new(2.05, 1.33, -9.69),
    -12.93,
    -170.01,
    null,
);
var enable_gamma_correction = true;
var gamma_value: f32 = 2.2;

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

var dir_light_ambient = [_]f32{ 0.1, 0.1, 0.1 };
var dir_light_diffuse = [_]f32{ 0.1, 0.1, 0.1 };
var dir_light_specular = [_]f32{ 0.1, 0.1, 0.1 };
var dir_light_direction = [_]f32{ 0, -1, 0 };
var point_light_ambient = [_]f32{ 0.02, 0.02, 0.02 };
var point_light_diffuse = [_]f32{ 0.5, 0.5, 0.5 };
var point_light_position = [_]f32{ 1.2, 1, -2 };
var point_light_attenuation_linear: f32 = 1.09;
var point_light_attenuation_quadratic: f32 = 1.032;
var spot_light_ambient = [_]f32{ 0.02, 0.02, 0.02 };
var spot_light_diffuse = [_]f32{ 0.8, 0.1, 0.1 };
var spot_light_position = [_]f32{ -4.31, 1.52, -2.25 };
var spot_light_direction = [_]f32{ 0.36, -0.46, -0.04 };
var spot_light_attenuation_linear: f32 = 0.02;
var spot_light_attenuation_quadratic: f32 = 0.01;
var spot_light_attenuation_cutoff: f32 = 5.9;
var spot_light_attenuation_outer_cutoff: f32 = 7.1;

fn init(ctx: *zp.Context) anyerror!void {
    std.log.info("game init", .{});

    try dig.init(ctx.window);

    // allocate framebuffer stuff
    var width: u32 = undefined;
    var height: u32 = undefined;
    ctx.graphics.getDrawableSize(ctx.window, &width, &height);
    fb_texture = try Texture2D.init(
        std.testing.allocator,
        null,
        .rgb,
        width,
        height,
        .{},
    );
    fb_material = Material.init(.{
        .single_texture = fb_texture,
    });
    fb = try Framebuffer.fromTexture(
        fb_texture.tex,
        .{},
    );

    // init gamma correction
    gamma_correction = try GammaCorrection.init(std.testing.allocator);

    // simple renderer
    simple_renderer = SimpleRenderer.init();

    // phong renderer
    var dir_light = Light.init(.{
        .directional = .{
            .ambient = Vec3.fromSlice(&dir_light_ambient),
            .diffuse = Vec3.fromSlice(&dir_light_diffuse),
            .specular = Vec3.fromSlice(&dir_light_specular),
            .direction = Vec3.fromSlice(&dir_light_direction),
        },
    });
    var point_light = Light.init(.{
        .point = .{
            .ambient = Vec3.fromSlice(&point_light_ambient),
            .diffuse = Vec3.fromSlice(&point_light_diffuse),
            .position = Vec3.fromSlice(&point_light_position),
            .linear = point_light_attenuation_linear,
            .quadratic = point_light_attenuation_quadratic,
        },
    });
    var spot_light = Light.init(.{
        .spot = .{
            .ambient = Vec3.fromSlice(&spot_light_ambient),
            .diffuse = Vec3.fromSlice(&spot_light_diffuse),
            .position = Vec3.fromSlice(&spot_light_position),
            .direction = Vec3.fromSlice(&spot_light_direction),
            .linear = spot_light_attenuation_linear,
            .quadratic = spot_light_attenuation_quadratic,
            .cutoff = spot_light_attenuation_cutoff,
            .outer_cutoff = spot_light_attenuation_outer_cutoff,
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

    // generate mesh
    plane = try Mesh.genPlane(std.testing.allocator, 50, 50, 20, 20);
    cube = try Mesh.genCube(std.testing.allocator, 1, 1, 1);
    point_light_mesh = try Mesh.genSphere(std.testing.allocator, 0.5, 20, 20);
    spot_light_mesh = try Mesh.genCylinder(std.testing.allocator, 2, 0.5, 0, 10, 10);

    // material init
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
    box_material = Material.init(.{
        .phong = .{
            .diffuse_map = try Texture2D.fromFilePath(
                std.testing.allocator,
                "assets/container2.png",
                false,
                .{
                    .need_linearization = true,
                },
            ),
            .specular_map = try Texture2D.fromFilePath(
                std.testing.allocator,
                "assets/container2_specular.png",
                false,
                .{},
            ),
            .shiness = 10,
        },
    });
    floor_material = Material.init(.{
        .phong = .{
            .diffuse_map = try Texture2D.fromFilePath(
                std.testing.allocator,
                "assets/wall.jpg",
                false,
                .{
                    .need_linearization = true,
                    .gen_mipmap = true,
                },
            ),
            .specular_map = try Texture2D.fromPixelData(
                std.testing.allocator,
                &.{ 20, 20, 20 },
                3,
                1,
                1,
                .{},
            ),
            .shiness = 0.1,
        },
    });
    var unit = box_material.allocTextureUnit(0);
    unit = floor_material.allocTextureUnit(unit);
    unit = light_material.allocTextureUnit(unit);
    _ = fb_material.allocTextureUnit(unit);

    // enable depth test
    ctx.graphics.toggleCapability(.depth_test, true);
    ctx.graphics.toggleCapability(.blend, true);
    ctx.graphics.toggleCapability(.cull_face, true);
}

fn loop(ctx: *zp.Context) void {
    const S = struct {
        var current_renderer: c_int = 1;
        var rd = blinn_phong_renderer.renderer();
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

    // render scene
    ctx.graphics.useFramebuffer(if (enable_gamma_correction) fb else null);
    {
        ctx.graphics.clear(true, true, false, [_]f32{ 0, 0, 0, 1.0 });

        // lighting scene
        const projection = Mat4.perspective(
            camera.zoom,
            @intToFloat(f32, width) / @intToFloat(f32, height),
            0.1,
            100,
        );
        S.rd.begin(false);
        plane.render(
            S.rd,
            Mat4.fromRotation(-90, Vec3.right()).translate(Vec3.new(0, -4, 0)),
            projection,
            camera,
            floor_material,
        ) catch unreachable;
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
                box_material,
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
                point_light_mesh.render(
                    rd,
                    model,
                    projection,
                    camera,
                    light_material,
                ) catch unreachable;
            }
            for (phong_renderer.spot_lights.items) |light| {
                const model = Mat4.fromScale(Vec3.set(0.1)).translate(light.getPosition().?);
                point_light_mesh.render(
                    rd,
                    model,
                    projection,
                    camera,
                    light_material,
                ) catch unreachable;
            }
        }
        rd.end();
    }

    // post gamma correction
    if (enable_gamma_correction) {
        ctx.graphics.useFramebuffer(null);
        ctx.graphics.clear(true, false, false, null);
        gamma_correction.draw(&ctx.graphics, gamma_value, fb_material);
    }

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
            _ = dig.checkbox("gamma correction", &enable_gamma_correction);
            if (enable_gamma_correction) {
                _ = dig.dragFloat(
                    "gamma value",
                    &gamma_value,
                    .{
                        .v_speed = 0.1,
                        .v_min = 0.01,
                        .v_max = 10,
                    },
                );
            }

            dig.separator();
            dig.text("Parameters of materials");
            _ = dig.dragFloat(
                "shiness of boxes",
                &box_material.data.phong.shiness,
                .{
                    .v_speed = 0.1,
                    .v_min = 0.01,
                    .v_max = 20,
                },
            );
            _ = dig.dragFloat(
                "shiness of floor",
                &floor_material.data.phong.shiness,
                .{
                    .v_speed = 0.1,
                    .v_min = 0.01,
                    .v_max = 20,
                },
            );

            dig.separator();
            dig.text("Parameters of directional light");
            if (dig.colorEdit3("ambient##1", &dir_light_ambient, null)) {
                phong_renderer.dir_light.data.directional.ambient =
                    Vec3.fromSlice(&dir_light_ambient);
                blinn_phong_renderer.dir_light.data.directional.ambient =
                    Vec3.fromSlice(&dir_light_ambient);
            }
            if (dig.colorEdit3("diffuse##1", &dir_light_diffuse, null)) {
                phong_renderer.dir_light.data.directional.diffuse =
                    Vec3.fromSlice(&dir_light_diffuse);
                blinn_phong_renderer.dir_light.data.directional.diffuse =
                    Vec3.fromSlice(&dir_light_diffuse);
            }
            if (dig.colorEdit3("specular##1", &dir_light_specular, null)) {
                phong_renderer.dir_light.data.directional.specular =
                    Vec3.fromSlice(&dir_light_specular);
                blinn_phong_renderer.dir_light.data.directional.specular =
                    Vec3.fromSlice(&dir_light_specular);
            }
            if (dig.dragFloat3("direction##1", &dir_light_direction, .{
                .v_speed = 0.01,
                .v_min = -1,
                .v_max = 1,
            })) {
                phong_renderer.dir_light.data.directional.direction =
                    Vec3.fromSlice(&dir_light_direction);
                blinn_phong_renderer.dir_light.data.directional.direction =
                    Vec3.fromSlice(&dir_light_direction);
            }

            dig.separator();
            dig.text("Parameters of point light");
            if (dig.colorEdit3("ambient##2", &point_light_ambient, null)) {
                phong_renderer.point_lights.items[0].data.point.ambient =
                    Vec3.fromSlice(&point_light_ambient);
                blinn_phong_renderer.point_lights.items[0].data.point.ambient =
                    Vec3.fromSlice(&point_light_ambient);
            }
            if (dig.colorEdit3("diffuse##2", &point_light_diffuse, null)) {
                phong_renderer.point_lights.items[0].data.point.diffuse =
                    Vec3.fromSlice(&point_light_diffuse);
                blinn_phong_renderer.point_lights.items[0].data.point.diffuse =
                    Vec3.fromSlice(&point_light_diffuse);
            }
            if (dig.dragFloat3("position##2", &point_light_position, .{
                .v_speed = 0.01,
                .v_min = -10,
                .v_max = 10,
            })) {
                phong_renderer.point_lights.items[0].data.point.position =
                    Vec3.fromSlice(&point_light_position);
                blinn_phong_renderer.point_lights.items[0].data.point.position =
                    Vec3.fromSlice(&point_light_position);
            }
            if (dig.dragFloat("attenuation linear##2", &point_light_attenuation_linear, .{
                .v_speed = 0.01,
                .v_min = 0,
                .v_max = 10,
            })) {
                phong_renderer.point_lights.items[0].data.point.linear =
                    point_light_attenuation_linear;
                blinn_phong_renderer.point_lights.items[0].data.point.linear =
                    point_light_attenuation_linear;
            }
            if (dig.dragFloat("attenuation quadratic##2", &point_light_attenuation_quadratic, .{
                .v_speed = 0.01,
                .v_min = 0,
                .v_max = 10,
            })) {
                phong_renderer.point_lights.items[0].data.point.quadratic =
                    point_light_attenuation_quadratic;
                blinn_phong_renderer.point_lights.items[0].data.point.quadratic =
                    point_light_attenuation_quadratic;
            }

            dig.separator();
            dig.text("Parameters of spot light");
            if (dig.colorEdit3("ambient##3", &spot_light_ambient, null)) {
                phong_renderer.spot_lights.items[0].data.spot.ambient =
                    Vec3.fromSlice(&spot_light_ambient);
                blinn_phong_renderer.spot_lights.items[0].data.spot.ambient =
                    Vec3.fromSlice(&spot_light_ambient);
            }
            if (dig.colorEdit3("diffuse##3", &spot_light_diffuse, null)) {
                phong_renderer.spot_lights.items[0].data.spot.diffuse =
                    Vec3.fromSlice(&spot_light_diffuse);
                blinn_phong_renderer.spot_lights.items[0].data.spot.diffuse =
                    Vec3.fromSlice(&spot_light_diffuse);
            }
            if (dig.dragFloat3("position##3", &spot_light_position, .{
                .v_speed = 0.01,
                .v_min = -10,
                .v_max = 10,
            })) {
                phong_renderer.spot_lights.items[0].data.spot.position =
                    Vec3.fromSlice(&spot_light_position);
                blinn_phong_renderer.spot_lights.items[0].data.spot.position =
                    Vec3.fromSlice(&spot_light_position);
            }
            if (dig.dragFloat3("direction##3", &spot_light_direction, .{
                .v_speed = 0.01,
                .v_min = -1,
                .v_max = 1,
            })) {
                phong_renderer.spot_lights.items[0].data.spot.direction =
                    Vec3.fromSlice(&spot_light_direction);
                blinn_phong_renderer.spot_lights.items[0].data.spot.direction =
                    Vec3.fromSlice(&spot_light_direction);
            }
            if (dig.dragFloat("attenuation linear##3", &spot_light_attenuation_linear, .{
                .v_speed = 0.01,
                .v_min = 0,
                .v_max = 10,
            })) {
                phong_renderer.spot_lights.items[0].data.spot.linear =
                    spot_light_attenuation_linear;
                blinn_phong_renderer.spot_lights.items[0].data.spot.linear =
                    spot_light_attenuation_linear;
            }
            if (dig.dragFloat("attenuation quadratic##3", &spot_light_attenuation_quadratic, .{
                .v_speed = 0.01,
                .v_min = 0,
                .v_max = 10,
            })) {
                phong_renderer.spot_lights.items[0].data.spot.quadratic =
                    spot_light_attenuation_quadratic;
                blinn_phong_renderer.spot_lights.items[0].data.spot.quadratic =
                    spot_light_attenuation_quadratic;
            }
            if (dig.dragFloat("attenuation cutoff##3", &spot_light_attenuation_cutoff, .{
                .v_speed = 0.01,
                .v_min = 0,
                .v_max = 20,
            })) {
                phong_renderer.spot_lights.items[0].data.spot.cutoff =
                    spot_light_attenuation_cutoff;
                blinn_phong_renderer.spot_lights.items[0].data.spot.cutoff =
                    spot_light_attenuation_cutoff;
            }
            if (dig.dragFloat("attenuation outer cutoff##3", &spot_light_attenuation_outer_cutoff, .{
                .v_speed = 0.01,
                .v_min = 0,
                .v_max = 20,
            })) {
                phong_renderer.spot_lights.items[0].data.spot.outer_cutoff =
                    spot_light_attenuation_outer_cutoff;
                blinn_phong_renderer.spot_lights.items[0].data.spot.outer_cutoff =
                    spot_light_attenuation_outer_cutoff;
            }
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
