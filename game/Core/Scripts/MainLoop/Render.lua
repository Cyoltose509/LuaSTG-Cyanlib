---@class Core.MainLoop.Render
local M = {}
Core.MainLoop.Render = M

local eventListener = Core.MainLoop.EventListener
eventListener:create("render")


function M.Run()
    lstg.BeginScene()
    eventListener:dispatch("render")
    lstg.EndScene()
end

function M.AddEvent(name, level, func)
    eventListener:addEvent("render", name, level, func)
end

function M.RemoveEvent(name)
    eventListener:remove("render", name)
end

RenderFunc = M.Run