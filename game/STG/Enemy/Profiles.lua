---@class STG.Enemy.Profiles
local M = {}
STG.Enemy.Profiles = M

---@param fromPhase string
---@param toPhase string
---@param condition fun(ctx:STG.Enemy.System.Phase.Context):boolean
function M.NewPhase(fromPhase, toPhase, condition)
    ---@class STG.Enemy.Profiles.NewPhase
    return {
        fromPhase = fromPhase,
        toPhase = toPhase,
        condition = condition
    }
end

---@class STG.Enemy.Profiles.Default
M.Default = {
    size = 1, ---缩放大小，包括判定大小
    hp = 30, ---生命值
    not_collide = false, ---无体术伤害

    ---@type string
    ---敌人使用的行走图
    style_name = "",

    --enter_time = 0.5,
    ---@type STG.Enemy.Profiles.NewPhase[]
    --new_phases = {},
    default_damage_modifier = true,
    ---@type (fun(enemy:STG.Enemy.Base, system:STG.Enemy.System):STG.Enemy.System.DamageModifier.Base)[]
    damage_modifier = {

    }
}
