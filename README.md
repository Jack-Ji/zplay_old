# zplay
A simple framework intended for game/tool creation.

## Features
* Little dependency, only SDL2 and OpenGL3 are needed
* Support PC platforms: windows/linux (possibly macOS, don't know for sure)
* Support image formats: tga/png/jpeg
* Support audio formats: mp3/ogg (TODO)
* glTF 2.0 file support
* Sprite system (TODO)
* Collision system (TODO)
* Particle system (TODO)
* dear-imgui and extensions(implot/imnodes) integration 
* NanoVG/NanoSVG integration

# Install
1. Download and install zig 0.9.x version
2. Install SDL2 library, please refer to [docs of SDL2.zig](https://github.com/MasterQ32/SDL.zig)

# Examples
* glTF 2.0 model
![picture](https://github.com/jack-ji/zplay/blob/main/examples/screenshots/gltf_demo.png)

* environment mapping
![picture](https://github.com/jack-ji/zplay/blob/main/examples/screenshots/environment_mapping.png)

* imgui demo
![picture](https://github.com/jack-ji/zplay/blob/main/examples/screenshots/imgui_demo.png)

* vector graphics
![picture](https://github.com/jack-ji/zplay/blob/main/examples/screenshots/vector_graphics.png)

* phong lighting
![picture](https://github.com/jack-ji/zplay/blob/main/examples/screenshots/phong_lighting.png)

# FYI
I'm still learning, which means codebase will probably change drastically over time. If you want a stable
framework, please consider using more mature frameworks like MonoGame/LibGDX, or fork the repo if you want!
