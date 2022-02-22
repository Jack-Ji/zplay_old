const std = @import("std");
const assert = std.debug.assert;
const zp = @import("zplay");
const dig = zp.deps.dig;
const alg = zp.deps.alg;
const Vec3 = alg.Vec3;
const Vec4 = alg.Vec4;
const gfx = zp.graphics;
const Texture = gfx.gpu.Texture;
const Mesh = gfx.Mesh;
const Camera = gfx.Camera;
const Material = gfx.Material;
const Renderer = gfx.Renderer;
const SimpleRenderer = gfx.SimpleRenderer;

var simple_renderer: SimpleRenderer = undefined;
var wireframe_mode = true;
var perspective_mode = true;
var use_texture = false;
var meshes: std.ArrayList(Mesh) = undefined;
var positions: std.ArrayList(Vec3) = undefined;
var default_material: Material = undefined;
var picture_material: Material = undefined;
var camera = Camera.fromPositionAndTarget(
    Vec3.new(0, 0, 6),
    Vec3.zero(),
    null,
);
var proj_persp: alg.Mat4 = undefined;
var proj_ortho: alg.Mat4 = undefined;
var render_data: Renderer.Input = undefined;

fn init(ctx: *zp.Context) anyerror!void {
    std.log.info("game init", .{});

    // init imgui
    try dig.init(ctx.window);

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
    }, true);
    picture_material = Material.init(.{
        .single_texture = Texture.init2DFromFilePath(
            std.testing.allocator,
            "assets/wall.jpg",
            false,
            .{},
        ) catch unreachable,
    }, true);
    var unit = default_material.allocTextureUnit(0);
    _ = picture_material.allocTextureUnit(unit);

    // compose renderer's input
    var width: u32 = undefined;
    var height: u32 = undefined;
    ctx.graphics.getDrawableSize(&width, &height);
    proj_persp = alg.Mat4.perspective(
        camera.zoom,
        @intToFloat(f32, width) / @intToFloat(f32, height),
        0.1,
        100,
    );
    proj_ortho = alg.Mat4.orthographic(
        -3,
        3,
        -3,
        3,
        0,
        100,
    );
    render_data = try Renderer.Input.init(
        std.testing.allocator,
        &ctx.graphics,
        &.{},
        if (perspective_mode) proj_persp else proj_ortho,
        &camera,
        if (use_texture) &picture_material else &default_material,
        null,
    );
    for (meshes.items) |m| {
        try render_data.vds.?.append(m.getVertexData(null, null));
    }

    // init graphics context params
    ctx.graphics.toggleCapability(.depth_test, true);
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
    simple_renderer.draw(render_data) catch unreachable;

    // settings
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
            if (dig.checkbox("wireframe", &wireframe_mode)) {
                ctx.graphics.setPolygonMode(if (wireframe_mode) .line else .fill);
            }
            if (dig.checkbox("perspective", &perspective_mode)) {
                render_data.projection = if (perspective_mode) proj_persp else proj_ortho;
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
    });
}
