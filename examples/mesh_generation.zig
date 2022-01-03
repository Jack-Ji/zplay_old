const std = @import("std");
const zp = @import("zplay");
const SimpleRenderer = zp.graphics.@"3d".SimpleRenderer;
const Mesh = zp.graphics.@"3d".Mesh;
const Camera = zp.graphics.@"3d".Camera;
const Material = zp.graphics.@"3d".Material;
const Texture2D = zp.graphics.texture.Texture2D;
const dig = zp.deps.dig;
const alg = zp.deps.alg;
const Vec3 = alg.Vec3;
const Vec4 = alg.Vec4;

var simple_renderer: SimpleRenderer = undefined;
var wireframe_mode = true;
var perspective_mode = true;
var use_texture = false;
var quad: Mesh = undefined;
var cube1: Mesh = undefined;
var cube2: Mesh = undefined;
var sphere: Mesh = undefined;
var cylinder: Mesh = undefined;
var prim: Mesh = undefined;
var cone: Mesh = undefined;
var default_material: Material = undefined;
var picture_material: Material = undefined;
var camera = Camera.fromPositionAndTarget(
    Vec3.new(0, 0, 6),
    Vec3.zero(),
    null,
);

fn init(ctx: *zp.Context) anyerror!void {
    std.log.info("game init", .{});

    // init imgui
    try dig.init(ctx.window);

    // simple renderer
    simple_renderer = SimpleRenderer.init();

    // generate meshes
    quad = try Mesh.genQuad(std.testing.allocator, 1, 1);
    cube1 = try Mesh.genCube(std.testing.allocator, 0.5, 0.5, 0.5);
    cube2 = try Mesh.genCube(std.testing.allocator, 0.5, 0.7, 2);
    sphere = try Mesh.genSphere(std.testing.allocator, 0.7, 36, 18);
    cylinder = try Mesh.genCylinder(std.testing.allocator, 1, 0.5, 0.5, 2, 36);
    prim = try Mesh.genCylinder(std.testing.allocator, 1, 0.3, 0.3, 1, 3);
    cone = try Mesh.genCylinder(std.testing.allocator, 1, 0.5, 0, 1, 36);

    // create picture_material
    default_material = Material.init(.{
        .single_texture = Texture2D.fromPixelData(
            std.testing.allocator,
            &.{ 0, 255, 0, 255 },
            1,
            1,
            .{},
        ) catch unreachable,
    });
    picture_material = Material.init(.{
        .single_texture = Texture2D.fromFilePath(
            std.testing.allocator,
            "assets/wall.jpg",
            false,
            .{},
        ) catch unreachable,
    });
    var unit = default_material.allocTextureUnit(0);
    _ = picture_material.allocTextureUnit(unit);

    // enable depth test
    ctx.graphics.toggleCapability(.depth_test, true);
}

fn loop(ctx: *zp.Context) void {
    const S = struct {
        var frame: f32 = 0;
        var axis = Vec4.new(1, 1, 1, 0);
        var last_tick: ?f32 = null;
    };
    S.frame += 1;

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

    // start drawing
    ctx.graphics.clear(true, true, false, [_]f32{ 0.2, 0.3, 0.3, 1.0 });

    var projection: alg.Mat4 = undefined;
    if (perspective_mode) {
        projection = alg.Mat4.perspective(
            camera.zoom,
            @intToFloat(f32, width) / @intToFloat(f32, height),
            0.1,
            100,
        );
    } else {
        projection = alg.Mat4.orthographic(
            -3,
            3,
            -3,
            3,
            0,
            100,
        );
    }
    S.axis = alg.Mat4.fromRotation(1, Vec3.new(-1, 1, -1)).multByVec4(S.axis);
    const model = alg.Mat4.fromRotation(
        S.frame,
        Vec3.new(S.axis.x, S.axis.y, S.axis.z),
    );

    var renderer = simple_renderer.renderer();
    renderer.begin();
    {
        renderer.renderMesh(
            quad,
            model.translate(Vec3.new(-2.0, 1.2, 0)),
            projection,
            camera,
            if (use_texture) picture_material else default_material,
            null,
        ) catch unreachable;

        renderer.renderMesh(
            cube1,
            model.translate(Vec3.new(-0.5, 1.2, 0)),
            projection,
            camera,
            if (use_texture) picture_material else default_material,
            null,
        ) catch unreachable;

        renderer.renderMesh(
            cube2,
            model.translate(Vec3.new(1.0, 1.2, 0)),
            projection,
            camera,
            if (use_texture) picture_material else default_material,
            null,
        ) catch unreachable;

        renderer.renderMesh(
            sphere,
            model.translate(Vec3.new(-2.2, -1.2, 0)),
            projection,
            camera,
            if (use_texture) picture_material else default_material,
            null,
        ) catch unreachable;

        renderer.renderMesh(
            cylinder,
            model.translate(Vec3.new(-0.4, -1.2, 0)),
            projection,
            camera,
            if (use_texture) picture_material else default_material,
            null,
        ) catch unreachable;

        renderer.renderMesh(
            prim,
            model.translate(Vec3.new(1.1, -1.2, 0)),
            projection,
            camera,
            if (use_texture) picture_material else default_material,
            null,
        ) catch unreachable;

        renderer.renderMesh(
            cone,
            model.translate(Vec3.new(2.3, -1.2, 0)),
            projection,
            camera,
            if (use_texture) picture_material else default_material,
            null,
        ) catch unreachable;
    }
    renderer.end();

    // settings
    dig.beginFrame();
    {
        dig.setNextWindowPos(
            .{ .x = @intToFloat(f32, width) - 10, .y = 50 },
            .{
                .cond = dig.c.ImGuiCond_Once,
                .pivot = .{ .x = 1, .y = 0 },
            },
        );
        if (dig.begin(
            "settings",
            null,
            dig.c.ImGuiWindowFlags_NoResize |
                dig.c.ImGuiWindowFlags_AlwaysAutoResize,
        )) {
            _ = dig.checkbox("wireframe", &wireframe_mode);
            _ = dig.checkbox("perspective", &perspective_mode);
            _ = dig.checkbox("texture", &use_texture);

            ctx.graphics.setPolygonMode(
                if (wireframe_mode) .line else .fill,
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
        .enable_highres_depth = false,
    });
}
