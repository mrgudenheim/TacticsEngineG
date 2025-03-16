# [Click here for newest release](https://github.com/mrgudenheim/FFT-like-engine/releases)

# About
This engine is intended to create a game similar to Final Fantasy Tactics (FFT), including reading data from an FFT ROM


Controls:

WASD: Move

Q/E: Rotate camera

Space: Jump

Right Click: Use ability (only Stasis Sword vfx work)

Left Click: Attack (not implemented)

Scroll Wheel: Zoom in/out

Escape: Open/Close debug menus


# Features
- Displays maps
- Displays unit animations
- Dipslays vfx frames (not 3d models or movement)
- FFTae allows exporting a grid sheet of all shp frames
- FFTae allows exporting a gif of an animation - Ignores all Opcodes and rotations
...

# Limitations and Notes
- A new map may need to be manually loaded (through the debug menu) if the players falls off the edge or through a hole. Also it may be impossible to reach Algus on some maps.

# Future Improvements
- Animated textures on maps
- Generally improve ability vfx by using more data from vfx files
- UI for unit hp, mp, ct
- UI to deploy units on maps

# Building From Source
This project is built with Godot 4.4
https://godotengine.org/
