const std = @import("std");
const assert = std.debug.assert;
const light = @import("light.zig");
const Model = @import("Model.zig");
const zp = @import("../../zplay.zig");
const gfx = zp.graphics;
const Framebuffer = gfx.gpu.Framebuffer;
const Context = gfx.gpu.Context;
const Renderer = gfx.Renderer;
const Camera = gfx.Camera;
const Material = gfx.Material;
const RenderPipeline = gfx.RenderPipeline;
const alg = zp.deps.alg;
const Vec2 = alg.Vec2;
const Vec3 = alg.Vec3;
const Vec4 = alg.Vec4;
const Mat4 = alg.Mat4;
const Quat = alg.Quat;
const Self = @This();

const Error = error{
    InvalidModel,
};

/// memory allocator
allocator: std.mem.Allocator,

/// viewer's camera
viewer_camera: Camera,

/// params of sun light
sun_camera: Camera,
sun: light.Light,

/// render-passes
rd_pipeline: RenderPipeline,

/// rendering data for shadow-mapping
rdata_shadow: Renderer.Input,

/// rendering data for regular shading
rdata_scene: Renderer.Input,

/// models' search table
model_table: std.AutoHashMap(*Model, ModelInfo),

/// model table
const ModelTable = std.AutoHashMap(*Model, ModelInfo);

/// model information
const ModelInfo = struct {
    model: *Model,
    shadow_vds: ?[]Renderer.Input.VertexData = null,
    scene_vds: []Renderer.Input.VertexData = undefined,

    fn invalidate(info: ModelInfo) void {
        if (info.shadow_vds) |vds| {
            for (vds) |*d| d.valid = false;
        }
        for (info.scene_vds) |*d| d.valid = false;
    }
};

pub const InitOption = struct {
    viewer_frustrum: Camera.ViewFrustrum,
    viewer_position: Vec3 = Vec3.set(1),
    viewer_target: Vec3 = Vec3.zero(),
    viewer_up: Vec3 = Vec3.up(),
    sun_frustrum: Camera.ViewFrustrum = .{
        .orthographic = .{
            .left = -50.0,
            .right = 50.0,
            .bottom = -50.0,
            .top = 50.0,
            .near = 0.1,
            .far = 100,
        },
    },
    sun_position: Vec3 = Vec3.new(0, 30, 0),
    sun_dir: Vec3 = Vec3.new(0.5, -1, 0),
    sun_up: Vec3 = Vec3.up(),
    sun_ambient: Vec3 = Vec3.set(0.8),
    sun_diffuse: Vec3 = Vec3.set(0.3),
    sun_specular: Vec3 = Vec3.set(0.1),
};

/// create scene
pub fn init(allocator: std.mem.Allocator, option: InitOption) !*Self {
    var self = try allocator.create(Self);
    self.allocator = allocator;
    self.viewer_camera = Camera.fromPositionAndTarget(
        option.viewer_frustrum,
        option.viewer_position,
        option.viewer_target,
        option.viewer_up,
    );
    self.sun_camera = Camera.fromPositionAndTarget(
        option.sun_frustrum,
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
            .space_matrix = self.sun_camera.getViewProjectMatrix(),
        },
    };
    self.rd_pipeline = try RenderPipeline.init(allocator, &.{});
    self.rdata_shadow = try Renderer.Input.init(
        allocator,
        &.{},
        &self.sun_camera,
        null,
        null,
    );
    self.rdata_scene = try Renderer.Input.init(
        allocator,
        &.{},
        &self.viewer_camera,
        null,
        null,
    );
    self.model_table = ModelTable.init(allocator);
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
    self.model_table.deinit();
    self.allocator.destroy(self);
}

/// add rendering object into scene
pub fn addModel(
    self: *Self,
    model: *Model,
    trs: []Mat4,
    material: ?*Material,
    has_shadow: bool,
) !void {
    assert(trs.len > 0);
    var info: ModelInfo = .{ .model = model };

    if (has_shadow) {
        const begin = self.rdata_shadow.vds.?.items.len;
        defer info.shadow_vds = self.rdata_shadow.vds.?.items[begin..];
        if (trs.len == 1) {
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
        assert(self.rdata_shadow.vds.?.items.len > begin);
    }

    {
        const begin = self.rdata_scene.vds.?.items.len;
        defer info.scene_vds = self.rdata_scene.vds.?.items[begin..];
        if (trs.len == 1) {
            try model.appendVertexData(
                &self.rdata_scene,
                trs[0],
                material,
            );
        } else {
            try model.appendVertexDataInstanced(
                self.allocator,
                &self.rdata_scene,
                trs,
                material,
            );
        }
        assert(self.rdata_scene.vds.?.items.len > begin);
    }

    try self.model_table.put(model, info);
}

/// remove all models
pub fn clearModel(self: *Self) void {
    self.model_table.clearRetainingCapacity();
    self.rdata_shadow.vds.?.clearRetainingCapacity();
    self.rdata_scene.vds.?.clearRetainingCapacity();
}

/// remove one model
pub fn removeModel(self: *Self, model: *Model) !void {
    if (self.model_table.fetchRemove(model)) |kv| {
        kv.value.invalidate();
    }
}

/// change model's transformation
pub fn setTransform(self: Self, model: *Model, trs: []Mat4) !void {
    if (self.model_table.get(model)) |info| {
        assert(info.model == model);
        assert(info.scene_vds.len > 0);
        if (info.scene_vds[0].transform == .single) {
            model.fillTransforms(info.scene_vds, trs[0]);
        } else {
            try model.fillInstanceTransformArray(info.scene_vds, trs, null);
        }
    } else {
        return error.InvalidModel;
    }
}

/// set render-passes
pub const RenderPassOption = struct {
    /// frame buffer of the render-pass
    fb: ?Framebuffer = null,

    /// do some work before/after rendering
    beforeFn: ?RenderPipeline.TriggerFunc = null,
    afterFn: ?RenderPipeline.TriggerFunc = null,

    /// renderer of the render-pass
    rd: Renderer,
    light_rd: ?light.Renderer = null,

    /// renderer's input
    rdata: *const Renderer.Input,

    /// custom data
    custom: ?*anyopaque = null,
};
pub fn setRenderPasses(self: *Self, passes: []RenderPassOption) !void {
    self.rd_pipeline.clear();
    for (passes) |p| {
        try self.rd_pipeline.appendPass(.{
            .fb = p.fb,
            .beforeFn = p.beforeFn,
            .afterFn = p.afterFn,
            .rd = p.rd,
            .data = p.rdata,
            .custom = p.custom,
        });
        if (p.light_rd) |lrd| {
            assert(lrd.ptr == p.rd.ptr);
            lrd.applyLights(&[_]light.Light{self.sun});
        }
    }
}

/// draw the scene
pub fn draw(self: Self, ctx: *Context) !void {
    try self.rd_pipeline.run(ctx);
}
