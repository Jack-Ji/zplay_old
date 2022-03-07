const std = @import("std");
const zp = @import("zplay");
const gfx = zp.graphics;
const Context = gfx.gpu.Context;
const VertexArray = gfx.gpu.VertexArray;
const Texture = gfx.gpu.Texture;
const Renderer = gfx.Renderer;
const render_pass = gfx.render_pass;
const SimpleRenderer = gfx.SimpleRenderer;
const Material = gfx.Material;
const Camera = gfx.Camera;
const Mesh = gfx.Mesh;
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
var pipeline: render_pass.Pipeline = undefined;

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

var plane_norm = [_]f32{ 0, 0, 1 };
var plane_point = [_]f32{ 0, 0, 0.2 };
var plane_vs = [_]f32{0} ** 12;

fn init(ctx: *zp.Context) anyerror!void {
    std.log.info("game init", .{});

    try dig.init(ctx.window);

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
    }, true);
    wire_material = Material.init(.{
        .single_texture = try Texture.init2DFromPixels(
            std.testing.allocator,
            &[_]u8{ 0, 0, 0 },
            .rgb,
            1,
            1,
            .{},
        ),
    }, true);
    plane_material = Material.init(.{
        .single_texture = try Texture.init2DFromPixels(
            std.testing.allocator,
            &[_]u8{ 200, 0, 0, 100 },
            .rgba,
            1,
            1,
            .{},
        ),
    }, true);
    camera = Camera.fromPositionAndTarget(
        Vec3.new(1.5, -1.5, 2),
        Vec3.new(0.5, 0.5, 0.5),
        Vec3.new(0, 0, 1),
    );

    var width: u32 = undefined;
    var height: u32 = undefined;
    ctx.graphics.getDrawableSize(&width, &height);
    const projection = Mat4.perspective(
        45,
        @intToFloat(f32, width) / @intToFloat(f32, height),
        0.1,
        100,
    );
    render_data_cube = try Renderer.Input.init(
        std.testing.allocator,
        &.{},
        projection,
        &camera,
        null,
        null,
    );
    try render_data_cube.vds.?.append(
        cube.getVertexData(
            &cube_material,
            Renderer.LocalTransform{
                .single = Mat4.fromTranslate(Vec3.set(0.5)),
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
        projection,
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
    pipeline = try render_pass.Pipeline.init(
        std.testing.allocator,
        &[_]render_pass.RenderPass{
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

    ctx.graphics.toggleCapability(.blend, true);
}

fn beforeRenderingCube(ctx: *Context, custom: ?*anyopaque) void {
    _ = custom;
    ctx.clear(true, false, false, [_]f32{ 0.5, 0.5, 0.5, 1 });
}

fn loop(ctx: *zp.Context) void {
    while (ctx.pollEvent()) |e| {
        switch (e) {
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

    // calculate a plane determined by normal and point
    const cube_center = Vec3.set(0.5);
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
