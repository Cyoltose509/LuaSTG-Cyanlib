---@class Core.MainLoop
---@field Frame Core.MainLoop.Frame
---@field Render Core.MainLoop.Render
local M = {}
Core.MainLoop = M
M.HasStarted = false

M.EventListener = Core.Lib.EventListener()

M.EventListener:create("start")
M.EventListener:create("exit")

M.EventListener:create("onFocusLoseFunc")
M.EventListener:create("onFocusGainFunc")

M.EventListener:create("onSceneChange.Before")
M.EventListener:create("onSceneChange.After")

function M.Start()
    M.EventListener:dispatch("start")
    M.HasStarted = true
end

function M.Exit()
    M.EventListener:dispatch("exit")
end

function M.AddStartEvent(name, level, func)
    M.EventListener:addEvent("start", name, level, func)
end

function M.AddExitEvent(name, level, func)
    M.EventListener:addEvent("exit", name, level, func)
end

function M.RemoveStartEvent(name)
    M.EventListener:remove("start", name)
end

function M.RemoveExitEvent(name)
    M.EventListener:remove("exit", name)
end

function M.OnFocusLose()
    M.EventListener:dispatch("onFocusLoseFunc")
end

function M.OnFocusGain()
    M.EventListener:dispatch("onFocusGainFunc")
end

function M.AddOnFocusLoseEvent(name, level, func)
    M.EventListener:addEvent("onFocusLoseFunc", name, level, func)

end
function M.AddOnFocusGainEvent(name, level, func)
    M.EventListener:addEvent("onFocusGainFunc", name, level, func)
end

function M.RemoveOnFocusLoseEvent(name)
    M.EventListener:remove("onFocusLoseFunc", name)
end
function M.RemoveOnFocusGainEvent(name)
    M.EventListener:remove("onFocusGainFunc", name)
end

function M.OnSceneChangeBefore()
    M.EventListener:dispatch("onSceneChange.Before")
end
function M.OnSceneChangeAfter()
    M.EventListener:dispatch("onSceneChange.After")
end

function M.AddOnSceneChangeBeforeEvent(name, level, func)
    M.EventListener:addEvent("onSceneChange.Before", name, level, func)
end
function M.AddOnSceneChangeAfterEvent(name, level, func)
    M.EventListener:addEvent("onSceneChange.After", name, level, func)
end

function M.RemoveOnSceneChangeBeforeEvent(name)
    M.EventListener:remove("onSceneChange.Before", name)
end
function M.RemoveOnSceneChangeAfterEvent(name)
    M.EventListener:remove("onSceneChange.After", name)
end

require("Core.Scripts.MainLoop.Frame")
require("Core.Scripts.MainLoop.Render")

GameInit = M.Start
GameExit = M.Exit

FocusLoseFunc = M.OnFocusLose
FocusGainFunc = M.OnFocusGain

require("Core.Scripts.MainLoop.Initialization")