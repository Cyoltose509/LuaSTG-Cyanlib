---@class Core.Resource
---@field Animation Core.Resource.Animation
---@field Sound Core.Resource.Sound
---@field Music Core.Resource.Music
---@field Model Core.Resource.Model
---@field Font Core.Resource.Font
---@field TTF Core.Resource.TTF
---@field Particle Core.Resource.Particle
---@field Shader Core.Resource.Shader
---@field Texture Core.Resource.Texture
---@field Sprite Core.Resource.Sprite
---@field RenderTarget Core.Resource.RenderTarget
---@field LazyLoader Core.Resource.LazyLoader
local M = {}
Core.Resource = M

M.resPool = lstg.GetResourceStatus()

---@class lstg.ResourceType
M.ResType = {
    RenderTarget = 1,--和Texture同类
    Texture = 1,
    Sprite = 2,
    Animation = 3,
    Music = 4,
    Sound = 5,
    Particle = 6,
    Font = 7,
    TTF = 8,
    Shader = 9,
    Model = 10
}

---@class lstg.ResourcePoolType
M.PoolType = {
    None = "none",
    Stage = "stage",
    Global = "global",
}

---@class lstg.KnownSamplerState
M.SamplerState = {
    PointWrap = "point+wrap",
    PointClamp = "point+clamp",
    LinearWrap = "linear+wrap",
    LinearClamp = "linear+clamp",
}


require("Core.Scripts.Resource.RenderTarget")
require("Core.Scripts.Resource.Sound")
require("Core.Scripts.Resource.Music")
require("Core.Scripts.Resource.Model")
require("Core.Scripts.Resource.Font")
require("Core.Scripts.Resource.TTF")
require("Core.Scripts.Resource.Particle")
require("Core.Scripts.Resource.Shader")
require("Core.Scripts.Resource.Texture")
require("Core.Scripts.Resource.Sprite")
require("Core.Scripts.Resource.Animation")
require("Core.Scripts.Resource.LazyLoader")

---@param pool lstg.ResourcePoolType
function M.SetResourcePool(pool)

    lstg.SetResourceStatus(pool)
    M.resPool = pool
end

function M.GetResourcePool()
    return lstg.GetResourceStatus() or M.resPool
end

---@param pool lstg.ResourcePoolType
function M.ClearResourcePool(pool)
    pool = pool or M.resPool
    lstg.RemoveResource(pool)
end


