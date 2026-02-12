---@class Core.Effect.ParticleSystem
local M = Core.Class()
Core.Effect.ParticleSystem = M

local ran = Core.Effect.rand
local lerp = Core.Math.Lerp
local HUGE = math.huge

function M:init()
    ---@type Core.Effect.ParticleSystem.Particle[]
    self.objects = {}
    self._emit_fraction = 0---发射积累的小数

    self.max_count = HUGE---最大粒子数量

    self.timer = 0
    self.duration = HUGE---粒子播放持续时间
    self.emit_speed = 30---粒子发射速度（颗/s）

    self.lifetime = 1---粒子生命周期
    self.lifetime_rand = 0.5---粒子生命周期随机值

    self.shoot_angle = 90---粒子发射角度
    self.shoot_angle_rand = 0---粒子发射角度随机值

    self.emit_field = {
        left = -1,
        right = 1,
        top = 1,
        bottom = -1,
        radius1 = 0,
        radius2 = 0,
        angle1 = 0,
        angle2 = 360,
    }

    self.gravity_x = 0---粒子x方向引力
    self.gravity_x_rand = 0---粒子x方向引力随机值

    self.gravity_y = 0---粒子y方向引力
    self.gravity_y_rand = 0---粒子y方向引力随机值

    self.accel_rad = 0---粒子向心加速度
    self.accel_rad_rand = 0---粒子向心加速度随机值

    self.accel_tan = 0---粒子切向加速度
    self.accel_tan_rand = 0---粒子切向加速度随机值

    self.start_speed = 20---粒子发射速度
    self.start_speed_rand = 0---粒子发射速度随机值

    self.end_speed = 0---粒子结束速度
    self.end_speed_rand = 0---粒子结束速度随机值

    self.start_size = 1---粒子初始大小
    self.start_size_rand = 0---粒子初始大小随机值

    self.end_size = 1---粒子结束大小
    self.end_size_rand = 0---粒子结束大小随机值

    self.start_rot = 0---粒子初始旋转
    self.start_rot_rand = 0---粒子初始旋转随机值

    self.end_rot = 0---粒子结束旋转
    self.end_rot_rand = 0---粒子结束旋转随机值

    self.start_A = 1---粒子初始透明度
    self.start_A_rand = 0---粒子初始透明度随机值
    self.end_A = 1---粒子结束透明度
    self.end_A_rand = 0---粒子结束透明度随机值

    self.start_R = 1---粒子初始红色
    self.start_R_rand = 0---粒子初始红色随机值
    self.end_R = 1---粒子结束红色
    self.end_R_rand = 0---粒子结束红色随机值

    self.start_G = 1---粒子初始绿色
    self.start_G_rand = 0---粒子初始绿色随机值
    self.end_G = 1---粒子结束绿色
    self.end_G_rand = 0---粒子结束绿色随机值

    self.start_B = 1---粒子初始蓝色
    self.start_B_rand = 0---粒子初始蓝色随机值
    self.end_B = 1---粒子结束蓝色
    self.end_B_rand = 0---粒子结束蓝色随机值

    self.blend = Core.Render.BlendMode.Default

    self.fade_in_time = 0---粒子淡入时间
    self.fade_in_time_rand = 0---粒子淡入时间随机值

    self.fade_out_time = 0---粒子淡出时间
    self.fade_out_time_rand = 0---粒子淡出时间随机值

    self.ignore_end_speed = false---粒子速度是否相等（忽视结束速度）
    self.ignore_end_size = false---粒子大小是否相等（忽视结束大小）
    self.ignore_end_rot = false---粒子旋转是否相等（忽视结束旋转）
    self.ignore_end_color = false---粒子颜色是否相等（忽视结束颜色）

    self.img = "white"
    ---@type Core.Resource.Image|Core.Resource.Animation
    self.img_res = Core.Resource.Image.Get(self.img)
    self.ani_timer_multi = 10---动画播放速度倍数
end
function M:setMaxCount(c)
    self.max_count = c or HUGE
    return self
end
function M:setDuration(t)
    self.duration = t or HUGE
    return self
end
function M:setEmitSpeed(speed)
    self.emit_speed = speed or 30
    return self
end
function M:setLifetime(lt, rand)
    self.lifetime = lt or self.lifetime
    self.lifetime_rand = rand or self.lifetime_rand
    return self
end
function M:setShootAngle(sa, rand)
    self.shoot_angle = sa or self.shoot_angle
    self.shoot_angle_rand = rand or self.shoot_angle_rand
    return self
end

function M:setEmitRect(left, right, bottom, top)
    self.emit_field.left = left or 0
    self.emit_field.right = right or 0
    self.emit_field.bottom = bottom or 0
    self.emit_field.top = top or 0
    return self
end
function M:setEmitCenter(x, y)
    x = x or 0
    y = y or 0
    self.emit_field.left = x
    self.emit_field.right = x
    self.emit_field.bottom = y
    self.emit_field.top = y
    return self
end
function M:setEmitRadius(radius1, radius2)
    self.emit_field.radius1 = radius1 or 0
    self.emit_field.radius2 = radius2 or 0
    return self
end
function M:setEmitAngle(angle1, angle2)
    self.emit_field.angle1 = angle1 or 0
    self.emit_field.angle2 = angle2 or 360
    return self
end

function M:setGravity(x, y, x_rand, y_rand)
    self.gravity_x = x or self.gravity_x
    self.gravity_y = y or self.gravity_y
    self.gravity_x_rand = x_rand or self.gravity_x_rand
    self.gravity_y_rand = y_rand or self.gravity_y_rand
    return self
end
function M:setSpeed(start_speed, start_rand, end_speed, end_rand)
    self.start_speed = start_speed or self.start_speed
    self.end_speed = end_speed or start_speed or self.end_speed
    self.start_speed_rand = start_rand or self.start_speed_rand
    self.end_speed_rand = end_rand or self.end_speed_rand
    return self
end
function M:setAccelRad(ar, rand)
    self.accel_rad = ar or self.accel_rad
    self.accel_rad_rand = rand or self.accel_rad_rand
    return self
end
function M:setAccelTan(at, rand)
    self.accel_tan = at or self.accel_tan
    self.accel_tan_rand = rand or self.accel_tan_rand
    return self
end

function M:setSize(start_size, start_rand, end_size, end_rand)
    self.start_size = start_size or self.start_size
    self.end_size = end_size or start_size or self.end_size
    self.start_size_rand = start_rand or self.start_size_rand
    self.end_size_rand = end_rand or self.end_size_rand
    return self
end

function M:setRotation(start_rot, start_rand, end_rot, end_rand)
    self.start_rot = start_rot or self.start_rot
    self.end_rot = end_rot or start_rot or self.end_rot
    self.start_rot_rand = start_rand or self.start_rot_rand
    self.end_rot_rand = end_rand or self.end_rot_rand
    return self
end

function M:setStartColor(A, R, G, B, A_rand, R_rand, G_rand, B_rand)
    self.start_A = A or self.start_A
    self.start_R = R or self.start_R
    self.start_G = G or self.start_G
    self.start_B = B or self.start_B
    self.start_A_rand = A_rand or self.start_A_rand
    self.start_R_rand = R_rand or self.start_R_rand
    self.start_G_rand = G_rand or self.start_G_rand
    self.start_B_rand = B_rand or self.start_B_rand
    return self
end

function M:setEndColor(A, R, G, B, A_rand, R_rand, G_rand, B_rand)
    self.end_A = A or self.end_A
    self.end_R = R or self.end_R
    self.end_G = G or self.end_G
    self.end_B = B or self.end_B
    self.end_A_rand = A_rand or self.end_A_rand
    self.end_R_rand = R_rand or self.end_R_rand
    self.end_G_rand = G_rand or self.end_G_rand
    self.end_B_rand = B_rand or self.end_B_rand
    return self
end

function M:setFadeInTime(t, rand)
    self.fade_in_time = t or self.fade_in_time
    self.fade_in_time_rand = rand or self.fade_in_time_rand
    return self
end

function M:setFadeOutTime(t, rand)
    self.fade_out_time = t or self.fade_out_time
    self.fade_out_time_rand = rand or self.fade_out_time_rand
    return self
end

function M:setBlendMode(b)
    self.blend = b or Core.Render.BlendMode.Default
    return self
end

function M:ignoreEndSpeed(flag)
    self.ignore_end_speed = flag ~= false
    return self
end
function M:ignoreEndSize(flag)
    self.ignore_end_size = flag ~= false
    return self
end
function M:ignoreEndRotation(flag)
    self.ignore_end_rot = flag ~= false
    return self
end
function M:ignoreEndColor(flag)
    self.ignore_end_color = flag ~= false
    return self
end

---@overload fun(img:string):self
function M:setImage(ani, ani_timer_multi)
    self.img = ani or self.img

    self.img_res = (ani_timer_multi and Core.Resource.Animation.Get or Core.Resource.Image.Get)(self.img)
    self.ani_timer_multi = ani_timer_multi or 1
    assert(self.img_res, ("Particle Image: %s not found."):format(ani))
    return self
end

function M:newParticle(count)
    count = count or 1
    local f = self.emit_field
    local icount = int(count)
    self._emit_fraction = self._emit_fraction + (count - icount)
    for _ = 1, icount + self._emit_fraction do
        if #self.objects >= self.max_count then
            return
        end
        local a = ran:float(f.angle1, f.angle2)
        local r = ran:float(f.radius1, f.radius2)
        local cosa, sina = cos(a), sin(a)
        local va = self.shoot_angle + ran:float(-self.shoot_angle_rand, self.shoot_angle_rand)
        local vcosa, vsina = cos(va), sin(va)

        local sv = self.start_speed + ran:float(-self.start_speed_rand, self.start_speed_rand)
        local ev = self.ignore_end_speed and sv or (self.end_speed + ran:float(-self.end_speed_rand, self.end_speed_rand))
        local gx = self.gravity_x + ran:float(-self.gravity_x_rand, self.gravity_x_rand)
        local gy = self.gravity_y + ran:float(-self.gravity_y_rand, self.gravity_y_rand)
        local ar = self.accel_rad + ran:float(-self.accel_rad_rand, self.accel_rad_rand)
        local at = self.accel_tan + ran:float(-self.accel_tan_rand, self.accel_tan_rand)
        local ss = self.start_size + ran:float(-self.start_size_rand, self.start_size_rand)
        local es = self.ignore_end_size and ss or (self.end_size + ran:float(-self.end_size_rand, self.end_size_rand))
        local sr = self.start_rot + ran:float(-self.start_rot_rand, self.start_rot_rand)
        local er = self.ignore_end_rot and sr or (self.end_rot + ran:float(-self.end_rot_rand, self.end_rot_rand))
        local A = self.start_A + ran:float(-self.start_A_rand, self.start_A_rand)
        local R = self.start_R + ran:float(-self.start_R_rand, self.start_R_rand)
        local G = self.start_G + ran:float(-self.start_G_rand, self.start_G_rand)
        local B = self.start_B + ran:float(-self.start_B_rand, self.start_B_rand)
        local eA = self.ignore_end_color and A or (self.end_A + ran:float(-self.end_A_rand, self.end_A_rand))
        local eR = self.ignore_end_color and R or (self.end_R + ran:float(-self.end_R_rand, self.end_R_rand))
        local eG = self.ignore_end_color and G or (self.end_G + ran:float(-self.end_G_rand, self.end_G_rand))
        local eB = self.ignore_end_color and B or (self.end_B + ran:float(-self.end_B_rand, self.end_B_rand))
        local fade_in = self.fade_in_time + ran:float(-self.fade_in_time_rand, self.fade_in_time_rand)
        local fade_out = self.fade_out_time + ran:float(-self.fade_out_time_rand, self.fade_out_time_rand)
        local lifetime = self.lifetime + ran:float(-self.lifetime_rand, self.lifetime_rand)

        ---@class Core.Effect.ParticleSystem.Particle
        self.objects[#self.objects + 1] = {
            x = ran:float(f.left, f.right) + r * cosa,
            y = ran:float(f.bottom, f.top) + r * sina,
            d_vx = (-sv + ev) * vcosa,
            d_vy = (-sv + ev) * vsina,
            vx = sv * vcosa,
            vy = sv * vsina,
            gravity_x = gx,
            gravity_y = gy,
            accel_rad = ar,
            accel_tan = at,
            size = ss,
            start_size = ss,
            end_size = es,
            rot = sr,
            start_rot = sr,
            end_rot = er,
            A = A,
            R = R,
            G = G,
            B = B,
            start_A = A,
            start_R = R,
            start_G = G,
            start_B = B,
            end_A = eA,
            end_R = eR,
            end_G = eG,
            end_B = eB,
            alpha = 0,
            fade_in_time = fade_in,
            fade_out_time = fade_out,
            lifetime = lifetime,
            timer = 0,
        }
    end
    self._emit_fraction = self._emit_fraction % 1
end

function M:update(dt)
    self.timer = self.timer + dt
    if self.timer <= self.duration and #self.objects < self.max_count then
        self:newParticle(self.emit_speed * dt)
    end

    for i = #self.objects, 1, -1 do
        local o = self.objects[i]
        local m = clamp(o.timer / o.lifetime, 0, 1)
        o.x = o.x + o.vx * dt
        o.y = o.y + o.vy * dt
        o.vx = o.vx + o.gravity_x * dt + o.d_vx / o.lifetime * dt
        o.vy = o.vy + o.gravity_y * dt + o.d_vy / o.lifetime * dt
        if o.accel_rad ~= 0 or o.accel_tan ~= 0 then
            local a = Core.Math.Angle(0, 0, o.vx, o.vy)
            local cosa, sina = cos(a), sin(a)
            o.vx = o.vx + o.accel_rad * cosa * dt + o.accel_tan * sina * dt
            o.vy = o.vy + o.accel_rad * sina * dt - o.accel_tan * cosa * dt
        end
        o.rot = lerp(o.start_rot, o.end_rot, m)
        o.size = lerp(o.start_size, o.end_size, m)
        o.A = lerp(o.start_A, o.end_A, m)
        o.R = lerp(o.start_R, o.end_R, m)
        o.G = lerp(o.start_G, o.end_G, m)
        o.B = lerp(o.start_B, o.end_B, m)

        if o.fade_in_time == 0 then
            o.alpha = 1
        elseif o.timer <= o.fade_in_time then
            o.alpha = o.timer / o.fade_in_time
        end
        if (o.fade_out_time ~= 0) and (o.timer >= o.lifetime - o.fade_out_time) then
            o.alpha = (o.lifetime - o.timer) / o.fade_out_time
        end
        if o.timer >= o.lifetime then
            table.remove(self.objects, i)
        end
        o.timer = o.timer + dt
    end

end
local Color = Core.Render.Color
function M:render()
    for _, o in ipairs(self.objects) do
        self.img_res:setState(self.blend, Color(o.A * o.alpha, o.R, o.G, o.B))
            :setPos(o.x, o.y)
            :setRotation(o.rot)
            :setScale(o.size, o.size)
            :draw(o.timer * self.ani_timer_multi)
    end
end



