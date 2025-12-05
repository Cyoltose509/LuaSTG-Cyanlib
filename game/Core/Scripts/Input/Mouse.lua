---@class Core.Input.Mouse
local M = {}
Core.Input.Mouse = M

M.x = 0
M.y = 0
M.last_x = 0
M.last_y = 0
M.dx = 0
M.dy = 0

M.wheel = 0

local keyState = {}
local keyStatePre = {}

function M.IsPressed(key)
    return keyState[key]
end
function M.IsUp(key)
    return not keyState[key] and keyStatePre[key]
end
function M.IsDown(key)
    return keyState[key] and not keyStatePre[key]
end

---Get the position of the mouse cursor on the screen.
---If the camera is provided, the position will be converted to the world space.
---@param camera nil|Core.Display.Camera
---@param simulated_z nil|number @ simulated z value for 3D camera
function M.GetPosition(camera, simulated_z)
    if camera and camera.screenToWorld then
        return camera:screenToWorld(M.x, M.y, simulated_z)
    end
    return M.x, M.y
end

---Get the delta of the mouse cursor position since the last frame.
---@param camera nil|Core.Display.Camera
---@param simulated_z nil|number @ simulated z value for 3D camera
function M.GetDelta(camera, simulated_z)
    if camera and camera.screenToWorld then
        local dx, dy = camera:screenToWorld(M.dx, M.dy, simulated_z)
        local x0, y0 = camera:screenToWorld(0, 0, simulated_z)
        return dx - x0, dy - y0
    end
    return M.dx, M.dy
end

function M.GetWheel()
    return M.wheel
end

function M.IsStatic()
    local click = false
    for i = 1, 5 do
        click = click or keyState[i] or keyStatePre[i]
        if click then
            break
        end
    end
    return M.dx == 0 and M.dy == 0 and M.wheel == 0 and not click
end

local KEY_OFFSET = 0x100
---@class Core.Input.Mouse.Key
---range: 0x100~0x1FF
M.Key = {
    Left = 0 + KEY_OFFSET,
    Middle = 1 + KEY_OFFSET,
    Right = 2 + KEY_OFFSET,
    X1 = 3 + KEY_OFFSET,
    X2 = 4 + KEY_OFFSET,
}

M.KeyTriggering = {}
for _, v in pairs(M.Key) do
    M.KeyTriggering[v] = Core.Input.NewTriggerRecord(v)
end

function M.Update()
    M.last_x, M.last_y = M.x, M.y
    local x, y = lstg.GetMousePosition()
    if Core.Math.IsReal(x) then
        --这b屎山什么时候改
        M.x, M.y = x, y
    end
    M.dx, M.dy = M.x - M.last_x, M.y - M.last_y
    for i = 0, 4 do
        local key = i + KEY_OFFSET
        keyStatePre[key] = keyState[key]
        keyState[key] = lstg.GetMouseState(i)
    end
    M.wheel = lstg.GetMouseWheelDelta()
    Core.Input.KeyTriggerUpdate(M.KeyTriggering, keyState)
end

function M.GetLast()
    return Core.Input.GetLastTrigger(M.KeyTriggering)
end

local keyName = {}
for k, v in pairs(M.Key) do
    keyName[v] = k
end
function M.GetKeyName(code)
    return keyName[code]
end