local base = STG.Player.ComponentBase

---@class STG.Player.System.Shoot:STG.Player.ComponentBase
---玩家射击系统：主射击、子机射击、灵力等级
local M = Core.Class(base)
STG.Player.System.Shoot = M

local CT = STG.Constants
local Shots = STG.Shots

function M:init(player, system)
    base.init(self, player, system)
    self:reset()
end

function M:reset()
    self.power = CT.PLAYER_INITIAL_POWER
    self.max_power = CT.PLAYER_MAX_POWER
    self.power_level = 0     ---0~4
    self.shoot_timer = 0
    self.shoot_interval = CT.SHOOT_INTERVAL_MAIN
    self.sub_shot_timer = 0
    self.sub_shot_count = 0
    self.sub_shot_interval = CT.SHOOT_INTERVAL_SUB
    ---子机偏移位置
    self.sub_shot_positions = {
        { x = -16, y = 0 },
        { x = 16, y = 0 },
        { x = -8, y = -12 },
        { x = 8, y = -12 },
    }
end

---@param profile STG.Player.Profiles.Default
function M:setProfile(profile)
    if not profile then return end
    if profile.shoot then
        self.shoot_interval = profile.shoot.main_interval or self.shoot_interval
        self.sub_shot_interval = profile.shoot.sub_interval or self.sub_shot_interval
    end
    if profile.power then
        self.power = profile.power or self.power
        self:recalcPowerLevel()
    end
end

function M:update(dt)
    local phase = self.system:getPhase()
    if phase ~= "normal" then return end

    local input = self.system:getInput()
    self.shoot_timer = self.shoot_timer + dt

    if input.shoot then
        self:_tryShoot()
    else
        self.shoot_timer = self.shoot_interval -- 松开后立即可射击
    end
end

---尝试射击
function M:_tryShoot()
    if self.shoot_timer < self.shoot_interval then return end
    self.shoot_timer = 0

    local p = self.player
    local damage = CT.PLAYER_DAMAGE_TABLE[self.power_level + 1] or 1

    -- 主射击
    self:_fireMain(p.x, p.y - 8, damage)

    -- 子机射击
    self:_fireSubShots(p.x, p.y, damage)
end

---主射击
function M:_fireMain(x, y, damage)
    local speed = CT.PLAYER_BULLET_SPEED
    -- 根据灵力等级调整弹幕形态
    if self.power_level == 0 then
        -- 单发
        Shots.BulletStraight(x, y, x, y - speed, speed, Shots.Color.Red, damage)
    elseif self.power_level == 1 then
        -- 双发
        Shots.BulletStraight(x - 4, y, x - 4, y - speed, speed, Shots.Color.Red, damage)
        Shots.BulletStraight(x + 4, y, x + 4, y - speed, speed, Shots.Color.Red, damage)
    elseif self.power_level == 2 then
        -- 三发
        Shots.BulletStraight(x, y, x, y - speed, speed, Shots.Color.Red, damage)
        Shots.BulletStraight(x - 8, y, x - 8, y - speed, speed, Shots.Color.Red, damage)
        Shots.BulletStraight(x + 8, y, x + 8, y - speed, speed, Shots.Color.Red, damage)
    elseif self.power_level == 3 then
        -- 四发
        Shots.BulletStraight(x - 12, y, x - 12, y - speed, speed, Shots.Color.Red, damage)
        Shots.BulletStraight(x - 4, y, x - 4, y - speed, speed, Shots.Color.Red, damage)
        Shots.BulletStraight(x + 4, y, x + 4, y - speed, speed, Shots.Color.Red, damage)
        Shots.BulletStraight(x + 12, y, x + 12, y - speed, speed, Shots.Color.Red, damage)
    else
        -- 五发
        Shots.BulletStraight(x - 16, y, x - 16, y - speed, speed, Shots.Color.Red, damage)
        Shots.BulletStraight(x - 8, y, x - 8, y - speed, speed, Shots.Color.Red, damage)
        Shots.BulletStraight(x, y, x, y - speed, speed, Shots.Color.Red, damage)
        Shots.BulletStraight(x + 8, y, x + 8, y - speed, speed, Shots.Color.Red, damage)
        Shots.BulletStraight(x + 16, y, x + 16, y - speed, speed, Shots.Color.Red, damage)
    end
end

---子机射击
function M:_fireSubShots(x, y, damage)
    local speed = CT.PLAYER_SUB_BULLET_SPEED
    for i = 1, self.sub_shot_count do
        local pos = self.sub_shot_positions[i]
        if pos then
            Shots.BulletStraight(
                x + pos.x, y + pos.y,
                x + pos.x, y + pos.y - speed,
                speed, Shots.Color.Blue, damage
            )
        end
    end
end

---增加灵力
---@param amount number
function M:addPower(amount)
    self.power = math.min(self.power + amount * CT.PLAYER_POWER_PER_POINT, self.max_power)
    self:recalcPowerLevel()
end

---灵力减半 (死亡惩罚)
function M:halvePower()
    self.power = math.floor(self.power / 2)
    self:recalcPowerLevel()
end

---重新计算灵力等级
function M:recalcPowerLevel()
    if self.power >= 400 then self.power_level = 4
    elseif self.power >= 300 then self.power_level = 3
    elseif self.power >= 200 then self.power_level = 2
    elseif self.power >= 100 then self.power_level = 1
    else self.power_level = 0 end
    -- 更新子机数量
    self.sub_shot_count = math.min(self.power_level, CT.MAX_SUB_SHOT)
end

---获取灵力等级
---@return number
function M:getPowerLevel()
    return self.power_level
end

---获取当前灵力值
---@return number
function M:getPower()
    return self.power
end

function M:getViewData()
    return {
        power = self.power,
        power_level = self.power_level,
        sub_shot_count = self.sub_shot_count,
    }
end

function M:getName()
    return "Shoot"
end

return M
