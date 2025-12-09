---@class Core.Display.Screen
local M = {}
Core.Display.Screen = M

M.responsive_layout = true
M.resolution_x = 960
M.resolution_y = 540
M.scale_factor = 1

local screen = {
    width = 400,
    height = 400,
    hScale = 1,
    vScale = 1,
    resScale = 1,
    scale = 1,
    dx = 0,
    dy = 0,
}

---获取逻辑屏幕的大小
---Get the size of the logical screen.
function M.GetSize()
    return screen.width, screen.height
end

---获取逻辑屏幕相对于物理屏幕的缩放比例
---Get the scale factor of the logical screen relative to the physical screen.
function M.GetScale()
    return screen.scale
end

local cameras = setmetatable({}, { __mode = "v" })
local screenCallbacks = {}

---为屏幕注册摄像机
---注册的摄像机会在屏幕大小变化时自动重置
---Register a camera for the screen.
---The registered camera will be reset automatically when the screen size changes.
---@param cam Core.Display.Camera.Base
function M.RegisterCamera(cam)
    for _, c in ipairs(cameras) do
        if c == cam then
            return
        end
    end
    table.insert(cameras, cam)
    cam:reset()
end

---取消注册摄像机
---Unregister a camera for the screen.
---@param cam Core.Display.Camera.Base
function M.UnregisterCamera(cam)
    for i = #cameras, 1, -1 do
        if cameras[i] == cam then
            table.remove(cameras, i)
            return
        end
    end
end

---注册一个回调函数
---注册的回调函数会在屏幕大小变化时自动调用
---Register a callback function.
---The registered callback function will be called automatically when the screen size changes.
---@param name string
---@param cb fun()
function M.RegisterCallback(name, cb)
    screenCallbacks[name] = cb
end

---取消注册回调函数
---Unregister a callback function.
function M.UnregisterCallback(name)
    screenCallbacks[name] = nil
end

function M.Reset()
    local resx, resy = Core.Display.Window.GetSize()
    if M.responsive_layout then
        local FullW, FullH = Core.Display.GetSize()
        local scale = resx / resy
        local _fullW, _fullH
        if scale > 1 then
            _fullW, _fullH = FullH * scale, FullH
        else
            _fullW, _fullH = FullH, FullH / scale
        end
        local ui_scale = M.scale_factor / 100
        _fullW = _fullW / ui_scale
        _fullH = _fullH / ui_scale
        screen.width = _fullW --/ 2
        screen.height = _fullH --/ 2
    else
        screen.width = M.resolution_x
        screen.height = M.resolution_y
    end
    screen.hScale = resx / screen.width
    screen.vScale = resy / screen.height
    screen.resScale = resx / resy
    screen.scale = min(screen.hScale, screen.vScale)
    if screen.resScale >= (screen.width / screen.height) then
        screen.dx = (resx - screen.scale * screen.width) * 0.5
        screen.dy = 0
    else
        screen.dx = 0
        screen.dy = (resy - screen.scale * screen.height) * 0.5
    end
    for _, cam in ipairs(cameras) do
        if cam.reset then
            cam:reset()
        end
    end
    for _, cb in pairs(screenCallbacks) do
        cb()
    end
end

---设置是否使用响应式布局
---默认启用
---响应式布局：屏幕大小会根据分辨率自动调整，以适应不同分辨率的屏幕
---非响应式布局：屏幕大小固定为设置的分辨率
---Set or unset the responsive layout.
---The default value is true.
---Responsive layout: the screen size will be adjusted automatically according to the resolution, suitable for different screen resolutions.
---Non-responsive layout: the screen size is fixed to the set resolution.
---@param flag boolean
function M.SetResponsiveLayout(flag)
    M.responsive_layout = flag
end
---获取逻辑屏幕分辨率，一般不调用
---这个值不会改变，除非调用SetResolution()
---若要获取当前逻辑屏幕大小，请使用GetSize()
---Get the logical screen resolution, which is generally not called.
---This value will not change unless SetResolution() is called.
---To get the current logical screen size, please use GetSize().
function M.GetResolution()
    return M.resolution_x, M.resolution_y
end
---设置逻辑屏幕分辨率
---仅在非响应式布局下生效
---Set the logical screen resolution.
---It only takes effect in non-responsive layout.
function M.SetResolution(x, y)
    M.resolution_x = x
    M.resolution_y = y
    M.Reset()
end
---设置UI缩放比例
---仅在响应式布局下生效
---Set the UI scale factor.
---It only takes effect in responsive layout.
function M.SetScale(f)
    M.scale_factor = f
    M.Reset()
end








--[[
function M.ResetWorld()
    local sw, sh = screen.width, screen.height
    local w = 480 * 2 / SQRT3
    local h = 480
    local bound = 32
    local sx, sy = sw / 2, sh / 2
    local viewsize = min(1, sw / w, sh / h)
    world.l = -w / 2
    world.r = w / 2
    world.b = -h / 2
    world.t = h / 2
    world.boundl = -w / 2 - bound
    world.boundr = w / 2 + bound
    world.boundb = -h / 2 - bound
    world.boundt = h / 2 + bound
    world.scrl = sx - w / 2 * viewsize
    world.scrr = sx + w / 2 * viewsize
    world.scrb = sy - h / 2 * viewsize
    world.scrt = sy + h / 2 * viewsize
    world.pl = -w / 2
    world.pr = w / 2
    world.pb = -h / 2
    world.pt = h / 2
    world.world = 15
    lstg.SetBound(world.boundl, world.boundr, world.boundb, world.boundt)
end--]]




