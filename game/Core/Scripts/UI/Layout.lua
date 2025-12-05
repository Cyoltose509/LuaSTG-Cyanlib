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
Base:addSerializeSimple(Core.UI.Child, "isLayout", "paddingTop", "paddingBottom", "paddingLeft", "paddingRight",
        "spacing", "ignoreSpacingAndFill", "lockAspectRatio", "align")
Base:addSerializeOrder("align", Core.Lib.Json.Encode)
Base:addDeserializeOrder("align", Core.Lib.Json.Decode)

function Base:init(layer)
    Core.UI.Child.init(self, "Layout", layer)
    ---@type Core.UI.Child[]
    self.children = {}
    self.isLayout = true
    self:setDirty()
    self.paddingTop = 0
    self.paddingBottom = 0
    self.paddingLeft = 0
    self.paddingRight = 0
    self.spacing = 10
    self.ignoreSpacingAndFill = false
    self.lockAspectRatio = true
    self._needSort = false
    self.align = M.Alignments.CenterCenter
end
function Base:addChild(child)
    table.insert(self.children, child)
    child.parent = self
    child.parentLayout = self
    self._needSort = true
    return self
end
function Base:setPadding(top, bottom, left, right)
    self.paddingTop = top or 0
    self.paddingBottom = bottom or 0
    self.paddingLeft = left or 0
    self.paddingRight = right or 0
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
            child.parentLayout = nil
            self._needSort = true
            return
        end
    end
end

function Base:applyLayout()

end
function Base:setDirty()
    if self.isDirty then
        return self
    end
    self.isDirty = true

    if self.parentLayout then
        self.parentLayout:setDirty()
    end
    if self.children then
        for _, child in ipairs(self.children) do
            if child.isLayout then
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
    if self._needSort then
        table.sort(self.children, function(a, b)
            return (a.layer or 0) < (b.layer or 0)
        end)
        self._needSort = nil
    end
    Core.UI.Child.update(self)
    local childRebuild = false
    if self.isDirty then
        self:rebuild()
        childRebuild = true
        self.isDirty = false
    end
    for _, child in ipairs(self.children) do
        if child.update then
            child:update()
        end
    end


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
    for _, child in pairs(self.children) do
        if child.draw then
            child:draw()
        end
    end
end

function Base:getCenter(offsetX, offsetY)
    offsetX = offsetX or 0
    offsetY = offsetY or 0
    local halign, valign = self.align[1], self.align[2]
    local cx = self._x + offsetX
    local cy = self._y + offsetY
    if halign == -1 then
        cx = cx - (self.width / 2 + self.paddingLeft) * self._hscale
    elseif halign == 1 then
        cx = cx + (self.width / 2 - self.paddingRight) * self._hscale
    end
    if valign == -1 then
        cy = cy - (self.height / 2 + self.paddingBottom) * self._vscale
    elseif valign == 1 then
        cy = cy + (self.height / 2 - self.paddingTop) * self._vscale

    end
    return cx, cy
end

function Base:setIgnoreSpacing(enable)
    self.ignoreSpacingAndFill = enable
end
function Base:setLockAspectRatio(enable)
    self.lockAspectRatio = enable
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
    local availableRect = Vec.New(self.width - self.paddingLeft - self.paddingRight, self.height - self.paddingTop - self.paddingBottom) * scaleVec
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
    if self.lockAspectRatio then
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

    if self.ignoreSpacingAndFill then
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
Grid:addSerializeSimple(Base, "spacingH", "spacingV", "horizontalCount", "verticalCount", "weightData", "gridData")
Grid:addSerializeOrder("gridData", Core.Lib.Json.Encode)
Grid:addDeserializeOrder("gridData", Core.Lib.Json.Decode)
Grid:addSerializeOrder("weightData", Core.Lib.Json.Encode)
Grid:addDeserializeOrder("weightData", Core.Lib.Json.Decode)

function Grid:init(horizontalCount, verticalCount, layer)
    Base.init(self, layer)
    self:setGrid(horizontalCount, verticalCount)
    self:setSpacing()
end

---设置网格的水平间隔和垂直间隔
---Set the horizontal and vertical spacing of the grid
---@overload fun(h:number, v:number):self
---@overload fun(spacing:number):self
function Grid:setSpacing(h, v)
    self.spacingH = h or 0
    self.spacingV = v or h or 0
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
        self.gridData[i][j].align = alignment
    else
        for _i = 1, self.horizontalCount do
            for _j = 1, self.verticalCount do
                self.gridData[_i][_j].align = alignment
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
function Grid:setLockAspectRatio(enable, i, j)
    if i and j then
        self.gridData[i][j].lockAspectRatio = enable
    else
        for _i = 1, self.horizontalCount do
            for _j = 1, self.verticalCount do
                self.gridData[_i][_j].lockAspectRatio = enable
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
        self.weightData.x[col] = weight
    end
    if row then
        self.weightData.y[row] = weight
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
        self.gridData[i][j].scale = scale
    else
        for _i = 1, self.horizontalCount do
            for _j = 1, self.verticalCount do
                self.gridData[_i][_j].scale = scale
            end
        end
    end
    self:setDirty()
    return self
end

function Grid:setGrid(horizontalCount, verticalCount)
    self.horizontalCount = horizontalCount or 3
    self.verticalCount = verticalCount or 3
    ---@type Core.UI.Layout.GridData[][]
    self.gridData = {}
    for i = 1, self.horizontalCount do
        self.gridData[i] = {}
        for j = 1, self.verticalCount do
            ---@class Core.UI.Layout.GridData
            self.gridData[i][j] = {
                lockAspectRatio = true,
                scale = 1,
                align = M.Alignments.CenterCenter,
                childID = 0,
            }
        end
    end
    self.weightData = {
        x = {},
        y = {}
    }
    for i = 1, self.horizontalCount do
        self.weightData.x[i] = 1
    end
    for i = 1, self.verticalCount do
        self.weightData.y[i] = 1
    end
    self:setDirty()
    return self
end
function Grid:getChild(i, j)
    i = i or 1
    j = j or 1
    assert(1 <= i and i <= self.horizontalCount and 1 <= j and j <= self.verticalCount, "Invalid cell index")
    if self.gridData[i][j].childID > 0 then
        return self.children[self.gridData[i][j].childID]
    else
        return self.children[(i - 1) * 9 + j]
    end
end

function Grid:applyLayout()
    local count = Vec.New(self.horizontalCount, self.verticalCount)
    local scaleVec = Vec.New(self._hscale, self._vscale)
    local spacing = Vec.New(self.spacingH, self.spacingV) * scaleVec
    local realRect = Vec.New(self.width - self.paddingLeft - self.paddingRight, self.height - self.paddingTop - self.paddingBottom) * scaleVec
    local availableRect = realRect - spacing * (count - Vec.New(1, 1))
    local weightVec = Vec.New(0, 0)
    for i = 1, self.horizontalCount do
        weightVec.x = weightVec.x + self.weightData.x[i]
    end
    for i = 1, self.verticalCount do
        weightVec.y = weightVec.y + self.weightData.y[i]
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
    for j = 1, self.verticalCount do
        local weight
        local realSize
        for i = 1, self.horizontalCount do
            local cur = getChild()
            if cur then
                local data = self.gridData[i][j]
                data.childID = childP - 1
                weight = Vec.New(self.weightData.x[i], self.weightData.y[j]) / weightVec
                realSize = availableRect * weight
                cur.layout_x = Pos.x + self._x - realRect.x / 2
                cur.layout_y = Pos.y + self._y + realRect.y / 2
                Pos.x = Pos.x + realSize.x + spacing.x
                local picSize = Vec.New(cur.width, cur.height)
                local scale = realSize / picSize * data.scale
                if data.lockAspectRatio then
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
