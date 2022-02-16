const std = @import("std");
const zp = @import("zplay");
const dig = zp.deps.dig;
const alg = zp.deps.alg;
const Vec2 = alg.Vec2;
const Vec3 = alg.Vec3;
const Vec4 = alg.Vec4;
const Mat4 = alg.Mat4;
const gfx = zp.graphics;
const Framebuffer = gfx.gpu.Framebuffer;
const Texture = gfx.gpu.Texture;
const Renderer = gfx.Renderer;
const Camera = gfx.Camera;
const Mesh = gfx.Mesh;
const Material = gfx.Material;
const light = gfx.@"3d".light;
const SimpleRenderer = gfx.@"3d".SimpleRenderer;
const PhongRenderer = gfx.@"3d".PhongRenderer;
const BlinnPhongRenderer = gfx.@"3d".BlinnPhongRenderer;
const GammaCorrection = gfx.post_processing.GammaCorrection;

var shadow_fb: Framebuffer = undefined;
var scene_fb: Framebuffer = undefined;
var fb_material: Material = undefined;
var gamma_correction: GammaCorrection = undefined;
var shadow_map_renderer: SimpleRenderer = undefined;
var light_renderer: SimpleRenderer = undefined;
var phong_renderer: PhongRenderer = undefined;
var plane: Mesh = undefined;
var cube: Mesh = undefined;
var light_mesh: Mesh = undefined;
var light_material: Material = undefined;
var box_material: Material = undefined;
var floor_material: Material = undefined;
var light_view_camera: Camera = undefined;
var light_view_projection: Mat4 = undefined;
var view_camera = Camera.fromPositionAndEulerAngles(
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
var dir_light_direction = [_]f32{ -1, -1, 0 };
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
var all_lights: std.ArrayList(light.Light) = undefined;

const shadow_width = 1024;
const shadow_height = 1024;

fn init(ctx: *zp.Context) anyerror!void {
    std.log.info("game init", .{});

    try dig.init(ctx.window);

    // allocate framebuffer stuff
    var width: u32 = undefined;
    var height: u32 = undefined;
    ctx.graphics.getDrawableSize(ctx.window, &width, &height);
    shadow_fb = try Framebuffer.initForShadowMapping(
        std.testing.allocator,
        shadow_width,
        shadow_height,
    );
    scene_fb = try Framebuffer.init(
        std.testing.allocator,
        width,
        height,
        .{},
    );
    fb_material = Material.init(.{
        .single_texture = scene_fb.tex.?,
    }, false);

    // init gamma correction
    gamma_correction = try GammaCorrection.init(std.testing.allocator);

    // simple renderer
    var pos = Vec3.new(0, 10, 0);
    light_view_camera = Camera.fromPositionAndTarget(
        pos,
        pos.add(Vec3.fromSlice(&dir_light_direction)),
        null,
    );
    light_view_projection = Mat4.orthographic(-20.0, 20.0, -20.0, 20.0, 0.1, 100.0);
    shadow_map_renderer = SimpleRenderer.init(.{ .no_draw = true });
    light_renderer = SimpleRenderer.init(.{});

    // init lights and phong renderer
    all_lights = std.ArrayList(light.Light).init(std.testing.allocator);
    try all_lights.append(.{
        .directional = .{
            .ambient = Vec3.fromSlice(&dir_light_ambient),
            .diffuse = Vec3.fromSlice(&dir_light_diffuse),
            .specular = Vec3.fromSlice(&dir_light_specular),
            .direction = Vec3.fromSlice(&dir_light_direction),
            .space_matrix = light_view_projection.mult(light_view_camera.getViewMatrix()),
        },
    });
    try all_lights.append(.{
        .point = .{
            .ambient = Vec3.fromSlice(&point_light_ambient),
            .diffuse = Vec3.fromSlice(&point_light_diffuse),
            .position = Vec3.fromSlice(&point_light_position),
            .linear = point_light_attenuation_linear,
            .quadratic = point_light_attenuation_quadratic,
        },
    });
    try all_lights.append(.{
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
    phong_renderer = PhongRenderer.init(.{ .has_shadow = true });
    phong_renderer.lightRenderer().applyLights(all_lights.items);

    // generate mesh
    plane = try Mesh.genPlane(std.testing.allocator, 50, 50, 20, 20);
    cube = try Mesh.genCube(std.testing.allocator, 1, 1, 1);
    light_mesh = try Mesh.genSphere(std.testing.allocator, 0.5, 20, 20);

    // material init
    light_material = Material.init(.{
        .single_texture = try Texture.init2DFromPixels(
            std.testing.allocator,
            &.{ 255, 255, 255 },
            .rgb,
            1,
            1,
            .{},
        ),
    }, true);
    box_material = Material.init(.{
        .phong = .{
            .diffuse_map = try Texture.init2DFromFilePath(
                std.testing.allocator,
                "assets/container2.png",
                false,
                .{
                    .need_linearization = true,
                },
            ),
            .specular_map = try Texture.init2DFromFilePath(
                std.testing.allocator,
                "assets/container2_specular.png",
                false,
                .{},
            ),
            .shiness = 10,
            .shadow_map = shadow_fb.depth_stencil.?.tex,
        },
    }, true);
    floor_material = Material.init(.{
        .phong = .{
            .diffuse_map = try Texture.init2DFromFilePath(
                std.testing.allocator,
                "assets/wall.jpg",
                false,
                .{
                    .need_linearization = true,
                    .gen_mipmap = true,
                },
            ),
            .specular_map = try Texture.init2DFromPixels(
                std.testing.allocator,
                &.{ 20, 20, 20 },
                .rgb,
                1,
                1,
                .{},
            ),
            .shiness = 0.1,
            .shadow_map = shadow_fb.depth_stencil.?.tex,
        },
    }, true);
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
    // camera movement
    const distance = ctx.delta_tick * view_camera.move_speed;
    if (ctx.isKeyPressed(.w)) {
        view_camera.move(.forward, distance);
    }
    if (ctx.isKeyPressed(.s)) {
        view_camera.move(.backward, distance);
    }
    if (ctx.isKeyPressed(.a)) {
        view_camera.move(.left, distance);
    }
    if (ctx.isKeyPressed(.d)) {
        view_camera.move(.right, distance);
    }
    if (ctx.isKeyPressed(.left)) {
        view_camera.rotate(0, -1);
    }
    if (ctx.isKeyPressed(.right)) {
        view_camera.rotate(0, 1);
    }
    if (ctx.isKeyPressed(.up)) {
        view_camera.rotate(1, 0);
    }
    if (ctx.isKeyPressed(.down)) {
        view_camera.rotate(-1, 0);
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

    // 1st render: generate shadow map
    ctx.graphics.useFramebuffer(shadow_fb);
    {
        const projection = Mat4.orthographic(-20.0, 20.0, -20.0, 20.0, 0.1, 100.0);
        ctx.graphics.setViewport(0, 0, shadow_width, shadow_height);
        defer ctx.graphics.setViewport(0, 0, width, height);

        ctx.graphics.clear(false, true, false, null);
        renderScene(ctx, shadow_map_renderer.renderer(), light_view_camera, projection, true);
    }

    // 2nd render: lighting scene
    ctx.graphics.useFramebuffer(if (enable_gamma_correction) scene_fb else null);
    {
        const projection = Mat4.perspective(
            view_camera.zoom,
            @intToFloat(f32, width) / @intToFloat(f32, height),
            0.1,
            100,
        );

        // lighting scene
        ctx.graphics.clear(true, true, false, [_]f32{ 0, 0, 0, 1.0 });
        renderScene(ctx, phong_renderer.renderer(), view_camera, projection, false);

        // draw lights
        var rd = light_renderer.renderer();
        rd.begin(false);
        {
            var old_blend_option = ctx.graphics.blend_option;
            defer ctx.graphics.setBlendOption(old_blend_option);
            ctx.graphics.setBlendOption(.{
                .src_rgb = .constant_alpha,
                .dst_rgb = .one_minus_constant_alpha,
                .constant_color = [4]f32{ 0, 0, 0, 0.8 },
            });
            for (all_lights.items) |d| {
                if (d.getType() == .directional) continue;
                const model = Mat4.fromScale(Vec3.set(0.1)).translate(d.getPosition().?);
                light_mesh.render(
                    rd,
                    model,
                    projection,
                    view_camera,
                    light_material,
                ) catch unreachable;
            }
        }
        rd.end();
    }

    // 3rd render: gamma correction
    if (enable_gamma_correction) {
        ctx.graphics.useFramebuffer(null);
        ctx.graphics.clear(true, false, false, null);
        gamma_correction.draw(&ctx.graphics, fb_material, gamma_value);
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
                view_camera.position.x(),
                view_camera.position.y(),
                view_camera.position.z(),
            });
            dig.ztext("Current camera's euler angles: {d:.2}, {d:.2}, {d:.2}", .{
                view_camera.euler.x(),
                view_camera.euler.y() + 90,
                view_camera.euler.z(),
            });

            dig.separator();
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

            var lights_changed = false;
            dig.separator();
            dig.text("Parameters of directional light");
            if (dig.colorEdit3("ambient##1", &dir_light_ambient, null)) {
                all_lights.items[0].directional.ambient = Vec3.fromSlice(&dir_light_ambient);
                lights_changed = true;
            }
            if (dig.colorEdit3("diffuse##1", &dir_light_diffuse, null)) {
                all_lights.items[0].directional.diffuse = Vec3.fromSlice(&dir_light_diffuse);
                lights_changed = true;
            }
            if (dig.colorEdit3("specular##1", &dir_light_specular, null)) {
                all_lights.items[0].directional.specular = Vec3.fromSlice(&dir_light_specular);
                lights_changed = true;
            }
            if (dig.dragFloat3("direction##1", &dir_light_direction, .{
                .v_speed = 0.01,
                .v_min = -1,
                .v_max = 1,
            })) {
                all_lights.items[0].directional.direction = Vec3.fromSlice(&dir_light_direction);
                lights_changed = true;
            }

            dig.separator();
            dig.text("Parameters of point light");
            if (dig.colorEdit3("ambient##2", &point_light_ambient, null)) {
                all_lights.items[1].point.ambient = Vec3.fromSlice(&point_light_ambient);
                lights_changed = true;
            }
            if (dig.colorEdit3("diffuse##2", &point_light_diffuse, null)) {
                all_lights.items[1].point.diffuse = Vec3.fromSlice(&point_light_diffuse);
                lights_changed = true;
            }
            if (dig.dragFloat3("position##2", &point_light_position, .{
                .v_speed = 0.01,
                .v_min = -10,
                .v_max = 10,
            })) {
                all_lights.items[1].point.position = Vec3.fromSlice(&point_light_position);
                lights_changed = true;
            }
            if (dig.dragFloat("attenuation linear##2", &point_light_attenuation_linear, .{
                .v_speed = 0.01,
                .v_min = 0,
                .v_max = 10,
            })) {
                all_lights.items[1].point.linear = point_light_attenuation_linear;
                lights_changed = true;
            }
            if (dig.dragFloat("attenuation quadratic##2", &point_light_attenuation_quadratic, .{
                .v_speed = 0.01,
                .v_min = 0,
                .v_max = 10,
            })) {
                all_lights.items[1].point.quadratic = point_light_attenuation_quadratic;
                lights_changed = true;
            }

            dig.separator();
            dig.text("Parameters of spot light");
            if (dig.colorEdit3("ambient##3", &spot_light_ambient, null)) {
                all_lights.items[2].spot.ambient = Vec3.fromSlice(&spot_light_ambient);
                lights_changed = true;
            }
            if (dig.colorEdit3("diffuse##3", &spot_light_diffuse, null)) {
                all_lights.items[2].spot.diffuse = Vec3.fromSlice(&spot_light_diffuse);
                lights_changed = true;
            }
            if (dig.dragFloat3("position##3", &spot_light_position, .{
                .v_speed = 0.01,
                .v_min = -10,
                .v_max = 10,
            })) {
                all_lights.items[2].spot.position = Vec3.fromSlice(&spot_light_position);
                lights_changed = true;
            }
            if (dig.dragFloat3("direction##3", &spot_light_direction, .{
                .v_speed = 0.01,
                .v_min = -1,
                .v_max = 1,
            })) {
                all_lights.items[2].spot.direction = Vec3.fromSlice(&spot_light_direction);
                lights_changed = true;
            }
            if (dig.dragFloat("attenuation linear##3", &spot_light_attenuation_linear, .{
                .v_speed = 0.01,
                .v_min = 0,
                .v_max = 10,
            })) {
                all_lights.items[2].spot.linear = spot_light_attenuation_linear;
                lights_changed = true;
            }
            if (dig.dragFloat("attenuation quadratic##3", &spot_light_attenuation_quadratic, .{
                .v_speed = 0.01,
                .v_min = 0,
                .v_max = 10,
            })) {
                all_lights.items[2].spot.quadratic = spot_light_attenuation_quadratic;
                lights_changed = true;
            }
            if (dig.dragFloat("attenuation cutoff##3", &spot_light_attenuation_cutoff, .{
                .v_speed = 0.01,
                .v_min = 0,
                .v_max = 20,
            })) {
                all_lights.items[2].spot.cutoff = spot_light_attenuation_cutoff;
                lights_changed = true;
            }
            if (dig.dragFloat("attenuation outer cutoff##3", &spot_light_attenuation_outer_cutoff, .{
                .v_speed = 0.01,
                .v_min = 0,
                .v_max = 20,
            })) {
                all_lights.items[2].spot.outer_cutoff = spot_light_attenuation_outer_cutoff;
                lights_changed = true;
            }
            if (lights_changed) {
                light_view_camera = Camera.fromPositionAndTarget(
                    light_view_camera.position,
                    light_view_camera.position.add(Vec3.fromSlice(&dir_light_direction)),
                    null,
                );
                all_lights.items[0].directional.space_matrix =
                    light_view_projection.mult(light_view_camera.getViewMatrix());
                phong_renderer.lightRenderer().applyLights(all_lights.items);
            }
        }
        dig.end();
    }
    dig.endFrame();
}

fn renderScene(ctx: *zp.Context, rd: Renderer, camera: Camera, projection: Mat4, generating_shadow_map: bool) void {
    rd.begin(false);
    plane.render(
        rd,
        Mat4.fromRotation(-90, Vec3.right()).translate(Vec3.new(0, -4, 0)),
        projection,
        camera,
        floor_material,
    ) catch unreachable;

    var old_culling_option = ctx.graphics.culling_option;
    if (generating_shadow_map) {
        ctx.graphics.setCullingOption(.{ .face = .front });
    }
    for (cube_positions) |pos, i| {
        const model = Mat4.fromRotation(
            20 * @intToFloat(f32, i),
            Vec3.new(1, 0.3, 0.5),
        ).translate(pos);
        cube.render(
            rd,
            model,
            projection,
            camera,
            box_material,
        ) catch unreachable;
    }
    if (generating_shadow_map) {
        ctx.graphics.setCullingOption(old_culling_option);
    }
    rd.end();
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
