---@class STG.Enemy
---@field System STG.Enemy.System
---@field ComponentBase STG.Enemy.ComponentBase
---@field Profiles STG.Enemy.Profiles
---@field Resource STG.Enemy.Resource
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
    self.sys = (system or STG.Enemy.System)(self)
    self.time = STG.System.Time()
end
function Base:colli(other)
end

function Base:frame()
    local dt = self.time:getDelta()
    Core.Task.Do(self, dt)
    self.sys:update(dt)
end
function Base:render()
    self.sys:render()
end

require("STG.Scripts.Enemy.Resource")
require("STG.Scripts.Enemy.Profiles")
require("STG.Scripts.Enemy.System")
require("STG.Scripts.Enemy.ComponentBase")

---@class STG.Enemy.Variant:STG.Enemy.Base
local Variant = {}
Variant.name = "example"
---@type STG.Enemy.Profiles.Default
Variant.profiles = nil
Variant.onInit = function()

end
---@type STG.Enemy.System
Variant.system = nil

---@class STG.Enemy.Variant.ReplaceSystem
---@field move_system STG.Enemy.System.Move
---@field collide_system STG.Enemy.System.Collide
---@field health_system STG.Enemy.System.Health
---@field anim_system STG.Enemy.System.Anim
---@field damage_modifier_system STG.Enemy.System.DamageModifier
---@field phase_system STG.Enemy.System.Phase
---@field death_system STG.Enemy.System.Death
local ReplaceSystem = {}
Variant.replace_subsystem = ReplaceSystem

---@type STG.Enemy.ComponentBase[]
Variant.components = {}

---@param base STG.Enemy.Variant
function M.NewVariant(base)
    return Core.Lib.Table.DeepCopy(base or Variant)
end

---@param variant STG.Enemy.Variant
function M.SpawnVariant(variant, x, y, ...)
    ---@type STG.Enemy.Base
    local e = lstg.New(Base, variant.system)
    e.x = x
    e.y = y

    e.sys:applyVariant(variant)
    if variant.onInit then
        variant.onInit(e, ...)
    end
    return e
end

---@param options STG.Enemy.Profiles.Default
function M.Spawn(x, y, options)
    ---@type STG.Enemy.Base
    local e = lstg.New(Base)
    e.x = x
    e.y = y
    e.sys:applyProfile(options)
    return e
end

