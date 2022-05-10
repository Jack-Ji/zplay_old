const std = @import("std");
const assert = std.debug.assert;
const zp = @import("zplay");
const dig = zp.deps.dig;
const alg = zp.deps.alg;
const Vec3 = alg.Vec3;
const Vec4 = alg.Vec4;
const gfx = zp.graphics;
const Texture = gfx.gpu.Texture;
const Camera = gfx.Camera;
const Material = gfx.Material;
const Renderer = gfx.Renderer;
const Mesh = gfx.@"3d".Mesh;
const SimpleRenderer = gfx.@"3d".SimpleRenderer;

var simple_renderer: SimpleRenderer = undefined;
var wireframe_mode = true;
var perspective_mode = true;
var use_texture = false;
var meshes: std.ArrayList(Mesh) = undefined;
var positions: std.ArrayList(Vec3) = undefined;
var default_material: Material = undefined;
var picture_material: Material = undefined;
var camera: Camera = undefined;
var view_persp: Camera.ViewFrustrum = undefined;
var view_ortho: Camera.ViewFrustrum = undefined;
var render_data: Renderer.Input = undefined;

fn init(ctx: *zp.Context) anyerror!void {
    std.log.info("game init", .{});

    // init imgui
    try dig.init(ctx);

    // simple renderer
    simple_renderer = SimpleRenderer.init(.{});

    // generate meshes
    meshes = std.ArrayList(Mesh).init(std.testing.allocator);
    positions = std.ArrayList(Vec3).init(std.testing.allocator);
    try meshes.append(try Mesh.genQuad(std.testing.allocator, 1, 1));
    try meshes.append(try Mesh.genCircle(std.testing.allocator, 0.5, 50));
    try meshes.append(try Mesh.genCube(std.testing.allocator, 0.5, 0.7, 2));
    try meshes.append(try Mesh.genSphere(std.testing.allocator, 0.7, 36, 18));
    try meshes.append(try Mesh.genCylinder(std.testing.allocator, 1, 0.5, 0.5, 2, 36));
    try meshes.append(try Mesh.genCylinder(std.testing.allocator, 1, 0.3, 0.3, 1, 3));
    try meshes.append(try Mesh.genCylinder(std.testing.allocator, 1, 0.5, 0, 1, 36));
    try positions.append(Vec3.new(-2.0, 1.2, 0));
    try positions.append(Vec3.new(-0.5, 1.2, 0));
    try positions.append(Vec3.new(1.0, 1.2, 0));
    try positions.append(Vec3.new(-2.2, -1.2, 0));
    try positions.append(Vec3.new(-0.4, -1.2, 0));
    try positions.append(Vec3.new(1.1, -1.2, 0));
    try positions.append(Vec3.new(2.3, -1.2, 0));
    assert(meshes.items.len == positions.items.len);

    // create picture_material
    default_material = Material.init(.{
        .single_texture = Texture.init2DFromPixels(
            std.testing.allocator,
            &.{ 0, 255, 0 },
            .rgb,
            1,
            1,
            .{},
        ) catch unreachable,
    });
    picture_material = Material.init(.{
        .single_texture = Texture.init2DFromFilePath(
            std.testing.allocator,
            "assets/wall.jpg",
            false,
            .{},
        ) catch unreachable,
    });

    // compose renderer's input
    view_persp = .{
        .perspective = .{
            .fov = 45,
            .aspect_ratio = ctx.graphics.viewport.getAspectRatio(),
            .near = 0.1,
            .far = 100,
        },
    };
    view_ortho = .{
        .orthographic = .{
            .left = -3,
            .right = 3,
            .bottom = -3,
            .top = 3,
            .near = 0.1,
            .far = 100,
        },
    };
    camera = Camera.fromPositionAndTarget(
        view_persp,
        Vec3.new(0, 0, 6),
        Vec3.zero(),
        null,
    );
    render_data = try Renderer.Input.init(
        std.testing.allocator,
        &.{},
        &camera,
        if (use_texture) &picture_material else &default_material,
        null,
    );
    for (meshes.items) |m| {
        try render_data.vds.?.append(m.getVertexData(null, null));
    }

    // init graphics context params
    ctx.graphics.setPolygonMode(if (wireframe_mode) .line else .fill);
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

    ctx.graphics.clear(true, true, false, [_]f32{ 0.2, 0.3, 0.3, 1.0 });

    // start render
    S.axis = alg.Mat4.fromRotation(1, Vec3.new(-1, 1, -1)).mulByVec4(S.axis);
    const model = alg.Mat4.fromRotation(
        S.frame,
        Vec3.new(S.axis.x(), S.axis.y(), S.axis.z()),
    );
    for (render_data.vds.?.items) |*d, i| {
        d.transform.single = model.translate(positions.items[i]);
    }
    simple_renderer.draw(&ctx.graphics, render_data) catch unreachable;

    // settings
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
            if (dig.checkbox("wireframe", &wireframe_mode)) {
                ctx.graphics.setPolygonMode(if (wireframe_mode) .line else .fill);
            }
            if (dig.checkbox("perspective", &perspective_mode)) {
                camera.frustrum = if (perspective_mode) view_persp else view_ortho;
            }
            if (dig.checkbox("texture", &use_texture)) {
                render_data.material = if (use_texture) &picture_material else &default_material;
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
        .enable_depth_test = true,
    });
}
