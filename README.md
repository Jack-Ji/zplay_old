# zplay
A simple framework intended for game/tool creation.

## Features
* Little dependency, only SDL2 and OpenGL3 are needed
* Support PC platforms: windows/linux (possibly macOS, don't know for sure)
* Abstracted graphics renderer interface, available renderers:
    * A simple mesh renderer
    * Blinn-Phong renderer (directional/point/spot light)
    * Environment mapping renderer
    * Skybox renderer
    * PBR renderer (TODO)
    * Post-processing effect renderers:
        * Grayscale
        * Gamma-Correction
        * Color-inversion
        * Convolution (sharpen/blur/edge-detect etc)
* Flexible render-passes pipeline, greatly simplify rendering code
* 3D model loading and rendering (only glTF 2.0 for now)
* TrueType font loading and rendering
* Particle system (TODO)
* SpriteBatch system (TODO)
* Texture packer used to programmatically create sprite sheet
* 2D physics (TODO)
* Bullet3 physics lib integration (credit to [zig-gamedev](https://github.com/michal-z/zig-gamedev))
* Graphics oriented math library: Vec2/Vec3/Mat4/Quaternion (credit to [zalgebra](https://github.com/kooparse/zalgebra))
* Image/Audio asset loading/decoding via [great stb](https://github.com/nothings/stb)
* Hand-crafted integration of [dear-imgui](https://github.com/ocornut/imgui) and popular extensions ([implot](https://github.com/epezent/implot)/[imnodes](https://github.com/Nelarius/imnodes))
* Hand-crafted integration of [NanoVG](https://github.com/memononen/nanovg)/[NanoSVG](https://github.com/memononen/nanosvg)
* Hand-crafted OpenGL wrappers: GraphicsContext/FrameBuffer/ShaderProgram/VertexArray/Buffer/Texture

# Install
1. Download and install zig master branch
2. Install SDL2 library, please refer to [docs of SDL2.zig](https://github.com/MasterQ32/SDL.zig)

# Examples
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

# FYI
I'm still learning, which means codebase will probably change drastically over time. If you want a stable
framework, please consider using more mature frameworks like MonoGame/LibGDX, or fork the repo if you want!
