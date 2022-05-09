# zplay
A simple framework intended for game/tool creation.

## Features
* Little external dependency, only SDL2 and OpenGL3
* Support PC platforms: windows/linux (possibly macOS, don't know for sure)
* Flexible render-passes pipeline, greatly simplify rendering code
* Graphics oriented math library: Vec2/Vec3/Mat4/Quaternion
* Vector graphics drawing ([nanovg](https://github.com/memononen/nanovg))
* Immediate mode GUI toolkits ([dear-imgui](https://github.com/ocornut/imgui))
* Realtime data visualization ([ImPlot](https://github.com/epezent/implot))
* TrueType font loading and rendering
* Image picture loading/decoding/writing (support png/jpg/bmp/tga)
* Audio playback (support wav/flac/mp3/vorbis)
* 2D toolkits:
  * Sprite and SpriteBatch system
  * Texture packer used to programmatically create sprite-sheet
  * Chipmunk physics lib integration
  * Particle system
* 3D toolkits:
  * Model loading and rendering (only glTF 2.0 for now)
  * Bullet3 physics lib integration (credit to [zig-gamedev](https://github.com/michal-z/zig-gamedev))
  * Blinn-Phong renderer (directional/point/spot light)
  * Environment mapping renderer
  * Skybox renderer

## Getting started
Copy `zplay` folder or clone repo (recursively) into `libs` subdirectory of the root of your project.

Install SDL2 library, please refer to [docs of SDL2.zig](https://github.com/MasterQ32/SDL.zig)

Then in your `build.zig` add:

```zig
const std = @import("std");
const zplay = @import("libs/zplay/build.zig");

pub fn build(b: *std.build.Builder) void {
    const exe = b.addExecutable("your_bin", "src/main.zig");

    exe.setBuildMode(b.standardReleaseOptions());
    exe.setTarget(b.standardTargetOptions(.{}));
    exe.install();

    zplay.link(exe, .{
      // link optional modules (imgui/nanovg etc)
    });

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
```

Now in your code you may import and use zplay:

```zig
const std = @import("std");
const zp = @import("zplay");

fn init(ctx: *zp.Context) anyerror!void {
    _ = ctx;
    std.log.info("game init", .{});

    // your init code
}

fn loop(ctx: *zp.Context) void {
    while (ctx.pollEvent()) |e| {
        switch (e) {
            .quit_event => ctx.kill(),
            else => {},
        }
    }

    // your game loop
}

fn quit(ctx: *zp.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});

    // your deinit code
}

pub fn main() anyerror!void {
    try zp.run(.{
        .initFn = init,
        .loopFn = loop,
        .quitFn = quit,
    });
}
```

## Examples
* sprites benchmark
![picture](https://github.com/jack-ji/zplay/blob/main/examples/screenshots/sprites_benchmark.png)

* chipmunk test
![picture](https://github.com/jack-ji/zplay/blob/main/examples/screenshots/chipmunk_test.gif)

* fake rasterization demonstration (granularity is triangle) (original idea is from [michal-z](https://github.com/michal-z/zig-gamedev/tree/main/samples/rasterization))
![picture](https://github.com/jack-ji/zplay/blob/main/examples/screenshots/rasterization.png)

* glTF 2.0 model
![picture](https://github.com/jack-ji/zplay/blob/main/examples/screenshots/gltf_demo.png)

* environment mapping
![picture](https://github.com/jack-ji/zplay/blob/main/examples/screenshots/environment_mapping.png)

* mesh generation
![picture](https://github.com/jack-ji/zplay/blob/main/examples/screenshots/mesh_generation.png)

* phong/blinn-phong light shading
![picture](https://github.com/jack-ji/zplay/blob/main/examples/screenshots/phong_lighting.png)

* post-processing effects
![picture](https://github.com/jack-ji/zplay/blob/main/examples/screenshots/post_processing.png)

* collision test
![picture](https://github.com/jack-ji/zplay/blob/main/examples/screenshots/bullet_test.gif)

* imgui demo
![picture](https://github.com/jack-ji/zplay/blob/main/examples/screenshots/imgui_demo.png)

* vector graphics
![picture](https://github.com/jack-ji/zplay/blob/main/examples/screenshots/vector_graphics.png)

## Third-Party Libraries
* [SDL2](https://www.libsdl.org) (zlib license)
* [glad-generated OpenGL3 loader](https://glad.dav1d.de) (Apache Version 2.0 license)
* [zalgebra](https://github.com/kooparse/zalgebra) (MIT license)
* [miniaudio](https://miniaud.io/index.html) (MIT license)
* [cgltf](https://github.com/jkuhlmann/cgltf) (MIT license)
* [stb headers](https://github.com/nothings/stb) (MIT license)
* [dear-imgui](https://github.com/ocornut/imgui) (MIT license)
* [ImPlot](https://github.com/epezent/implot) (MIT license)
* [imnodes](https://github.com/Nelarius/imnodes) (MIT license)
* [nanovg](https://github.com/memononen/nanovg) (zlib license)
* [nanosvg](https://github.com/memononen/nanosvg) (zlib license)
* [bullet3](https://github.com/bulletphysics/bullet3) (zlib license)
* [chipmunk](https://chipmunk-physics.net/) (MIT license)
* [nativefiledialog](https://github.com/mlabbe/nativefiledialog) (zlib license)
* [known-folders](https://github.com/ziglibs/known-folders) (MIT license)

