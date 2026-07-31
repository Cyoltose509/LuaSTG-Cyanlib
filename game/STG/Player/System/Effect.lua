local base = STG.Player.ComponentBase

---@class STG.Player.System.Effect:STG.Player.ComponentBase
---玩家特效系统：被弹特效、复活动画、炸弹特效
local M = Core.Class(base)
STG.Player.System.Effect = M

local Object = STG.Object
local SetSpriteState = Core.Render.SetSpriteState
local QuadSprite = Core.Render.QuadSprite
local SimpleSprite = Core.Render.SimpleSprite

function M:init(player, system)
    base.init(self, player, system)
    self.effect_queue = {}
end

function M:update(dt)
    -- 处理特效队列
    for i = #self.effect_queue, 1, -1 do
        local eff = self.effect_queue[i]
        eff.timer = eff.timer - dt
        if eff.timer <= 0 then
            table.remove(self.effect_queue, i)
        end
    end
end

---被弹特效
---@param x number
---@param y number
function M:spawnHitEffect(x, y)
    -- 圆形扩散环
    local e = Object.New(Object.Define())
    e.x = x
    e.y = y
    e.group = Object.Group.Ghost
    e.layer = Object.Layer.EnemyBulletEF
    e.lifetime = 30
    e.radius = 0
    e.max_radius = 48

    e.frame = function(self2)
        self2.lifetime = self2.lifetime - 1
        self2.radius = self2.radius + (self2.max_radius - self2.radius) * 0.1
        if self2.lifetime <= 0 then
            Object.Del(self2)
        end
    end

    e.render = function(self2)
        local alpha = math.floor(255 * self2.lifetime / 30)
        SetSpriteState("white", "", alpha, 255, 100, 100)
        QuadSprite("white",
            self2.x - self2.radius, self2.y, 0.5,
            self2.x, self2.y - self2.radius, 0.5,
            self2.x + self2.radius, self2.y, 0.5,
            self2.x, self2.y + self2.radius, 0.5)
    end
end

---复活特效
---@param x number
---@param y number
function M:spawnRespawnEffect(x, y)
    -- 樱花飘散效果
    for i = 1, 8 do
        local e = Object.New(Object.Define())
        e.x = x
        e.y = y
        e.group = Object.Group.Ghost
        e.layer = Object.Layer.EnemyBulletEF
        e.vx = (math.random() - 0.5) * 4
        e.vy = (math.random() - 0.5) * 4
        e.lifetime = 60 + math.random() * 30
        e.rot = math.random() * 360
        e.rot_speed = (math.random() - 0.5) * 8

        e.frame = function(self2)
            self2.x = self2.x + self2.vx
            self2.y = self2.y + self2.vy
            self2.rot = self2.rot + self2.rot_speed
            self2.lifetime = self2.lifetime - 1
            if self2.lifetime <= 0 then
                Object.Del(self2)
            end
        end

        e.render = function(self2)
            local alpha = math.floor(255 * self2.lifetime / 90)
            SetSpriteState("white", "", alpha, 189, 252, 201)
            SimpleSprite("white", self2.x, self2.y, self2.rot, 0.15, 0.15)
        end
    end
end

---炸弹使用特效 (自机周围保护圈)
---@param x number
---@param y number
function M:spawnBombEffect(x, y)
    -- 闪光扩散
    local e = Object.New(Object.Define())
    e.x, e.y = x, y
    e.group = Object.Group.Ghost
    e.layer = Object.Layer.Top
    e.lifetime = 45
    e.radius = 0
    e.max_radius = 200

    e.frame = function(self2)
        self2.lifetime = self2.lifetime - 1
        self2.radius = self2.radius + (self2.max_radius - self2.radius) * 0.15
        if self2.lifetime <= 0 then
            Object.Del(self2)
        end
    end

    e.render = function(self2)
        local alpha = math.floor(200 * self2.lifetime / 45)
        SetSpriteState("white", "", alpha, 255, 255, 200)
        QuadSprite("white",
            self2.x - self2.radius, self2.y, 0.5,
            self2.x, self2.y - self2.radius, 0.5,
            self2.x + self2.radius, self2.y, 0.5,
            self2.x, self2.y + self2.radius, 0.5)
    end
end

function M:getName()
    return "Effect"
end

return M
