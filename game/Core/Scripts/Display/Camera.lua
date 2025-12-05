---@class Core.Display.Camera
local M = { }
Core.Display.Camera = M
---@type Core.Display.Camera.Base[]
M.List = {}
---@type Core.Display.Camera.Base
M.Current = nil

function M.Render()
    for _, camera in ipairs(M.List) do
        M.Current = camera
        camera:render()
    end
    M.Current = nil
end
function M.Frame()
    for _, camera in ipairs(M.List) do
        Core.Task.Do(camera._shakeTask)
        Core.Task.Do(camera)
        camera.renderEvents:dispatch("update")
    end
end

function M.GetCurrent()
    return M.Current
end

---摄像机基类
---Base class of camera
---@class Core.Display.Camera.Base
local base = Core.Class()
M.Base = base

function base:init()
    self._shakeTask = {}
    self.renderObjs = {}
    self.apply_stack = 0
    self.renderEvents = Core.Lib.EventListener()
    self.renderEvents:create("update")
    self.renderEvents:create("before")
    self.renderEvents:create("after")
end
---@return self
function base:register(level)
    self.level = level or 0
    table.insert(M.List, self)
    table.sort(M.List, function(a, b)
        return a.level < b.level
    end)
    return self
end
function base:release()
    for _, c in ipairs(self.renderObjs) do
        Core.Object.Del(c.obj)
    end
    for i = #M.List, 1, -1 do
        if M.List[i] == self then
            table.remove(M.List, i)
            break
        end
    end
    self.renderObjs = {}
    self.renderEvents = nil
    --TODO：是否需要释放RenderTarget？
end

function base:worldToScreen()
end

function base:screenToWorld()
end

---将当前摄像机下的世界坐标，通过屏幕坐标映射，转换为另一摄像机下的世界坐标
---Convert the world coordinates in the current camera view to the world coordinates in another camera view
---@overload fun(otherCamera:Core.Display.Camera3D, x:number, y:number, z:number, virtual_z:number):number, number, number
---@overload fun(otherCamera:Core.Display.Camera2D, x:number, y:number, virtual_z:number):number, number
function base:worldToWorld(otherCamera, x, y, z, virtual_z)
    local x0, y0 = self:worldToScreen(x, y, z or 0.5)
    local x1, y1, z1 = otherCamera:screenToWorld(x0, y0, virtual_z or 0.5)
    return x1, y1, z1
end

---将当前摄像机视角下的相机坐标，转换为另一摄像机视角下的相机坐标
---Convert the camera coordinates in the current camera view to the camera coordinates in another camera view
---@param otherCamera Core.Display.Camera
---@param x number
---@param y number
---@param virtual_z number
---@return number, number
function base:screenToScreen(otherCamera, x, y, virtual_z)
    local x0, y0, z0 = self:screenToWorld(x, y, virtual_z or 0.5)
    local x1, y1 = otherCamera:worldToScreen(x0, y0, z0)
    return x1, y1
end

---重置Camera参数
---如果要实现自动重置，要把该相机注册给Core.Display.Screen，在Screen刷新时调用Reset时，会调用此函数
---Reset the camera parameters
---If you want to implement automatic reset, you need to register the camera to Core.Display.Screen and call this function when the screen is refreshed.
---@see Core.Display.Screen
function base:reset()

end

---应用Camera参数
function base:apply()

end

function base:finish()
    lstg.SetViewport(0, 0, 0, 0)
    lstg.SetScissorRect(0, 0, 0, 0)
    if self.z_buffer_enable then
        lstg.SetZBufferEnable(0)
    end
end

local RenderEventObj = Core.Object.Define(Core.Object.Base, {
    init = function(self, layer, master, renderf, updatef)
        self.layer = layer
        self.renderf = renderf
        self.updatef = updatef
        self.colli = false
        self.bound = false
        self.group = Core.Object.Group.Ghost
        self.master = master
    end,
    frame = function(self)
        if self.updatef then
            self.updatef()
        end
    end,
    render = function(self)
        if self.renderf and M.Current == self.master then
            self.renderf()
        end
    end,
}, true)
---@return self
function base:setRenderTarget(target)
    self.renderTarget = target
    return self
end

function base:pushRenderTarget()
    if self.renderTarget then
        lstg.PushRenderTarget(self.renderTarget)
        if self._notClearRenderTarget then
            lstg.RenderClear(Core.Render.Color.Black)
            self._notClearRenderTarget = false
        end
    end
end
function base:popRenderTarget()
    if self.renderTarget then
        lstg.PopRenderTarget()
    end
end
---@return self
function base:addBeforeRenderEvent(name, layer, render, update)
    self.renderEvents:addEvent("before", name, layer, render)
    if update then
        self.renderEvents:addEvent("update", name, layer, update)
    end
    return self
end
---@return self
function base:addAfterRenderEvent(name, layer, render, update)
    self.renderEvents:addEvent("after", name, layer, render)
    if update then
        self.renderEvents:addEvent("update", name, layer, update)
    end
    return self
end

---添加渲染事件
---@param layer number|"before"|"after"
---@return self
function base:addRenderObjects(name, layer, render, update)
    local obj = Core.Object.New(RenderEventObj, layer, self, function()
        self:startCapture()
        render()
        self:stopCapture()
    end, update)
    table.insert(self.renderObjs, {
        name = name,
        obj = obj
    })

    return self
end

---@return self
function base:removeBeforeRenderEvent(name)

    self.renderEvents:remove("before", name)
    self.renderEvents:remove("update", name)
end

---@return self
function base:removeAfterRenderEvent(name)

    self.renderEvents:remove("after", name)
    self.renderEvents:remove("update", name)
end

---@return self
function base:removeRenderObjects(name)
    for i, v in ipairs(self.renderObjs) do
        if v.name == name then
            --如果有重名的对象，会全都删除
            Core.Object.Del(v.obj)
            table.remove(self.renderObjs, i)

        end
    end
end

function base:startCapture()
    self.apply_stack = self.apply_stack + 1
    if self.apply_stack == 1 then
        self:apply()
        self:pushRenderTarget()
    end
end
function base:stopCapture()
    self.apply_stack = self.apply_stack - 1
    if self.apply_stack == 0 then
        self:popRenderTarget()
        self:finish()
    end
end

---@return self
function base:captureLayers(name, fromLayer, toLayer)
    local obj1 = Core.Object.New(RenderEventObj, fromLayer, self, function()
        self:startCapture()
    end)
    local obj2 = Core.Object.New(RenderEventObj, toLayer, self, function()
        self:stopCapture()
    end)
    table.insert(self.renderObjs, {
        name = name,
        obj = obj1,
    })
    table.insert(self.renderObjs, {
        name = name,
        obj = obj2,
    })
    return self
end

function base:render()
    if self.renderTarget then
        self._notClearRenderTarget = true
    end
    if self.z_buffer_enable then
        self._notClearZBuffer = true
    end
    if not self.renderEvents:empty("before") then
        self:startCapture()
        self.renderEvents:dispatch("before")
        self:stopCapture()
    end
    if #self.renderObjs > 0 then
        lstg.ObjRender()
    end
    if not self.renderEvents:empty("after") then
        self:startCapture()
        self.renderEvents:dispatch("after")
        self:stopCapture()
    end
end

---@return self
function base:setResponsiveViewport(enable)
    if enable then
        Core.Display.Screen.RegisterCamera(self)
    else
        Core.Display.Screen.UnregisterCamera(self)
    end
    return self
end

