const std = @import("std");
const zp = @import("zplay");
const gl = zp.deps.gl;
const dig = zp.deps.dig;
const alg = zp.deps.alg;
const Vec3 = alg.Vec3;
const Mat4 = alg.Mat4;
const gfx = zp.graphics;
const Framebuffer = gfx.gpu.Framebuffer;
const Texture = gfx.gpu.Texture;
const Renderer = gfx.Renderer;
const Camera = gfx.Camera;
const Material = gfx.Material;
const post_processing = gfx.post_processing;
const Mesh = gfx.@"3d".Mesh;
const SimpleRenderer = gfx.@"3d".SimpleRenderer;

var fb: Framebuffer = undefined;
var fb_material: Material = undefined;
var simple_renderer: SimpleRenderer = undefined;
var box: Mesh = undefined;
var box_material: Material = undefined;
var camera: Camera = undefined;
var pp_texture_display: post_processing.TextureDisplay = undefined;
var pp_gamma_correction: post_processing.GammaCorrection = undefined;
var pp_grayscale: post_processing.Grayscale = undefined;
var pp_inversion: post_processing.Inversion = undefined;
var pp_convolution: post_processing.Convolution = undefined;

var gamma_value: f32 = 2.2;
const kernel_shapen = post_processing.Convolution.Kernel.initShapen();
const kernel_blur = post_processing.Convolution.Kernel.initBlur();
const kernel_edge = post_processing.Convolution.Kernel.initEdgeDetection();
var kernel_selection: enum(c_int) {
    shapen,
    blur,
    edge,
} = .shapen;
var pp_selection: enum(c_int) {
    texture_display,
    gamma_correction,
    grayscale,
    inversion,
    convolution,
} = .convolution;
var pp_rd: Renderer = undefined;
var render_data: Renderer.Input = undefined;

fn init(ctx: *zp.Context) anyerror!void {
    std.log.info("game init", .{});

    // init imgui
    try dig.init(ctx);

    // create framebuffer
    const size = ctx.graphics.getDrawableSize();
    fb = try Framebuffer.init(std.testing.allocator, size.w, size.h, .{});

    // create renderer
    simple_renderer = SimpleRenderer.init(.{});

    // create mesh
    box = try Mesh.genCube(std.testing.allocator, 2, 2, 2);

    // create material
    fb_material = Material.init(.{
        .single_texture = fb.tex.?,
    });
    box_material = Material.init(.{
        .single_texture = try Texture.init2DFromFilePath(
            std.testing.allocator,
            "assets/container2.png",
            false,
            .{},
        ),
    });

    // create post-processing renderers
    pp_texture_display = try post_processing.TextureDisplay.init(std.testing.allocator);
    pp_gamma_correction = try post_processing.GammaCorrection.init(std.testing.allocator);
    pp_grayscale = try post_processing.Grayscale.init(std.testing.allocator);
    pp_inversion = try post_processing.Inversion.init(std.testing.allocator);
    pp_convolution = try post_processing.Convolution.init(std.testing.allocator);
    pp_rd = switch (pp_selection) {
        .texture_display => pp_texture_display.renderer(),
        .gamma_correction => pp_gamma_correction.renderer(),
        .grayscale => pp_grayscale.renderer(),
        .inversion => pp_inversion.renderer(),
        .convolution => pp_convolution.renderer(),
    };

    // compose render data
    camera = Camera.fromPositionAndTarget(
        .{
            .perspective = .{
                .fov = 45,
                .aspect_ratio = ctx.graphics.viewport.getAspectRatio(),
                .near = 0.1,
                .far = 100,
            },
        },
        Vec3.new(3, 3, 3),
        Vec3.zero(),
        null,
    );
    var vertex_data = box.getVertexData(null, null);
    render_data = try Renderer.Input.init(
        std.testing.allocator,
        &.{vertex_data},
        &camera,
        &box_material,
        null,
    );
}

fn loop(ctx: *zp.Context) void {
    while (ctx.pollEvent()) |e| {
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

    // render scene
    Framebuffer.use(fb);
    {
        ctx.graphics.clear(true, true, false, [_]f32{ 0.2, 0.3, 0.3, 1.0 });
        simple_renderer.draw(&ctx.graphics, render_data) catch unreachable;
    }

    // post processing
    Framebuffer.use(null);
    {
        ctx.graphics.clear(true, true, false, [_]f32{ 0.2, 0.3, 0.3, 1.0 });
        var input = Renderer.Input{
            .material = &fb_material,
        };
        switch (pp_selection) {
            .gamma_correction => input.custom = &gamma_value,
            .convolution => input.custom = switch (kernel_selection) {
                .shapen => &kernel_shapen,
                .blur => &kernel_blur,
                .edge => &kernel_edge,
            },
            else => {},
        }
        pp_rd.draw(&ctx.graphics, input) catch unreachable;
    }

    // control panel
    dig.beginFrame();
    {
        dig.setNextWindowPos(
            .{ .x = @intToFloat(f32, ctx.graphics.viewport.w) - 10, .y = 50 },
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
            var current_selection: c_int = @enumToInt(pp_selection);
            _ = dig.combo_Str(
                "post-processing effect",
                @ptrCast(*c_int, &current_selection),
                "normal display\x00gamma correction\x00grayscale\x00inversion\x00convolution\x00",
                null,
            );
            pp_selection = @intToEnum(@TypeOf(pp_selection), current_selection);
            if (pp_selection == .gamma_correction) {
                _ = dig.dragFloat(
                    "gamma value",
                    &gamma_value,
                    .{
                        .v_speed = 0.01,
                        .v_min = 0.01,
                        .v_max = 10,
                    },
                );
            }
            if (pp_selection == .convolution) {
                current_selection = @enumToInt(kernel_selection);
                _ = dig.combo_Str(
                    "kernel",
                    @ptrCast(*c_int, &current_selection),
                    "shapen\x00blur\x00edge\x00",
                    null,
                );
                kernel_selection = @intToEnum(@TypeOf(kernel_selection), current_selection);
            }
            pp_rd = switch (pp_selection) {
                .texture_display => pp_texture_display.renderer(),
                .gamma_correction => pp_gamma_correction.renderer(),
                .grayscale => pp_grayscale.renderer(),
                .inversion => pp_inversion.renderer(),
                .convolution => pp_convolution.renderer(),
            };
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
