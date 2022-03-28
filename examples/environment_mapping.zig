const std = @import("std");
const zp = @import("zplay");
const dig = zp.deps.dig;
const alg = zp.deps.alg;
const Vec3 = alg.Vec3;
const Vec4 = alg.Vec4;
const Mat4 = alg.Mat4;
const gfx = zp.graphics;
const Texture = gfx.gpu.Texture;
const Renderer = gfx.Renderer;
const Material = gfx.Material;
const Camera = gfx.Camera;
const Model = gfx.@"3d".Model;
const SkyboxRenderer = gfx.@"3d".SkyboxRenderer;
const EnvMappingRenderer = gfx.@"3d".EnvMappingRenderer;

var skybox: SkyboxRenderer = undefined;
var cubemap: *Texture = undefined;
var skybox_material: Material = undefined;
var refract_air_material: Material = undefined;
var refract_water_material: Material = undefined;
var refract_ice_material: Material = undefined;
var refract_glass_material: Material = undefined;
var refract_diamond_material: Material = undefined;
var current_scene_renderer: Renderer = undefined;
var reflect_renderer: EnvMappingRenderer = undefined;
var refract_renderer: EnvMappingRenderer = undefined;
var model: *Model = undefined;
var camera: Camera = undefined;
var render_data_scene: Renderer.Input = undefined;
var render_data_skybox: Renderer.Input = undefined;

fn init(ctx: *zp.Context) anyerror!void {
    std.log.info("game init", .{});

    // init imgui
    try dig.init(ctx.window);

    // allocate materials
    cubemap = try Texture.initCubeFromFilePaths(
        std.testing.allocator,
        "assets/skybox/right.jpg",
        "assets/skybox/left.jpg",
        "assets/skybox/top.jpg",
        "assets/skybox/bottom.jpg",
        "assets/skybox/front.jpg",
        "assets/skybox/back.jpg",
        false,
    );
    skybox_material = Material.init(.{
        .single_cubemap = cubemap,
    }, false);
    refract_air_material = Material.init(.{
        .refract_mapping = .{
            .cubemap = cubemap,
            .ratio = 1.0,
        },
    }, false);
    refract_water_material = Material.init(.{
        .refract_mapping = .{
            .cubemap = cubemap,
            .ratio = 1.33,
        },
    }, false);
    refract_ice_material = Material.init(.{
        .refract_mapping = .{
            .cubemap = cubemap,
            .ratio = 1.309,
        },
    }, false);
    refract_glass_material = Material.init(.{
        .refract_mapping = .{
            .cubemap = cubemap,
            .ratio = 1.52,
        },
    }, false);
    refract_diamond_material = Material.init(.{
        .refract_mapping = .{
            .cubemap = cubemap,
            .ratio = 2.42,
        },
    }, false);

    // alloc renderers
    skybox = SkyboxRenderer.init(std.testing.allocator);
    reflect_renderer = EnvMappingRenderer.init(.reflect);
    refract_renderer = EnvMappingRenderer.init(.refract);
    current_scene_renderer = reflect_renderer.renderer();

    // load model
    model = try Model.fromGLTF(std.testing.allocator, "assets/SciFiHelmet/SciFiHelmet.gltf", false, null);

    // compose renderer's input
    var width: u32 = undefined;
    var height: u32 = undefined;
    ctx.graphics.getDrawableSize(&width, &height);
    camera = Camera.fromPositionAndTarget(
        .{
            .perspective = .{
                .fov = 45,
                .aspect_ratio = @intToFloat(f32, width) / @intToFloat(f32, height),
                .near = 0.1,
                .far = 100,
            },
        },
        Vec3.new(0, 0, 3),
        Vec3.zero(),
        null,
    );
    render_data_scene = try Renderer.Input.init(
        std.testing.allocator,
        &.{},
        &camera,
        &skybox_material,
        null,
    );
    try model.appendVertexData(&render_data_scene, Mat4.identity(), null);
    render_data_skybox = .{
        .camera = &camera,
        .material = &skybox_material,
    };

    // enable depth test
    ctx.graphics.toggleCapability(.depth_test, true);
}

fn loop(ctx: *zp.Context) void {
    const S = struct {
        var frame: f32 = 0;
        var current_mapping: c_int = 0;
        var refract_material: c_int = 0;
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
    ctx.graphics.getDrawableSize(&width, &height);
    ctx.graphics.clear(true, true, true, [4]f32{ 0.2, 0.3, 0.3, 1.0 });

    // render scene
    model.fillTransforms(
        render_data_scene.vds.?.items,
        Mat4.fromTranslate(Vec3.new(0.0, 0, 0))
            .scale(Vec3.set(0.6))
            .mul(Mat4.fromRotation(ctx.tick * 10, Vec3.up())),
    );
    current_scene_renderer.draw(&ctx.graphics, render_data_scene) catch unreachable;
    skybox.draw(&ctx.graphics, render_data_skybox) catch unreachable;

    // rendering settings
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
            _ = dig.combo_Str(
                "environment mapping",
                &S.current_mapping,
                "reflect\x00refract\x00",
                null,
            );
            if (S.current_mapping == 1) {
                current_scene_renderer = refract_renderer.renderer();
                _ = dig.combo_Str(
                    "refract ratio",
                    &S.refract_material,
                    "air\x00water\x00ice\x00glass\x00diamond",
                    null,
                );
                render_data_scene.material = switch (S.refract_material) {
                    0 => &refract_air_material,
                    1 => &refract_water_material,
                    2 => &refract_ice_material,
                    3 => &refract_glass_material,
                    4 => &refract_diamond_material,
                    else => unreachable,
                };
            } else {
                current_scene_renderer = reflect_renderer.renderer();
                render_data_scene.material = &skybox_material; // reflect material is same as skybox
            }
        }
        dig.end();
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
        .width = 1600,
        .height = 900,
        .quitFn = quit,
    });
}
