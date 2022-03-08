const std = @import("std");
const assert = std.debug.assert;
const light = @import("light.zig");
const Model = @import("Model.zig");
const zp = @import("../../zplay.zig");
const gfx = zp.graphics;
const Framebuffer = gfx.gpu.Framebuffer;
const Context = zp.Context;
const Renderer = gfx.Renderer;
const Camera = gfx.Camera;
const Material = gfx.Material;
const render_pass = gfx.render_pass;
const alg = zp.deps.alg;
const Vec2 = alg.Vec2;
const Vec3 = alg.Vec3;
const Vec4 = alg.Vec4;
const Mat4 = alg.Mat4;
const Quat = alg.Quat;
const Self = @This();

/// memory allocator
allocator: std.mem.Allocator,

/// viewer's camera
viewer_camera: Camera,

/// params of sun light
sun_camera: Camera,
sun: light.Light,

/// render-passes
rd_pipeline: render_pass.Pipeline,

/// rendering data for shadow-mapping
rdata_shadow: Renderer.Input,

/// rendering data for regular shading
rdata_scene: Renderer.Input,

/// rendering data for post-processing
rdata_post: Renderer.Input,

pub const InitOption = struct {
    viewer_projection: Mat4,
    viewer_position: Vec3 = Vec3.set(1),
    viewer_target: Vec3 = Vec3.zero(),
    viewer_up: Vec3 = Vec3.up(),
    sun_position: Vec3 = Vec3.new(0, 30, 0),
    sun_dir: Vec3 = Vec3.new(0.5, -1, 0),
    sun_up: Vec3 = Vec3.up(),
    sun_ambient: Vec3 = Vec3.set(0.8),
    sun_diffuse: Vec3 = Vec3.set(0.3),
    sun_specular: Vec3 = Vec3.set(0.1),
    sun_projection: Mat4 = Mat4.orthographic(
        -100.0,
        100.0,
        -100.0,
        100.0,
        0.1,
        1000,
    ),
};

/// create scene
pub fn init(allocator: std.mem.Allocator, option: InitOption) !*Self {
    var self = try allocator.create(Self);
    self.allocator = allocator;
    self.viewer_camera = Camera.fromPositionAndTarget(
        option.viewer_position,
        option.viewer_target,
        option.viewer_up,
    );
    self.sun_camera = Camera.fromPositionAndTarget(
        option.sun_position,
        option.sun_position.add(option.sun_dir),
        option.sun_up,
    );
    self.sun = light.Light{
        .directional = .{
            .ambient = option.sun_ambient,
            .diffuse = option.sun_diffuse,
            .specular = option.sun_specular,
            .direction = option.sun_dir,
            .space_matrix = option.sun_projection
                .mul(self.sun_camera.getViewMatrix()),
        },
    };
    self.rd_pipeline = try render_pass.Pipeline.init(allocator, &.{});
    self.rdata_shadow = try Renderer.Input.init(
        allocator,
        &.{},
        option.sun_projection,
        &self.sun_camera,
        null,
        null,
    );
    self.rdata_scene = try Renderer.Input.init(
        allocator,
        &.{},
        option.viewer_projection,
        &self.viewer_camera,
        null,
        null,
    );
    self.rdata_post = try Renderer.Input.init(
        allocator,
        &.{},
        null,
        null,
        null,
        null,
    );
    return self;
}

fn destroyRenderData(rdata: Renderer.Input) void {
    for (rdata.vds.?.items) |vd| {
        switch (vd.transform) {
            .single => {},
            .instanced => |trs| trs.deinit(),
        }
    }
    rdata.deinit();
}

/// remove scene
pub fn deinit(self: *Self) void {
    self.rd_pipeline.deinit();
    destroyRenderData(self.rdata_shadow);
    destroyRenderData(self.rdata_scene);
    destroyRenderData(self.rdata_post);
    self.allocator.destroy(self);
}

/// add rendering object into scene
pub fn addModel(
    self: *Self,
    model: Model,
    trs: []Mat4,
    material: ?*Material,
    has_shadow: bool,
) !void {
    assert(trs.len > 0);
    if (has_shadow) {
        if (trs.len == 0) {
            try model.appendVertexData(
                &self.rdata_shadow,
                trs[0],
                material,
            );
        } else {
            try model.appendVertexDataInstanced(
                self.allocator,
                &self.rdata_shadow,
                trs,
                material,
            );
        }
    }
    if (trs.len == 0) {
        try model.appendVertexData(&self.rdata_scene, trs[0], material);
    } else {
        try model.appendVertexDataInstanced(
            self.allocator,
            &self.rdata_scene,
            trs,
            material,
        );
    }
}

/// set render-passes
pub const RenderPassOption = struct {
    /// frame buffer of the render-pass
    fb: ?Framebuffer,

    /// material setting
    mr: ?Material = null,

    /// do some work before/after rendering
    beforeFn: ?render_pass.TriggerFunc = null,
    afterFn: ?render_pass.TriggerFunc = null,

    /// renderer of the render-pass
    rd: Renderer,
    light_rd: ?light.Renderer = null,

    /// custom data
    custom: ?*anyopaque = null,
};
pub fn setRenderPasses(
    self: *Self,
    shadow_mapping: ?RenderPassOption,
    regular_shading: ?RenderPassOption,
    post_processing: ?RenderPassOption,
) !void {
    var passes: [3]render_pass.RenderPass = undefined;
    var count: u32 = 0;
    if (shadow_mapping) |p| {
        passes[count] = .{
            .fb = p.fb,
            .beforeFn = p.beforeFn,
            .afterFn = p.afterFn,
            .rd = p.rd,
            .custom = p.custom,
        };
        self.rdata_shadow.material = p.mr;
        count += 1;
    }
    if (regular_shading) |p| {
        passes[count] = .{
            .fb = p.fb,
            .beforeFn = p.beforeFn,
            .afterFn = p.afterFn,
            .rd = p.rd,
            .custom = p.custom,
        };
        self.rdata_shadow.material = p.mr;
        if (p.light_rd) |lrd| {
            assert(lrd.ptr == p.rd.ptr);
            lrd.applyLights(&[_]light.Light{self.sun});
        }
        count += 1;
    }
    if (post_processing) |p| {
        passes[count] = .{
            .fb = p.fb,
            .beforeFn = p.beforeFn,
            .afterFn = p.afterFn,
            .rd = p.rd,
            .custom = p.custom,
        };
        self.rdata_shadow.material = p.mr;
        count += 1;
    }
    try self.rd_pipeline.setPasses(passes[0..count]);
}

/// draw the scene
pub fn draw(self: Self, ctx: Context) !void {
    try self.rd_pipeline.run(ctx);
}
