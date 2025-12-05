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
---@field Image Core.Resource.Image
---@field RenderTarget Core.Resource.RenderTarget
---@field LazyLoader Core.Resource.LazyLoader
local M = {}
Core.Resource = M

M.resPool = lstg.GetResourceStatus()

---@class lstg.ResourceType
M.ResType = {
    RenderTarget = 1,--和Texture同类
    Texture = 1,
    Image = 2,
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




require("Core.Scripts.Resource.RenderTarget")
require("Core.Scripts.Resource.Sound")
require("Core.Scripts.Resource.Music")
require("Core.Scripts.Resource.Model")
require("Core.Scripts.Resource.Font")
require("Core.Scripts.Resource.TTF")
require("Core.Scripts.Resource.Particle")
require("Core.Scripts.Resource.Shader")
require("Core.Scripts.Resource.Texture")
require("Core.Scripts.Resource.Image")
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


