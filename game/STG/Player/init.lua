---@class STG.Player
---@field Shots STG.Player.Shots
---@field System STG.Player.System
---@field Profiles STG.Player.Profiles
---@field Resource STG.Player.Resource
---@field ComponentBase STG.Player.ComponentBase
local M = {}
STG.Player = M

local Object = STG.Object

local rawRand = Core.RNG:newRaw(Core.RNG.Algorithm.Xoshiro128ss, os.time())
M.RawRand = rawRand
M.Rand = Core.RNG:getRNG("player")

M.Current = nil


---@class STG.Player.Base : Core.Object.Base
local Base = Object.Define()

function Base:init(x, y)
    self.x, self.y = x, y
    self.is_player = true
    self.layer = Object.Layer.Player
    self.group = Object.Group.Player
    self.sys = M.System(self)
    self.time = STG.System.Time()
    self.bound = false
    M.Current = self
end
function Base:colli(other)
end
function Base:frame()
    local dt = self.time:getDelta()
    Core.Task.Do(self, dt)
    self.sys:update(dt)
    --self.move_system:update(dt)
end
function Base:render()
    self.sys:render()
end
M.Base = Base

function M.Spawn(x, y, options)
    ---@type STG.Player.Base
    local p = Object.New(Base, x, y)
    -- 合并顺序: Define 默认值 → 传入 options → Profiles.Default 兜底
    local profile = {}
    local style_name = (options and options.style_name) or ""
    if style_name ~= "" then
        local data = M.Resource.GetSafe(style_name)
        if data and data.defaults then
            for k, v in pairs(data.defaults) do
                profile[k] = v
            end
        end
    end
    if options then
        for k, v in pairs(options) do
            profile[k] = v
        end
    end
    p.sys:applyProfile(profile)
    return p
end

require("STG.Player.ComponentBase")
require("STG.Player.System")
require("STG.Player.Shots")
require("STG.Player.Profiles")
require("STG.Player.Resource")
require("STG.Player.Register")

---@return STG.Player.Base
function M.Get()
    if Object.IsValid(M.Current) then
        return M.Current
    end
end

---@param p STG.Player.Base
function M.SetTimeScale(p, s)
    if p and p.time then
        p.time:setScale(s)
    end
end