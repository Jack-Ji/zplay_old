const std = @import("std");
const math = std.math;
const zp = @import("zplay");
const gfx = zp.graphics;
const Context = gfx.gpu.Context;
const VertexArray = gfx.gpu.VertexArray;
const Texture = gfx.gpu.Texture;
const Renderer = gfx.Renderer;
const RenderPipeline = gfx.RenderPipeline;
const Material = gfx.Material;
const Camera = gfx.Camera;
const SimpleRenderer = gfx.@"3d".SimpleRenderer;
const Mesh = gfx.@"3d".Mesh;
const dig = zp.deps.dig;
const alg = zp.deps.alg;
const Vec3 = alg.Vec3;
const Vec4 = alg.Vec4;
const Mat4 = alg.Mat4;

var cube: Mesh = undefined;
var cube_wire_va: VertexArray = undefined;
var plane_va: VertexArray = undefined;
var cube_material: Material = undefined;
var wire_material: Material = undefined;
var plane_material: Material = undefined;
var camera: Camera = undefined;
var render_data_cube: Renderer.Input = undefined;
var render_data_section: Renderer.Input = undefined;
var cube_renderer: SimpleRenderer = undefined;
var section_renderer: SimpleRenderer = undefined;
var pipeline: RenderPipeline = undefined;

var wire_vs = [_]f32{
    0, 0, 0, 1, 0, 0,
    0, 0, 1, 1, 0, 1,
    0, 1, 1, 1, 1, 1,
    0, 1, 0, 1, 1, 0,
    0, 0, 0, 0, 1, 0,
    0, 0, 1, 0, 1, 1,
    1, 0, 1, 1, 1, 1,
    1, 0, 0, 1, 1, 0,
    0, 0, 0, 0, 0, 1,
    1, 0, 0, 1, 0, 1,
    1, 1, 0, 1, 1, 1,
    0, 1, 0, 0, 1, 1,
};

const cube_center = Vec3.set(0.5);
var plane_norm = [_]f32{ 0, 0, 1 };
var plane_point = [_]f32{ 0, 0, 0.2 };
var plane_vs = [_]f32{0} ** 12;

fn init(ctx: *zp.Context) anyerror!void {
    std.log.info("game init", .{});

    try dig.init(ctx);

    cube = try Mesh.genCube(std.testing.allocator, 1, 1, 1);
    cube_wire_va = VertexArray.init(std.testing.allocator, 1);
    cube_wire_va.use();
    cube_wire_va.vbos[0].allocInitData(
        f32,
        &wire_vs,
        .static_draw,
    );
    cube_wire_va.setAttribute(0, 0, 3, f32, false, 0, 0);
    cube_wire_va.disuse();
    plane_va = VertexArray.init(std.testing.allocator, 1);
    plane_va.vbos[0].allocData(@sizeOf(@TypeOf(plane_vs)), .dynamic_draw);
    plane_va.use();
    plane_va.setAttribute(0, 0, 3, f32, false, 0, 0);
    plane_va.disuse();
    cube_material = Material.init(.{
        .single_texture = try Texture.init2DFromPixels(
            std.testing.allocator,
            &[_]u8{ 200, 200, 200, 128 },
            .rgba,
            1,
            1,
            .{},
        ),
    });
    wire_material = Material.init(.{
        .single_texture = try Texture.init2DFromPixels(
            std.testing.allocator,
            &[_]u8{ 0, 0, 0 },
            .rgb,
            1,
            1,
            .{},
        ),
    });
    plane_material = Material.init(.{
        .single_texture = try Texture.init2DFromPixels(
            std.testing.allocator,
            &[_]u8{ 200, 0, 0, 100 },
            .rgba,
            1,
            1,
            .{},
        ),
    });

    camera = Camera.fromPositionAndTarget(
        .{
            .perspective = .{
                .fov = 45,
                .aspect_ratio = ctx.graphics.viewport.getAspectRatio(),
                .near = 0.1,
                .far = 100,
            },
        },
        Vec3.new(1.5, -1.5, 2),
        cube_center,
        Vec3.forward(),
    );
    render_data_cube = try Renderer.Input.init(
        std.testing.allocator,
        &.{},
        &camera,
        null,
        null,
    );
    try render_data_cube.vds.?.append(
        cube.getVertexData(
            &cube_material,
            Renderer.LocalTransform{
                .single = Mat4.fromTranslate(cube_center),
            },
        ),
    );
    try render_data_cube.vds.?.append(.{
        .element_draw = false,
        .vertex_array = cube_wire_va,
        .primitive = .lines,
        .count = 24,
        .material = &wire_material,
    });
    render_data_section = try Renderer.Input.init(
        std.testing.allocator,
        &.{},
        &camera,
        null,
        null,
    );
    try render_data_section.vds.?.append(.{
        .element_draw = false,
        .vertex_array = plane_va,
        .primitive = .triangle_fan,
        .count = 4,
        .material = &plane_material,
    });
    cube_renderer = SimpleRenderer.init(.{});
    section_renderer = SimpleRenderer.init(.{
        .pos_range1_min = Vec3.set(0),
        .pos_range1_max = Vec3.set(1),
    });
    pipeline = try RenderPipeline.init(
        std.testing.allocator,
        &[_]RenderPipeline.RenderPass{
            .{
                .beforeFn = beforeRenderingCube,
                .rd = cube_renderer.renderer(),
                .data = &render_data_cube,
            },
            .{
                .rd = section_renderer.renderer(),
                .data = &render_data_section,
            },
        },
    );
}

fn beforeRenderingCube(ctx: *Context, custom: ?*anyopaque) void {
    _ = custom;
    ctx.clear(true, false, false, [_]f32{ 0.5, 0.5, 0.5, 1 });
}

fn loop(ctx: *zp.Context) void {
    const S = struct {
        var mouse_btn_pressed = false;
        var camera_orig_pos: Vec3 = undefined;
        var mouse_orig_x: i32 = undefined;
        var mouse_orig_y: i32 = undefined;
    };

    while (ctx.pollEvent()) |e| {
        if (e == .mouse_event and dig.getIO().*.WantCaptureMouse) {
            _ = dig.processEvent(e);
            continue;
        }
        switch (e) {
            .keyboard_event => |key| {
                if (key.trigger_type == .up) {
                    switch (key.scan_code) {
                        .escape => ctx.kill(),
                        else => {},
                    }
                }
            },
            .mouse_event => |me| {
                switch (me.data) {
                    .button => |click| {
                        if (click.btn != .left) {
                            continue;
                        }
                        if (click.clicked and !S.mouse_btn_pressed) {
                            S.camera_orig_pos = camera.position;
                            S.mouse_orig_x = click.x;
                            S.mouse_orig_y = click.y;
                        }
                        S.mouse_btn_pressed = click.clicked;
                    },
                    .motion => |move| {
                        if (!S.mouse_btn_pressed) continue;
                        const vpos = S.camera_orig_pos.sub(cube_center);
                        const offset_angle_h = @intToFloat(f32, -(move.x - S.mouse_orig_x)) / 10;
                        const offset_angle_v = @intToFloat(f32, move.y - S.mouse_orig_y) / 10;
                        const angle_h = if (vpos.x() > 0)
                            alg.toDegrees(math.atan(vpos.y() / vpos.x()))
                        else
                            180 + alg.toDegrees(math.atan(vpos.y() / vpos.x()));
                        const angle_v = 90 - vpos.getAngle(Vec3.forward());
                        const new_angle_h = alg.toRadians(angle_h + offset_angle_h);
                        const new_angle_v = alg.toRadians(angle_v + offset_angle_v);
                        const new_pos = cube_center.add(
                            Vec3.new(
                                @cos(new_angle_v) * @cos(new_angle_h),
                                @cos(new_angle_v) * @sin(new_angle_h),
                                @sin(new_angle_v),
                            ).scale(vpos.length()),
                        );
                        var new_camera = Camera.fromPositionAndTarget(
                            camera.frustrum,
                            new_pos,
                            cube_center,
                            Vec3.new(0, 0, 1),
                        );
                        camera = new_camera;
                    },
                    .wheel => |scroll| {
                        camera.frustrum.perspective.fov -= @intToFloat(f32, scroll.scroll_y);
                        if (camera.frustrum.perspective.fov < 1) {
                            camera.frustrum.perspective.fov = 1;
                        }
                        if (camera.frustrum.perspective.fov > 45) {
                            camera.frustrum.perspective.fov = 45;
                        }
                    },
                }
            },
            .quit_event => ctx.kill(),
            else => {},
        }
    }

    // calculate a plane determined by normal and point
    const norm = Vec3.fromSlice(&plane_norm).norm();
    plane_vs = zp.utils.getPlane(
        norm,
        cube_center.add(
            norm.scale(
                Vec3.fromSlice(&plane_point).sub(cube_center).dot(norm),
            ),
        ),
        2.5,
    );
    plane_va.vbos[0].updateData(
        0,
        f32,
        &plane_vs,
    );

    // render the scene
    pipeline.run(&ctx.graphics) catch unreachable;

    // control panel
    dig.beginFrame();
    defer dig.endFrame();
    if (dig.begin("settings", null, null)) {
        _ = dig.dragFloat3("plane normal", &plane_norm, .{
            .v_speed = 0.001,
            .v_min = -1,
            .v_max = 1,
        });
        _ = dig.dragFloat3("plane point", &plane_point, .{
            .v_speed = 0.001,
            .v_min = 0,
            .v_max = 1,
        });
    }
    dig.end();
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
        .width = 1024,
        .height = 760,
    });
}
