# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

LuaSTG Cyanlib is a modular Lua scripting library for the **LuaSTG Sub** bullet-hell/Touhou-style STG game engine. It provides a Java/C#-style OOP framework with camera-driven rendering, a class system, a UI framework, and an STG extension module.

- **Language:** Lua (192 `.lua` files). A small amount of C++ in `engine/common/` for engine-override customization.
- **Engine:** [LuaSTG-Sub](https://github.com/Legacy-LuaSTG-Engine/LuaSTG-Sub) (C++ engine with LuaJIT scripting, symlinked at `engine/luastg/`).
- **Entry point:** `game/core.lua` — loaded by the engine at startup.
- **Config:** `game/config.json` (window, graphics, audio, logging).

## How to Run

The engine executable is prebuilt and checked in:

```
game/LuaSTG.Dev.exe     # Dev mode (ImGui enabled, console output, no asset encryption)
game/LuaSTG.exe         # Release mode (encryption enabled, no console)
```

Run the appropriate `.exe` from the `game/` directory to launch the Test module demos. No Lua build step is needed — scripts are loaded at runtime.

## Engine Build (C++)

The engine only needs to be rebuilt when the C++ overrides in `engine/common/` change or when pulling upstream LuaSTG-Sub updates.

1. **Clone engine source:** `engine/download_luastg.bat` (requires Git)
2. **Build:** `engine/build_release.bat` (requires Visual Studio 2022/2026 and CMake)
   - Also available: `build_develop.bat`, `build_release_steam.bat`
3. After build, copy the resulting `LuaSTGSub.exe` into `game/`.

Engine build uses CMake + CPM for dependency management. Custom config lives in `engine/develop/Config.h`, `engine/release/Config.h`, and `engine/release_steam/Config.h`.

## Name Conventions

| Type | Convention | Example |
|------|-----------|---------|
| Class name | PascalCase | `Camera`, `Vector3`, `MainLoop` |
| Static method | PascalCase | `Camera.New()` |
| Instance method | camelCase | `camera:setPosition()` |
| Constant | UPPER_CASE | `EPSILON` |
| Private variable | lowercase | `cacheValue` |

## Module Architecture

```
game/core.lua          -- Entry point, requires Core, then STG, then Test
  Core/                -- Foundation library (the most complete module)
    init.lua           -- Requires Global → Scripts → Lang → Assets
    Global/            -- Math, String, Table utility extensions
    Scripts/           -- All library subsystems (~80+ files)
    Assets/            -- Shared sprites, fonts (.ttf/.otf), shaders (.hlsl)
    Lang/              -- I18n key mapping (key_name.csv)
  STG/                 -- STG game extension (in development)
    Scripts/           -- Enemy, Player, Shots (Bullet/Laser/CurveLaser), Item, Area, Effect
    Assets/            -- Structure only, no actual assets
  Test/                -- Runnable demos and examples (entry point for understanding Cyanlib)
    Scripts/           -- Camera, DataVisual (UI tree, pause menu), STG scene demos
```

## Core Subsystems (`Core/Scripts/`)

Each subsystem lives in its own directory with an `init.lua` that exports into the global `Core` table. Load order is defined in `Core/Scripts/init.lua`.

| Subsystem | Purpose |
|-----------|---------|
| **Class** | `Core.Class()` in `Scripts/init.lua`. Single-inheritance OOP. Classes are callable tables: `local obj = MyClass()` calls `init()`. Supports metamethod forwarding (`__add`, `__eq`, etc.). |
| **Lib** | Utilities: CSV/JSON/YAML parsing, Easing, EventListener, StateMachine, Debug, Matcher, Smooth, Accessor, ComponentBase/ComponentSystem |
| **Math** | Vector2/3/4, Matrix4x4, Quaternion, Ray, Plane, Geometry, PointSet |
| **Render** | Camera-driven 2D/3D rendering pipeline. Sprite, Mesh, Skybox, Ball, Color, GPU abstraction, Draw commands, RichText/CJK text rendering |
| **Display** | Camera (base), Camera2D, Camera3D, Screen, Window |
| **Object** | Extensions for manipulating LuaSTG game objects: AttributeProxy, Group, Layer |
| **Resource** | OOP wrappers for engine resources: Shader, Texture, Sprite, Font (TTF), Sound, Music, Model, Particle, Animation, RenderTarget, LazyLoader |
| **UI** | Widget framework with Anchor, Image, Text, TextureRect, Layout, Animation, Manager, Root. Draw primitives: Rect, RoundedRect, Sector, Parallelogram, HexRect. |
| **Input** | Keyboard, Mouse, XInput wrappers |
| **MainLoop** | Unified update cycle with pluggable event groups. Events registered via `Core.MainLoop.AddEvent(loopGroup, eventGroup, opts)`. Loop groups: Init, Exit, FocusLose/Gain, SceneChangeBefore/After, Frame (Before/Gameplay/After), Render, Custom. The engine calls `GameInit`/`FrameFunc`/`RenderFunc`/`FocusLoseFunc`/`FocusGainFunc` which are assigned at the bottom of `MainLoop/init.lua`. |
| **Effect** | ParticleSystem, Post-processing, ScreenFX |
| **Collision** | Collider system |
| **Data** | Score, Setting persistence |
| **Task** | Coroutine-based task system |
| **I18n** | Internationalization — locale-specific CSV key maps registered via `Core.Lang` |
| **SceneManager** | Scene transition management |
| **AudioManager** | Audio playback management |
| **RNG** | Consistent random number utilities |

## How Subsystems Register

Every `Core/Scripts/<Subsystem>/init.lua` follows this pattern:

```lua
local M = {}
Core.<Subsystem> = M
-- ... subsystem code ...
```

The subsystem is then `require`d in `Core/Scripts/init.lua`. This exposes it on the global `Core` table for all other modules.

## STG Module

`STG/init.lua` is the activation point. Subsystems mirror Core patterns but are STG-specific:

- **Shots/** — Bullet, Laser, CurveLaser (each with Resource, Updater, Collider). Most complete STG subsystem.
- **Enemy/** — Enemy base, Boss, Profiles, Resource, Systems (Anim, Collide, Health, Move, Phase, Death, DamageModifier)
- **Player/** — Player base, Profiles, Registry, Resource, Systems (Anim, Death, Effect, Graze, Health, Hit, Input, Move, Phase, Shoot, Shots)

## Key Patterns

- **OOP classes are tables with metatables** — `Core.Class()` creates a callable class table. `__call` is the constructor. `__index` walks the inheritance chain via `_mbc` (member cache).
- **LuaSTG engine API** is accessed via the global `lstg` table (e.g., `lstg.GetFPS()`, `lstg.BeginScene()`, `lstg.EndScene()`).
- **No test framework exists.** `Test/` is a demo module (fully runnable). To validate changes, launch `LuaSTG.Dev.exe` and navigate the Test demos.
- **Asset encryption** is disabled in dev mode and enabled in release mode (controlled by `engine/*/Config.h`).
