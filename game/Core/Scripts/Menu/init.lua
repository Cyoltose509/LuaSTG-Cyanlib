---@class Core.Menu
---@field Base Core.Menu.Base
local M = {}
Core.Menu = M

M.DEFAULT_CAMERA_OBJECT_NAME = "Core.Menu.Stack"
---@type Core.Display.Camera.Base
M.current_camera = nil
---@type Core.Menu.Base[]
M.stack = {}

---@type Core.Menu.Base[]
M.pop_up = {}

function M.Pop()
    local n = #M.stack
    M.stack[n]:release()
    M.stack[n] = nil
end
function M.Update(dt)
    for _, menu in ipairs(M.stack) do
        menu:update(dt)
    end
    for i = #M.pop_up, 1, -1 do
        local menu = M.pop_up[i]
        menu:update(dt)
        if menu:isKilled() then
            table.remove(M.pop_up, i)
        end
    end
end

---传入鼠标坐标
function M.UpdateInput(x, y)
    local flag = false
    for i = #M.stack, 1, -1 do
        local menu = M.stack[i]
        if menu:updateInput(x, y) then
            return true
        end

    end
    return flag
end

---@param camera Core.Display.Camera.Base
function M.RegisterCamera(camera, layer)
    if M.current_camera and not M.current_camera._is_released then
        M.current_camera:removeAfterRenderEvent(M.DEFAULT_CAMERA_OBJECT_NAME)
    end
    M.current_camera = camera
    M.current_camera:addAfterRenderEvent(M.DEFAULT_CAMERA_OBJECT_NAME, layer or 0, function()
        for _, menu in ipairs(M.stack) do
            menu:render()
        end
        for _, menu in ipairs(M.pop_up) do
            menu:render()
        end
    end)
end

function M.Release()
    if M.current_camera and not M.current_camera._is_released then
        M.current_camera:removeAfterRenderEvent(M.DEFAULT_CAMERA_OBJECT_NAME)
        M.current_camera = nil
    end
    for _, menu in ipairs(M.stack) do
        menu:release()
    end
    for _, menu in ipairs(M.simple_list) do
        menu:release()
    end
end

---@generic T
---@param menu_class T
---@param opt T
function M.Push(menu_class, opt)
    local m = menu_class(opt or {})
    M.stack[#M.stack + 1] = m
    return m
end

---@generic T
---@param pop_up_class T
---@param opt T
function M.AddPopUp(pop_up_class, opt)
    local m = pop_up_class(opt or {})
    M.pop_up[#M.pop_up + 1] = m
    return m
end

require("Core.Scripts.Menu.Base")
