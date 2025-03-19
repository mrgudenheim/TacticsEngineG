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
- FFTae allows exporting a gif of an animation
...


# Limitations and Notes
- vfx do not display 3d models
- FFTae does not show items (MFItem related opcodes)
...


# Future Improvements
- Animated textures on maps
- Generally improve ability vfx by using more data from vfx files
- UI for unit hp, mp, ct
- UI to deploy units on maps
- Alternate palettes for weapons and items in animations
- Accurately handle transparency in unit animations
- Allow exporting gif of full ability animation chain
...


# Building From Source
This project is built with Godot 4.4
https://godotengine.org/
