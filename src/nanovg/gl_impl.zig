const std = @import("std");
const zp = @import("../lib.zig");
const gl = zp.gl;
const api = @import("api.zig");

pub const CreateFlags = struct {
    const Self = @This();

    /// flag indicating if geometry based anti-aliasing is used (may not be needed when using MSAA).
    enable_antialias: bool = false,

    /// flag indicating if strokes should be drawn using stencil buffer. The rendering will be a little
    /// slower, but path overlaps (i.e. self-intersecting or sharp turns) will be drawn just once.
    enable_stencil_strokes: bool = false,

    /// flag indicating that additional debug checks are done.
    enable_debug_check: bool = false,
};

/// create NanoVG context
pub fn createContext(flags: CreateFlags) *api.NVGcontext {
    var param = std.mem.zeroes(api.NVGparams);
    var internal_ctx = InternalContext.init(
        std.heap.c_allocator,
        flags,
    );
    param.renderCreate = InternalContext.renderCreate;
    param.renderCreateTexture = InternalContext.renderCreateTexture;
    param.renderDeleteTexture = InternalContext.renderDeleteTexture;
    param.renderUpdateTexture = InternalContext.renderUpdateTexture;
    param.renderGetTextureSize = InternalContext.renderGetTextureSize;
    param.renderViewport = InternalContext.renderViewport;
    param.renderCancel = InternalContext.renderCancel;
    param.renderFlush = InternalContext.renderFlush;
    param.renderFill = InternalContext.renderFill;
    param.renderStroke = InternalContext.renderStroke;
    param.renderTriangles = InternalContext.renderTriangles;
    param.renderDelete = InternalContext.renderDelete;
    param.userPtr = internal_ctx;
    param.edgeAntiAlias = if (flags.enable_antialias) 1 else 0;
    return api.nvgCreateInternal(&param) orelse unreachable;
}

/// delete NanoVG context
pub fn deleteContext(ctx: *api.NVGcontext) void {
    api.nvgDeleteInternal(ctx);
}

const image_nodelete_flag: c_int = 1 << 16;

const BufferIndex = enum(usize) {
    index_vertex_buffer = 0,
    index_frag_buffer = 1,
    max_index = 2,
};

const UniformLocation = enum(usize) {
    loc_viewsize = 0,
    loc_tex = 1,
    loc_frag = 2,
    max_locs = 3,
};

const ShaderType = enum(c_int) {
    shader_fillgrad = 0,
    shader_fillimg = 1,
    shader_simple = 2,
    shader_img = 3,
};

const UniformBinding = enum(c_int) {
    frag_binding = 0,
};

const Shader = struct {
    const Self = @This();

    program: gl.ShaderProgram,
    locs: [@enumToInt(UniformLocation.max_locs)]gl.GLint,

    fn init(vs: [:0]const u8, fs: [:0]const u8) Self {
        var self: Self = undefined;
        self.program = gl.ShaderProgram.init(vs, fs);
        self.locs[@enumToInt(UniformLocation.loc_viewsize)] = self.program.getUniformLocation("viewSize");
        self.locs[@enumToInt(UniformLocation.loc_tex)] = self.program.getUniformLocation("tex");
        self.locs[@enumToInt(UniformLocation.loc_frag)] = @intCast(gl.GLint, self.program.getUniformBlockIndex("frag"));
        return self;
    }

    fn deinit(self: *Self) void {
        self.program.deinit();
    }
};

const Texture = struct {
    id: c_int = 0,
    tex: gl.GLuint = 0,
    width: c_int = 0,
    height: c_int = 0,
    type: c_int = 0,
    flags: c_int = 0,
};

const Blend = struct {
    src_rgb: gl.GLenum = 0,
    dst_rgb: gl.GLenum = 0,
    src_alpha: gl.GLenum = 0,
    dst_alpha: gl.GLenum = 0,
};

const CallType = enum(c_int) {
    none = 0,
    fill = 1,
    convexfill = 2,
    stroke = 3,
    triangles = 4,
};

const Call = struct {
    type: CallType = .none,
    image: c_int = 0,
    path_offset: usize = 0,
    path_count: usize = 0,
    triangle_offset: usize = 0,
    triangle_count: usize = 0,
    uniform_offset: usize = 0,
    blend_func: Blend = .{},
};

const Path = struct {
    fill_offset: usize = 0,
    fill_count: usize = 0,
    stroke_offset: usize = 0,
    stroke_count: usize = 0,
};

const FragUniform = extern struct {
    scissor_mat: [12]f32,
    paint_mat: [12]f32,
    inner_color: api.NVGcolor,
    outer_color: api.NVGcolor,
    scissor_ext: [2]f32,
    scissor_scale: [2]f32,
    extent: [2]f32,
    radius: f32,
    feather: f32,
    stroke_mult: f32,
    stroke_thr: f32,
    tex_type: c_int,
    type: c_int,
};

const InternalContext = struct {
    const Self = @This();

    allocator: *std.mem.Allocator,
    shader: Shader,
    textures: std.ArrayList(Texture),
    view: [2]f32,
    texture_id: c_int,
    vertex_array: gl.VertexArray,
    frag_size: usize,
    flags: CreateFlags,

    // per frame buffers
    calls: std.ArrayList(Call),
    paths: std.ArrayList(Path),
    verts: std.ArrayList(api.NVGvertex),
    uniforms: std.ArrayList(u8),

    // cached state
    bound_texture: gl.GLuint,
    stencil_mask: gl.GLuint,
    stencil_func: gl.GLenum,
    stencil_func_ref: gl.GLint,
    stencil_func_mask: gl.GLuint,
    blend_func: Blend,

    dummy_tex: c_int,

    fn init(allocator: *std.mem.Allocator, flags: CreateFlags) *Self {
        var self = allocator.create(Self) catch unreachable;
        self.allocator = allocator;
        self.shader = undefined;
        self.textures = std.ArrayList(Texture).init(allocator);
        self.view = [2]f32{ 0, 0 };
        self.texture_id = 0;
        self.vertex_array = undefined;
        self.frag_size = 0;
        self.flags = flags;
        self.calls = std.ArrayList(Call).init(allocator);
        self.paths = std.ArrayList(Path).init(allocator);
        self.verts = std.ArrayList(api.NVGvertex).init(allocator);
        self.uniforms = std.ArrayList(u8).init(allocator);
        self.bound_texture = 0;
        self.stencil_mask = 0;
        self.stencil_func = 0;
        self.stencil_func_ref = 0;
        self.stencil_func_mask = 0;
        self.blend_func = .{};
        self.dummy_tex = 0;
        return self;
    }

    fn bindTexture(self: *Self, tex: gl.GLuint) void {
        if (self.bound_texture != tex) {
            self.bound_texture = tex;
            gl.bindTexture(gl.GL_TEXTURE_2D, tex);
        }
    }

    fn stencilMask(self: *Self, mask: gl.GLuint) void {
        if (self.stencil_mask != mask) {
            self.stencil_mask = mask;
            gl.stencilMask(mask);
        }
    }

    fn stencilFunc(self: *Self, func: gl.GLenum, ref: gl.GLint, mask: gl.GLuint) void {
        if (self.stencil_func != func or
            self.stencil_func_ref != ref or
            self.stencil_func_mask != mask)
        {
            self.stencil_func = func;
            self.stencil_func_ref = ref;
            self.stencil_func_mask = mask;
            gl.stencilFunc(func, ref, mask);
        }
    }

    fn blendFuncSeparate(self: *Self, blend: Blend) void {
        if (self.blend_func.src_rgb != blend.src_rgb or
            self.blend_func.dst_rgb != blend.dst_rgb or
            self.blend_func.src_alpha != blend.src_alpha or
            self.blend_func.dst_alpha != blend.dst_alpha)
        {
            self.blend_func = blend;
            gl.blendFuncSeparate(blend.src_rgb, blend.dst_rgb, blend.src_alpha, blend.dst_alpha);
        }
    }

    fn allocTexture(self: *Self) *Texture {
        var tex: *Texture = for (self.textures.items) |*t| {
            if (t.id == 0) {
                break t;
            }
        } else self.textures.addOne() catch unreachable;
        self.texture_id += 1;
        tex.* = Texture{};
        tex.id = self.texture_id;
        return tex;
    }

    fn findTexture(self: *Self, id: c_int) ?*Texture {
        return for (self.textures.items) |*t| {
            if (t.id == id) {
                break t;
            }
        } else null;
    }

    fn deleteTexture(self: *Self, id: c_int) bool {
        return for (self.textures.items) |*t| {
            if (t.id == id) {
                if (t.tex != 0 and (t.flags & image_nodelete_flag) == 0) {
                    gl.deleteTextures(1, &t.tex);
                }
                t.* = Texture{};
                break true;
            }
        } else false;
    }

    fn checkError(self: *Self) void {
        if (!self.flags.enable_debug_check) {
            return;
        }
        gl.util.checkError();
    }

    fn setUniforms(self: *Self, offset: usize, image: c_int) void {
        gl.bindBufferRange(
            gl.GL_UNIFORM_BUFFER,
            @enumToInt(UniformBinding.frag_binding),
            self.vertex_array.vbos[@enumToInt(BufferIndex.index_frag_buffer)],
            offset,
            @sizeOf(FragUniform),
        );

        var tex: ?*Texture = null;
        if (image != 0) {
            tex = findTexture(image);
        }
        // if no image is set, use empty texture
        if (tex == null) {
            tex = findTexture(self.dummy_tex);
        }
        if (tex) |t| {
            self.bindTexture(t.tex);
        } else {
            self.bindTexture(0);
        }
        self.checkError();
    }

    fn fill(self: *Self, call: *Call) void {
        var paths = self.paths.items[call.path_offset .. call.path_offset + call.path_count];

        // draw shapes
        gl.enable(gl.GL_STENCIL_TEST);
        defer gl.disable(gl.GL_STENCIL_TEST);
        self.stencilMask(0xff);
        self.stencilFunc(gl.GL_ALWAYS, 0, 0xff);
        gl.colorMask(gl.GL_FALSE, gl.GL_FALSE, gl.GL_FALSE, gl.GL_FALSE);

        // set bindpoint for solid loc
        self.setUniforms(call.uniform_offset, 0);
        self.checkError();

        gl.stencilOpSeparate(gl.GL_FRONT, gl.GL_KEEP, gl.GL_KEEP, gl.GL_INCR_WRAP);
        gl.stencilOpSeparate(gl.GL_BACK, gl.GL_KEEP, gl.GL_KEEP, gl.GL_DECR_WRAP);
        gl.disable(gl.GL_CULL_FACE);
        for (paths) |p| {
            gl.drawArrays(
                gl.GL_TRIANGLE_FAN,
                @intCast(c_int, p.fill_offset),
                @intCast(c_int, p.fill_count),
            );
        }
        gl.enable(gl.GL_CULL_FACE);

        // draw anti-aliased pixels
        gl.colorMask(gl.GL_TRUE, gl.GL_TRUE, gl.GL_TRUE, gl.GL_TRUE);

        self.setUniforms(call.uniform_offset + self.frag_size, call.image);
        self.checkError();

        if (self.flags.enable_antialias) {
            self.stencilFunc(gl.GL_EQUAL, 0x00, 0xff);
            gl.stencilOp(gl.GL_KEEP, gl.GL_KEEP, gl.GL_KEEP);
            // draw fringes
            for (paths) |p| {
                gl.drawArrays(
                    gl.GL_TRIANGLE_STRIP,
                    @intCast(c_int, p.stroke_offset),
                    @intCast(c_int, p.stroke_count),
                );
            }
        }

        // draw fill
        self.stencilFunc(gl.GL_NOTEQUAL, 0x0, 0xff);
        gl.stencilOp(gl.GL_ZERO, gl.GL_ZERO, gl.GL_ZERO);
        gl.drawArrays(
            gl.GL_TRIANGLE_STRIP,
            @intCast(c_int, call.triangle_offset),
            @intCast(c_int, call.triangle_count),
        );
    }

    fn convexFill(self: *Self, call: *Call) void {
        var paths = self.paths.items[call.path_offset .. call.path_offset + call.path_count];

        self.setUniforms(call.uniform_offset, call.image);
        self.checkError();

        for (paths) |p| {
            gl.drawArrays(
                gl.GL_TRIANGLE_FAN,
                @intCast(c_int, p.fill_offset),
                @intCast(c_int, p.fill_count),
            );
            // draw fringes
            if (p.stroke_count > 0) {
                gl.drawArrays(
                    gl.GL_TRIANGLE_STRIP,
                    @intCast(c_int, p.stroke_offset),
                    @intCast(c_int, p.stroke_count),
                );
            }
        }
    }

    fn stroke(self: *Self, call: *Call) void {
        var paths = self.paths.items[call.path_offset .. call.path_offset + call.path_count];

        if (self.flags.enable_stencil_strokes) {
            gl.enable(gl.GL_STENCIL_TEST);
            defer gl.disable(gl.GL_STENCIL_TEST);

            self.stencilMask(0xff);

            // fill the stroke base without overlap
            self.stencilFunc(gl.GL_EQUAL, 0x0, 0xff);
            gl.stencilOp(gl.GL_KEEP, gl.GL_KEEP, gl.GL_INCR);
            self.setUniforms(call.uniform_offset + self.frag_size, call.image);
            self.checkError();
            for (paths) |p| {
                gl.drawArrays(
                    gl.GL_TRIANGLE_STRIP,
                    @intCast(c_int, p.stroke_offset),
                    @intCast(c_int, p.stroke_count),
                );
            }

            // Draw anti-aliased pixels.
            self.setUniforms(call.uniform_offset, call.image);
            self.stencilFunc(gl.GL_EQUAL, 0x00, 0xff);
            gl.stencilOp(gl.GL_KEEP, gl.GL_KEEP, gl.GL_KEEP);
            for (paths) |p| {
                gl.drawArrays(
                    gl.GL_TRIANGLE_STRIP,
                    @intCast(c_int, p.stroke_offset),
                    @intCast(c_int, p.stroke_count),
                );
            }

            // clear stencil buffer.
            gl.colorMask(gl.GL_FALSE, gl.GL_FALSE, gl.GL_FALSE, gl.GL_FALSE);
            self.stencilFunc(gl.GL_ALWAYS, 0x0, 0xff);
            gl.stencilOp(gl.GL_ZERO, gl.GL_ZERO, gl.GL_ZERO);
            self.checkError();
            for (paths) |p| {
                gl.drawArrays(
                    gl.GL_TRIANGLE_STRIP,
                    @intCast(c_int, p.stroke_offset),
                    @intCast(c_int, p.stroke_count),
                );
            }
            gl.colorMask(gl.GL_TRUE, gl.GL_TRUE, gl.GL_TRUE, gl.GL_TRUE);
        } else {
            self.setUniforms(call.uniform_offset, call.image);
            self.checkError();
            // draw Strokes
            for (paths) |p| {
                gl.drawArrays(
                    gl.GL_TRIANGLE_STRIP,
                    @intCast(c_int, p.stroke_offset),
                    @intCast(c_int, p.stroke_count),
                );
            }
        }
    }

    fn triangles(self: *Self, call: *Call) void {
        self.setUniforms(call.uniform_offset, call.image);
        self.checkError();
        gl.drawArrays(
            gl.GL_TRIANGLES,
            @intCast(c_int, call.triangle_offset),
            @intCast(c_int, call.triangle_count),
        );
    }

    fn maxVertCount(self: *Self, paths: []const api.NVGpath) usize {
        _ = self;
        var count: usize = 0;
        for (paths) |p| {
            count += p.nfill;
            count += p.nstroke;
        }
        return count;
    }

    fn allocCall(self: *Self) *Call {
        var call = self.calls.addOne() catch unreachable;
        return call;
    }

    fn allocPaths(self: *Self, n: c_int) usize {
        var offset = self.paths.items.len;
        _ = self.paths.addManyAsArray(n) catch unreachable;
        return offset;
    }

    fn allocVerts(self: *Self, n: usize) usize {
        var offset = self.verts.items.len;
        _ = self.verts.addManyAsArray(n) catch unreachable;
        return offset;
    }

    fn allocFragUniforms(self: *Self, n: c_int) usize {
        var offset = self.uniforms.items.len;
        _ = self.verts.addManyAsArray(n * self.frag_size) catch unreachable;
        return offset;
    }

    fn fragUniformPtr(self: *Self, i: usize) *FragUniform {
        return @ptrCast(*FragUniform, &self.unifoms.items[i]);
    }

    fn vset(self: *Self, vtx: *api.NVGvertex, x: f32, y: f32, u: f32, v: f32) void {
        _ = self;
        vtx.x = x;
        vtx.y = y;
        vtx.u = u;
        vtx.v = v;
    }

    fn convertBlendFuncFactor(self: *Self, factor: c_int) gl.GLenum {
        _ = self;
        return switch (factor) {
            api.NVG_ZERO => gl.GL_ZERO,
            api.NVG_ONE => gl.GL_ONE,
            api.NVG_SRC_COLOR => gl.GL_SRC_COLOR,
            api.NVG_ONE_MINUS_SRC_COLOR => gl.GL_ONE_MINUS_SRC_COLOR,
            api.NVG_DST_COLOR => gl.GL_DST_COLOR,
            api.NVG_ONE_MINUS_DST_COLOR => gl.GL_ONE_MINUS_DST_COLOR,
            api.NVG_SRC_ALPHA => gl.GL_SRC_ALPHA,
            api.NVG_ONE_MINUS_SRC_ALPHA => gl.GL_ONE_MINUS_SRC_ALPHA,
            api.NVG_DST_ALPHA => gl.GL_DST_ALPHA,
            api.NVG_ONE_MINUS_DST_ALPHA => gl.GL_ONE_MINUS_DST_ALPHA,
            api.NVG_SRC_ALPHA_SATURATE => gl.GL_SRC_ALPHA_SATURATE,
            else => gl.GL_INVALID_ENUM,
        };
    }

    fn blendCompositeOperation(self: *Self, op: api.NVGcompositeOperationState) Blend {
        _ = self;
        var blend: Blend = undefined;
        blend.src_rgb = self.convertBlendFuncFactor(op.srcRGB);
        blend.dst_rgb = self.convertBlendFuncFactor(op.dstRGB);
        blend.src_alpha = self.convertBlendFuncFactor(op.srcAlpha);
        blend.dst_alpha = self.convertBlendFuncFactor(op.dstAlpha);
        if (blend.src_rgb == gl.GL_INVALID_ENUM or
            blend.dst_rgb == gl.GL_INVALID_ENUM or
            blend.src_alpha == gl.GL_INVALID_ENUM or
            blend.dst_alpha == gl.GL_INVALID_ENUM)
        {
            blend.src_rgb = gl.GL_ONE;
            blend.dst_rgb = gl.GL_ONE_MINUS_SRC_ALPHA;
            blend.src_alpha = gl.GL_ONE;
            blend.dst_alpha = gl.GL_ONE_MINUS_SRC_ALPHA;
        }
        return blend;
    }

    fn xformToMat3x4(self: *Self, m3: [*c]f32, t: [*c]f32) void {
        _ = self;
        m3[0] = t[0];
        m3[1] = t[1];
        m3[2] = 0.0;
        m3[3] = 0.0;
        m3[4] = t[2];
        m3[5] = t[3];
        m3[6] = 0.0;
        m3[7] = 0.0;
        m3[8] = t[4];
        m3[9] = t[5];
        m3[10] = 1.0;
        m3[11] = 0.0;
    }

    fn premulColor(self: *Self, c: api.NVGcolor) api.NVGcolor {
        _ = self;
        c.unnamed_0.unnamed_0.r *= c.unnamed_0.unnamed_0.a;
        c.unnamed_0.unnamed_0.g *= c.unnamed_0.unnamed_0.a;
        c.unnamed_0.unnamed_0.b *= c.unnamed_0.unnamed_0.a;
        return c;
    }

    fn convertPaint(
        self: *Self,
        frag: *FragUniform,
        paint: *api.NVGpaint,
        scissor: *api.NVGscissor,
        width: f32,
        fringe: f32,
        stroke_thr: f32,
    ) c_int {
        var invxform: [6]f32 = undefined;

        frag.* = std.mem.zeroes(FragUniform);

        frag.inner_color = premulColor(paint.innerColor);
        frag.outer_color = premulColor(paint.outerColor);

        if (scissor.extent[0] < -0.5 or scissor.extent[1] < -0.5) {
            frag.scissor_ext[0] = 1.0;
            frag.scissor_ext[1] = 1.0;
            frag.scissor_scale[0] = 1.0;
            frag.scissor_scale[1] = 1.0;
        } else {
            api.transformInverse(&invxform, &scissor.xform);
            self.xformToMat3x4(frag.scissorMat, invxform);
            frag.scissor_ext[0] = scissor.extent[0];
            frag.scissor_ext[1] = scissor.extent[1];
            frag.scissor_scale[0] = std.math.sqrt(scissor.xform[0] * scissor.xform[0] + scissor.xform[2] * scissor.xform[2]) / fringe;
            frag.scissorScale[1] = std.math.sqrt(scissor.xform[1] * scissor.xform[1] + scissor.xform[3] * scissor.xform[3]) / fringe;
        }

        frag.extent = paint.extent;
        frag.stroke_mult = (width * 0.5 + fringe * 0.5) / fringe;
        frag.stroke_thr = stroke_thr;

        if (paint.image != 0) {
            var tex = self.findTexture(paint.image);
            if (tex == null) return 0;
            if ((tex.flags & api.NVG_IMAGE_FLIPY) != 0) {
                var m1: [6]f32 = undefined;
                var m2: [6]f32 = undefined;
                api.transformTranslate(&m1, 0.0, frag.extent[1] * 0.5);
                api.transformMultiply(&m1, &paint.xform);
                api.transformScale(&m2, 1.0, -1.0);
                api.transformMultiply(&m2, &m1);
                api.transformTranslate(&m1, 0.0, -frag.extent[1] * 0.5);
                api.transformMultiply(&m1, &m2);
                api.transformInverse(&invxform, &m1);
            } else {
                api.transformInverse(&invxform, &paint.xform);
            }
            frag.type = .shader_fillimg;

            if (tex.type == api.NVG_TEXTURE_RGBA) {
                frag.tex_type = if ((tex.flags & api.NVG_IMAGE_PREMULTIPLIED) != 0) 0 else 1;
            } else {
                frag.tex_type = 2;
            }
        } else {
            frag.type = .shader_fillgrad;
            frag.radius = paint.radius;
            frag.feather = paint.feather;
            api.transformInverse(&invxform, &paint.xform);
        }

        self.xformToMat3x4(&frag.paint_mat, &invxform);

        return 1;
    }

    fn renderCreate(uptr: ?*c_void) callconv(.C) c_int {
        var self = @ptrCast(*Self, @alignCast(@alignOf(*Self), uptr).?);
        const header = "#version 150 core\n";
        const aadef = "#define EDGE_AA 1\n";
        const vs = header ++
            \\layout (location = 0) in vec2 vertex;
            \\layout (location = 1) in vec2 tcoord;
            \\uniform vec2 viewSize;
            \\out vec2 ftcoord;
            \\out vec2 fpos;
            \\
            \\void main(void) {
            \\    ftcoord = tcoord;
            \\    fpos = vertex;
            \\    gl_Position = vec4(2.0*vertex.x/viewSize.x - 1.0, 1.0 - 2.0*vertex.y/viewSize.y, 0, 1);
            \\};
        ;

        const fs =
            \\layout(std140) uniform frag {
            \\    mat3 scissorMat;
            \\    mat3 paintMat;
            \\    vec4 innerCol;
            \\    vec4 outerCol;
            \\    vec2 scissorExt;
            \\    vec2 scissorScale;
            \\    vec2 extent;
            \\    float radius;
            \\    float feather;
            \\    float strokeMult;
            \\    float strokeThr;
            \\    int texType;
            \\    int type;
            \\};
            \\uniform sampler2D tex;
            \\in vec2 ftcoord;
            \\in vec2 fpos;
            \\out vec4 outColor;
            \\float sdroundrect(vec2 pt, vec2 ext, float rad) {
            \\    vec2 ext2 = ext - vec2(rad,rad);
            \\    vec2 d = abs(pt) - ext2;
            \\    return min(max(d.x,d.y),0.0) + length(max(d,0.0)) - rad;
            \\}
            \\
            \\// Scissoring
            \\float scissorMask(vec2 p) {
            \\    vec2 sc = (abs((scissorMat * vec3(p,1.0)).xy) - scissorExt);
            \\    sc = vec2(0.5,0.5) - sc * scissorScale;
            \\    return clamp(sc.x,0.0,1.0) * clamp(sc.y,0.0,1.0);
            \\}
            \\
            \\#ifdef EDGE_AA
            \\// Stroke - from [0..1] to clipped pyramid, where the slope is 1px.
            \\float strokeMask() {
            \\    return min(1.0, (1.0-abs(ftcoord.x*2.0-1.0))*strokeMult) * min(1.0, ftcoord.y);
            \\}
            \\#endif
            \\
            \\void main(void) {
            \\    vec4 result;
            \\    float scissor = scissorMask(fpos);
            \\#ifdef EDGE_AA
            \\    float strokeAlpha = strokeMask();
            \\    if (strokeAlpha < strokeThr) discard;
            \\#else
            \\    float strokeAlpha = 1.0;
            \\#endif
            \\    if (type == 0) {			// Gradient
            \\        // Calculate gradient color using box gradient
            \\        vec2 pt = (paintMat * vec3(fpos,1.0)).xy;
            \\        float d = clamp((sdroundrect(pt, extent, radius) + feather*0.5) / feather, 0.0, 1.0);
            \\        vec4 color = mix(innerCol,outerCol,d);
            \\        // Combine alpha
            \\        color *= strokeAlpha * scissor;
            \\        result = color;
            \\    } else if (type == 1) {		// Image
            \\        // Calculate color fron texture
            \\        vec2 pt = (paintMat * vec3(fpos,1.0)).xy / extent;
            \\        vec4 color = texture(tex, pt);
            \\        if (texType == 1) color = vec4(color.xyz*color.w,color.w);"
            \\        if (texType == 2) color = vec4(color.x);"
            \\        // Apply color tint and alpha.
            \\        color *= innerCol;
            \\        // Combine alpha
            \\        color *= strokeAlpha * scissor;
            \\        result = color;
            \\    } else if (type == 2) {		// Stencil fill
            \\        result = vec4(1,1,1,1);
            \\    } else if (type == 3) {		// Textured tris
            \\        vec4 color = texture(tex, ftcoord);
            \\        if (texType == 1) color = vec4(color.xyz*color.w,color.w);"
            \\        if (texType == 2) color = vec4(color.x);"
            \\        color *= scissor;
            \\        result = color * innerCol;
            \\    }
            \\    outColor = result;
            \\};
        ;

        const aa_fs = header ++ aadef ++ fs;
        const regular_fs = header ++ fs;

        if (self.flags.enable_antialias) {
            self.shader = Shader.init(vs, aa_fs);
        } else {
            self.shader = Shader.init(vs, regular_fs);
        }
        self.vertex_array = gl.VertexArray.init(@enumToInt(BufferIndex.max_index));

        // Create UBOs
        gl.uniformBlockBinding(
            self.shader.program.id,
            @intCast(
                c_uint,
                self.shader.locs[@enumToInt(UniformLocation.loc_frag)],
            ),
            @enumToInt(UniformBinding.frag_binding),
        );

        var alignment: c_int = 4;
        gl.getIntegerv(gl.GL_UNIFORM_BUFFER_OFFSET_ALIGNMENT, &alignment);
        self.frag_size = @intCast(
            usize,
            @sizeOf(FragUniform) + alignment - @rem(@sizeOf(FragUniform), alignment),
        );

        // Some platforms does not allow to have samples to unset textures.
        // Create empty one which is bound when there's no texture specified.
        self.dummy_tex = Self.renderCreateTexture(uptr, api.NVG_TEXTURE_ALPHA, 1, 1, 0, null);
        self.checkError();

        gl.finish();
        return 1;
    }

    fn renderCreateTexture(
        uptr: ?*c_void,
        _type: c_int,
        w: c_int,
        h: c_int,
        flags: c_int,
        data: [*c]const u8,
    ) callconv(.C) c_int {
        var self = @ptrCast(*Self, @alignCast(@alignOf(*Self), uptr).?);
        var tex = self.allocTexture();
        gl.genTextures(1, &tex.tex);
        tex.width = w;
        tex.height = h;
        tex.type = _type;
        tex.flags = flags;
        self.bindTexture(tex.tex);
        defer self.bindTexture(0);

        gl.pixelStorei(gl.GL_UNPACK_ALIGNMENT, 1);
        gl.pixelStorei(gl.GL_UNPACK_ROW_LENGTH, tex.width);
        gl.pixelStorei(gl.GL_UNPACK_SKIP_PIXELS, 0);
        gl.pixelStorei(gl.GL_UNPACK_SKIP_ROWS, 0);

        if (_type == api.NVG_TEXTURE_RGBA) {
            gl.texImage2D(gl.GL_TEXTURE_2D, 0, gl.GL_RGBA, w, h, 0, gl.GL_RGBA, gl.GL_UNSIGNED_BYTE, data);
        } else {
            gl.texImage2D(gl.GL_TEXTURE_2D, 0, gl.GL_RED, w, h, 0, gl.GL_RED, gl.GL_UNSIGNED_BYTE, data);
        }

        if ((flags & api.NVG_IMAGE_GENERATE_MIPMAPS) != 0) {
            if ((flags & api.NVG_IMAGE_NEAREST) != 0) {
                gl.texParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, gl.GL_NEAREST_MIPMAP_NEAREST);
            } else {
                gl.texParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, gl.GL_LINEAR_MIPMAP_LINEAR);
            }
        } else {
            if ((flags & api.NVG_IMAGE_NEAREST) != 0) {
                gl.texParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, gl.GL_NEAREST);
            } else {
                gl.texParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, gl.GL_LINEAR);
            }
        }

        if ((flags & api.NVG_IMAGE_NEAREST) != 0) {
            gl.texParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MAG_FILTER, gl.GL_NEAREST);
        } else {
            gl.texParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MAG_FILTER, gl.GL_LINEAR);
        }

        if ((flags & api.NVG_IMAGE_REPEATX) != 0) {
            gl.texParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_S, gl.GL_REPEAT);
        } else {
            gl.texParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_S, gl.GL_CLAMP_TO_EDGE);
        }

        if ((flags & api.NVG_IMAGE_REPEATY) != 0) {
            gl.texParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_T, gl.GL_REPEAT);
        } else {
            gl.texParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_T, gl.GL_CLAMP_TO_EDGE);
        }

        gl.pixelStorei(gl.GL_UNPACK_ALIGNMENT, 4);
        gl.pixelStorei(gl.GL_UNPACK_ROW_LENGTH, 0);
        gl.pixelStorei(gl.GL_UNPACK_SKIP_PIXELS, 0);
        gl.pixelStorei(gl.GL_UNPACK_SKIP_ROWS, 0);

        // The new way to build mipmaps on GLES and GL3
        if ((flags & api.NVG_IMAGE_GENERATE_MIPMAPS) != 0) {
            gl.generateMipmap(gl.GL_TEXTURE_2D);
        }
        self.checkError();

        return tex.id;
    }

    fn renderDeleteTexture(uptr: ?*c_void, image: c_int) callconv(.C) c_int {
        var self = @ptrCast(*Self, @alignCast(@alignOf(*Self), uptr).?);
        return if (self.deleteTexture(image)) 1 else 0;
    }

    fn renderUpdateTexture(
        uptr: ?*c_void,
        image: c_int,
        x: c_int,
        y: c_int,
        w: c_int,
        h: c_int,
        data: [*c]const u8,
    ) callconv(.C) c_int {
        var self = @ptrCast(*Self, @alignCast(@alignOf(*Self), uptr).?);
        var tex = self.findTexture(image);
        if (tex == null) return 0;

        self.bindTexture(tex.?.tex);
        defer self.bindTexture(0);

        gl.pixelStorei(gl.GL_UNPACK_ALIGNMENT, 1);
        gl.pixelStorei(gl.GL_UNPACK_ROW_LENGTH, tex.?.width);
        gl.pixelStorei(gl.GL_UNPACK_SKIP_PIXELS, x);
        gl.pixelStorei(gl.GL_UNPACK_SKIP_ROWS, y);

        if (tex.?.type == api.NVG_TEXTURE_RGBA) {
            gl.texSubImage2D(gl.GL_TEXTURE_2D, 0, x, y, w, h, gl.GL_RGBA, gl.GL_UNSIGNED_BYTE, data);
        } else {
            gl.texSubImage2D(gl.GL_TEXTURE_2D, 0, x, y, w, h, gl.GL_RED, gl.GL_UNSIGNED_BYTE, data);
        }

        gl.pixelStorei(gl.GL_UNPACK_ALIGNMENT, 4);
        gl.pixelStorei(gl.GL_UNPACK_ROW_LENGTH, 0);
        gl.pixelStorei(gl.GL_UNPACK_SKIP_PIXELS, 0);
        gl.pixelStorei(gl.GL_UNPACK_SKIP_ROWS, 0);

        return 1;
    }

    fn renderGetTextureSize(uptr: ?*c_void, image: c_int, w: [*c]c_int, h: [*c]c_int) callconv(.C) c_int {
        var self = @ptrCast(*Self, @alignCast(@alignOf(*Self), uptr).?);
        var tex = self.findTexture(image);
        if (tex == null) return 0;

        w.* = tex.?.width;
        h.* = tex.?.height;
        return 1;
    }

    fn renderViewport(uptr: ?*c_void, width: f32, height: f32, pixel_ratio: f32) callconv(.C) void {
        var self = @ptrCast(*Self, @alignCast(@alignOf(*Self), uptr).?);
        _ = pixel_ratio;
        self.view[0] = width;
        self.view[0] = height;
    }

    fn renderCancel(uptr: ?*c_void) callconv(.C) void {
        var self = @ptrCast(*Self, @alignCast(@alignOf(*Self), uptr).?);
        self.verts.resize(0) catch unreachable;
        self.paths.resize(0) catch unreachable;
        self.calls.resize(0) catch unreachable;
        self.uniforms.resize(0) catch unreachable;
    }

    fn renderFlush(uptr: ?*c_void) callconv(.C) void {
        var self = @ptrCast(*Self, @alignCast(@alignOf(*Self), uptr).?);
        if (self.calls.items.len > 0) {
            // setup require GL state.
            self.shader.program.use();
            defer self.shader.program.disuse();

            gl.enable(gl.GL_CULL_FACE);
            defer gl.disable(gl.GL_CULL_FACE);

            gl.cullFace(gl.GL_BACK);
            gl.frontFace(gl.GL_CCW);
            gl.enable(gl.GL_BLEND);
            gl.disable(gl.GL_DEPTH_TEST);
            gl.disable(gl.GL_SCISSOR_TEST);
            gl.colorMask(gl.GL_TRUE, gl.GL_TRUE, gl.GL_TRUE, gl.GL_TRUE);
            gl.stencilMask(0xffffffff);
            gl.stencilOp(gl.GL_KEEP, gl.GL_KEEP, gl.GL_KEEP);
            gl.stencilFunc(gl.GL_ALWAYS, 0, 0xffffffff);
            gl.activeTexture(gl.GL_TEXTURE0);
            gl.bindTexture(gl.GL_TEXTURE_2D, 0);
            self.bound_texture = 0;
            self.stencil_mask = 0xffffffff;
            self.stencil_func = gl.GL_ALWAYS;
            self.stencil_func_ref = 0;
            self.stencil_func_mask = 0xffffffff;
            self.blend_func.src_rgb = gl.GL_INVALID_ENUM;
            self.blend_func.src_alpha = gl.GL_INVALID_ENUM;
            self.blend_func.dst_rgb = gl.GL_INVALID_ENUM;
            self.blend_func.dst_alpha = gl.GL_INVALID_ENUM;

            // upload ubo for frag shaders
            gl.bindBuffer(
                gl.GL_UNIFORM_BUFFER,
                self.vertex_array.vbos[@enumToInt(BufferIndex.index_frag_buffer)],
            );
            gl.bufferData(
                gl.GL_UNIFORM_BUFFER,
                @intCast(c_longlong, self.uniforms.items.len),
                self.uniforms.items.ptr,
                gl.GL_STREAM_DRAW,
            );

            // upload vertex data
            self.vertex_array.use();
            defer self.vertex_array.disuse();
            gl.bindBuffer(
                gl.GL_ARRAY_BUFFER,
                self.vertex_array.vbos[@enumToInt(BufferIndex.index_vertex_buffer)],
            );
            defer gl.bindBuffer(gl.GL_ARRAY_BUFFER, 0);
            gl.bufferData(
                gl.GL_ARRAY_BUFFER,
                @intCast(c_longlong, self.verts.items.len * @sizeOf(api.NVGvertex)),
                self.verts.items.ptr,
                gl.GL_STREAM_DRAW,
            );
            gl.enableVertexAttribArray(0);
            defer gl.disableVertexAttribArray(0);
            gl.enableVertexAttribArray(1);
            defer gl.disableVertexAttribArray(1);
            gl.vertexAttribPointer(
                0,
                2,
                gl.GL_FLOAT,
                gl.GL_FALSE,
                @sizeOf(api.NVGvertex),
                @intToPtr(*allowzero c_void, 0),
            );
            gl.vertexAttribPointer(
                1,
                2,
                gl.GL_FLOAT,
                gl.GL_FALSE,
                @sizeOf(api.NVGvertex),
                @intToPtr(*allowzero c_void, 2 * @sizeOf(f32)),
            );

            // set view and texture just once per frame.
            gl.uniform1i(self.shader.locs[@enumToInt(UniformLocation.loc_tex)], 0);
            gl.uniform2fv(self.shader.locs[@enumToInt(UniformLocation.loc_viewsize)], 1, &self.view);

            for (self.calls.items) |*c| {
                self.blendFuncSeparate(c.blend_func);
                switch (c.type) {
                    .fill => self.fill(c),
                    .convexfill => self.convexFill(c),
                    .stroke => self.stroke(c),
                    .triangles => self.triangles(c),
                    else => {},
                }
            }

            self.bindTexture(0);
        }

        // reset calls
        Self.renderCancel(uptr);
    }

    fn renderFill(
        uptr: ?*c_void,
        paint: [*c]api.NVGpaint,
        comp_op: api.NVGcompositeOperationState,
        scissor: [*c]api.NVGscissor,
        fringe: f32,
        bounds: [*c]const f32,
        paths: [*c]const api.NVGpath,
        npaths: c_int,
    ) callconv(.C) void {
        var self = @ptrCast(*Self, @alignCast(@alignOf(*Self), uptr).?);
        var call = self.allocCall();
        call.type = .fill;
        call.triangle_count = 4;
        call.path_offset = self.allocPaths(npaths);
        call.path_count = @intCast(usize, npaths);
        call.image = paint.*.image;
        call.blend_func = self.blendCompositeOperation(comp_op);

        if (npaths == 1 and paths[0].convex == 1) {
            call.type = .convexfill;
            call.triangle_count = 0; // bounding box fill quad not needed for convex fill
        }

        // allocate vertices for all the paths.
        var maxverts = self.maxVertCount(paths[0..@intCast(usize, npaths)]) + call.triangle_count;
        var offset = self.allocVerts(maxverts);

        for (self.paths.items[call.path_offset .. call.path_offset + @intCast(usize, npaths)]) |*p, i| {
            const path = &paths[i];
            p.* = .{};
            if (path.nfill > 0) {
                p.fill_offset = offset;
                p.fill_count = @intCast(usize, path.nfill);
                self.verts.replaceRange(offset, p.fill_count, path.fill[0..p.fill_count]) catch unreachable;
                offset += p.fill_count;
            }
            if (path.nstroke > 0) {
                p.stroke_offset = offset;
                p.stroke_count = @intCast(usize, path.nstroke);
                self.verts.replaceRange(offset, p.stroke_count, path.stroke[0..p.stroke_count]) catch unreachable;
                offset += p.stroke_count;
            }
        }

        // setup uniforms for draw calls
        if (call.type == .fill) {
            // quad
            call.triangle_offset = offset;
            self.vset(&self.verts.items[call.triangle_offset], bounds[2], bounds[3], 0.5, 1.0);
            self.vset(&self.verts.items[call.triangle_offset + 1], bounds[2], bounds[1], 0.5, 1.0);
            self.vset(&self.verts.items[call.triangle_offset + 2], bounds[0], bounds[3], 0.5, 1.0);
            self.vset(&self.verts.items[call.triangle_offset + 3], bounds[0], bounds[1], 0.5, 1.0);

            call.uniform_offset = self.allocFragUniforms(2);

            // simple shader for stencil
            var frag = self.fragUniformPtr(call.uniform_offset);
            frag.* = std.mem.zeroes(FragUniform);
            frag.stroke_thr = -1.0;
            frag.type = @enumToInt(ShaderType.shader_simple);
            // fill shader
            _ = self.convertPaint(
                self.fragUniformPtr(call.uniform_offset + self.frag_size),
                paint,
                scissor,
                fringe,
                fringe,
                -1.0,
            );
        } else {
            call.uniform_offset = self.allocFragUniforms(1);
            // fill shader
            _ = self.convertPaint(
                self.fragUniformPtr(call.uniform_offset),
                paint,
                scissor,
                fringe,
                fringe,
                -1.0,
            );
        }

        return;
    }

    fn renderStroke(
        uptr: ?*c_void,
        paint: [*c]api.NVGpaint,
        comp_op: api.NVGcompositeOperationState,
        scissor: [*c]api.NVGscissor,
        fringe: f32,
        stroke_width: f32,
        paths: [*c]const api.NVGpath,
        npaths: c_int,
    ) callconv(.C) void {
        var self = @ptrCast(*Self, @alignCast(@alignOf(*Self), uptr).?);
        var call = self.allocCall();
        call.type = .stroke;
        call.path_offset = self.allocPaths(npaths);
        call.path_count = @intCast(usize, npaths);
        call.image = paint.*.image;
        call.blend_func = self.blendCompositeOperation(comp_op);

        // allocate vertices for all the paths.
        var maxverts = self.maxVertCount(paths[0..@intCast(usize, npaths)]);
        var offset = self.allocVerts(maxverts);

        for (self.paths.items[call.path_offset .. call.path_offset + @intCast(usize, npaths)]) |*p, i| {
            const path = &paths[i];
            p.* = .{};
            if (path.nstroke > 0) {
                p.stroke_offset = offset;
                p.stroke_count = @intCast(usize, path.nstroke);
                self.verts.replaceRange(offset, p.stroke_count, path.stroke[0..p.stroke_count]) catch unreachable;
                offset += p.stroke_count;
            }
        }

        if (self.flags.enable_stencil_strokes) {
            // fill shader
            call.uniform_offset = self.allocFragUniforms(2);

            _ = self.convertPaint(
                self.fragUniformPtr(call.uniform_offset),
                paint,
                scissor,
                stroke_width,
                fringe,
                -1.0,
            );
            _ = self.convertPaint(
                self.fragUniformPtr(call.uniform_offset + self.frag_size),
                paint,
                scissor,
                stroke_width,
                fringe,
                1.0 - 0.5 / 255.0,
            );
        } else {
            // Fill shader
            call.uniform_offset = self.allocFragUniforms(1);
            _ = self.convertPaint(
                self.fragUniformPtr(call.uniform_offset),
                paint,
                scissor,
                stroke_width,
                fringe,
                -1.0,
            );
        }

        return;
    }

    fn renderTriangles(
        uptr: ?*c_void,
        paint: [*c]api.NVGpaint,
        comp_op: api.NVGcompositeOperationState,
        scissor: [*c]api.NVGscissor,
        verts: [*c]const api.NVGvertex,
        nverts: c_int,
        fringe: f32,
    ) callconv(.C) void {
        var self = @ptrCast(*Self, @alignCast(@alignOf(*Self), uptr).?);
        var call = self.allocCall();
        call.type = .triangles;
        call.image = paint.*.image;
        call.blend_func = self.blendCompositeOperation(comp_op);

        // allocate vertices for all the paths.
        call.triangle_offset = self.allocVerts(@intCast(usize, nverts));
        call.triangle_count = @intCast(usize, nverts);
        self.verts.replaceRange(call.triangle_offset, call.triangle_count, verts[0..call.triangle_count]) catch unreachable;

        // fill shader
        call.uniform_offset = self.allocFragUniforms(1);
        var frag = self.fragUniformPtr(call.uniform_offset);
        _ = self.convertPaint(frag, paint, scissor, 1.0, fringe, -1.0);
        frag.type = @enumToInt(ShaderType.shader_img);

        return;
    }

    fn renderDelete(uptr: ?*c_void) callconv(.C) void {
        var self = @ptrCast(*Self, @alignCast(@alignOf(*Self), uptr).?);
        self.shader.deinit();
        self.vertex_array.deinit();
        for (self.textures.items) |t| {
            if (t.tex != 0 and (t.flags & image_nodelete_flag) == 0) {
                gl.deleteTextures(1, &t.tex);
            }
        }
        self.textures.deinit();
        self.calls.deinit();
        self.paths.deinit();
        self.verts.deinit();
        self.uniforms.deinit();
        self.allocator.free(self);
    }
};
