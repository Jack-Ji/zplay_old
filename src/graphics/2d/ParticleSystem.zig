const std = @import("std");
const assert = std.debug.assert;
const zp = @import("../../zplay.zig");
const alg = zp.deps.alg;
const Vec2 = alg.Vec2;
const Vec4 = alg.Vec4;
const Sprite = @import("Sprite.zig");
const SpriteBatch = @import("SpriteBatch.zig");

/// represent a particle
pub const Particle = struct {
    /// life of particle
    age: f32,

    /// position changing
    pos: Vec2,
    move_speed: Vec2,
    move_acceleration: Vec2,
    move_damp: f32,

    /// rotation changing
    angle: f32,
    rotation_speed: f32,
    rotation_damp: f32,

    /// scale changing
    scale: f32,
    scale_speed: f32,
    scale_acceleration: f32,
    scale_max: f32,

    /// color changing
    color: Vec4,
    color_initial: Vec4,
    color_final: Vec4,
    color_fade_age: f32,

    fn updatePos(self: *Particle, delta_time: f32) void {
        assert(self.move_damp >= 0 and self.move_damp <= 1);
        self.move_speed = self.move_speed.scale(self.move_damp);
        self.move_speed = self.move_speed.add(self.move_acceleration.scale(delta_time));
        self.pos = self.pos.add(self.move_speed.scale(delta_time));
    }

    fn updateRotation(self: *Particle, delta_time: f32) void {
        assert(self.rotation_damp >= 0 and self.rotation_damp <= 1);
        self.rotation_speed *= self.rotation_damp;
        self.angle += self.rotation_speed * delta_time;
    }

    fn updateScale(self: *Particle, delta_time: f32) void {
        assert(self.scale_max > 0);
        self.scale_speed += self.scale_acceleration * delta_time;
        self.scale += self.scale_speed * delta_time;
        self.scale = std.math.clamp(self.scale, 0.0, self.scale_max);
    }

    fn updateColor(self: *Particle) void {
        if (self.age > self.color_fade_age) {
            self.color = self.color_initial;
        } else {
            assert(self.color_fade_age > 0);
            const c1 = self.age / self.color_fade_age;
            const c2 = 1.0 - c1;
            self.color = self.color_initial
                .scale(c1)
                .add(self.color_final.scale(c2));
        }
    }

    /// if particle is dead
    pub inline fn isDead(self: Particle) bool {
        return self.age <= 0;
    }

    /// update particle's status
    pub fn update(self: *Particle, delta_time: f32) void {
        if (self.age <= 0) return;
        self.age -= delta_time;
        self.updatePos(delta_time);
        self.updateRotation(delta_time);
        self.updateScale(delta_time);
        self.updateColor();
    }

    /// add particle to sprite batch
    pub fn draw(self: Particle, sprite: Sprite, sprite_batch: SpriteBatch) !void {
        try sprite_batch.drawSprite(
            sprite,
            .{
                .pos = .{ .x = self.pos.x(), .y = self.pos.y() },
                .color = self.color.toArray(),
                .scale_w = self.scale,
                .scale_h = self.scale,
                .rotate_degree = self.angle,
                .anchor_point = .{ .x = 0.5, .y = 0.5 },
                .depth = 0,
            },
        );
    }
};

/// represent a particle effect
pub const ParticleEffect = struct {
    pub const GenerateParticleFunc = fn (origin: Vec2) Particle;

    /// all particles
    particles: std.ArrayList(Particle),

    /// particles' generator
    gen_func: GenerateParticleFunc,

    /// origin of particle
    origin: Vec2,

    /// effect duration
    effect_duration: f32,

    /// new particle amount per burst
    gen_amount: u32,

    /// burst frequency
    burst_freq: f32,

    /// burst countdown
    burst_countdown: f32,

    /// particle effect initialization
    pub fn init(
        allocator: std.mem.Allocator,
        max_particle_num: u32,
        gen_func: GenerateParticleFunc,
        origin: Vec2,
        effect_duration: f32,
        gen_amount: u32,
        burst_freq: f32,
    ) !ParticleEffect {
        assert(max_particle_num > 0);
        assert(effect_duration > 0);
        assert(gen_amount > 0);
        assert(burst_freq > 0);
        assert(effect_duration > burst_freq);
        return ParticleEffect{
            .particles = try std.ArrayList(Particle).initCapacity(allocator, max_particle_num),
            .gen_func = gen_func,
            .origin = origin,
            .effect_duration = effect_duration,
            .gen_amount = gen_amount,
            .burst_freq = burst_freq,
            .burst_countdown = burst_freq,
        };
    }

    /// update effect
    pub fn update(self: *ParticleEffect, delta_time: f32) void {
        if (self.effect_duration > 0) {
            self.effect_duration -= delta_time;
            self.burst_countdown -= delta_time;
            if (self.effect_duration >= 0 and self.burst_countdown <= 0) {
                var i: u32 = 0;
                while (i < self.gen_amount) : (i += 1) {
                    // generate new particle
                    self.particles.appendAssumeCapacity(
                        self.gen_func(self.origin),
                    );
                    if (self.particles.items.len == self.particles.capacity) break;
                }
            }
        }

        // update each particles' status
        var size = self.particles.len;
        for (self.particles.items) |*p, i| {
            p.update(delta_time);
            while (p.isDead()) {
                _ = self.particles.swapRemove(i);
                size -= 1;
                if (i < size) p.update(delta_time);
            }
            if (i == size) break;
        }
    }

    /// draw the effect
    pub fn draw(self: ParticleEffect, sprite: Sprite, sprite_batch: SpriteBatch) !void {
        for (self.particles.items) |p| {
            try p.draw(sprite, sprite_batch);
        }
    }
};
