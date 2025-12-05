---@class Core.UI.Child
local M = Core.Class()
Core.UI.Child = M

M._serialize_simple = {
    "name",
    "_name",
    "layer",
    "x",
    "y",
    "width",
    "height",
    "hscale",
    "vscale",
    "rot",
}
M._serialize_order = {}
M._deserialize_order = {}

function M:addSerializeSimple(master, ...)
    self._serialize_simple = Core.Lib.Table.Copy(master._serialize_simple)
    for _, str in ipairs({ ... }) do
        table.insert(self._serialize_simple, str)
    end
end
---@param key string
---@param func fun(value:any, self:self):any
function M:addSerializeOrder(key, func)
    self._serialize_order[key] = func
end
---@param key string
---@param func fun(value:any, self:self):any
function M:addDeserializeOrder(key, func)
    self._deserialize_order[key] = func
end

---@alias Core.UI.Child.New Core.UI.Child|fun(name:string, layer:number):Core.UI.Child
function M:init(name, layer)
    ---@type Core.UI.Layout|Core.UI.Root
    self.parent = nil
    self.parentLayout = nil
    ---节点的名字信息
    self.name = name
    ---真正对象类型，用于序列化与反序列化
    ---@private
    self._name = name
    self.layer = layer or 0
    self:initStatus()
    ---是否参与序列化
    self.canSerialize = true
end

---@return table
function M:serialize()
    local data = {}
    if self.canSerialize then
        for _, k in ipairs(self._serialize_simple) do
            if self._serialize_order[k] then
                data[k] = self._serialize_order[k](self[k], self)
            else
                if type(self[k]) == "userdata" then
                    data[k] = tostring(self[k])
                else
                    data[k] = self[k]
                end
            end
            if self.children then
                data.children = {}
                for _, child in ipairs(self.children) do
                    if child.canSerialize then
                        table.insert(data.children, child:serialize())
                    end
                end
            end
        end
    end
    return data
end
---@param data table
---@return self
function M:deserialize(data)
    for k, v in pairs(data) do
        if k ~= "children" then
            if self._deserialize_order[k] then
                self[k] = self._deserialize_order[k](v, self)
            else
                self[k] = v
            end
        end
    end
    if data.children then
        self.children = {}
        for _, childData in ipairs(data.children) do
            local child = Core.UI[childData._name]()
            child:deserialize(childData)
            table.insert(self.children, child)
        end
    end
    return self
end

function M:update()
    self._hscale, self._vscale = self:getScale()
    self._x, self._y = self:getXY()
end
function M:draw()
end
---@return self
function M:setLayer(layer)
    self.layer = layer or self.layer
    if self.parent then
        self.parent._needSort = true
    end
    return self
end
function M:remove()
    if self.parent then
        self.parent:removeChild(self)
    end
end
---@return self
function M:setScale(hscale, vscale)
    self.hscale = hscale or self.hscale
    self.vscale = vscale or self.hscale
    return self
end
---@return self
function M:setPos(x, y)
    self.x = x or self.x
    self.y = y or self.y
    return self
end
function M:setRotation(rot)
    self.rot = rot
    return self
end
---初始化节点属性
---注意：x和y坐标并不一定是绝对坐标，而是相对于布局的坐标
---真正显示在屏幕上的坐标是_x和_y
---同理，真正显示在屏幕上的尺寸是_hscale和_vscale
---节点的width和height一般不会影响真正显示的尺寸，而会影响节点的布局，可以理解成节点的碰撞盒
---如果width和height比实际显示的尺寸要大，在布局中则会呈现出变小的效果，反之毅然
---如果要修改节点的实际尺寸而不影响布局，请修改hscale和vscale
---要注意部分节点并不参与rot的计算，因此rot的设置并不一定生效
---Initialize the node properties.
---Note: x and y coordinates are not necessarily absolute coordinates, but relative coordinates to the layout.
---The actual coordinates displayed on the screen are _x and _y.
---Similarly, the actual size displayed on the screen is _hscale and _vscale.
---The width and height of the node generally do not affect the actual size displayed,
---but will affect the layout of the node. It can be understood as the collision box of the node.
---If the width and height are larger than the actual displayed size, it will show a smaller effect in the layout and vice versa.
---If you want to modify the actual size of the node without affecting the layout, please modify hscale and vscale.
---Note that some nodes do not participate in the calculation of rot, so the setting of rot may not take effect.
---@return self
function M:initStatus()
    ---the relative x of the node
    self.x = 0
    ---the relative y of the node
    self.y = 0
    ---the rotation, sometimes it is not used
    self.rot = 0
    ---the width of the node, participating in the layout calculation
    self.width = 100
    ---the height of the node, participating in the layout calculation
    self.height = 100
    self.hscale = 1
    self.vscale = 1
    self._x = 0
    self._y = 0
    self._hscale = 1
    self._vscale = 1
    ---在layout下的位置
    self.layout_x = 0
    self.layout_y = 0
    ---在layout下自身产生的缩放（注意单位是倍率）
    self.layout_hscale = 1
    self.layout_vscale = 1
    ---忽视layout的缩放
    self.ignore_layout_scale = false
    if self.setDirty then
        self:setDirty()
    end
    return self
end

---@return self
function M:setWH(width, height)
    width = width or 100
    height = height or width
    self.width = width
    self.height = height
    if self.setDirty then
        self:setDirty()
    end
    return self
end

function M:setDirty()
    if self.parentLayout then
        self.parentLayout:setDirty()
    end
    return self
end
---@return self
function M:ignoreLayoutScale(enable)
    self.ignore_layout_scale = enable
    if self.setDirty then
        self:setDirty()
    end
    return self
end

function M:getScale()
    if self.ignore_layout_scale then
        return self.hscale, self.vscale
    end
    return self.hscale * self.layout_hscale, self.vscale * self.layout_vscale
end
function M:getXY()
    return self.x + self.layout_x, self.y + self.layout_y
end