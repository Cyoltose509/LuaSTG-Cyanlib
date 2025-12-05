---@class Core.UI.Manager
local M = {}
Core.UI.Manager = M

local Canvas = {
    ---@type Core.UI.Root[]
    roots = {},
    _needSort = false
}

function Canvas:addRoot(root)
    table.insert(self.roots, root)
    self._needSort = true
end

function Canvas:removeRoot(root)
    for i, r in ipairs(self.roots) do
        if r == root then
            table.remove(self.roots, i)
            self._needSort = true
            return
        end
    end
end

function Canvas:update()
    if self._needSort then
        table.sort(self.roots, function(a, b)
            return (a.layer or 0) < (b.layer or 0)
        end)
        self._needSort = nil
    end
    for _, root in ipairs(self.roots) do
        if root.update then
            root:update()

        end
    end
end

function Canvas:draw()
    for _, root in ipairs(self.roots) do
        if root.draw then
            root:draw()
        end
    end
end

--- Creates a new root and adds it to the canvas.
function M.CreateHUDRoot(name, layer)
    local root = Core.UI.Root(name, layer)
    Canvas:addRoot(root)
    return root
end
function M.DestroyHUDRoot(root)
    Canvas:removeRoot(root)
end

---@param camera Core.Display.Camera.Base The camera to use for the root.
function M.CreateCameraRoot(camera, name, layer)
    layer = layer or 0
    local root = Core.UI.Root(name, layer)
    root.camera = camera
    camera:addRenderObjects(name, layer, function()
        root:draw()
    end, function()
        root:update()
    end)
     --Canvas:addRoot(root)
    return root
end

function M.Update()
    Canvas:update()
end
function M.Draw()
    Core.UI.Camera:apply()
    Canvas:draw()
end