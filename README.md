# zplay
A simple framework intended for game/tool creation.

## Features
* Little dependency, only SDL2 and OpenGL3 are needed
* Support PC platforms: windows/linux (possibly macOS, don't know for sure)
* Flexible render-passes pipeline, greatly simplify rendering code
* 3D model loading and rendering (only glTF 2.0 for now)
* Various 3D shading renderers: Blinn-Phong/EnvMapping/PBR(TODO)
* Ready to use post-processing effects: Blur/Inversion/Grayscale/Gamma-Correction/Convolution
* Bullet3 physics lib integration (credit to [zig-gamedev](https://github.com/michal-z/zig-gamedev))
* Graphics oriented math library: Vec2/Vec3/Mat4/Quaternion (credit to [zalgebra](https://github.com/kooparse/zalgebra))
* Image/Audio asset loading/decoding via [great stb](https://github.com/nothings/stb)
* Particle system (TODO)
* 2D Sprite system (TODO)
* Hand-crafted integration of [dear-imgui](https://github.com/ocornut/imgui) and popular extensions ([implot](https://github.com/epezent/implot)/[imnodes](https://github.com/Nelarius/imnodes))
* Hand-crafted integration of [NanoVG](https://github.com/memononen/nanovg)/[NanoSVG](https://github.com/memononen/nanosvg)
* Hand-crafted OpenGL wrappers: GraphicsContext/FrameBuffer/ShaderProgram/VertexArray/Buffer/Texture

# Install
1. Download and install zig master branch
2. Install SDL2 library, please refer to [docs of SDL2.zig](https://github.com/MasterQ32/SDL.zig)

# Examples
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

# FYI
I'm still learning, which means codebase will probably change drastically over time. If you want a stable
framework, please consider using more mature frameworks like MonoGame/LibGDX, or fork the repo if you want!
