const std = @import("std");
const zp = @import("zplay");
const dig = zp.deps.dig;
const alg = zp.deps.alg;
const Vec2 = alg.Vec2;
const Vec3 = alg.Vec3;
const Vec4 = alg.Vec4;
const Mat4 = alg.Mat4;
const gfx = zp.graphics;
const GraphicsContext = gfx.gpu.Context;
const Framebuffer = gfx.gpu.Framebuffer;
const Texture = gfx.gpu.Texture;
const Renderer = gfx.Renderer;
const RenderPipeline = gfx.RenderPipeline;
const Camera = gfx.Camera;
const Material = gfx.Material;
const GammaCorrection = gfx.post_processing.GammaCorrection;
const SimpleRenderer = gfx.@"3d".SimpleRenderer;
const light = gfx.@"3d".light;
const PhongRenderer = gfx.@"3d".PhongRenderer;
const BlinnPhongRenderer = gfx.@"3d".BlinnPhongRenderer;
const Mesh = gfx.@"3d".Mesh;

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
var person_view_camera: Camera = undefined;
var enable_gamma_correction = true;
var gamma_value: f32 = 2.2;
var render_data_scene: Renderer.Input = undefined;
var render_data_light: Renderer.Input = undefined;
var render_data_screen: Renderer.Input = undefined;
var render_pipeline_gc: RenderPipeline = undefined;
var render_pipeline: RenderPipeline = undefined;

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

    try dig.init(ctx);

    // allocate framebuffer stuff
    const size = ctx.graphics.getDrawableSize();
    shadow_fb = try Framebuffer.initForShadowMapping(
        std.testing.allocator,
        shadow_width,
        shadow_height,
    );
    scene_fb = try Framebuffer.init(
        std.testing.allocator,
        size.w,
        size.h,
        .{},
    );
    fb_material = Material.init(.{
        .single_texture = scene_fb.tex.?,
    });

    // init gamma correction
    gamma_correction = try GammaCorrection.init(std.testing.allocator);

    // simple renderer
    var pos = Vec3.new(0, 10, 0);
    light_view_camera = Camera.fromPositionAndTarget(
        .{
            .orthographic = .{
                .left = -20.0,
                .right = 20.0,
                .bottom = -20.0,
                .top = 20.0,
                .near = 0.1,
                .far = 100.0,
            },
        },
        pos,
        pos.add(Vec3.fromSlice(&dir_light_direction)),
        null,
    );
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
            .space_matrix = light_view_camera.getViewProjectMatrix(),
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
    phong_renderer.applyLights(all_lights.items);

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
    });
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
    });
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
    });

    // compose renderer's input
    person_view_camera = Camera.fromPositionAndEulerAngles(
        .{
            .perspective = .{
                .fov = 45,
                .aspect_ratio = ctx.graphics.viewport.getAspectRatio(),
                .near = 0.1,
                .far = 100,
            },
        },
        Vec3.new(2.05, 1.33, -9.69),
        -12.93,
        -170.01,
        null,
    );
    render_data_scene = try Renderer.Input.init(
        std.testing.allocator,
        &.{},
        null,
        null,
        null,
    );
    try render_data_scene.vds.?.append(plane.getVertexData(
        &floor_material,
        Renderer.LocalTransform{
            .single = Mat4.fromRotation(-90, Vec3.right())
                .translate(Vec3.new(0, -4, 0)),
        },
    ));
    for (cube_positions) |cpos, i| {
        try render_data_scene.vds.?.append(cube.getVertexData(
            &box_material,
            Renderer.LocalTransform{
                .single = Mat4.fromRotation(
                    20 * @intToFloat(f32, i),
                    Vec3.new(1, 0.3, 0.5),
                ).translate(cpos),
            },
        ));
    }
    render_data_light = try Renderer.Input.init(
        std.testing.allocator,
        &.{},
        &person_view_camera,
        null,
        null,
    );
    for (all_lights.items) |d| {
        if (d.getType() == .directional) continue;
        try render_data_light.vds.?.append(light_mesh.getVertexData(
            &light_material,
            Renderer.LocalTransform{
                .single = Mat4.fromScale(Vec3.set(0.1)).translate(d.getPosition().?),
            },
        ));
    }
    render_data_screen = try Renderer.Input.init(
        std.testing.allocator,
        &.{},
        null,
        &fb_material,
        &gamma_value,
    );
    render_pipeline_gc = try RenderPipeline.init(
        std.testing.allocator,
        &[_]RenderPipeline.RenderPass{
            .{
                .fb = shadow_fb,
                .beforeFn = beforeShadowMapGeneration,
                .afterFn = afterShadowMapGeneration,
                .rd = shadow_map_renderer.renderer(),
                .data = &render_data_scene,
            },
            .{
                .fb = scene_fb,
                .beforeFn = beforeSceneRendering1,
                .rd = phong_renderer.renderer(),
                .data = &render_data_scene,
            },
            .{
                .fb = scene_fb,
                .beforeFn = beforeSceneRendering2,
                .afterFn = afterSceneRendering2,
                .rd = light_renderer.renderer(),
                .data = &render_data_light,
            },
            .{
                .beforeFn = beforeScreenRendering,
                .rd = gamma_correction.renderer(),
                .data = &render_data_screen,
            },
        },
    );
    render_pipeline = try RenderPipeline.init(
        std.testing.allocator,
        &[_]RenderPipeline.RenderPass{
            .{
                .fb = shadow_fb,
                .beforeFn = beforeShadowMapGeneration,
                .afterFn = afterShadowMapGeneration,
                .rd = shadow_map_renderer.renderer(),
                .data = &render_data_scene,
            },
            .{
                .beforeFn = beforeSceneRendering1,
                .rd = phong_renderer.renderer(),
                .data = &render_data_scene,
            },
            .{
                .beforeFn = beforeSceneRendering2,
                .afterFn = afterSceneRendering2,
                .rd = light_renderer.renderer(),
                .data = &render_data_light,
            },
        },
    );
}

fn beforeShadowMapGeneration(ctx: *GraphicsContext, custom: ?*anyopaque) void {
    _ = custom;
    ctx.setViewport(.{ .w = shadow_width, .h = shadow_height });
    ctx.clear(false, true, false, null);
    render_data_scene.camera = &light_view_camera;
}

fn afterShadowMapGeneration(ctx: *GraphicsContext, custom: ?*anyopaque) void {
    _ = custom;
    const size = ctx.getDrawableSize();
    ctx.setViewport(.{ .w = size.w, .h = size.h });
}

fn beforeSceneRendering1(ctx: *GraphicsContext, custom: ?*anyopaque) void {
    _ = custom;
    ctx.clear(true, true, false, [_]f32{ 0, 0, 0, 1.0 });
    render_data_scene.camera = &person_view_camera;
}

var old_blend_option: GraphicsContext.BlendOption = undefined;
fn beforeSceneRendering2(ctx: *GraphicsContext, custom: ?*anyopaque) void {
    _ = custom;
    old_blend_option = ctx.blend_option;
    ctx.setBlendOption(.{
        .src_rgb = .constant_alpha,
        .dst_rgb = .one_minus_constant_alpha,
        .constant_color = [4]f32{ 0, 0, 0, 0.8 },
    });
}

fn afterSceneRendering2(ctx: *GraphicsContext, custom: ?*anyopaque) void {
    _ = custom;
    ctx.setBlendOption(old_blend_option);
}

fn beforeScreenRendering(ctx: *GraphicsContext, custom: ?*anyopaque) void {
    _ = custom;
    ctx.clear(true, false, false, null);
}

fn loop(ctx: *zp.Context) void {
    // camera movement
    const distance = ctx.delta_tick * person_view_camera.move_speed;
    if (ctx.isKeyPressed(.w)) {
        person_view_camera.move(.forward, distance);
    }
    if (ctx.isKeyPressed(.s)) {
        person_view_camera.move(.backward, distance);
    }
    if (ctx.isKeyPressed(.a)) {
        person_view_camera.move(.left, distance);
    }
    if (ctx.isKeyPressed(.d)) {
        person_view_camera.move(.right, distance);
    }
    if (ctx.isKeyPressed(.left)) {
        person_view_camera.rotate(0, -1);
    }
    if (ctx.isKeyPressed(.right)) {
        person_view_camera.rotate(0, 1);
    }
    if (ctx.isKeyPressed(.up)) {
        person_view_camera.rotate(1, 0);
    }
    if (ctx.isKeyPressed(.down)) {
        person_view_camera.rotate(-1, 0);
    }

    while (ctx.pollEvent()) |e| {
        _ = dig.processEvent(e);
        switch (e) {
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

    // render the scene
    if (enable_gamma_correction) {
        render_pipeline_gc.run(&ctx.graphics) catch unreachable;
    } else {
        render_pipeline.run(&ctx.graphics) catch unreachable;
    }

    dig.beginFrame();
    {
        dig.setNextWindowPos(
            .{ .x = @intToFloat(f32, ctx.graphics.viewport.w) - 30, .y = 50 },
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
                person_view_camera.position.x(),
                person_view_camera.position.y(),
                person_view_camera.position.z(),
            });
            dig.ztext("Current camera's euler angles: {d:.2}, {d:.2}, {d:.2}", .{
                person_view_camera.euler.x(),
                person_view_camera.euler.y() + 90,
                person_view_camera.euler.z(),
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
                    .{
                        .orthographic = .{
                            .left = -20.0,
                            .right = 20.0,
                            .bottom = -20.0,
                            .top = 20.0,
                            .near = 0.1,
                            .far = 100.0,
                        },
                    },
                    light_view_camera.position,
                    light_view_camera.position.add(Vec3.fromSlice(&dir_light_direction)),
                    null,
                );
                all_lights.items[0].directional.space_matrix = light_view_camera.getViewProjectMatrix();
                phong_renderer.applyLights(all_lights.items);
                var idx: u32 = 0;
                for (all_lights.items) |d| {
                    if (d.getType() == .directional) continue;
                    render_data_light.vds.?.items[idx].transform =
                        Renderer.LocalTransform{
                        .single = Mat4.fromScale(Vec3.set(0.1)).translate(d.getPosition().?),
                    };
                    idx += 1;
                }
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
        .enable_depth_test = true,
    });
}
