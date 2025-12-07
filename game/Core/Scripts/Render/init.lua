---@class Core.Render:Core.Render.Utils
---@field Draw Core.Render.Draw
---@field Mesh Core.Render.Mesh
---@field Skybox Core.Render.Skybox
---@field Color Core.Render.Color
---@field GPU Core.Render.GPU
---@field ScreenRT Core.Render.ScreenRT
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
require("Core.Scripts.Render.ScreenRT")
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









