---@class Core.UI
---@field Manager Core.UI.Manager
---@field Root Core.UI.Root.New @用于管理UI的根节点，负责管理所有UI节点的生命周期和渲染。请通过Core.UI.Manager.CreateRoot来创建根节点
---@field Child Core.UI.Child.New @UI节点的基类
---@field Layout Core.UI.Layout @用于管理UI节点的布局，负责节点的位置和尺寸的计算
---@field Immediate Core.UI.Immediate.New @创建即时计算即时渲染的UI节点
---@field Text Core.UI.Text.New @用于创建文本节点，可以显示文本内容
---@field Image Core.UI.Image.New @用于创建图片节点，可以显示图片
---@field Animation Core.UI.Animation.New @用于创建动画节点，可以播放动画
---@field TextureRect Core.UI.TextureRect.New @用于创建纹理矩形节点，可以显示纹理内容
local M = {}
Core.UI = M

---@type Core.Display.Camera2D
---UI渲染的默认摄像机
---最好不要轻易修改这个摄像机，除非你知道你在做什么
---Default camera for UI rendering.
---Do not modify this camera unless you know what you are doing.
M.Camera = Core.Display.Camera2D():setResponsiveViewport(true)

---@param worldCamera Core.Display.Camera.Base
function M.Camera:worldToUI(worldCamera, x, y, z)
    local sx, sy = worldCamera:worldToScreen(x, y, z)
    return self:screenToWorld(sx, sy)
end

require("Core.Scripts.UI.Root")
require("Core.Scripts.UI.Child")

require("Core.Scripts.UI.Layout")
require("Core.Scripts.UI.Immediate")
require("Core.Scripts.UI.Animation")
require("Core.Scripts.UI.Image")
require("Core.Scripts.UI.Text")
require("Core.Scripts.UI.TextureRect")

require("Core.Scripts.UI.Manager")
