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
        speed = 10,       -- shots per second at base power
        dmg = 10,
        bullet_life = 60,
        bullet_velocity = 12,
    },
    bomb = {
        max_bombs = 8,
        starting_bombs = 3,
        duration = 2,
        invincible = true,
    },
    resource = {
        max_power = 4.0,
        max_lives = 8,
        max_bombs = 8,
        starting_lives = 3,
        starting_bombs = 3,
    },
}

---Reimu Hakurei — balanced, homing amulets + persuasion needle
M.Reimu = {
    name = "Reimu",
    color = { 255, 100, 100 },
    size = 1,
    style_name = "reimu_player",
    move = {
        high_speed = 9,      -- 4.5 px/frame at 60fps = 4.5 units * 2
        low_speed = 4.5,
    },
    health = {
        invincible_time = 0.5,
        max_containers = 10,
        init_containers = {
            STG.Player.System.Health.Container.Normal,
        }
    },
    shoot = {
        speed = 15,
        dmg = 10,
        bullet_life = 60,
        bullet_velocity = 12,
    },
    bomb = {
        max_bombs = 8,
        starting_bombs = 3,
        duration = 2,
        invincible = true,
    },
    resource = {
        max_power = 4.0,
        max_lives = 8,
        max_bombs = 8,
        starting_lives = 3,
        starting_bombs = 3,
    },
}

---Marisa Kirisame — fast, wide spread + laser piercing
M.Marisa = {
    name = "Marisa",
    color = { 100, 200, 255 },
    size = 1,
    style_name = "marisa_player",
    move = {
        high_speed = 10,     -- 5 px/frame * 2
        low_speed = 5,
    },
    health = {
        invincible_time = 0.5,
        max_containers = 10,
        init_containers = {
            STG.Player.System.Health.Container.Normal,
        }
    },
    shoot = {
        speed = 12,
        dmg = 10,
        bullet_life = 60,
        bullet_velocity = 12,
    },
    bomb = {
        max_bombs = 8,
        starting_bombs = 3,
        duration = 2,
        invincible = true,
    },
    resource = {
        max_power = 4.0,
        max_lives = 8,
        max_bombs = 8,
        starting_lives = 3,
        starting_bombs = 3,
    },
}
