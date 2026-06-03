---@class Test.STG.UI
local M = {}
Test.STG.UI = M

M.keyTriggerShow = true

local Core = Core
local UI = Core.UI
local Render = Core.Render
local Color = Core.Render.Color

local Debug = Core.Lib.Debug

function M.Main(self)
    --   local root = UI.Manager.CreateHUDRoot("Test.Main", 1)
    local hud_root = UI.Manager.CreateHUDRoot("Test.HUD", 1)
    hud_root:addChild(UI.Immediate("FPS", 0, function()
        local hud = UI.Camera:getView()
        Render.Text("exo2", ("%.1f"):format(lstg.GetFPS()), hud.right - 20, hud.top - 30,
                1, Color(150, 255, 255, 255), "right")
    end))


    return hud_root
end
