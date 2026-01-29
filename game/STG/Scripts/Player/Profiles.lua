---@class STG.Player.Profiles
local M = {}
STG.Player.Profiles = M

---@param fromPhase string
---@param toPhase string
---@param condition fun(ctx:STG.Player.System.Phase.Context):boolean
function M.NewPhase(fromPhase, toPhase, condition)
    ---@class STG.Player.Profiles.NewPhase
    return {
        fromPhase = fromPhase,
        toPhase = toPhase,
        condition = condition
    }
end

---默认角色配置
---@class STG.Player.Profiles.Default
M.Default = {
    name = "Default",
    color = { 189, 252, 201 },
    size = 1,
    style_name = "reimu_player",
    move = {
        high_speed = 10,
        low_speed = 5,
    },
    ---@type STG.Player.Profiles.NewPhase[]
    new_phases = {

    },
    health = {
        invincible_time = 0.5,
        max_containers = 10,
        init_containers = {
            STG.Player.System.Health.Container.Normal,
            --  STG.Player.System.Health.Container.Normal,
            --  STG.Player.System.Health.Container.Normal,
        }
    },
    shoot = {
        speed = 0.2,
        knockback = 15,
        dmg = 10,
        bullet_life = 60,
        bullet_velocity = 10,
    }
}
