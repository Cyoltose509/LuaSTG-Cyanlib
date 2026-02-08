local base = STG.Player.ComponentBase

---@class STG.Player.System.Graze:STG.Player.ComponentBase
local M = Core.Class(base)
STG.Player.System.Graze = M

local Object = STG.Object
local Render = Core.Render
local rand = STG.Player.RawRand

function M:init(player, system)
    base.init(self, player, system)
    self.grazer = Object.New(M.GrazerClass, player, system, self)
    self:setGrazeRadius(48)
end

function M:setLayer(layer)
    local grazer = self.grazer
    if Object.IsValid(grazer) then
        grazer.layer = layer
    end
end

--TODO
function M:onGraze(other)
    --local var = lstg.var
    --var.graze = var.graze + 1
    --player_lib.AddScore(GrazeScore[lstg.var.difficulty])
    --PlaySound("graze")
end

function M:setGrazerImage(center, aura)
    local grazer = self.grazer
    if Object.IsValid(grazer) then
        grazer.center_img = center or grazer.center_img
        grazer.aura_img = aura or grazer.aura_img
    end
end

function M:setGrazeRadius(r)
    local grazer = self.grazer
    if Object.IsValid(grazer) then
        grazer.a = r or 48
        grazer.b = grazer.a
    end
end

function M:setGrazerSize(s)
    if Object.IsValid(self.grazer) then
        self.grazer.size = s or 1
    end
end

function M:update()
end

local GrazerClass = Core.Object.Define()
M.GrazerClass = GrazerClass
---@param player STG.Player.Base
---@param system STG.Player.System
---@param graze_system STG.Player.System.Graze
function GrazerClass:init(player, system, graze_system)
    self.layer = Object.Layer.EnemyBulletEF
    self.group = Object.Group.Player
    self.player = player
    self.system = system
    self.graze_system = graze_system
    self.aura = 0
    self.aura_d = 0
    self.log_state = self.player.slow
    self._slowTimer = 0
    self._pause = 0
    self.ps = {}
    self.bound = false
    self.alpha2 = 0
    self.lh = 0
    self.center_img = "stg:player_center"
    self.aura_img = "stg:player_aura"
    self.size = 1
end
function GrazerClass:frame()
    local phase = self.system:getPhase()
    if phase == "dead" then
        return
    end
    local p = self.player
    local dt = p.time:getDelta()
    self.x = p.x
    self.y = p.y
    self.hide = p.hide
    if not p.time_stop then
        --这是个什么变量
        local slow = self.system:isSlow() and 1 or 0
        if self.log_state ~= slow then
            self.log_state = slow
            self._pause = 30
        end
        if slow == 1 then
            if self._slowTimer < 30 then
                self._slowTimer = self._slowTimer + dt
            end
        else
            self._slowTimer = 0
        end
        if self._pause == 0 then
            self.aura = self.aura + 1.5 * dt
        end
        self._pause = max(self._pause - dt, 0)
        local S = cos(90 * self._slowTimer / 30)
        self.aura_d = 180 * S * S
        self.lh = clamp(self.lh + (slow - 0.5) * 0.3, 0, 1)
    end
    for i = #self.ps, 1, -1 do
        local s = self.ps[i]
        s.x = s.x + s.vx * dt
        s.y = s.y + s.vy * dt
        s.vx = Core.Math.ExpInterp(s.vx, 0, dt * 0.07)
        s.vy = Core.Math.ExpInterp(s.vy, 0, dt * 0.07)
        if s.timer >= 25 then
            s.alpha = max(0, s.alpha - 16 * dt)
        end
        s.rot = s.rot + s.omega
        s.timer = s.timer + dt
        if s.alpha == 0 then
            table.remove(self.ps, i)
        end
    end

end
function GrazerClass:render()
    -- local p = self.player
    for _, g in ipairs(self.ps) do
        Render.Draw.SetState(Render.BlendMode.MulAdd, g.alpha, 255, 227, 132)
        Render.Draw.Line(g.x, g.y, g.rot, 8)
    end
    local size = self.size
    local aura = self.aura_img
    local center = self.center_img
    Render.SetImageState(center, Render.BlendMode.Default, self.lh * 255, 255, 255, 255)
    Render.Image(center, self.x, self.y, 0, size)
    Render.SetImageState(aura, Render.BlendMode.Default, 255, 255, 255, 255)
    Render.Image(aura, self.x, self.y, -self.aura + self.aura_d, self.lh * size)
    Render.SetImageState(aura, Render.BlendMode.Default, self.lh * 255, 255, 255, 255)
    Render.Image(aura, self.x, self.y, self.aura, (2 - self.lh) * size)

end
function GrazerClass:colli(other)
    local phase = self.system:getPhase()
    if phase == "dead" then
        return
    end
    if other.group == Object.Group.EnemyBullet or other.group == Object.Group.InDes then
        if not (other._graze) or other._inf_graze then
            self.graze_system:onGraze(other)
            local a = rand:float(0, 360)
            local v = rand:float(8, 13)
            table.insert(self.ps, {
                x = self.x, y = self.y,
                vx = cos(a) * v, vy = sin(a) * v,
                alpha = 100, timer = 0,
                rot = rand:float(0, 360), omega = rand:sign() * 5
            })
            if not (other._inf_graze) then
                other._graze = true
            end
        end
    end
end
