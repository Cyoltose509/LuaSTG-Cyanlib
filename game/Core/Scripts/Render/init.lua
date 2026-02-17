---@class Core.Render:Core.Render.Utils
---@field Draw Core.Render.Draw
---@field Mesh Core.Render.Mesh
---@field Skybox Core.Render.Skybox
---@field Color Core.Render.Color
---@field GPU Core.Render.GPU
---@field Ball Core.Render.Ball
---@field Utils Core.Render.Utils
---@field Text Core.Render.Text
local M = {}
Core.Render = M


require("Core.Scripts.Render.Draw")
require("Core.Scripts.Render.Mesh")
require("Core.Scripts.Render.Skybox")
require("Core.Scripts.Render.Color")
require("Core.Scripts.Render.GPU")
require("Core.Scripts.Render.Ball")
require("Core.Scripts.Render.Text")

---@class lstg.BlendMode
M.BlendMode = {
    Default = "",
    MulAlpha = "mul+alpha",
    MulAdd = "mul+add",
    MulRev = "mul+rev",
    MulSub = "mul+sub",
    AddAlpha = "add+alpha",
    AddAdd = "add+add",
    AddRev = "add+rev",
    AddSub = "add+sub",
    AlphaBal = "alpha+bal",
    MulMin = "mul+min",
    MulMax = "mul+max",
    MulMul = "mul+mul",
    MulScreen = "mul+screen",
    AddMin = "add+min",
    AddMax = "add+max",
    AddMul = "add+mul",
    AddScreen = "add+screen",
    Force = "one",
}

---@class lstg.KnownSamplerState
M.SamplerState = {
    PointWrap = "point+wrap",
    PointClamp = "point+clamp",
    LinearWrap = "linear+wrap",
    LinearClamp = "linear+clamp",
}


local function SetClipRect(l, r, b, t, scrl, scrr, scrb, scrt)
    lstg.SetOrtho(l, r, b, t)
    lstg.SetViewport(scrl, scrr, scrb, scrt)
    lstg.SetScissorRect(scrl, scrr, scrb, scrt)
end

M._clip_stack = {}
--TODO:有隐患
function M.PushClipRect(left, right, bottom, top)
    local scrl, scrr, scrb, scrt = left, right, bottom, top
    local cam = Core.Display.Camera.GetCurrent()
    if cam then
        scrl, scrb = cam:worldToScreen(scrl, scrb)
        scrr, scrt = cam:worldToScreen(scrr, scrt)
    end
    SetClipRect(left, right, bottom, top, scrl, scrr, scrb, scrt)
    M._clip_stack[#M._clip_stack + 1] = { left, right, bottom, top, scrl, scrr, scrb, scrt }
end
function M.PopClipRect()
    table.remove(M._clip_stack)
    local size = #M._clip_stack
    if size > 0 then
        local last = M._clip_stack[size]
        SetClipRect(last[1], last[2], last[3], last[4], last[5], last[6], last[7], last[8])

    else
        local cam = Core.Display.Camera.GetCurrent()
        if cam then
            cam:apply()
        end
    end
end


require("Core.Scripts.Render.Utils")
setmetatable(M, {
    __index = function(t, k)
        local v = M.Utils[k]
        if v ~= nil then
            rawset(t, k, v)
            return v
        end
    end
})









