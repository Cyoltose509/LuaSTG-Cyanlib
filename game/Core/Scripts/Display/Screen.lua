---@class Core.Display.Screen
local M = {}
Core.Display.Screen = M

M.ResponsiveLayout = true
M.ResolutionX = 960
M.ResolutionY = 540
function M.SetResponsiveLayout(flag)
    M.ResponsiveLayout = flag
end
function M.GetResolution()
    return M.ResolutionX, M.ResolutionY
end
function M.SetResolution(x, y)
    M.ResolutionX = x
    M.ResolutionY = y
end
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

function M.GetSize()
    return screen.width, screen.height
end

function M.GetDelta()
    return screen.dx, screen.dy
end

function M.GetScale()
    return screen.scale
end

local cameras = setmetatable({}, { __mode = "v" })
local screenCallbacks = {}

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
function M.UnregisterCamera(cam)
    for i = #cameras, 1, -1 do
        if cameras[i] == cam then
            table.remove(cameras, i)
            return
        end
    end
end

function M.RegisterCallback(name, cb)
    screenCallbacks[name] = cb
end

function M.UnregisterCallback(name)
    screenCallbacks[name] = nil
end

---@param set Core.Data.Setting.Settings
function M.Reset(set)
    local FullW, FullH = Core.Display.GetResolution()
    set = set or Core.Data.Setting.Get()
    --16:9
    local gs = set.graphics_system
    local resx, resy = gs.width, gs.height
    --[[
    if gs.fullscreen then
        resx, resy = FullW, FullH
    end--]]
    local scale = resx / resy
    local _fullW, _fullH
    if scale > 1 then
        _fullW, _fullH = FullH * scale, FullH
    else
        _fullW, _fullH = FullH, FullH / scale
    end
    local ui_scale = set.ui_scaling / 100
    _fullW = _fullW / ui_scale
    _fullH = _fullH / ui_scale
    if M.ResponsiveLayout then
        screen.width = _fullW --/ 2
        screen.height = _fullH --/ 2
    else
        screen.width = M.ResolutionX
        screen.height = M.ResolutionY
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




