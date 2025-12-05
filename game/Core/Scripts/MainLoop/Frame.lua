---@class Core.MainLoop.Frame
local M = {}
Core.MainLoop.Frame = M

M.Label = {
    Gameplay = "Gameplay",
    Other = "Other",
}
M.Group = {
    Before = "frame.Before",
    Game = "frame.Game",
    After = "frame.After",
}

M.Ticker = 0
M.Speed = 1

M.ExitFlag = false

local eventListener = Core.MainLoop.EventListener
eventListener:create(M.Group.Before)
eventListener:create(M.Group.Game)
eventListener:create(M.Group.After)
function M.SetSpeed(speed)
    M.Speed = speed
end

function M.Run()
    M.Ticker = M.Ticker + M.Speed
    eventListener:dispatch(M.Group.Before)
    while M.Ticker > 0 do
        eventListener:dispatch(M.Group.Game)
        M.Ticker = M.Ticker - 1
    end
    eventListener:dispatch(M.Group.After)
    return M.ExitFlag
end

function M.EnableLabel(label)
    eventListener:enableByLabel(label)
end
function M.DisableLabel(label)
    eventListener:disableByLabel(label)
end
---增加先前事件
---Add a previous event
---@param label string 可以被统一开启和关闭的事件标签，可以用于暂停
function M.AddBeforeEvent(name, level, func, label)
    eventListener:addEvent(M.Group.Before, name, level, func, label)
end
---增加游戏事件
---这里的事件会受游戏速度影响
---Add a game event
---The event here will be affected by the game speed
---@param label string 可以被统一开启和关闭的事件标签，可以用于暂停
function M.AddGameEvent(name, level, func, label)
    eventListener:addEvent(M.Group.Game, name, level, func, label)
end
---增加后续事件
---Add a subsequent event
---@param label string 可以被统一开启和关闭的事件标签，可以用于暂停
function M.AddAfterEvent(name, level, func, label)
    eventListener:addEvent(M.Group.After, name, level, func, label)
end

function M.GetEventLevel(group, name)
    local find = eventListener:find(group, name)
    if find then
        return find.level
    else
        return 0
    end
end

function M.RemoveBeforeEvent(name)
    eventListener:remove(M.Group.Before, name)
end
function M.RemoveGameEvent(name)
    eventListener:remove(M.Group.Game, name)
end
function M.RemoveAfterEvent(name)
    eventListener:remove(M.Group.After, name)
end
FrameFunc = M.Run