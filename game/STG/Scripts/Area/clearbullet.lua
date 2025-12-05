


---clear_bullet
---用消弹圈切割直线激光
---@param drop Core.Object.Base|fun(x:number, y:number)@掉落的道具
local function cutLasersByCircle(x1, y1, r, drop)
    local drop_func
    if type(drop) == "function" then
        drop_func = drop
    else
        if lstg.var.powerful_point and not lstg.var.stop_getting then
            drop = drop or item.drop_point
        end
        drop_func = function(x, y)
            New(drop, x, y)
        end
    end
    Core.Object.Utils.LaserDo(function(self)
        if not self.IsBentLaser and IsValid(self) then
            if self.colli and self.alpha > 0.999 and self.protect == 0 then
                --用尽毕生所学
                local lx, ly = self.x, self.y
                local len = self.l1 + self.l2 + self.l3
                local dx, dy = x1 - lx, y1 - ly--向量
                local cosr, sinr = cos(self.rot), sin(self.rot)
                local a, b, c = sinr, -cosr, cosr * ly - sinr * lx
                local dist = abs(a * x1 + b * y1 + c) / sqrt(a * a + b * b)
                if dist < r then
                    local d = sqrt(r * r - dist * dist)
                    local l = sign(dx * cosr + dy * sinr) * sqrt(dx * dx + dy * dy - dist * dist)
                    local cut, _l1, _l2
                    if l >= d then
                        local l1, l2 = l - d, l + d
                        if l1 < len then
                            _l1, _l2 = laser.CutOnRadius(self, l1, l2)
                            cut = true
                        end
                    elseif l >= -d then
                        local l1, l2 = 0, d + l
                        _l1, _l2 = laser.CutOnRadius(self, l1, l2)
                        cut = true
                    end
                    if cut and drop and self.drop_CD == 0 then
                        --间隔8采样
                        for L = _l1, _l2, 12 do
                            local x, y = lx + cosr * L, ly + sinr * L
                            drop_func(x, y)
                            if self.index then
                                BulletBreak_Table:New(x, y, self.index)
                            end
                            if lstg.var.protect_lotus then
                                stg_levelUPlib.class2.add_protect_lotus_c(1)
                            end
                        end
                        self.drop_CD = 9--9帧冷却
                    end

                end
            end
        end
    end)
end
_G.cutLasersByCircle = cutLasersByCircle

local function cutAllLaser(drop)
    local drop_func
    if type(drop) == "function" then
        drop_func = drop
    else
        if lstg.var.powerful_point and not lstg.var.stop_getting then
            drop = drop or item.drop_point
        end
        drop_func = function(x, y)
            New(drop, x, y)
        end
    end
    Core.Object.Utils.LaserDo(function(self)
        local l = self.l1 + self.l2 + self.l3
        laser.CutOnRadius(self, 0, l)
        if drop and self.drop_CD == 0 then
            --间隔8采样
            local cosr, sinr = cos(self.rot), sin(self.rot)
            for L = 0, l, 12 do
                local x, y = self.x + cosr * L, self.y + sinr * L
                drop_func(x, y)
                if self.index then
                    BulletBreak_Table:New(x, y, self.index)
                end
                if lstg.var.protect_lotus then
                    stg_levelUPlib.class2.add_protect_lotus_c(1)
                end
            end
            self.drop_CD = 9--9帧冷却
        end
    end)
end
_G.cutAllLaser = cutAllLaser

bullet_cleaner = Core.Object.Define()
function bullet_cleaner:init(x, y, radius, time, time2, into, indes, vy, vx)
    self.x = x
    self.y = y
    if time == 0 then
        self.radius = radius
    else
        self.radius = 0
        self.delta = radius / time
    end
    self.time = time
    self.time2 = time2
    self.into = into and "Kill" or "Del"
    self.indes = indes
    self.bound = false
    self.group = Core.Object.Group.Player
    self.a = self.radius
    self.b = self.radius
    self.vx = vx or 0
    self.vy = vy or 0.2
    self.colli = false
end
function bullet_cleaner:frame()
    if self.timer < self.time then
        self.radius = self.radius + self.delta
        self.a = self.radius
        self.b = self.radius
    end
    if self.timer > self.time2 then
        Core.Object.Utils.RawDel(self)
    end
    cutLasersByCircle(self.x, self.y, self.a, (self.into == "Kill") and item.drop_point)
    Core.Object.Utils.BulletDo(function(o)
        if Dist(self, o) < self.a then
            Core.Object.Utils[self.into](o)
        end
    end)
    Core.Object.Utils.LaserDo(function(o)
        if Dist(self, o) < self.a then
            if self.indes or not (o.Isradial or o.Isgrowing) then
                Core.Object.Utils[self.into](o)
            end
        end
    end)
    if self.indes then
        Core.Object.Utils.IndesDo(function(o)
            if Dist(self, o) < self.a then
                Core.Object.Utils[self.into](o)
            end
        end)
    end
end

bomb_bullet_killer = Core.Object.Define()
function bomb_bullet_killer:init(x, y, a, b, kill_indes)
    self.x = x
    self.y = y
    self.a = a
    self.b = b
    self.group = Core.Object.Group.Player
    self.hide = true
    self.kill_indes = kill_indes
    self.colli = false
end
function bomb_bullet_killer:frame()
    if self.timer == 1 then
        Del(self)
    end
    cutLasersByCircle(self.x, self.y, self.a, item.drop_point)
    Core.Object.Utils.BulletDo(function(o)
        if Dist(self, o) < self.a then
            Core.Object.Utils.Kill(o)
        end
    end)
    Core.Object.Utils.LaserDo(function(o)
        if Dist(self, o) < self.a then
            if self.kill_indes or not (o.Isradial or o.Isgrowing) then
                Core.Object.Utils.Kill(o)
            end
        end
    end)
    if self.kill_indes then
        Core.Object.Utils.IndesDo(function(o)
            if Dist(self, o) < self.a then
                Core.Object.Utils.Kill(o)
            end
        end)
    end
end

