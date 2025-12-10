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
    self.parent_layout = nil
    ---节点的名字信息
    self.name = name
    ---真正对象类型，用于序列化与反序列化
    ---@private
    self._name = name
    self.layer = layer or 0
    self:initStatus()
    ---是否参与序列化
    self.can_serialize = true
end

---@return table
function M:serialize()
    local data = {}
    if self.can_serialize then
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
        end
        if self.children then
            data.children = {}
            for _, child in ipairs(self.children) do
                if child.can_serialize then
                    table.insert(data.children, child:serialize())
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
            local child = Core.UI.ParseName(childData._name)()
            child:deserialize(childData)
            child.parent = self
            table.insert(self.children, child)
        end
    end
    return self
end
---omg，这是什么鬼
---omg what the fuck
function M:before_update()
    for _, child in ipairs(self.children) do
        if child.before_update then
            child:before_update()
        end
    end
end
function M:update()
    if self._need_sort then
        table.sort(self.children, function(a, b)
            return (a.layer or 0) < (b.layer or 0)
        end)
        self._need_sort = nil
    end
    self._last_hscale, self._last_vscale = self._hscale, self._vscale
    self._last_x, self._last_y = self._x, self._y

    self._hscale, self._vscale = self:getScale()
    self._x, self._y = self:getXY()
    if not self._need_update then
        if not self._ignore_pos_update and (self._x ~= self._last_x or self._y ~= self._last_y) then
            self._need_update = true
        end
        if not self._ignore_scale_update and (self._hscale ~= self._last_hscale or self._vscale ~= self._last_vscale) then
            self._need_update = true
        end
    end
    for _, child in ipairs(self.children) do
        if child.update then
            child:update()
        end
    end
end
function M:draw()
    for _, child in pairs(self.children) do
        if child.draw then
            child:draw()
        end
    end
end
---@return self
function M:setLayer(layer)
    self.layer = layer or self.layer
    if self.parent then
        self.parent._need_sort = true
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
---@return self
function M:setRotation(rot)
    rot = rot or 0
    if rot ~= self.rot then
        self.rot = rot
        self._need_update = true
    end
    return self
end
---初始化节点属性
---注意：x和y坐标并不是绝对坐标，而是相对于布局和父节点的坐标
---真正显示在屏幕上的坐标是_x和_y
---同理，真正显示在屏幕上的尺寸是_hscale和_vscale
---如果要忽略布局对缩放带来的影响，请调用ignoreLayoutScale(enable)
---节点的width和height一般不会影响真正显示的尺寸，而会影响节点的布局，可以理解成节点的碰撞盒
---如果width和height比实际显示的尺寸要大，在布局中则会呈现出变小的效果，反之毅然
---如果要修改节点的实际尺寸而不影响布局，请修改hscale和vscale
---要注意可能有节点并不参与rot的计算，因此rot的设置并不一定生效
---当_x, _y, _hscale, _vscale等变化时，_need_update会变为true，可用于一些渲染数据的刷新
---同时也可以屏蔽某一方面的变化带来的更新，比如ignore_pos_update和ignore_scale_update
---一般不应对对象操作这两个属性
---Initialize the node properties.
---Note: x and y coordinates are not absolute coordinates, but relative to the layout and parent nodes.
---The actual coordinates displayed on the screen are _x and _y.
---Similarly, the actual size displayed on the screen is _hscale and _vscale.
---If you want to ignore the layout scale effect, please call ignoreLayoutScale(enable).
---The width and height of the node generally do not affect the actual size displayed,
---but will affect the layout of the node. It can be understood as the collision box of the node.
---If the width and height are larger than the actual displayed size, it will show a smaller effect in the layout and vice versa.
---If you want to modify the actual size of the node without affecting the layout, please modify hscale and vscale.
---Note that maybe not all nodes participate in the rot calculation, so the setting of rot may not take effect.
---when _x, _y, _hscale, _vscale and some properties change, _need_update will become true, which can be used for refreshing rendering data.
---At the same time, you can block some changes to the update by setting ignore_pos_update and ignore_scale_update (not object operation).
---@return self
function M:initStatus()
    ---whether ignore pos change to _need_update
    self._ignore_pos_update = false
    ---whether ignore scale change to _need_update
    self._ignore_scale_update = false
    ---some class will use this to refresh rendering data
    self._need_update = false
    ---whether link scale to parent
    self.link_parent_scale = false
    self.children = {}
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
    self._last_x = 0
    self._last_y = 0
    self._last_hscale = 1
    self._last_vscale = 1
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
function M:enableLinkParentScale(scale)
    self.link_parent_scale = scale
    return self
end

---@return self
function M:addChild(child)
    table.insert(self.children, child)
    child.parent = self
    self._need_sort = true
    return self
end
---@return self
function M:removeChild(child)
    for i, c in ipairs(self.children) do
        if c == child then
            table.remove(self.children, i)
            child.parent = nil
            self._need_sort = true
            break
        end
    end
    return self
end

---@return self
function M:setWH(width, height)
    width = width or 100
    height = height or width
    if width ~= self.width or height ~= self.height then
        self.width = width
        self.height = height
        if self.setDirty then
            self:setDirty()
        end
    end
    return self
end

---@return self
function M:setDirty()
    if self.parent_layout then
        self.parent_layout:setDirty()
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
    if self.link_parent_scale and self.parent then
        local w = self.parent.width * self.parent._hscale / self.width
        local h = self.parent.height * self.parent._vscale / self.height
        return w * self.hscale * self.layout_hscale, h * self.vscale * self.layout_vscale
    end
    return self.hscale * self.layout_hscale, self.vscale * self.layout_vscale
end
function M:getXY()
    local x, y = self.x + self.layout_x, self.y + self.layout_y
    if self.parent then
        x = x + self.parent._x
        y = y + self.parent._y
    end
    return x, y
end
