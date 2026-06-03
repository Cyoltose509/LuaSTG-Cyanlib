---@class Core.UI.Layout
local M = {}
Core.UI.Layout = M

---@alias Core.UI.Layout.Alignment table<number, number>
M.Alignments = {
    LeftTop = { -1, 1 },
    LeftCenter = { -1, 0 },
    LeftBottom = { -1, -1 },
    CenterTop = { 0, 1 },
    CenterCenter = { 0, 0 },
    CenterBottom = { 0, -1 },
    RightTop = { 1, 1 },
    RightCenter = { 1, 0 },
    RightBottom = { 1, -1 }
}

---@class Core.UI.Layout.Base:Core.UI.Child
local Base = Core.Class(Core.UI.Child)
Base:addSerializeSimple(Core.UI.Child, "is_layout", "padding_top", "padding_bottom", "padding_left", "padding_right",
        "spacing", "ignore_spacing", "lock_aspect_ratio", "align")
Base:addSerializeOrder("align", Core.Lib.Json.Encode)
Base:addDeserializeOrder("align", Core.Lib.Json.Decode)

function Base:init(layer)
    Core.UI.Child.init(self, "Layout", layer)
    ---@type Core.UI.Child[]
    self.is_layout = true
    self:setDirty()
    self.padding_top = 0
    self.padding_bottom = 0
    self.padding_left = 0
    self.padding_right = 0
    self.spacing = 10
    self.ignore_spacing = false
    self.lock_aspect_ratio = true
    self._need_sort = false
    self.align = M.Alignments.CenterCenter
end
function Base:addChild(child)
    table.insert(self.children, child)
    child.parent = self
    child.parent_layout = self
    self._need_sort = true
    return self
end
function Base:setPadding(top, bottom, left, right)
    self.padding_top = top or 0
    self.padding_bottom = bottom or 0
    self.padding_left = left or 0
    self.padding_right = right or 0
    self:setDirty()
    return self
end
function Base:setSpacing(spacing)
    self.spacing = spacing or 10
    self:setDirty()
    return self
end

function Base:removeChild(child)
    for i, c in ipairs(self.children) do
        if c == child then
            table.remove(self.children, i)
            child.parent = nil
            child.parent_layout = nil
            self._need_sort = true
            return
        end
    end
end

function Base:applyLayout()

end
function Base:setDirty()
    if self._is_dirty then
        return self
    end
    self._is_dirty = true

    if self.parent_layout then
        self.parent_layout:setDirty()
    end
    if self.children then
        for _, child in ipairs(self.children) do
            if child.is_layout then
                child:setDirty()
            end
        end
    end
    return self
end
function Base:rebuild()
    --self:calculateDesiredSize()
    self:applyLayout()
end
function Base:update()
    self._hscale, self._vscale = self:getScale()
    if self._is_dirty then
        self:rebuild()
        self._is_dirty = false
    end
    Core.UI.Child.update(self)
end
---@param alignment Core.UI.Layout.Alignment
function Base:setAlignment(alignment)
    assert(type(alignment) == "table" and #alignment == 2, "Alignment must be a table with 2 elements")
    self.align = alignment
    self:setDirty()
    return self
end

function Base:draw()
    --test
    -- Core.Render.Draw.SetState(Core.Render.BlendMode.Default, Core.Render.Color.Default)
    -- Core.Render.Draw.RectOutline(self._x, self._y, self.width * self._hscale, self.height * self._vscale, 0, 2)
    Core.UI.Child.draw(self)
end

function Base:getCenter(offsetX, offsetY)
    offsetX = offsetX or 0
    offsetY = offsetY or 0
    local halign, valign = self.align[1], self.align[2]
    local cx = offsetX
    local cy = offsetY
    if halign == -1 then
        cx = cx - (self.width / 2 + self.padding_left) * self._hscale
    elseif halign == 1 then
        cx = cx + (self.width / 2 - self.padding_right) * self._hscale
    end
    if valign == -1 then
        cy = cy - (self.height / 2 + self.padding_bottom) * self._vscale
    elseif valign == 1 then
        cy = cy + (self.height / 2 - self.padding_top) * self._vscale

    end
    return cx, cy
end

function Base:setIgnoreSpacing(enable)
    self.ignore_spacing = enable
end
function Base:enableLockAspectRatio(enable)
    self.lock_aspect_ratio = enable
end

local Vec = Core.Math.Vector2
local vertical = Vec.up--(0, 1)
local horizontal = Vec.right--(1, 0)
---@param dir Core.Math.Vector2
---@param self Core.UI.Layout.Base
local function applyLayout(self, dir)
    dir:normalize()
    local reverseDir = Vec.New(dir.y, dir.x)
    local scaleVec = Vec.New(self._hscale, self._vscale)
    local availableRect = Vec.New(self.width - self.padding_left - self.padding_right, self.height - self.padding_top - self.padding_bottom) * scaleVec
    local availableVec = availableRect * dir
    local count = 0
    local childVec = availableRect * reverseDir
    local picVec = Vec.New(0, 0)
    local maxVec = Vec.New(0, 0)
    local spaceVec = self.spacing * dir * scaleVec
    for _, child in ipairs(self.children) do
        if not child.not_use_layout then
            maxVec.x = max(maxVec.x, child.width)
            maxVec.y = max(maxVec.y, child.height)
            count = count + 1
        end
    end
    local maxSpace = availableVec / (count - 1)
    if spaceVec:magnitude() > maxSpace:magnitude() then
        spaceVec = maxSpace
    end
    local scale = availableRect / maxVec
    if self.lock_aspect_ratio then
        local p = scale:dot(reverseDir)
        scale = Vec.New(p, p)
    end
    for _, child in ipairs(self.children) do
        if not child.not_use_layout then
            child.layout_hscale = scale.x
            child.layout_vscale = scale.y
            local add = Vec.New(child.width * scale.x, child.height * scale.y) * dir
            local childBase = childVec * dir
            child.layout_x = childBase.x + add.x / 2
            child.layout_y = childBase.y + add.y / 2
            picVec = picVec + add

            childVec = childVec + add + spaceVec
        end
    end
    childVec = childVec - spaceVec

    if self.ignore_spacing then
        spaceVec = (availableVec - picVec) / (count - 1)
    end
    local allSpacing = spaceVec * (count - 1)
    local realVec = allSpacing + picVec
    if realVec:magnitude() >= availableVec:magnitude() then
        local scaleM = (availableVec - allSpacing):magnitude() / picVec:magnitude()
        scale = scale * scaleM
        childVec = Vec.New(0, 0)
        for _, child in ipairs(self.children) do
            if not child.not_use_layout then
                child.layout_hscale = scale.x
                child.layout_vscale = scale.y
                local childA = Vec.New(child.width * scale.x, child.height * scale.y)
                local add = childA * dir
                local childBase = childVec * dir
                child.layout_x = childBase.x + add.x / 2
                child.layout_y = childBase.y + add.y / 2
                local maxPart = Vec.Max(childVec, childA)
                childVec = maxPart * reverseDir + (childVec + add + spaceVec) * dir
            end
        end
        childVec = childVec - spaceVec
    end
    local halign, valign = self.align[1], self.align[2]
    local offsetVec = -childVec / 2 * (Vec.New(halign, valign) + dir)
    local cx, cy = self:getCenter(offsetVec.x, offsetVec.y)
    for _, child in ipairs(self.children) do
        if not child.not_use_layout then
            child.layout_x = child.layout_x + cx
            child.layout_y = child.layout_y + cy
        end
    end
end

---@class Core.UI.Layout.Vertical:Core.UI.Layout.Base
local Vertical = Core.Class(Base)
M.Vertical = Vertical
function Vertical:applyLayout()
    applyLayout(self, vertical)
end

---@class Core.UI.Layout.Horizontal:Core.UI.Layout.Base
local Horizontal = Core.Class(Base)
M.Horizontal = Horizontal
function Horizontal:applyLayout()
    applyLayout(self, horizontal)
end

---@class Core.UI.Layout.Grid:Core.UI.Layout.Base
local Grid = Core.Class(Base)
M.Grid = Grid
Grid:addSerializeSimple(Base, "spacing_h", "spacing_v", "horizontal_count", "vertical_count", "weight_data", "grid_data")
Grid:addSerializeOrder("grid_data", Core.Lib.Json.Encode)
Grid:addDeserializeOrder("grid_data", Core.Lib.Json.Decode)
Grid:addSerializeOrder("weight_data", Core.Lib.Json.Encode)
Grid:addDeserializeOrder("weight_data", Core.Lib.Json.Decode)

function Grid:init(horizontal_count, vertical_count, layer)
    Base.init(self, layer)
    self:setGrid(horizontal_count, vertical_count)
    self:setSpacing()
end

---设置网格的水平间隔和垂直间隔
---Set the horizontal and vertical spacing of the grid
---@overload fun(h:number, v:number):self
---@overload fun(spacing:number):self
function Grid:setSpacing(h, v)
    self.spacing_h = h or 0
    self.spacing_v = v or h or 0
    self:setDirty()
    return self
end

---设置某个单元格的对齐方式
---Set the alignment of a cell
---@param alignment Core.UI.Layout.Alignment 对齐方式
---@param i number 行号
---@param j number 列号
---@overload fun(alignment:Core.UI.Layout.Alignment):self
function Grid:setAlignment(alignment, i, j)
    if i and j then
        self.grid_data[i][j].align = alignment
    else
        for _i = 1, self.horizontal_count do
            for _j = 1, self.vertical_count do
                self.grid_data[_i][_j].align = alignment
            end
        end
    end
    self:setDirty()
    return self
end

---设置某个单元格是否锁定宽高比
---Set whether the aspect ratio of a cell is locked
---@param enable boolean 是否锁定
---@param i number 行号
---@param j number 列号
---@overload fun(enable:boolean):self
function Grid:enableLockAspectRatio(enable, i, j)
    if i and j then
        self.grid_data[i][j].lock_aspect_ratio = enable
    else
        for _i = 1, self.horizontal_count do
            for _j = 1, self.vertical_count do
                self.grid_data[_i][_j].lock_aspect_ratio = enable
            end
        end
    end
    self:setDirty()
    return self
end

---设置某行或列的权重
---@param weight number 权重
---@param col number 行号
---@param row number 列号
function Grid:setWeight(weight, col, row)
    assert(type(weight) == "number" and weight > 0, "Weight must be a positive number")
    if col then
        self.weight_data.x[col] = weight
    end
    if row then
        self.weight_data.y[row] = weight
    end
    self:setDirty()
    return self
end

---设置单元格的缩放比例
---@param scale number 缩放比例
---@param i number 行号
---@param j number 列号
---@overload fun(scale:number):self
function Grid:setScale(scale, i, j)
    if i and j then
        self.grid_data[i][j].scale = scale
    else
        for _i = 1, self.horizontal_count do
            for _j = 1, self.vertical_count do
                self.grid_data[_i][_j].scale = scale
            end
        end
    end
    self:setDirty()
    return self
end

function Grid:setGrid(horizontal_count, vertical_count)
    self.horizontal_count = horizontal_count or 3
    self.vertical_count = vertical_count or 3
    ---@type Core.UI.Layout.grid_data[][]
    self.grid_data = {}
    for i = 1, self.horizontal_count do
        self.grid_data[i] = {}
        for j = 1, self.vertical_count do
            ---@class Core.UI.Layout.grid_data
            self.grid_data[i][j] = {
                lock_aspect_ratio = true,
                scale = 1,
                align = M.Alignments.CenterCenter,
                childID = 0,
            }
        end
    end
    self.weight_data = {
        x = {},
        y = {}
    }
    for i = 1, self.horizontal_count do
        self.weight_data.x[i] = 1
    end
    for i = 1, self.vertical_count do
        self.weight_data.y[i] = 1
    end
    self:setDirty()
    return self
end
function Grid:getChild(i, j)
    i = i or 1
    j = j or 1
    assert(1 <= i and i <= self.horizontal_count and 1 <= j and j <= self.vertical_count, "Invalid cell index")
    if self.grid_data[i][j].childID > 0 then
        return self.children[self.grid_data[i][j].childID]
    else
        return self.children[(i - 1) * 9 + j]
    end
end

function Grid:applyLayout()
    local count = Vec.New(self.horizontal_count, self.vertical_count)
    local scaleVec = Vec.New(self._hscale, self._vscale)
    local spacing = Vec.New(self.spacing_h, self.spacing_v) * scaleVec
    local realRect = Vec.New(self.width - self.padding_left - self.padding_right, self.height - self.padding_top - self.padding_bottom) * scaleVec
    local availableRect = realRect - spacing * (count - Vec.New(1, 1))
    local weightVec = Vec.New(0, 0)
    for i = 1, self.horizontal_count do
        weightVec.x = weightVec.x + self.weight_data.x[i]
    end
    for i = 1, self.vertical_count do
        weightVec.y = weightVec.y + self.weight_data.y[i]
    end
    local Pos = Vec.New(0, 0)
    local childP = 1
    local function getChild()
        local cur = self.children[childP]
        if cur then
            childP = childP + 1
            if cur.not_use_layout then
                return getChild()
            else
                return cur
            end
        else
            return nil
        end
    end
    local breakFlag = false
    for j = 1, self.vertical_count do
        local weight
        local realSize
        for i = 1, self.horizontal_count do
            local cur = getChild()
            if cur then
                local data = self.grid_data[i][j]
                data.childID = childP - 1
                weight = Vec.New(self.weight_data.x[i], self.weight_data.y[j]) / weightVec
                realSize = availableRect * weight
                cur.layout_x = Pos.x - realRect.x / 2
                cur.layout_y = Pos.y + realRect.y / 2
                Pos.x = Pos.x + realSize.x + spacing.x
                local picSize = Vec.New(cur.width, cur.height)
                local scale = realSize / picSize * data.scale
                if data.lock_aspect_ratio then
                    local p = min(scale.x, scale.y)
                    scale = Vec.New(p, p)
                end
                cur.layout_hscale = scale.x
                cur.layout_vscale = scale.y
                local halign, valign = data.align[1], data.align[2]
                local offsetVec = Vec.New(halign, -valign) * (realSize - picSize)
                cur.layout_x = cur.layout_x + offsetVec.x + realSize.x / 2
                cur.layout_y = cur.layout_y + offsetVec.y - realSize.y / 2
            else
                breakFlag = true
                break
            end
        end
        if breakFlag then
            break
        end
        Pos.x = 0
        Pos.y = Pos.y - realSize.y - spacing.y
    end


end
