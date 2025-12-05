---@class Core.Input
---@field Keyboard Core.Input.Keyboard
---@field Mouse Core.Input.Mouse
---@field Xinput Core.Input.Xinput
local M = {}
Core.Input = M

--TODO:是否需要做Dinput的支持？

---@alias Core.Input.Key Core.Input.Keyboard.Key|Core.Input.Xinput.Key|Core.Input.Mouse.Key
---@alias Core.Input.Device Core.Input.Keyboard|Core.Input.Mouse|Core.Input.Xinput

local bit = require("bit")

---@alias Core.Input.Button table<Core.Input.Key, boolean>
---@type Core.Input.Button[]
M.Buttons = {}
---@type Core.Input.Axis[]
M.Axes = {}



--- Register a button with optional keyboard, xinput, and mouse bindings.
---@param name string
---@param keys Core.Input.Key[]
function M.RegisterButton(name, keys)
    assert(type(name) == "string", "Button name must be string")
    assert(type(keys) == "table", "Keys must be a table")
    local list = M.Buttons[name]
    if not list then
        list = {}
        M.Buttons[name] = list
    end
    for _, key in ipairs(keys or {}) do
        list[key] = true
    end
end

--- Unregister specific keys or the entire button.
---@param name string
---@param keys Core.Input.Key[]|nil
function M.UnregisterButton(name, keys)
    local set = M.Buttons[name]
    if not set then
        return
    end
    if keys then
        for _, key in ipairs(keys) do
            set[key] = nil
        end
        if next(set) == nil then
            M.Buttons[name] = nil
        end
    else
        M.Buttons[name] = nil
    end
end

function M.ButtonPressed(name)
    local btn = M.Buttons[name]
    if not btn then
        return false
    end
    for key in pairs(btn) do
        if M.IsPressed(key) then
            return true
        end
    end
    return false
end

function M.ButtonDown(name)
    local btn = M.Buttons[name]
    if not btn then
        return false
    end
    for key in pairs(btn) do
        if M.IsDown(key) then
            return true
        end
    end
    return false
end

function M.ButtonUp(name)
    local btn = M.Buttons[name]
    if not btn then
        return false
    end
    for key in pairs(btn) do
        if M.IsUp(key) then
            return true
        end
    end
    return false
end

--- Register an axis with left and right functions and optional smooth strength.
--- The left and right functions should return true if the respective direction is active.
--- The smooth strength is a value between 0 and 1 that controls the smoothing of the axis.
---@param name string The name of the axis.
---@param leftfunc fun():boolean The function to call when the left direction is active.
---@param rightfunc fun():boolean The function to call when the right direction is active.
---@param smoothStrength number
---@return Core.Input.Axis
function M.RegisterAxis(name, leftfunc, rightfunc, smoothStrength)
    assert(type(leftfunc) == "function", "Left function must be a function")
    assert(type(rightfunc) == "function", "Right function must be a function")
    smoothStrength = clamp(smoothStrength or 1, 0, 1)
    ---@class Core.Input.Axis
    local axisUnit = {
        name = name,
        left = leftfunc,
        right = rightfunc,
        value = 0,
        left_timer = 0,
        right_timer = 0,
        smooth = smoothStrength,
    }
    M.Axes[name] = axisUnit
    return axisUnit
end

function M.UnregisterAxis(name)
    if M.Axes[name] then
        M.Axes[name] = nil
    end
end

function M.GetAxis(name)
    local axis = M.Axes[name]
    if not axis then
        return 0
    end
    return axis.value
end

function M.AxisUpdate()
    for _, axis in pairs(M.Axes) do
        local left = axis.left()
        local right = axis.right()
        local value = 0
        if left then
            axis.left_timer = axis.left_timer + 1
            value = value - 1
        else
            axis.left_timer = 0
        end
        if right then
            axis.right_timer = axis.right_timer + 1
            value = value + 1
        else
            axis.right_timer = 0
        end
        if left and right then
            if axis.left_timer < axis.right_timer then
                value = -1
            elseif axis.left_timer > axis.right_timer then
                value = 1
            end
        end
        axis.value = axis.value + (value - axis.value) * axis.smooth

    end
end

function M.Update()
    M.Keyboard.Update()
    M.Mouse.Update()
    M.Xinput.Update()
    M.AxisUpdate()
end

---触发重复按键的间隔
M.REPEAT_INTERVAL = 2
---触发重复按键的延迟
M.REPEAT_DELAY = 30

M.TriggerList = {}
---用于记录触发的按键
function M.NewTriggerRecord(key, offset)
    offset = offset or 0
    ---@class Core.Input.TriggerRecord
    local m = {
        key = key,
        down = false,
        timer = 0,
        triggered = false,
    }
    M.TriggerList[key] = m
    return m
end
---@param triggerList Core.Input.TriggerRecord[]
---@param keyState table<Core.Input.Key, boolean>
function M.KeyTriggerUpdate(triggerList, keyState)
    for key, state in pairs(triggerList) do
        state.down = keyState[key]
        state.triggered = false
        if state.down then
            state.timer = state.timer + 1
            if state.timer == 1 then
                state.triggered = true
            elseif state.timer > M.REPEAT_DELAY and state.timer % M.REPEAT_INTERVAL == 0 then
                state.triggered = true
            end
        else
            state.timer = 0
        end

    end
end
---@param triggerList Core.Input.TriggerRecord[]
function M.GetLastTrigger(triggerList)
    ---@type Core.Input.TriggerRecord
    local last
    for _, state in pairs(triggerList) do
        if state.down and (not last or state.timer < last.timer) then
            last = state
        end
    end
    if last and last.triggered then
        return last.key
    else
        return nil
    end
end

function M.GetLast()
    return M.GetLastTrigger(M.TriggerList)
end

require("Core.Scripts.Input.Keyboard")
require("Core.Scripts.Input.Mouse")
require("Core.Scripts.Input.Xinput")

---@type Core.Input.Device[]
local DeviceMap = {
    [0x0000] = M.Keyboard,
    [0x0100] = M.Mouse,
    [0x0200] = M.Xinput,
}
local DeviceNames = {
    [0x0000] = "Keyboard",
    [0x0100] = "Mouse",
    [0x0200] = "Xinput",
}

function M.IsDown(keyCode)
    local dev = DeviceMap[bit.band(keyCode, 0xFF00)]
    return dev and dev.IsDown(keyCode) or false
end

function M.IsPressed(keyCode)
    local dev = DeviceMap[bit.band(keyCode, 0xFF00)]
    return dev and dev.IsPressed(keyCode) or false
end

function M.IsUp(keyCode)
    local dev = DeviceMap[bit.band(keyCode, 0xFF00)]
    return dev and dev.IsUp(keyCode) or false
end

function M.GetKeyName(keyCode, prefix)
    local h = bit.band(keyCode, 0xFF00)
    local dev = DeviceMap[h]
    local name = dev and dev.GetKeyName(keyCode) or "Unknown"
    if prefix then
        return DeviceNames[h] .. "." .. name
    else
        return name
    end
end

---初始化输入模块
---定义一些常用的按钮和虚拟轴，便于使用
---Initialize the input module.
---Define some common buttons and virtual axes, which can be used easily.
function M.Init()
    local keyboard = M.Keyboard
    M.RegisterAxis("MoveRight", function()
        return keyboard.IsPressed(keyboard.Key.A)
    end, function()
        return keyboard.IsPressed(keyboard.Key.D)
    end, 0.2)
    M.RegisterAxis("MoveUp", function()
        return keyboard.IsPressed(keyboard.Key.Shift)
    end, function()
        return keyboard.IsPressed(keyboard.Key.Space)
    end, 0.2)
    M.RegisterAxis("MoveForward", function()
        return keyboard.IsPressed(keyboard.Key.S)
    end, function()
        return keyboard.IsPressed(keyboard.Key.W)
    end, 0.2)
end
