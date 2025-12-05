---@class Core.Display.Camera2D : Core.Display.Camera.Base
local M = Core.Class(Core.Display.Camera.Base)
Core.Display.Camera2D = M
function M:init()
    Core.Display.Camera.Base.init(self)
    self.rot = 0
    self._is_2d = true
    self.view = {
        centerX = 0,
        centerY = 0,
        width = 100,
        height = 100,
        zoom = 1,
    }
    self.viewport = {
        left = -100,
        right = 100,
        bottom = -100,
        top = 100,
    }
end

---@param centerX number
---@param centerY number
---@param width number
---@param height number
function M:setView(centerX, centerY, width, height)
    self.view.centerX = centerX
    self.view.centerY = centerY
    self.view.width = width
    self.view.height = height
    return self
end
function M:setZoom(zoom)
    self.view.zoom = zoom
    return self
end
function M:addZoom(add)
    self.view.zoom = self.view.zoom + add
    return self
end
function M:getZoom()
    return self.view.zoom
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

function M:getViewportSize()
    return self.viewport.right - self.viewport.left, self.viewport.top - self.viewport.bottom
end

function M:getViewSize()
    local zoom = self.view.zoom
    return self.view.width / zoom, self.view.height / zoom
end
function M:getCenter()
    return self.view.centerX, self.view.centerY
end
function M:setCenter(x, y)
    self.view.centerX = x
    self.view.centerY = y
    return self
end

local view = {
    centerX = 0,
    centerY = 0,
    width = 100,
    height = 100,
    left = 0,
    right = 100,
    bottom = 0,
    top = 100,
}
---返回一个只读的table，包含相机视角的参数
---return a read-only table of the camera view parameters
function M:getView()
    local vw, vh = self:getViewSize()
    local cx, cy = self:getCenter()
    view.centerX = cx
    view.centerY = cy
    view.width = vw
    view.height = vh
    view.left = cx - vw / 2
    view.right = cx + vw / 2
    view.bottom = cy - vh / 2
    view.top = cy + vh / 2
    return view
end
local viewport = {
    left = 0,
    right = 100,
    bottom = 0,
    top = 100,
}
---返回一个只读的table，包含相机视角的视窗参数
---return a read-only table of the camera viewport parameters
function M:getViewport()
    viewport.left = self.viewport.left
    viewport.right = self.viewport.right
    viewport.bottom = self.viewport.bottom
    viewport.top = self.viewport.top
    return viewport
end

---将世界坐标转换为相机坐标
---Convert world coordinates to camera coordinates
function M:worldToScreen(x, y)
    x = x - self.view.centerX
    y = y - self.view.centerY
    if self.rot ~= 0 then
        local cosR, sinR = cos(-self.rot), sin(-self.rot)
        x, y = x * cosR - y * sinR, x * sinR + y * cosR
    end
    local w, h = self:getViewportSize()
    local vw, vh = self:getViewSize()
    local vx, vy = (self.viewport.left + self.viewport.right) / 2, (self.viewport.bottom + self.viewport.top) / 2
    return vx + x / vw * w, vy + y / vh * h
end

---将相机坐标转换为世界坐标
---Convert camera coordinates to world coordinates
function M:screenToWorld(x, y)
    x = x - self.viewport.left
    y = y - self.viewport.bottom
    local w, h = self:getViewportSize()
    local vw, vh = self:getViewSize()
    local left, bottom = self.view.centerX - vw / 2, self.view.centerY - vh / 2
    local wX = left + x / w * vw
    local wY = bottom + y / h * vh
    if self.rot ~= 0 then
        local cx, cy = self:getCenter()
        local dx, dy = wX - cx, wY - cy
        local cosR, sinR = cos(self.rot), sin(self.rot)
        wX = dx * cosR - dy * sinR + cx
        wY = dx * sinR + dy * cosR + cy
    end
    return wX, wY
end

function M:worldToScreenDelta(dx, dy)
    local rot = self.rot
    local vw, vh = self:getViewSize()
    local w, h = self:getViewportSize()
    local scaleX, scaleY = vw / w, vh / h
    if rot ~= 0 then
        local cosR, sinR = cos(rot), sin(rot)
        local rx = dx * cosR - dy * sinR
        local ry = dx * sinR + dy * cosR
        dx, dy = rx, ry
    end
    dx, dy = dx * scaleX, dy * scaleY
    return dx, dy

end
function M:screenToWorldDelta(dx, dy)
    local rot = self.rot
    local vw, vh = self:getViewSize()
    local w, h = self:getViewportSize()
    local scaleX, scaleY = vw / w, vh / h
    if rot ~= 0 then
        local cosR, sinR = cos(rot), sin(rot)
        local rx = dx * cosR - dy * sinR
        local ry = dx * sinR + dy * cosR
        dx, dy = rx, ry
    end
    dx, dy = dx / scaleX, dy / scaleY
    return dx, dy
end

function M:getRotation()
    return self.rot
end
---注意：旋转是用透视投影模拟的，
---rot一旦非0，将会启用透视投影
---若为了减少性能开销，可以尽量不修改rot
---Note: Rotation is simulated by perspective projection,
---if rot is not 0, perspective projection will be enabled.
---If you want to reduce performance overhead, try not to modify it.
function M:setRotation(rot)
    self.rot = rot
    return self
end

---应用相机参数
---Apply the camera parameters
function M:apply()
    lstg.SetViewport(self.viewport.left, self.viewport.right, self.viewport.bottom, self.viewport.top)
    lstg.SetScissorRect(self.viewport.left, self.viewport.right, self.viewport.bottom, self.viewport.top)
    local vw, vh = self:getViewSize()
    local cx, cy = self:getCenter()
    if self.rot == 0 then
        lstg.SetOrtho(cx - vw / 2, cx + vw / 2, cy - vh / 2, cy + vh / 2)
    else
        --用透视投影模拟旋转
        local z = -1000
        local fovy = 2 * math.atan(abs(vh / 2 / z))
        local aspect = vw / vh
        lstg.SetPerspective(cx, cy, z, cx, cy, 0, -sin(self.rot), cos(self.rot), 0, fovy, aspect, 0.001, 1000)
    end
    lstg.SetImageScale(1)
    lstg.SetFog()
    return self
end

function M:reset()
    local sw, sh = Core.Display.Screen.GetSize()
    local w, h = Core.Display.Window.GetSize()
    self:setViewport(0, w, 0, h)
        :setView(sw / 2, sh / 2, sw, sh)
    return self
end

---以此相机视角创建一个world对象
---Create a world object with this camera view
---@param outside number@边界外围的距离，单位为像素
---@return Core.World
function M:getWorld(outside)
    local view = self:getView()
    return Core.World.New(view.left, view.right, view.bottom, view.top, outside)
end
