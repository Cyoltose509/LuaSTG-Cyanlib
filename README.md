# LuaSTG Cyanlib

**LuaSTG Cyanlib** is a modular scripting library designed for **LuaSTG Sub**, aiming to provide a more modern, structured, and maintainable development experience.
The project adopts a **Java/C#-style Lua programming approach**, introducing layered modules, OOP-style design, and a unified update flow to significantly improve development clarity and scalability.

---

## Project Structure

```
game/
├── core/              # Core game engine module
│   ├── UI/            # UI framework (nodes, HUD, layout)
│   ├── Render/        # 2D/3D rendering, shaders, draw utilities
│   ├── Object/        # Object lifecycle & extensions
│   ├── Display/       # Screen, window, camera management
│   ├── Input/         # Keyboard, mouse, gamepad input
│   ├── Task/          # Coroutine-based task system
│   ├── MainLoop/      # Pluggable update event system
│   ├── Resource/      # Asset loading & management
│   ├── Math/          # Geometry, vectors, matrices, easing
│   ├── Collision/     # Collision detection (AABB, OBB, circle)
│   ├── World/         # World bounds & boundary rules
│   ├── Lib/           # General-purpose utilities
│   ├── Menu/          # UI menu system
│   ├── Effect/        # Visual effects & particles
│   ├── Animator/      # Animation state machine
│   ├── Data/          # Save data system
│   ├── System/        # Logging & diagnostics
│   ├── Steam/         # Steam API integration
│   ├── AudioManager.lua
│   ├── Class.lua
│   ├── I18n.lua
│   ├── RNG.lua
│   ├── Time.lua
│   ├── VFS.lua
│   ├── SceneManager.lua
│   ├── _Assets/       # Core shared assets (fonts, shaders, sprites)
│   ├── _Global/       # Global libraries (Math, String, Table helpers)
│   └── _Lang/         # Core localization strings
│
├── STG/               # Touhou-style STG extension module
│   ├── Player/        # Player system (profiles, styles, resources, components)
│   ├── Enemy/         # Enemy system (profiles, behaviors, Boss submodule)
│   │   └── Boss/      # Boss & spell card system
│   ├── Shots/         # Bullet & laser system
│   │   ├── Bullet/    # Straight & curved bullet factories
│   │   ├── Laser/     # Linear & curve laser factories
│   │   └── CurveLaser/ # Curve laser implementation
│   ├── Item/          # Power, point, life, bomb collectibles
│   ├── Background/     # Parallax & scrolling backgrounds
│   ├── Effect/        # STG-specific effects (break, bomb flash, etc.)
│   ├── Area/          # Screen area definitions & rules
│   ├── Data/          # Score, high score, achievement tracking
│   ├── Run/           # Game flow manager (playing/paused/game over states)
│   ├── Replay/        # Replay recording & playback
│   ├── Pause/         # Pause menu & state management
│   ├── Layout/        # Camera, viewport, frame border, side panel
│   ├── Loading/       # Loading screen scene
│   ├── HUD/           # Side-panel HUD (score, lives, bombs, power, graze)
│   ├── Menu/          # Title, stage select, settings, result screens
│   ├── Test/          # Test gameplay scene with sample enemies & boss
│   ├── Object/        # STG-specific object helpers
│   ├── _Assets/       # STG assets (sprites, BG, music, SE)
│   └── legacy/        # Reference implementations (original codebase)
│
├── Main/              # Main menu scene
├── Test/              # Core module demos & visualizations
└── User/              # User-generated data (configs, replays)
```

> Directories prefixed with `_` (e.g. `_Assets`, `_Lang`) contain **resources** — not requireable Lua modules.
> All other directories and standalone `.lua` files are **code modules**, loaded via the central `init.lua`.

---

## Module Overview

### **Core — Game Engine Module**

The foundation of Cyanlib (fairly complete):

| Feature | Description |
|---------|-------------|
| **Camera-Driven Rendering** | Camera → Capture → Render Output architecture (experimental) |
| **Object System** | Lifecycle management, layers, collision groups, custom attributes |
| **UI Framework** | Node-based UI with Immediate mode, HUD canvas, layout system |
| **MainLoop** | Pluggable update events for modular game logic |
| **Task System** | Coroutine-based async task scheduler |
| **Math Library** | Geometry, vectors, matrices, easing functions, point sets |
| **Collision** | AABB, OBB, circle collision detection |
| **Resource System** | Asset loading with object-oriented Shader support |
| **Render (2D/3D)** | Stable 2D rendering, experimental 3D rendering |
| **Input** | Keyboard, mouse, and gamepad input abstraction |
| **I18n** | Internationalization with CSV-based translations |
| **RNG** | Consistent, controllable random number generators |
| **VFS** | Virtual file system for asset path resolution |

### **STG — Touhou-Style STG Extension**

A standalone module for bullet-hell / Touhou-style STG games:

| Feature | Description |
|---------|-------------|
| **Player System** | Profile-based player with styles, resources (lives/bombs/power/graze), component architecture |
| **Enemy System** | Enemy profiles, behavior trees (move, shoot, wait, loop, parallel) |
| **Boss System** | Spell card management, HP-based phase transitions, spell card bonuses |
| **Shots (Bullets)** | Straight & curved bullet factories, style-driven bullet definitions |
| **Shots (Lasers)** | Linear lasers, curve lasers, width & rotation support |
| **Item System** | Power, point, life, bomb drops with auto-collect mechanics |
| **Background** | Parallax scrolling backgrounds with texture tiling |
| **HUD** | Side-panel display for score, hi-score, power, lives, bombs, graze, FPS |
| **Layout** | Game viewport, side panel, frame border with logical/physical coordinate mapping |
| **Game Flow** | Run manager with playing/paused/game-over state machine |
| **Pause Menu** | In-game pause with resume, restart, and quit options |
| **Menus** | Title screen, stage select, settings, and result screens |
| **Replay** | Replay recording and playback (structure in place) |
| **Data** | Score tracking, high scores, achievement system |
| **Area** | Screen area definitions for gameplay boundaries |

### **Test — Core Demos**

Visualizes the entire Core library structure and includes examples:

- Camera functionality
- UI rendering
- Embeddable pause menu
- Internationalization (I18n)
- Object & rendering basics
- Logic tests & feature showcases

This is the recommended entry point to understand Core.

---

## Design Conventions

### Module Loading

All code modules are **centrally loaded** in each module's `init.lua`. This means:

- Loading order is explicit and controllable
- Circular dependency issues are managed in one place
- `require` paths map directly to the global API namespace:
  ```lua
  require("core.UI")      →  Core.UI
  require("core.Render")   →  Core.Render
  require("STG.Player")     →  STG.Player
  require("STG.Enemy")     →  STG.Enemy
  ```

### Directory Naming

| Pattern | Meaning | Example |
|---------|---------|---------|
| `PascalCase/` | Code module (requireable) | `UI/`, `Render/`, `Player/` |
| `_Prefix/` | Resource directory (not requireable) | `_Assets/`, `_Lang/`, `_Global/` |
| `PascalCase.lua` | Single-file code module | `Class.lua`, `RNG.lua` |

### Coding Style (Java / C#-Inspired)

| Type | Rule | Example |
|------|------|---------|
| Class Name | PascalCase | `Camera`, `Vector3`, `MainLoop` |
| Static Method | PascalCase | `Camera.New()` |
| Instance Method | camelCase | `camera:setPosition()` |
| Constant | UPPER_CASE | `EPSILON` |
| Private Variable | lowercase | `cacheValue` |

---

## Assets & Copyright

### Assets used in `Test`:

- **Skybox**: from polyhaven.com
- **Music**: created by the author
- **test.jpg**: created by the author

### Shared assets in `Core/_Assets`:
All are **commercial-use-friendly** materials.

Some modules reference external logic; attribution is included in the source code.

---

## Development Status

Cyanlib is actively evolving and will continue to grow alongside real project needs.

---

## License

Cyanlib is released under the **MIT License**.
You are free to use, modify, distribute, and integrate it in commercial projects.

See the `LICENSE` file for full details.

---

## Contributing

Issues and pull requests are welcome.
Let's build a better LuaSTG-Cyanlib ecosystem together.

---

## Contact

**Discord:** cyoltose4769
**Email:** cyoltose@gmail.com
