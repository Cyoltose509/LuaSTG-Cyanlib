---@class Core.MainLoop
local M = {}
Core.MainLoop = M

M.HasInitialized = false
M.ExitFlag = false
M.EventListener = Core.Lib.EventListener()
M.Ticker = 0
M.Speed = 1

M.Label = {
    Gameplay = "Gameplay",
    Other = "Other",
}
M.LoopGroup = {
    Init = {},
    Exit = {},
    FocusLose = {},
    FocusGain = {},
    SceneChangeBefore = {},
    SceneChangeAfter = {},
    Frame = {},
    Render = {},
    Custom = {},
}
---Defines a new event group in the loop group table.
---@param loopGroup string The loop group to define the event group in.
---@param name string The name of the event group.
---@param action fun(self:Core.MainLoop.EventGroup) The action to perform when the event group is dispatched.
function M.DefineEventGroup(loopGroup, name, levelOption, action)
    assert(type(name) == "string" and name ~= "", "Invalid event group name")
    assert(type(loopGroup) == "string" and loopGroup ~= "", "Invalid loop group name")
    M.LoopGroup[loopGroup] = M.LoopGroup[loopGroup] or {}
    assert(not M.LoopGroup[loopGroup][name], ("Event group '%s' is already defined"):format(name))
    local _name = loopGroup .. "." .. name
    M.EventListener:create(_name)
    ---@class Core.MainLoop.EventGroup
    local eventGroup = {
        name = name,
        realName = _name,
        action = action or function(self)
            M.EventListener:dispatch(self.realName)
        end,
    }
    M.LoopGroup[loopGroup][name] = eventGroup
    table.insert(M.LoopGroup[loopGroup], eventGroup)
    if levelOption then
        M._ReorderGroup(M.LoopGroup[loopGroup], eventGroup, levelOption)
    end

    return eventGroup
end

---@private
function M._ReorderGroup(loopGroup, group, opt)
    if not opt then
        return
    end
    local order = loopGroup
    local function find(name)
        for i, g in ipairs(order) do
            if g.name == name then
                return i
            end
        end
    end

    local idx = find(group.name)
    if not idx then
        return
    end

    if opt.before then
        local target = find(opt.before)
        if target then
            table.remove(order, idx)
            table.insert(order, target, group)
        end
    elseif opt.after then
        local target = find(opt.after)
        if target then
            table.remove(order, idx)
            table.insert(order, target + 1, group)
        end
    end
end

function M.DoLoopGroup(loopGroup, ...)
    for _, eventGroup in ipairs(loopGroup) do
        eventGroup:action(...)
    end
end
M.DefineEventGroup("Init", "Default")
M.DefineEventGroup("Exit", "Default")

M.DefineEventGroup("FocusLose", "Default")
M.DefineEventGroup("FocusGain", "Default")
M.DefineEventGroup("SceneChangeBefore", "Default")
M.DefineEventGroup("SceneChangeAfter", "Default")

M.DefineEventGroup("Frame", "Before")
M.DefineEventGroup("Frame", "Gameplay", nil, function(self)
    M.Ticker = M.Ticker + M.Speed
    while M.Ticker > 0 do
        M.EventListener:dispatch(self.realName)
        M.Ticker = M.Ticker - 1
    end
end)
M.DefineEventGroup("Frame", "After")

M.DefineEventGroup("Render", "Default")

function M.EnableLabel(label)
    M.EventListener:enableByLabel(label)
end
function M.DisableLabel(label)
    M.EventListener:disableByLabel(label)
end

function M.Init()
    M.HasInitialized = true
    M.DoLoopGroup(M.LoopGroup.Init)
end

function M.Exit()
    M.DoLoopGroup(M.LoopGroup.Exit)
end

function M.OnFocusLose()
    M.DoLoopGroup(M.LoopGroup.FocusLose)
end

function M.OnFocusGain()
    M.DoLoopGroup(M.LoopGroup.FocusGain)
end

function M.OnSceneChangeBefore()
    M.DoLoopGroup(M.LoopGroup.SceneChangeBefore)
end

function M.OnSceneChangeAfter()
    M.DoLoopGroup(M.LoopGroup.SceneChangeAfter)
end

function M.Frame()
    M.DoLoopGroup(M.LoopGroup.Frame)
    return M.ExitFlag
end

function M.Render()
    lstg.BeginScene()
    M.DoLoopGroup(M.LoopGroup.Render)
    lstg.EndScene()
end

---Adds an event to the specified loop group and event group.
---@param loopGroup string The loop group to add the event to.
---@param eventGroup string The event group to add the event to.
---@param opt Core.Lib.EventListener.EventOption The options for the event.
function M.AddEvent(loopGroup, eventGroup, opt)
    assert(M.LoopGroup[loopGroup], "Invalid loop group")
    assert(M.LoopGroup[loopGroup][eventGroup], "Invalid event group")
    local group = M.LoopGroup[loopGroup][eventGroup].realName
    M.EventListener:addEventAdvanced(group, opt)
end
--[[
M.AddEvent("Init", "Default", {
    name = "...",
    func = function()
    end,
    before = "...",
    labels = { "..." },
})--]]
function M.RemoveEvent(loopGroup, eventGroup, name)
    assert(M.LoopGroup[loopGroup], "Invalid loop group")
    assert(M.LoopGroup[loopGroup][eventGroup], "Invalid event group")
    local group = M.LoopGroup[loopGroup][eventGroup].realName
    M.EventListener:remove(group, name)
end

function M.SetSpeed(speed)
    M.Speed = speed
end

function M.GetEventListener()
    return M.EventListener
end

GameInit = M.Init
GameExit = M.Exit
FrameFunc = M.Frame
RenderFunc = M.Render
FocusLoseFunc = M.OnFocusLose
FocusGainFunc = M.OnFocusGain

require("Core.Scripts.MainLoop.Initialization")