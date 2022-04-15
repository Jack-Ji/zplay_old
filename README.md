# zplay
A simple framework intended for game/tool creation.

## Features
* Little external dependency, only SDL2 and OpenGL3
* Support PC platforms: windows/linux (possibly macOS, don't know for sure)
* Flexible render-passes pipeline, greatly simplify rendering code
* Graphics oriented math library: Vec2/Vec3/Mat4/Quaternion (credit to [zalgebra](https://github.com/kooparse/zalgebra))
* Vector graphics drawing ([nanovg](https://github.com/memononen/nanovg))
* Immediate GUI toolkits ([dear-imgui](https://github.com/ocornut/imgui))
* Realtime data visualization ([ImPlot](https://github.com/epezent/implot))
* Image picture loading/decoding/writing (support png/jpg/bmp/tga)
* TrueType font loading and rendering
* (TODO) Audio playback (support wav/flac/mp3/vorbis)
* 2D toolkits:
  * Sprite and SpriteBatch system
  * Texture packer used to programmatically create sprite-sheet
  * Chipmunk physics lib integration
  * (TODO) Particle system
* 3D toolkits:
  * Model loading and rendering (only glTF 2.0 for now)
  * Bullet3 physics lib integration (credit to [zig-gamedev](https://github.com/michal-z/zig-gamedev))
  * Blinn-Phong renderer (directional/point/spot light)
  * Environment mapping renderer
  * Skybox renderer
  * (TODO) PBR renderer
  * (TODO) Particle system

## Third-party Libraries
* [SDL2](https://www.libsdl.org) (zlib license)
* [nfd-zig](https://github.com/fabioarnold/nfd-zig) (MIT license)
* [known-folders](https://github.com/ziglibs/known-folders) (MIT license)
* [glad](https://glad.dav1d.de) (Apache Version 2.0 license)
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

## Install
1. Download and install zig master branch
2. Install SDL2 library, please refer to [docs of SDL2.zig](https://github.com/MasterQ32/SDL.zig)

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

