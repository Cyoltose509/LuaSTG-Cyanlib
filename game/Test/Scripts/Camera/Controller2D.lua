
---@class Test.Camera.Controller2D
local M = Core.Class()
Test.Camera.Controller2D = M

---@param camera Core.Display.Camera2D
function M:init(camera)
    self.camera = camera
    self.zoom = self.camera:getZoom()
    self.targetZoom = self.zoom
    self.minZoom = 0.2
    self.maxZoom = 4.0
    self.centerX, self.centerY = self.camera:getCenter()
    self.dragSpeed = 3
    self.zoomSpeed = 0.4
    self.smoothFactor = 0.1
    self.rot = self.camera:getRotation()
    self._rot = self.rot
    self.rotSpeed = 1
end

function M:frame()
    local mouse=Core.Input.Mouse
    local mx, my = mouse.GetPosition(self.camera)
    -- 滚轮缩放
    local wheel = sign(mouse.GetWheel()) * 0.4
    if wheel ~= 0 then
        self.targetZoom = clamp(self.targetZoom + wheel * self.zoomSpeed,
                self.minZoom,
                self.maxZoom)
    end
    local dv = self.targetZoom - self.zoom
    self.zoom = self.zoom + dv * self.smoothFactor

    self.centerX = self.centerX + (mx - self.centerX) * abs(dv) * 0.1
    self.centerY = self.centerY + (my - self.centerY) * abs(dv) * 0.1
    if mouse.IsPressed(mouse.Key.Middle) then
        local dx, dy = mouse.GetDelta(self.camera)
        self.centerX = self.centerX - dx / self.zoom
        self.centerY = self.centerY - dy / self.zoom
    end
    self.camera:setCenter(self.centerX, self.centerY)
    self.camera:setZoom(self.zoom)

    if mouse.IsPressed(mouse.Key.X1) then
        self._rot = self._rot - self.rotSpeed
    end
    if mouse.IsPressed(mouse.Key.X2) then
        self._rot = self._rot + self.rotSpeed
    end
    self.rot = self.rot + (-self.rot + self._rot) * self.smoothFactor
    self.camera:setRotation(self.rot)
end
