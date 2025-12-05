# LuaSTG Cyanlib

**LuaSTG Cyanlib** is a modular scripting library designed for **LuaSTG Sub**, aiming to provide a more modern, structured, and maintainable development experience.  
The project adopts a **Java/C#-style Lua programming approach**, introducing layered modules, OOP-style design, and a unified update flow to significantly improve development clarity and scalability.

Cyanlib currently consists of three main modules:

- **Core/** — Core game scripting module (fairly complete)  
- **STG/** — Touhou-style STG extension library (in development)  
- **Test/** — Examples and demos (fully runnable)

Run the included executable to view the demonstrations under the `Test` module.

---

# Module Overview

## **Core – Game Core Module**

Core is the foundation of Cyanlib (relatively complete), featuring:

### Camera-Driven Rendering  
Replaces the traditional “linear render pipeline” with a **Camera → Capture → Render Output** architecture.  
> This feature is experimental and will continue improving.

### Object-Oriented Resource System  
Designed to match LuaSTG’s ongoing resource objectization progress:  
- Shader is fully objectized  
- Other resource types will follow future LuaSTG updates

### UI Framework (In Development)  
Basic structure is implemented; more widgets and systems will be added.

### I18n – Internationalization Support  
Full usage examples are available in the `Test` module.

### MainLoop – Unified Update Cycle  
Provides modular, pluggable update events for clear and maintainable game logic.

### Math Library  
Includes common geometry tools, numeric utilities, vector/matrix operations, and more.

### Object Extensions  
Adds engineering-friendly helpers for LuaSTG object manipulation.

### Render (2D/3D)  
- Stable 2D rendering  
- Experimental 3D rendering (subject to change)

### RNG – Random Number Utilities  
Consistent, controllable random number interfaces.

---

## **STG – Touhou-Style STG Extension Library (In Development)**

A standalone module designed for bullet-hell / Touhou-style STG games.

Current features:

- **Shots module (bullets)** — relatively complete  
- Example asset-loading workflow in `STG/Assets`  
  *(Structure only; no actual assets included)*

Planned features:

- Enemy system  
- Boss system  
- Stage abstraction  

This module is still in its early stage.

---

## **Test – Examples & Demonstrations**

The `Test` module visualizes the entire structure of Cyanlib and includes various examples such as:

- Camera functionality  
- UI rendering  
- Embeddable pause menu  
- Internationalization (I18n)  
- Object & rendering basics  
- Logic tests & feature showcases  

This is the recommended entry point to understand Cyanlib.

---

# Assets & Copyright

### Assets used in `Test`:

- **Skybox**: from polyhaven.com  
- **Music**: created by myself  
- **test.jpg**: created by myself  

### Shared assets in `Core`:  
All are **commercial-use-friendly** materials.

Some modules reference external logic; attribution is included in the source code.

---

# Coding Style (Java / C#-Inspired)

Cyanlib uses a relatively unified naming convention:

| Type | Rule | Example |
|------|------|---------|
| Class Name | PascalCase | `Camera`, `Vector3`, `MainLoop` |
| Static Method | PascalCase | `Camera.New()` |
| Instance Method | camelCase | `camera:setPosition()` |
| Constant | UPPER_CASE | `EPSILON` |
| Private Variable | lowercase | `cacheValue` |

---

# Development Status

Cyanlib is actively evolving and will continue to grow alongside real project needs.

---

# License

Cyanlib is released under the **MIT License**.  
You are free to use, modify, distribute, and integrate it in commercial projects.

See the `LICENSE` file for full details.

---

# Contributing

Issues and pull requests are welcome.  
Let’s build a better LuaSTG-Cyanlib ecosystem together.

---

# Contact

**Discord:** cyoltose4769
**Email:** cyoltose@gmail.com
