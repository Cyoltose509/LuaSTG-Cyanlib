---@class Core.UI.Child
---UI 节点的基类。所有可见/容器节点都继承自它。
---
---坐标模型（重要）：
---本系统使用**以节点中心为原点**的坐标。每个节点最终显示位置 `_x,_y` 由三部分叠加得到：
---  - `parent._x, parent._y`：父节点（容器）的中心绝对坐标
---  - `x, y`：用户设置的、相对父中心的偏移
---  - `arranged_x, arranged_y`：父布局（Layout）计算并写入的本节点位置
---即 `getXY() = parent._x + x + arranged_x`（y 同理）。
---缩放同理：`getScale() = hscale * arranged_hscale`（vscale 同理）。
---
---一个节点只有唯一的 `parent`（它在树中的拥有者）。布局（Layout）本身也是父节点，
---因此不需要单独的 `parent_layout` 字段——布局通过计算子节点的 `arranged_*` 来完成排版。
local M = Core.Class()
Core.UI.Child = M

---Flex 模式枚举（值为引擎比较所用的字符串本身）
local P = Core.UI.Pattern

-- 需要被序列化的简单字段
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
    "margin",
    "flex_grow",
    "flex_shrink",
    "flex_basis",
    "align_self",
    "order",
    "position",
    "inset_top",
    "inset_right",
    "inset_bottom",
    "inset_left",
    "min_width",
    "max_width",
    "min_height",
    "max_height",
    "exclude_from_layout",
    "ignore_layout_scale",
    "link_parent_scale",
    "style_names",
    "display",
    "z_index",
}
M._serialize_order = {}
M._deserialize_order = {}

---@param master Core.UI.Child 基类（用于拷贝其序列化字段清单）
---@param ... string 额外要序列化的字段名
function M:addSerializeSimple(master, ...)
    self._serialize_simple = Core.Lib.Table.Copy(master._serialize_simple)
    for _, str in ipairs({ ... }) do
        table.insert(self._serialize_simple, str)
    end
end

---为某个字段注册自定义的序列化/反序列化函数（例如把 table 转成 json 字符串）
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

M:addSerializeOrder("margin", Core.Lib.Json.Encode)
M:addDeserializeOrder("margin", Core.Lib.Json.Decode)
M:addSerializeOrder("style_names", Core.Lib.Json.Encode)
M:addDeserializeOrder("style_names", Core.Lib.Json.Decode)

---@alias Core.UI.Child.New Core.UI.Child|fun(name:string, layer:number):Core.UI.Child
---@param name string 节点类型名（用于序列化/反序列化时重建）
---@param layer number 渲染层级
function M:init(name, layer)
    ---@type Core.UI.Child|Core.UI.Root|nil 在树中拥有本节点的父节点（容器/根）
    self.parent = nil
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
            self:addChild(child)
        end
    end
    -- 反序列化后标记样式待解析，确保命名/内联样式在下一次 update 时生效
    self._style_dirty = true
    return self
end

---在自身及其所有子节点 update 之前调用（用于刷新渲染相关数据）
function M:before_update()
    for _, child in ipairs(self.children) do
        if child.before_update then
            child:before_update()
        end
    end
end

---刷新显示坐标
---@return self
function M:refreshXY()
    self._x, self._y = self:getXY()
    return self
end

---刷新显示缩放
---@return self
function M:refreshScale()
    self._hscale, self._vscale = self:getScale()
    return self
end

function M:update()
    if self._need_sort then
        -- 使用稳定排序：以 layer 为主键，原始插入次序(_zorder)为辅键打破平局。
        -- 避免 Lua table.sort 不稳定导致 layer 相等的子节点顺序随机打乱。
        table.sort(self.children, function(a, b)
            local la, lb = a.layer or 0, b.layer or 0
            if la ~= lb then return la < lb end
            return (a._zorder or 0) < (b._zorder or 0)
        end)
        self._need_sort = nil
    end
    -- 样式级联：自身解析时读取父节点已计算好的可继承属性
    if self._style_dirty then
        self:applyStyles()
    end
    self._last_hscale, self._last_vscale = self._hscale, self._vscale
    self._last_x, self._last_y = self._x, self._y

    self:refreshScale()
    self:refreshXY()
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
    if self.display == P.DISPLAY.NONE then
        return
    end
    local children = self.children
    if self._zsort then
        children = {}
        for i, c in ipairs(self.children) do
            children[i] = c
        end
        table.sort(children, function(a, b)
            local za, zb = a.z_index or 0, b.z_index or 0
            if za ~= zb then
                return za < zb
            end
            return (a._zorder or 0) < (b._zorder or 0)
        end)
    end
    for _, child in ipairs(children) do
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

---从父节点移除自身
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

---设置绘制层级（z-index）。数值越大越靠上绘制；仅在兄弟节点间比较。
---触发父节点按 z 重新排序绘制列表。
---@param z number
---@return self
function M:setZIndex(z)
    self.z_index = z or 0
    if self.parent then
        self.parent._zsort = true
    end
    return self
end

---设置显示方式： "flex"（参与布局与绘制）| P.DISPLAY.NONE（完全隐藏，等价于 CSS display:none）
---@param v string
---@return self
function M:setDisplay(v)
    self.display = v
    self:setDirty()
    return self
end

---初始化节点属性
---@return self
function M:initStatus()
    ---是否忽略位置变化带来的 _need_update
    self._ignore_pos_update = false
    ---是否忽略缩放变化带来的 _need_update
    self._ignore_scale_update = false
    ---某些类会用它来刷新渲染数据
    self._need_update = false
    ---是否把缩放与父节点关联（link_parent_scale 用）
    self.link_parent_scale = false
    self.children = {}
    ---相对父中心的 x 偏移
    self.x = 0
    ---相对父中心的 y 偏移
    self.y = 0
    self.rot = 0
    ---参与布局计算的尺寸（可理解为碰撞盒/内容盒；默认 0 表示"由布局决定"）
    self.width = 0
    self.height = 0
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
    ---父布局计算并写入的本节点中心位置（相对父中心，单位：像素）
    self.arranged_x = 0
    self.arranged_y = 0
    ---父布局计算并写入的本节点缩放倍率
    self.arranged_hscale = 1
    self.arranged_vscale = 1
    ---外边距 {上, 右, 下, 左}，参与布局间距计算
    self.margin = { 0, 0, 0, 0 }
    ---flex 子项属性
    self.flex_grow = 0
    self.flex_shrink = 1
    self.flex_basis = P.FLEX_BASIS.AUTO
    ---覆盖容器的 align_items；为 nil 时使用容器设置
    self.align_self = nil
    ---排序权重（越小越靠前）
    self.order = 0
    self.min_width = 0
    self.max_width = 1e9
    self.min_height = 0
    self.max_height = 1e9
    ---定位方式：relative（参与流式布局）| absolute（脱离文档流，用 inset 定位）
    self.position = P.POSITION.RELATIVE
    ---绝对定位偏移。默认 nil 表示"未指定/auto"（保留内在尺寸）；显式设数字即从该边定位。
    ---注意 Lua 中 0 为真值，故用 nil 而非 0 表示"未指定"，否则 'left and right' 会误判。
    self.inset_top = nil
    self.inset_right = nil
    self.inset_bottom = nil
    self.inset_left = nil
    ---是否排除出布局（absolute 或手动标记时由布局处理；此标志用于"完全不参与"）
    self.exclude_from_layout = false
    ---忽视布局带来的缩放（保留自身 hscale/vscale）
    self.ignore_layout_scale = false
    ---显示方式：flex（默认，参与布局与绘制）| none（完全隐藏，等价于 CSS display:none）
    self.display = P.DISPLAY.FLEX
    ---绘制层级（仅兄弟节点间比较，数值越大越晚绘制/越靠上）
    self.z_index = 0
    ---样式系统
    self.style_names = {}
    self.inline_style = {}
    ---父节点计算好的、需要向下继承的可继承属性集合
    self._inherited = nil
    self._style_dirty = false
    ---交互：鼠标点击回调。参数为 (node, button)，button 为 Mouse.Key 值。
    ---由外部帧循环调用 hitTest + triggerClick 分发，本节点不自动检测。
    self.on_click = nil
    ---交互：鼠标悬停态（由 M.UpdateHover 每帧统一派发）。
    ---等价于 CSS `:hover`：当光标落在节点渲染边界内（或其子树内）时为 true。
    self.hovered = false
    ---悬停进入回调（state 由 false→true 时触发一次），签名 (node)
    self.on_hover_enter = nil
    ---悬停离开回调（state 由 true→false 时触发一次），签名 (node)
    self.on_hover_leave = nil
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
    child._zorder = #self.children
    if child.z_index and child.z_index ~= 0 then
        self._zsort = true
    end
    self._need_sort = true
    child._style_dirty = true
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
    width = width or 0
    height = height or 0
    if width ~= self.width or height ~= self.height then
        self.width = width
        self.height = height
        self:setDirty()
    end
    return self
end

---标记布局需要重算。基类只向上传播；布局类（Layout）会重写以标脏自身。
---@return self
function M:setDirty()
    if self.parent and self.parent.setDirty then
        self.parent:setDirty()
    end
    return self
end

---@return self
function M:ignoreLayoutScale(enable)
    self.ignore_layout_scale = enable
    self:setDirty()
    return self
end

---节点内容/布局尺寸（默认等于 width/height；文本等可覆盖为真实测量值）
---@return number, number
function M:getContentSize()
    return self.width, self.height
end

---主轴尺寸（isRow=true 时为主轴是水平方向）
---@param isRow boolean
function M:getMainSize(isRow)
    return isRow and self.width or self.height
end
---交叉轴尺寸
---@param isRow boolean
function M:getCrossSize(isRow)
    return isRow and self.height or self.width
end
---含外边距的主轴尺寸
---@param isRow boolean
function M:getOuterMainSize(isRow)
    return self:getMainSize(isRow) + (isRow and (self.margin[2] + self.margin[4]) or (self.margin[1] + self.margin[3]))
end
---含外边距的交叉轴尺寸
---@param isRow boolean
function M:getOuterCrossSize(isRow)
    return self:getCrossSize(isRow) + (isRow and (self.margin[1] + self.margin[3]) or (self.margin[2] + self.margin[4]))
end
---解析 flex-basis（P.FLEX_BASIS.AUTO 时回退到内容主尺寸）
---@param isRow boolean
function M:getFlexBasis(isRow)
    if self.flex_basis == P.FLEX_BASIS.AUTO then
        return self:getMainSize(isRow)
    end
    return self.flex_basis
end
---按 min/max 约束主轴尺寸
---@param size number
---@param isRow boolean
function M:clampMainSize(size, isRow)
    local mn = isRow and self.min_width or self.min_height
    local mx = isRow and self.max_width or self.max_height
    return min(max(size, mn), mx)
end

---@return number, number
function M:getScale()
    if self.ignore_layout_scale then
        return self.hscale, self.vscale
    end
    if self.link_parent_scale and self.parent then
        local w = self.parent.width * self.parent._hscale / self.width
        local h = self.parent.height * self.parent._vscale / self.height
        return w * self.hscale * self.arranged_hscale, h * self.vscale * self.arranged_vscale
    end
    return self.hscale * self.arranged_hscale, self.vscale * self.arranged_vscale
end

---@return number, number
function M:getXY()
    local x, y = self.x + self.arranged_x, self.y + self.arranged_y
    if self.parent then
        x = x + self.parent._x
        y = y + self.parent._y
    end
    return x, y
end

---命中测试：检查屏幕坐标点 (px, py) 是否落在节点的渲染边界内（AABB）。
---坐标须与节点 _x/_y 在同一坐标系中（通常为 UI.Camera 的世界坐标）。
---display 为 P.DISPLAY.NONE 的节点视为不可见、不参与命中（含其子树）。
---零尺寸节点自身不可点击（交由子节点命中）。
---@param px number
---@param py number
---@return boolean
function M:hitTest(px, py)
    if self.display == P.DISPLAY.NONE then
        return false
    end
    local cx, cy = self._x, self._y
    local sx, sy = self:getScale()
    local hw = self.width * sx / 2
    local hh = self.height * sy / 2
    -- 零尺寸节点本身不可点击（但子节点仍可命中）
    if hw <= 0 or hh <= 0 then
        return false
    end
    return (px >= cx - hw) and (px <= cx + hw) and (py >= cy - hh) and (py <= cy + hh)
end

---从本节点向下递归查找最深的、渲染边界包含 (px,py) 的节点（后序，子节点优先）。
---找到后沿 parent 链向上冒泡，返回最近的设置了 on_click 的祖先（含自身）；
---若子树中没有任何可点击节点，返回 nil。
---@param px number 屏幕坐标 X（与 _x 同坐标系）
---@param py number 屏幕坐标 Y
---@return Core.UI.Child|nil
function M:hitTestDeep(px, py)
    local deepest = self:_hitDeepRaw(px, py)
    if not deepest then return nil end
    -- 事件冒泡：从最深命中节点向上找最近的 on_click 处理者
    local n = deepest
    while n do
        if n.on_click then return n end
        n = n.parent
    end
    return nil
end

---设置悬停状态（由帧循环 M.UpdateHover 根据鼠标位置统一调用）。
---状态翻转时触发 on_hover_enter / on_hover_leave 回调（各只触发一次）。
---@param state boolean
---@return self
function M:setHovered(state)
    if state == self.hovered then
        return self
    end
    self.hovered = state
    if state then
        if self.on_hover_enter then self:on_hover_enter() end
    else
        if self.on_hover_leave then self:on_hover_leave() end
    end
    return self
end

---根据鼠标屏幕坐标 (mx, my) 重算整棵 UI 树的悬停状态。
---规则（等价于 CSS `:hover`）：最深层命中节点（_hitDeepRaw）及其所有祖先构成"命中链"，
---链上节点标记为 hovered；其余节点清除悬停。仅在状态变化时触发回调，避免每帧重复调用。
---调用方应在每帧渲染前调用一次（传入鼠标屏幕坐标，与 _x/_y 同坐标系）。
---@param root Core.UI.Child 子树根（通常是 HUDRoot 或其下的 app 容器）
---@param mx number 鼠标屏幕 X
---@param my number 鼠标屏幕 Y
function M.UpdateHover(root, mx, my)
    local hit = root:_hitDeepRaw(mx, my)
    local chain = {}
    local n = hit
    while n do
        chain[n] = true
        n = n.parent
    end
    -- 一步兄弟扩展：链上每个节点的直接子节点，若自身 bounds 命中指针也标 hovered。
    -- 修复背景(bg)作为内容(文字)同级兄弟时，光标移到文字上导致 bg 丢 :hover 的问题
    -- （bg 不在祖先链中）。仅扩展一层，避免把被遮挡的外部兄弟节点误标为 hovered。
    local nodes = {}
    for node in pairs(chain) do
        nodes[#nodes + 1] = node
    end
    for _, node in ipairs(nodes) do
        if node.children then
            for _, c in ipairs(node.children) do
                if not chain[c] and c.hitTest and c:hitTest(mx, my) then
                    chain[c] = true
                end
            end
        end
    end
    local prev = root._hover_set or {}
    for node in pairs(prev) do
        if not chain[node] and node.setHovered then
            node:setHovered(false)
        end
    end
    for node in pairs(chain) do
        if node.setHovered then
            node:setHovered(true)
        end
    end
    root._hover_set = chain
end

---内部：返回最深的 bounds 命中节点（不含 on_click 冒泡逻辑）。
---自身零尺寸时仍递归子节点，使子节点可优先命中。display:none 子树整体跳过。
---@param px number
---@param py number
---@return Core.UI.Child|nil
function M:_hitDeepRaw(px, py)
    if self.display == P.DISPLAY.NONE then
        return nil
    end
    local selfHit = self:hitTest(px, py)
    -- 递归子节点（反向遍历：后添加者 z 更高、视觉在上层，优先命中）
    local childHit
    if self.children then
        for i = #self.children, 1, -1 do
            local c = self.children[i]
            if c._hitDeepRaw then
                local h = c:_hitDeepRaw(px, py)
                if h then childHit = h; break end
            end
        end
    end
    if childHit then return childHit end
    if selfHit then return self end
    return nil
end

-- ===================== 样式系统（第 3 步） =====================

---添加一个命名样式（类似 CSS class）。会触发自身及子树重新解析样式。
---@param name string
---@return self
function M:addStyle(name)
    for _, n in ipairs(self.style_names) do
        if n == name then
            return self
        end
    end
    table.insert(self.style_names, name)
    self._style_dirty = true
    return self
end

---移除一个命名样式
---@param name string
---@return self
function M:removeStyle(name)
    for i, n in ipairs(self.style_names) do
        if n == name then
            table.remove(self.style_names, i)
            break
        end
    end
    self._style_dirty = true
    return self
end

---设置内联样式（优先级最高，类似 CSS 的 style="..."）
---@param props table
---@return self
function M:setInlineStyle(props)
    self.inline_style = props or {}
    self._style_dirty = true
    return self
end

---清空所有样式
---@return self
function M:clearStyles()
    self.style_names = {}
    self.inline_style = {}
    self._style_dirty = true
    return self
end

---解析并应用样式：合并（父继承 < 命名样式(按添加顺序) < 内联），并把可继承属性向下传递。
---通常在 _style_dirty 时由 update 自动调用，也可手动调用。
---@return self
function M:applyStyles()
    self._style_dirty = false
    local inherited = self.parent and self.parent._inherited or nil
    local effective, own = Core.UI.Style.Resolve(self, inherited)
    Core.UI.Style.Apply(self, effective)
    -- 可继承属性发生变化时，通知子节点重新解析（继承链向下传播）
    if not self:_inheritedEqual(own) then
        for _, ch in ipairs(self.children) do
            ch._style_dirty = true
        end
    end
    self._inherited = own
    return self
end

---比较两个可继承属性集合是否相等（决定是否需要向下传播）
---@param other table|nil
function M:_inheritedEqual(other)
    local a, b = self._inherited, other
    if a == nil and b == nil then
        return true
    end
    if a == nil or b == nil then
        return false
    end
    for _, k in ipairs({ "font", "color", "text_align" }) do
        if a[k] ~= b[k] then
            return false
        end
    end
    return true
end
