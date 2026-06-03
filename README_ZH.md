# LuaSTG Cyanlib

**LuaSTG Cyanlib** 是一个面向 **LuaSTG Sub** 的模块化脚本库，旨在为 LuaSTG 提供更现代化、工程化、可维护的开发体验。
本库采用 **类 Java / C# 的 Lua 编程风格**，通过模块分层、对象化封装和统一的更新流程，大幅提升 LuaSTG 脚本层的开发规范和可扩展性。

---

## 项目结构

```
game/
├── core/              # 游戏引擎核心模块
│   ├── UI/            # UI 框架（节点、HUD、布局）
│   ├── Render/        # 2D/3D 渲染、着色器、绘图工具
│   ├── Object/        # 对象生命周期与扩展
│   ├── Display/       # 屏幕、窗口、相机管理
│   ├── Input/         # 键盘、鼠标、手柄输入
│   ├── Task/          # 协程式任务系统
│   ├── MainLoop/      # 可插拔更新事件系统
│   ├── Resource/      # 资源加载与管理
│   ├── Math/          # 几何、向量、矩阵、缓动函数
│   ├── Collision/     # 碰撞检测（AABB、OBB、圆形）
│   ├── World/         # 世界边界与边界规则
│   ├── Lib/           # 通用工具库
│   ├── Menu/          # UI 菜单系统
│   ├── Effect/        # 视觉特效与粒子
│   ├── Animator/      # 动画状态机
│   ├── Data/          # 存档系统
│   ├── System/        # 日志与诊断
│   ├── Steam/         # Steam API 集成
│   ├── AudioManager.lua
│   ├── Class.lua
│   ├── I18n.lua
│   ├── RNG.lua
│   ├── Time.lua
│   ├── VFS.lua
│   ├── SceneManager.lua
│   ├── _Assets/       # 核心共享资源（字体、着色器、精灵图）
│   ├── _Global/       # 全局库（Math、String、Table 工具）
│   └── _Lang/         # 核心本地化字符串
│
├── STG/               # 东方 STG 扩展模块
│   ├── Player/        # 玩家系统（Profile、Style、资源、组件）
│   ├── Enemy/         # 敌机系统（Profile、行为树、Boss 子模块）
│   │   └── Boss/      # Boss 与符卡系统
│   ├── Shots/         # 弹幕系统
│   │   ├── Bullet/    # 直线弹与曲线弹工厂
│   │   ├── Laser/     # 直线激光与曲线激光工厂
│   │   └── CurveLaser/ # 曲线激光实现
│   ├── Item/          # 道具（火力、得分、残机、炸弹）
│   ├── Background/    # 视差滚动背景
│   ├── Effect/        # STG 专用特效（击破、 bomb 闪光等）
│   ├── Area/          # 游戏区域定义与规则
│   ├── Data/          # 得分、最高分、成就系统
│   ├── Run/           # 游戏流程管理（游戏中/暂停/Game Over 状态机）
│   ├── Replay/        # 录像录制与回放
│   ├── Pause/         # 暂停菜单与状态管理
│   ├── Layout/        # 相机、视口、边框、侧面板布局
│   ├── Loading/       # 加载画面场景
│   ├── HUD/           # 侧面板 HUD（得分、残机、炸弹、火力、擦弹）
│   ├── Menu/          # 标题、关卡选择、设置、结算画面
│   ├── Test/          # 测试用关卡（含示例敌机与 Boss）
│   ├── Object/        # STG 专用对象工具
│   ├── _Assets/       # STG 素材（精灵图、背景、音乐、音效）
│   └── legacy/        # 原版参考实现
│
├── Main/              # 主菜单场景
├── Test/              # Core 模块演示与可视化
└── User/              # 用户数据（配置、存档、录像）
```

> 以 `_` 为前缀的目录（如 `_Assets`、`_Lang`）存放的是**资源**，不是可通过 `require` 加载的 Lua 模块。
> 其余目录和独立 `.lua` 文件均为**代码模块**，通过各自的 `init.lua` 集中加载。

---

## 模块概览

### **Core —— 游戏引擎核心**

Cyanlib 的基础构成模块（完善度较高）：

| 功能 | 说明 |
|------|------|
| **Camera 主导渲染** | Camera 捕捉画面 → 渲染输出的架构（实验性） |
| **对象系统** | 生命周期管理、图层、碰撞组、自定义属性 |
| **UI 框架** | 基于节点的 UI，支持 Immediate 模式、HUD 画布、布局系统 |
| **MainLoop** | 可插拔事件驱动的统一更新循环 |
| **任务系统** | 基于协程的异步任务调度器 |
| **数学库** | 几何工具、向量、矩阵、缓动函数、点集迭代器 |
| **碰撞检测** | AABB、OBB、圆形碰撞 |
| **资源系统** | 对象化资源加载，Shader 已完全对象化 |
| **渲染 (2D/3D)** | 2D 渲染稳定，3D 为实验性功能 |
| **输入系统** | 键盘、鼠标、手柄输入抽象 |
| **I18n** | 基于 CSV 的国际化方案 |
| **RNG** | 一致、可控的随机数生成器 |
| **VFS** | 虚拟文件系统，用于资源路径解析 |

### **STG —— 东方 STG 扩展库**

专为东方类弹幕射击游戏设计的独立模块：

| 功能 | 说明 |
|------|------|
| **玩家系统** | Profile 驱动的玩家，支持 Style、资源（残机/炸弹/火力/擦弹）、组件架构 |
| **敌机系统** | 敌机 Profile，行为树（移动、射击、等待、循环、并行） |
| **Boss 系统** | 符卡管理，基于 HP 的阶段切换，符卡得分加成 |
| **弹幕 - 子弹** | 直线弹与曲线弹工厂，Style 驱动的弹幕定义 |
| **弹幕 - 激光** | 直线激光、曲线激光，支持宽度与旋转 |
| **道具系统** | 火力、得分、残机、炸弹掉落，含自动收集机制 |
| **背景系统** | 视差滚动背景，支持纹理平铺 |
| **HUD** | 侧面板显示得分、最高分、火力、残机、炸弹、擦弹、FPS |
| **布局** | 游戏视口、侧面板、边框，逻辑/物理坐标映射 |
| **游戏流程** | 游戏中/暂停/Game Over 状态机 |
| **暂停菜单** | 游戏内暂停，支持继续、重新开始、返回标题 |
| **菜单系统** | 标题画面、关卡选择、设置、结算画面 |
| **录像** | 录像录制与回放（结构已建立） |
| **数据** | 得分追踪、最高分、成就系统 |
| **区域** | 游戏区域定义与边界规则 |

### **Test —— Core 模块演示**

将 Core 库的整个结构可视化，并包含使用示例：

- Camera 使用
- UI 渲染
- 可嵌入的暂停菜单
- 国际化（I18n）
- 对象与渲染的基本使用
- 逻辑测试 / 功能展示

是理解 Core 库结构的最佳入口。

---

## 设计约定

### 模块加载

所有代码模块通过各自的 `init.lua` **集中加载**，优势在于：

- 加载顺序显式可控
- 循环依赖问题集中管理
- `require` 路径与全局 API 命名空间一一对应：
  ```lua
  require("core.UI")      →  Core.UI
  require("core.Render")   →  Core.Render
  require("STG.Player")     →  STG.Player
  require("STG.Enemy")     →  STG.Enemy
  ```

### 目录命名规范

| 模式 | 含义 | 示例 |
|------|------|------|
| `PascalCase/` | 代码模块（可通过 require 加载） | `UI/`、`Render/`、`Player/` |
| `_前缀/` | 资源目录（不可 require） | `_Assets/`、`_Lang/`、`_Global/` |
| `PascalCase.lua` | 单文件代码模块 | `Class.lua`、`RNG.lua` |

### 编程风格规范（类 Java / C#）

| 类型 | 规则 | 示例 |
|------|------|------|
| 类名 | PascalCase | `Camera`, `Vector3`, `MainLoop` |
| 静态方法 | PascalCase | `Camera.New()` |
| 实例方法 | camelCase | `camera:setPosition()` |
| 常量 | UPPER_CASE | `EPSILON` |
| 私有变量 | lowercase | `cacheValue` |

---

## 素材来源与版权声明

### Test 中使用的素材：

- **天空盒（Skybox）**：来自 polyhaven.com
- **音乐**：由我本人制作
- **test.jpg**：由我本人制作

### Core/_Assets 中的通用素材：
均为 **可商用素材**。

部分模块引用他人逻辑，在源码中已标注来源。

---

## 开发状态

Cyanlib 仍在持续开发中，会伴随实际项目需求持续成长。

---

## 许可协议

Cyanlib 使用 **MIT License** 开源。
你可以自由使用、修改、引用、商用。

> 具体内容见 `LICENSE` 文件。

---

## 贡献

欢迎提交 Issue 与 PR，一起完善 LuaSTG-Cyanlib 的生态。

---

## 联系方式

QQ: 3082857745
Discord: cyoltose4769
邮箱：cyoltose@gmail.com
