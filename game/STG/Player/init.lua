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
    self._a, self._r, self._g, self._b = 255, 255, 255, 255
    self._blend = ""
    self.hscale, self.vscale = 1, 1
    self.sys = M.System(self)
    self.time = STG.System.Time()
    self.bound = false
    M.Current = self
end
function Base:colli(other)
    if other.group == Object.Group.EnemyBullet or other.group == Object.Group.InDes then
        self.sys:hitByEnemyBullet(other)
    elseif other.group == Object.Group.Enemy then
        self.sys:hitByEnemy(other)
    end
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
    p.sys:applyProfile(options)
    return p
end

require("STG.Player.ComponentBase")
require("STG.Player.System")
require("STG.Player.Shots")
require("STG.Player.Profiles")
require("STG.Player.Resource")
require("STG.Player.DefaultStyles")

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