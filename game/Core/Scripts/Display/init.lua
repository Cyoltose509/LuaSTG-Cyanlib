---@class Core.Display
---@field Screen Core.Display.Screen
---@field Window Core.Display.Window
---@field Camera Core.Display.Camera
---@field Camera2D fun():Core.Display.Camera2D
---@field Camera3D fun():Core.Display.Camera3D
---@field Camera2DController fun(camera:Core.Display.Camera2D):Core.Display.Camera2DController
---@field Camera3DController fun(camera:Core.Display.Camera3D):Core.Display.Camera3DController
local M = {}
Core.Display = M

require("Core.Scripts.Display.Screen")
require("Core.Scripts.Display.Window")
require("Core.Scripts.Display.Camera")
require("Core.Scripts.Display.Camera2D")
require("Core.Scripts.Display.Camera3D")
require("Core.Scripts.Display.Camera2DController")
require("Core.Scripts.Display.Camera3DController")

local Display = require("lstg.Display")
---@type lstg.Display
local main_display
for _, d in ipairs(Display.getAll()) do
    if d:isPrimary() then
        main_display = d
    end
end

---在响应式布局下更新屏幕分辨率
---Update the screen resolution in responsive layout
function M.Update()
    if M.Screen.responsive_layout then
        local curW, curH = M.Window.GetClientAreaSize()
        if curW == 0 or curH == 0 then
            return
        end
        local lastW, lastH = M.Window.GetSize()
        if not M.Window.fullscreen then
            if curW ~= lastW or curH ~= lastH then
                M.Window.SetSize(curW, curH)
                M.Screen.Reset(curW, curH)
            end
        end
    end
end

---导入设置
---Import settings
function M.Import(set)
    set = set or Core.Data.Setting.Get()
    local gs = set.graphics_system
    M.Window.width = gs.width or 1280
    M.Window.height = gs.height or 720
    M.Window.fullscreen = gs.fullscreen or false
    M.Window.vsync = gs.vsync or true
    M.Screen.scale_factor = set.ui_scaling or 1
end

---导出设置
---Export settings
function M.Export(set)
    set = set or Core.Data.Setting.Get()
    local gs = set.graphics_system
    gs.width = M.Window.width
    gs.height = M.Window.height
    gs.fullscreen = M.Window.fullscreen
    gs.vsync = M.Window.vsync
    set.ui_scaling = M.Screen.scale_factor
end

---获取显示器分辨率
---Get the resolution of the display
function M.GetSize()
    local w, h = 1280, 720
    if main_display then
        local size = main_display:getSize()
        w, h = size.width, size.height
    end
    return w, h
end

---获取显示器位置
---Get the position of the display
function M.GetPosition()
    if main_display then
        local pos = main_display:getPosition()
        return pos.x, pos.y
    else
        return 0, 0
    end
end

---获取显示器矩形
---Get the rectangle of the display
function M.GetRect()
    if main_display then
        local rect = main_display:getRect()
        return rect.left, rect.right, rect.bottom, rect.top
    else
        return 0, 0, 0, 0
    end
end

---获取工作区大小
---Get the size of the work area
function M.GetWorkAreaSize()
    if main_display then
        local size = main_display:getWorkAreaSize()
        return size.width, size.height
    else
        return 1280, 720
    end
end

---获取工作区位置
---Get the position of the work area
function M.GetWorkAreaPosition()
    if main_display then
        local pos = main_display:getWorkAreaPosition()
        return pos.x, pos.y
    else
        return 0, 0
    end

end

---获取工作区矩形
---Get the rectangle of the work area
function M.GetWorkAreaRect()
    if main_display then
        local rect = main_display:getWorkAreaRect()
        return rect.left, rect.right, rect.bottom, rect.top
    else
        return 0, 0, 0, 0
    end
end

---获取缩放比例
---Get the scale factor
function M.GetScale()
    if main_display then
        return main_display:getDisplayScale()
    else
        return 1
    end
end


M.EnumGPUs = lstg.EnumGPUs
M.ChangeGPU = lstg.ChangeGPU
