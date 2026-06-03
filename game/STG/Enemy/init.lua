---@class STG.Enemy
---@field System STG.Enemy.System
---@field ComponentBase STG.Enemy.ComponentBase
---@field Profiles STG.Enemy.Profiles
---@field Resource STG.Enemy.Resource
---@field Behavior STG.Enemy.Behavior
---@field Boss STG.Enemy.Boss
---@field Color table
local M = {}
STG.Enemy = M

M.Color = Core.Lib.Table.Copy(STG.Shots.Color)

local Object = STG.Object
local rawRand = Core.RNG:newRaw(Core.RNG.Algorithm.Xoshiro128ss, os.time())
M.RawRand = rawRand

---@class STG.Enemy.Base : Core.Object.Base
local Base = Object.Define()

function Base:init(system)
    self.x, self.y = 0, 0
    self.layer = Object.Layer.Enemy
    self.group = Object.Group.Enemy
    self.is_enemy = true
    self._a, self._r, self._g, self._b = 255, 255, 255, 255
    self._blend = ""
    self.hscale, self.vscale = 1, 1
    self.sys = (system or STG.Enemy.System)(self)
    self.time = STG.System.Time()
end
function Base:colli(other)
    if other.group == Object.Group.PlayerShots or other.group == Object.Group.Spell then
        self.sys.collide_system:withPlayerShots(other)
    end
end

function Base:frame()
    self.sys:update(self.time:getDelta())
end

function Base:render()
    self.sys:render()
end

function Base:kill()
    if self.sys then
        self.sys:onDeath()
    end
    Object.Del(self)
end

function Base:del()
    if self.sys and self.sys.onRemove then
        self.sys:onRemove()
    end
end

---Spawn an enemy with position and profile options.
---@param x number
---@param y number
---@param options STG.Enemy.Profiles.Default
---@return STG.Enemy.Base
function M.Spawn(x, y, options)
    ---@type STG.Enemy.Base
    local e = lstg.New(Base)
    e.x = x
    e.y = y
    e.sys:applyProfile(options)
    return e
end

---@class STG.Enemy.Variant
---@field name string
---@field profiles STG.Enemy.Profiles.Default
---@field replace_subsystem table|nil
---@field components table[]
---@field onInit fun(boss:STG.Enemy.Base)|nil

---Create a new enemy variant definition.
---@return STG.Enemy.Variant
function M.NewVariant()
    return { name = "", components = {}, replace_subsystem = {} }
end

---Spawn an enemy from a variant definition.
---@param variant STG.Enemy.Variant
---@param x number
---@param y number
---@return STG.Enemy.Base
function M.SpawnVariant(variant, x, y, ...)
    local e = M.Spawn(x, y, variant.profiles)
    e.sys:applyVariant(variant)
    if variant.onInit then
        variant.onInit(e)
    end
    return e
end

require("STG.Enemy.ComponentBase")
require("STG.Enemy.Profiles")
require("STG.Enemy.Resource")
require("STG.Enemy.System")
require("STG.Enemy.Boss")
require("STG.Enemy.Behavior")
require("STG.Enemy.DefaultStyles")
