---@class Core.Display.Camera3DController
local M = Core.Class()
Core.Display.Camera3DController = M

---@param camera Core.Display.Camera3D
function M:init(camera)
    self.camera = camera
    self.fov = self.camera.fov
    self.targetFov = self.fov
    self.minFov = 10
    self.maxFov = 150
    self.fovSpeed = 10
    self.rotationSpeed = 0.1
    self.moveSpeed = 20
    self.smoothFactor = 0.1
    self.pitch = self.camera.pitch
    self.dir = self.camera.dir
    self._pitch = self.pitch
    self._dir = self.dir
end

function M:frame()
    local mouse = Core.Input.Mouse
    -- 滚轮缩放
    local wheel = sign(mouse.GetWheel()) * 0.4
    if wheel ~= 0 then
        self.targetFov = clamp(self.targetFov - wheel * self.fovSpeed, self.minFov, self.maxFov)
    end
    self.fov = self.fov + (self.targetFov - self.fov) * self.smoothFactor
    if mouse.IsPressed(mouse.Key.Middle) then
        local dx, dy = mouse.GetDelta()
        self._pitch = self._pitch - dy * self.rotationSpeed
        self._dir = self._dir - dx * self.rotationSpeed
    end

    self.pitch = self.pitch + (self._pitch - self.pitch) * self.smoothFactor
    self.dir = self.dir + (self._dir - self.dir) * self.smoothFactor
    self.camera:setRotation(self.pitch, self.dir)
    self.camera:setFieldOfView(self.fov)
    local vec=Core.Math.Vector3.New(Core.Input.GetAxis("MoveForward"),
            Core.Input.GetAxis("MoveRight"),
            Core.Input.GetAxis("MoveUp"))
    if vec:magnitude() > 1 then
        vec:normalize()
    end
    self.camera:move(vec.x * self.moveSpeed, vec.y * self.moveSpeed, vec.z * self.moveSpeed)
end
