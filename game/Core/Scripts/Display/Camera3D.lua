---@class Core.Display.Camera3D : Core.Display.Camera.Base
local M = Core.Class(Core.Display.Camera.Base)
Core.Display.Camera3D = M
function M:init()
    Core.Display.Camera.Base.init(self)
    self._is_3d = true
    self.yaw = 0
    self.pitch = 0
    self.roll = 0
    self.x = 0
    self.y = 0
    self.z = -10
    self._shake_x = 0
    self._shake_y = 0
    self._shake_z = 0

    self.fov = 80
    self.z_near = 0.01
    self.z_far = 1000.0
    self.z_buffer_enable = false
    self.fog_enable = false
    self.fog_near = 5
    self.fog_far = 20
    self.fog_color = { 0, 0, 0 }

    self.viewport = {
        left = -100,
        right = 100,
        bottom = -100,
        top = 100,
    }
end

local function vec2_rot(x, y, r_deg)
    local sin_v = sin(r_deg)
    local cos_v = cos(r_deg)
    return x * cos_v - y * sin_v, x * sin_v + y * cos_v
end

function M:fixedShake(time, strength, interval, way, fadeout_size_mode)
    Core.Task.Clear(self._shakeTask)
    Core.Task.New(self._shakeTask, function()
        local times = time / interval
        local a = 0
        local size = strength
        for i = 1, times do
            local fx, fy, fz = self:getForward()
            local ux, uy, uz = self:getUp()
            local rx, ry, rz = uy * fz - uz * fy, uz * fx - ux * fz, ux * fy - uy * fx
            local x, y, z = size * cos(a), size * sin(a), 0
            self._shake_x = x * rx + y * ux + z * fx
            self._shake_y = x * ry + y * uy + z * fy
            self._shake_z = x * rz + y * uz + z * fz
            if fadeout_size_mode then
                size = strength * Core.Lib.Easing[fadeout_size_mode](1 - i / times)
            end
            a = a + 360 / way
            Core.Task.Wait(interval)
        end
        self._shake_x = 0
        self._shake_y = 0
        self._shake_z = 0
    end)
end

function M:shake(time, strength, interval, way, fadeout_size_mode)
    Core.Task.Clear(self._shakeTask)
    Core.Task.New(self._shakeTask, function(dt)
        local times = int(time / interval)
        local a = 0
        local size = strength
        local timer = 0
        local i = 1
        while i < times do
            if timer >= interval then
                local fx, fy, fz = self:getForward()
                local ux, uy, uz = self:getUp()
                local rx, ry, rz = uy * fz - uz * fy, uz * fx - ux * fz, ux * fy - uy * fx
                local x, y, z = size * cos(a), size * sin(a), 0
                self._shake_x = x * rx + y * ux + z * fx
                self._shake_y = x * ry + y * uy + z * fy
                self._shake_z = x * rz + y * uz + z * fz
                if fadeout_size_mode then
                    size = strength * Core.Lib.Easing[fadeout_size_mode](1 - i / times)
                end
                a = a + 360 / way
                i = i + 1
                timer = timer % interval
            end
            timer = timer + dt
            Core.Task.Yield()
        end
        self._shake_x = 0
        self._shake_y = 0
        self._shake_z = 0
    end)
end

function M:apply()
    local fx, fy, fz = self:getForward()
    local ux, uy, uz = self:getUp()
    local vp = self.viewport
    local vl, vr, vb, vt = vp.left, vp.right, vp.bottom, vp.top
    local w, h = vp.right - vp.left, vp.top - vp.bottom
    local x, y, z = self.x + self._shake_x, self.y + self._shake_y, self.z + self._shake_z
    lstg.SetViewport(vl, vr, vb, vt)
    lstg.SetScissorRect(vl, vr, vb, vt)
    lstg.SetPerspective(x, y, z,
            x + fx, y + fy, z + fz,
            ux, uy, uz,
            math.rad(self.fov), w / h,
            self.z_near, self.z_far
    )
    lstg.SetImageScale(1)
    if self.fog_enable then
        lstg.SetFog(self.fog_near, self.fog_far, lstg.Color(
                255,
                self.fog_color[1],
                self.fog_color[2],
                self.fog_color[3]
        ))
    else
        lstg.SetFog()
    end
    if self.z_buffer_enable then
        lstg.SetZBufferEnable(1)
        if self._notClearZBuffer then
            lstg.ClearZBuffer(1)
            self._notClearZBuffer = false
        end
    end
    return self
end
function M:setZBufferEnable(enable)
    self.z_buffer_enable = enable
    return self
end

function M:getForward()
    local fx, fy, fz = 0, 0, 1
    fy, fz = vec2_rot(fy, fz, self.pitch)
    fx, fz = vec2_rot(fx, fz, self.yaw)
    fx, fy = vec2_rot(fx, fy, self.roll)
    return fx, fy, fz
end
function M:getUp()
    local ux, uy, uz = 0, 1, 0
    uy, uz = vec2_rot(uy, uz, self.pitch)
    ux, uz = vec2_rot(ux, uz, self.yaw)
    ux, uy = vec2_rot(ux, uy, self.roll)
    return ux, uy, uz
end

function M:getPosition()
    return self.x, self.y, self.z
end

---@param x number
---@param y number
---@param z number
function M:setPosition(x, y, z)
    self.x = x
    self.y = y
    self.z = z
    return self
end
---@param pitch number@绕X轴旋转的角度
---@param yaw number@绕Y轴旋转的角度
---@param roll number@绕Z轴旋转的角度
function M:setRotation(pitch, yaw, roll)
    self.pitch = pitch or self.pitch
    self.yaw = yaw or self.yaw
    self.roll = roll or self.roll
    return self
end
---@param z_near number
---@param z_far number
function M:setViewDistance(z_near, z_far)
    assert(z_near >= 0 and z_far > z_near)
    self.z_near = z_near
    self.z_far = z_far
    return self
end
---@param fov number
function M:setFieldOfView(fov)
    assert(fov > 0 and fov < 180)
    self.fov = fov
    return self
end

---@param enable boolean
---@return self
function M:setFogEnable(enable)
    self.fog_enable = enable
    return self
end
---@param near number
---@param far number
function M:setFogLinear(near, far)
    assert(near >= 0 and far > near)
    self.fog_near = near
    self.fog_far = far
    return self
end
---@param density number
function M:setFogExp(density)
    self.fog_near = -1
    self.fog_far = density
    return self
end
---@param density number
function M:setFogExp2(density)
    self.fog_near = -2
    self.fog_far = density
    return self
end
---@param r number
---@param g number
---@param b number
function M:setFogColorU(r, g, b)
    assert(r >= 0 and r <= 255)
    assert(g >= 0 and g <= 255)
    assert(b >= 0 and b <= 255)
    self.fog_color[1] = r
    self.fog_color[2] = g
    self.fog_color[3] = b
    return self
end

---@overload fun(left:number, right:number, bottom:number, top:number):void
---@overload fun(viewport:table):void
function M:setViewport(left, right, bottom, top)
    if type(left) == 'table' then
        self.viewport = left
    else
        self.viewport.left = left
        self.viewport.right = right
        self.viewport.bottom = bottom
        self.viewport.top = top
    end
    return self
end

local function normalize(_x, _y, _z)
    local len = math.sqrt(_x * _x + _y * _y + _z * _z)
    if len < 1e-8 then
        return _x, _y, _z
    end
    return _x / len, _y / len, _z / len
end

---获取屏幕坐标对应的射线
---如果objectified为true，则返回Core.Math.Ray3对象，否则返回x,y,z,dx,dy,dz
---Get the ray corresponding to the screen coordinates.
---If objectified is true, the Core.Math.Ray3 object is returned, otherwise x,y,z,dx,dy,dz is returned.
---@overload fun(cx:number, cy:number):number, number, number, number, number, number
---@overload fun(cx:number, cy:number, objectified:boolean):Core.Math.Ray3
function M:screenToRay(cx, cy, objectified)
    local vp = self.viewport
    local w, h = vp.right - vp.left, vp.top - vp.bottom

    -- 转为 NDC
    local ndc_x = -(2 * (cx - vp.left) / w - 1)
    local ndc_y = (2 * (cy - vp.bottom) / h - 1)

    local aspect = w / h
    local tan_fov = tan(self.fov * 0.5)

    local dir_eye_x = ndc_x * aspect * tan_fov
    local dir_eye_y = ndc_y * tan_fov
    local dir_eye_z = 1

    local fx, fy, fz = self:getForward()
    local ux, uy, uz = self:getUp()

    local rx, ry, rz = fy * uz - fz * uy, fz * ux - fx * uz, fx * uy - fy * ux
    rx, ry, rz = normalize(rx, ry, rz)
    fx, fy, fz = normalize(fx, fy, fz)
    ux, uy, uz = normalize(ux, uy, uz)
    local dx = dir_eye_x * rx + dir_eye_y * ux + dir_eye_z * fx
    local dy = dir_eye_x * ry + dir_eye_y * uy + dir_eye_z * fy
    local dz = dir_eye_x * rz + dir_eye_y * uz + dir_eye_z * fz

    dx, dy, dz = normalize(dx, dy, dz)
    local x, y, z = self.x + self._shake_x, self.y + self._shake_y, self.z + self._shake_z
    if objectified then
        local Math = Core.Math
        return Math.Ray3.New(Math.Vector3.New(x, y, z), Math.Vector3.New(dx, dy, dz))
    else
        return x, y, z, dx, dy, dz
    end
end

---指定Z坐标，返回相机视角下，该Z坐标对应的世界坐标
---Specified Z coordinate, return the world coordinates corresponding to the Z coordinate in the camera's perspective.
---@param cx number
---@param cy number
---@param z_plane number
---@return number, number, number
function M:screenToWorld(cx, cy, z_plane)
    local ox, oy, oz, dx, dy, dz = self:screenToRay(cx, cy)
    if abs(dz) < 1e-6 then
        return math.huge, math.huge, z_plane
    end
    local t = (z_plane - oz) / dz
    if t < 0 then
        return math.huge, math.huge, z_plane
    end
    return ox + dx * t, oy + dy * t, z_plane
end
---获取世界坐标对应相机视角下的屏幕坐标
---Get the screen coordinates corresponding to the world coordinates in the camera's perspective.
---@return number, number
function M:worldToScreen(x, y, z)
    local vp = self.viewport
    local dx = x - self.x - self._shake_x
    local dy = y - self.y - self._shake_y
    local dz = z - self.z - self._shake_z
    local w, h = vp.right - vp.left, vp.top - vp.bottom
    local aspect = w / h
    local tan_fov = tan(self.fov / 2)
    local fx, fy, fz = self:getForward()
    local ux, uy, uz = self:getUp()
    local rx, ry, rz = fy * uz - fz * uy, fz * ux - fx * uz, fx * uy - fy * ux

    rx, ry, rz = normalize(rx, ry, rz)
    fx, fy, fz = normalize(fx, fy, fz)
    ux, uy, uz = normalize(ux, uy, uz)

    local dir_eye_x, dir_eye_y, dir_eye_z = Core.Math.Solve3x3(
            rx, ux, fx, dx,
            ry, uy, fy, dy,
            rz, uz, fz, dz)
    if dir_eye_z and dir_eye_z > 0 then

        local ndc_x = dir_eye_x / (dir_eye_z * tan_fov * aspect)
        local ndc_y = dir_eye_y / (dir_eye_z * tan_fov)

        local screen_x = vp.left + (-ndc_x + 1) * w / 2
        local screen_y = vp.bottom + (ndc_y + 1) * h / 2

        return screen_x, screen_y
    else
        local huge = math.huge
        return huge, huge
    end
end

---Get the depth scale of the specified world coordinates in the camera's perspective.
---@param px number
---@param py number
---@param pz number
---@return number
function M:getDepthScale(px, py, pz)
    local ux, uy, uz = self:getUp()
    local x, y = self:worldToScreen(px, py, pz)
    local x1, y1 = self:worldToScreen(px + ux, py + uy, pz + uz)
    return hypot(x1 - x, y1 - y)
end

function M:moveForward(value)
    local fx, fy, fz = self:getForward()
    self.x = self.x + value * fx
    self.y = self.y + value * fy
    self.z = self.z + value * fz
end
function M:moveRight(value)
    local fx, fy, fz = self:getForward()
    local ux, uy, uz = self:getUp()
    local rx, ry, rz = uy * fz - uz * fy, uz * fx - ux * fz, ux * fy - uy * fx
    self.x = self.x + value * rx
    self.y = self.y + value * ry
    self.z = self.z + value * rz
end
function M:moveUp(value)
    local ux, uy, uz = self:getUp()
    self.x = self.x + value * ux
    self.y = self.y + value * uy
    self.z = self.z + value * uz
end
function M:fly(forward, right, up)
    local fx, fy, fz = self:getForward()
    local ux, uy, uz = self:getUp()
    local rx, ry, rz = uy * fz - uz * fy, uz * fx - ux * fz, ux * fy - uy * fx
    self.x = self.x + fx * forward + rx * right + ux * up
    self.y = self.y + fy * forward + ry * right + uy * up
    self.z = self.z + fz * forward + rz * right + uz * up
end
function M:move(forward, right, up)
    local fx, fy, fz = self:getForward()
    fy = 0
    local f = sqrt(fx * fx + fy * fy + fz * fz)
    fx, fy, fz = fx / f, fy / f, fz / f
    local ux, uy, uz = 0, 1, 0
    local rx, ry, rz = uy * fz - uz * fy, uz * fx - ux * fz, ux * fy - uy * fx
    self.x = self.x + fx * forward + rx * right + ux * up
    self.y = self.y + fy * forward + ry * right + uy * up
    self.z = self.z + fz * forward + rz * right + uz * up
end

---@param skybox Core.Render.Skybox.MeshRenderer
function M:setSkybox(skybox)
    self:addBeforeRenderEvent("Skybox", -11100, function()
        lstg.SetFog()--天空盒不受雾影响
        skybox:setPosition(self.x, self.y, self.z):draw()
        self:apply()
    end)
    return self
end

function M:pointInScreen(x, y, off)
    off = off or 0
    return x >= self.viewport.left - off
            and x <= self.viewport.right + off
            and y >= self.viewport.bottom - off
            and y <= self.viewport.top + off
end

---粗略计算一个球范围是否在屏幕内
---用于简化渲染
function M:sphereInScreen(px, py, pz, r)
    local ux, uy, uz = self:getUp()
    local x, y = self:worldToScreen(px, py, pz)
    local x1, y1 = self:worldToScreen(px + ux, py + uy, pz + uz)
    return self:pointInScreen(x, y, r * 2 * hypot(x1 - x, y1 - y))
end

function M:applyPostEffect()
    if not self.renderTarget or not self.postEffect then
        return
    end
    --TODO
    Core.UI.Camera:apply()
        self.postEffect(self.renderTarget, self.viewport.left, self.viewport.bottom, 1 / Core.Display.Screen.GetScale())
end

function M:reset()
    local w, h = Core.Display.Window.GetSize()
    self:setViewport(0, w, 0, h)
    return self
end