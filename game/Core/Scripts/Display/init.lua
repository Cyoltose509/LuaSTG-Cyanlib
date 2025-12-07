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
local main_display
for _, d in ipairs(Display.getAll()) do
    if d:isPrimary() then
        main_display = d
    end
end
function M.GetResolution()
    local w, h = 1280, 720
    if main_display then
        local size = main_display:getSize()
        w, h = size.width, size.height
    end
    return w, h
end

function M.Update()
    if M.Screen.ResponsiveLayout then
        local curW, curH = M.Window.GetClientAreaSize()
        if curW == 0 or curH == 0 then
            return
        end
        local set = Core.Data.Setting.Get()
        local lastW, lastH = M.Window.GetSize()
        if not set.graphics_system.fullscreen then
            if curW ~= lastW or curH ~= lastH then
                M.Window.SetSize(curW, curH)
                M.Screen.Reset()
                --Core.Data.Setting.Save() TODO
            end
        end
    end
end

M.SetFPS = lstg.SetFPS
M.GetFPS = lstg.GetFPS
M.EnumGPUs = lstg.EnumGPUs
M.ChangeGPU = lstg.ChangeGPU
