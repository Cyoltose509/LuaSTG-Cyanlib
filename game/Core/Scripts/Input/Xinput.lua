---@class Core.Input.Xinput
local M = {}
Core.Input.Xinput = M

local xinput = require("xinput")

---@private
M.MaxSlot = 4
---@private
M.MapThreshold = 0.5

---@param index number
---@overload fun():number|boolean
--- 判断手柄是否已经连接
function M.IsConnected(index)
    if index and index > 0 and index <= M.MaxSlot then
        return xinput.isConnected(index)
    else
        for i = 1, M.MaxSlot do
            if xinput.isConnected(i) then
                return i
            end
        end
        return false
    end

end

local keyState = {}
local keyStatePre = {}

function M.IsPressed(key, index)
    if index and index > 0 and index <= M.MaxSlot then
        return keyState[index][key]
    else
        for i = 1, M.MaxSlot do
            if xinput.isConnected(i) and keyState[i][key] then
                return true
            end
        end
        return false
    end
end
function M.IsDown(key, index)
    if index and index > 0 and index <= M.MaxSlot then
        return keyState[index][key] and not keyStatePre[index][key]
    else
        for i = 1, M.MaxSlot do
            if xinput.isConnected(i) and keyState[i][key] and not keyStatePre[i][key] then
                return true
            end
        end
        return false
    end
end
function M.IsUp(key, index)
    if index and index > 0 and index <= M.MaxSlot then
        return not keyState[index][key] and keyStatePre[index][key]
    else
        for i = 1, M.MaxSlot do
            if xinput.isConnected(i) and not keyState[i][key] and keyStatePre[i][key] then
                return true
            end
        end
        return false
    end

end

local KEY_OFFSET = 0x200

---@class Core.Input.Xinput.Key
---range: 0x200~0x2FF
M.Key = {
    --- 仅用于兼容
    --Null = xinput.Null,
    --- 手柄方向键，上
    Up = KEY_OFFSET + 0,
    --- 手柄方向键，下
    Down = KEY_OFFSET + 1,
    --- 手柄方向键，左
    Left = KEY_OFFSET + 2,
    --- 手柄方向键，右
    Right = KEY_OFFSET + 3,
    --- 手柄 start 按键（一般作为菜单键使用）
    Start = KEY_OFFSET + 4,
    --- 手柄 back 按键（一般作为返回键使用）
    Back = KEY_OFFSET + 5,
    --- 手柄左摇杆按键（按压摇杆）
    LeftThumb = KEY_OFFSET + 6,
    --- 手柄右摇杆按键（按压摇杆）
    RightThumb = KEY_OFFSET + 7,
    --- 手柄左肩键
    LeftShoulder = KEY_OFFSET + 8,
    --- 手柄右肩键
    RightShoulder = KEY_OFFSET + 9,
    --- 手柄 A 按键
    A = KEY_OFFSET + 10,
    --- 手柄 B 按键
    B = KEY_OFFSET + 11,
    --- 手柄 X 按键
    X = KEY_OFFSET + 12,
    --- 手柄 Y 按键
    Y = KEY_OFFSET + 13,
    --- 手柄左扳机（在左肩键旁边），有的手柄可能没有
    LeftTrigger = KEY_OFFSET + 14,
    --- 手柄右扳机（在右肩键旁边），有的手柄可能没有
    RightTrigger = KEY_OFFSET + 15,

    LeftThumbPositiveX = KEY_OFFSET + 16,
    LeftThumbPositiveY = KEY_OFFSET + 17,
    RightThumbPositiveX = KEY_OFFSET + 18,
    RightThumbPositiveY = KEY_OFFSET + 19,
    LeftThumbNegativeX = KEY_OFFSET + 20,
    LeftThumbNegativeY = KEY_OFFSET + 21,
    RightThumbNegativeX = KEY_OFFSET + 22,
    RightThumbNegativeY = KEY_OFFSET + 23,
}

M.KeyTriggering = {}
for i = 1, M.MaxSlot do
    M.KeyTriggering[i] = {}
    for _, v in pairs(M.Key) do
        M.KeyTriggering[i][v] = Core.Input.NewTriggerRecord(v, (i - 1) * 25)
    end
end

--- 按键集，真实存在的按键，不是从轴映射而来
local button_set = {
    Up = xinput.Up,
    Down = xinput.Down,
    Left = xinput.Left,
    Right = xinput.Right,
    Start = xinput.Start,
    Back = xinput.Back,
    LeftThumb = xinput.LeftThumb,
    RightThumb = xinput.RightThumb,
    LeftShoulder = xinput.LeftShoulder,
    RightShoulder = xinput.RightShoulder,
    A = xinput.A,
    B = xinput.B,
    X = xinput.X,
    Y = xinput.Y,
}

local function map_axis(v, minv, maxv, threshold)
    if minv == maxv then
        return false, false
    end
    local center = (minv + maxv) / 2
    if v > center then
        local value = (v - center) / (maxv - center)
        return false, value >= threshold
    else
        local value = (v - center) / (center - minv)
        return value <= -threshold, false
    end
end

--- 将索引为 device_index 的设备的原始数据映射为按键
---@author 璀境石
---@param device_index number
---@private
function M.MapKeyStateFromIndex(device_index)
    local threshold = M.MapThreshold
    local ret = {}
    -- 映射按键部分
    for k, v in pairs(button_set) do
        ret[M.Key[k]] = xinput.getKeyState(device_index, v)
    end
    -- 映射左右扳机
    ret[M.Key.LeftTrigger] = xinput.getLeftTrigger(device_index) >= threshold
    ret[M.Key.RightTrigger] = xinput.getRightTrigger(device_index) >= threshold
    -- 映射左右摇杆
    ret[M.Key.LeftThumbNegativeX], ret[M.Key.LeftThumbPositiveX] = map_axis(xinput.getLeftThumbX(device_index), -1.0, 1.0, threshold)
    ret[M.Key.LeftThumbNegativeY], ret[M.Key.LeftThumbPositiveY] = map_axis(xinput.getLeftThumbY(device_index), -1.0, 1.0, threshold)
    ret[M.Key.RightThumbNegativeX], ret[M.Key.RightThumbPositiveX] = map_axis(xinput.getRightThumbX(device_index), -1.0, 1.0, threshold)
    ret[M.Key.RightThumbNegativeY], ret[M.Key.RightThumbPositiveY] = map_axis(xinput.getRightThumbY(device_index), -1.0, 1.0, threshold)
    return ret
end

local timer = 0
function M.Update()
    xinput.update()

    timer = timer + 1
    if timer % 60 == 0 then
        -- 刷新设备不那么频繁
        M.MaxSlot = xinput.refresh()
    end
    for i = 1, M.MaxSlot do
        if xinput.isConnected(i) then
            keyStatePre[i] = keyState[i] or {}
            keyState[i] = M.MapKeyStateFromIndex(i)
            Core.Input.KeyTriggerUpdate(M.KeyTriggering[i], keyState[i])
        end
    end

end

function M.GetLast(index)
    if index and index > 0 and index <= M.MaxSlot then
        return Core.Input.GetLastTrigger(M.KeyTriggering[index])
    else
        local triggered
        for i = 1, M.MaxSlot do
            if xinput.isConnected(i) then
                triggered = Core.Input.GetLastTrigger(M.KeyTriggering[i])
                if triggered then
                    return triggered
                end
            end
        end
        return nil
    end
end

M.GetLeftTrigger = xinput.getLeftTrigger
M.GetRightTrigger = xinput.getRightTrigger
M.GetLeftThumbX = xinput.getLeftThumbX
M.GetLeftThumbY = xinput.getLeftThumbY
M.GetRightThumbX = xinput.getRightThumbX
M.GetRightThumbY = xinput.getRightThumbY

---设置按键映射的阈值
function M.SetThreshold(thres)
    M.MapThreshold = thres or 0.5
end

function M.GetMaxSlot()
    return M.MaxSlot
end

local keyName = {}
for k, v in pairs(M.Key) do
    keyName[v] = k
end
function M.GetKeyName(code)
    return keyName[code]
end

