---@class Core.UI.Layout
local M = {}
Core.UI.Layout = M

---Flex 模式枚举（值为引擎比较所用的字符串本身）
local P = Core.UI.Pattern

---预设对齐方式（供 Grid 等使用，{-1,1} 表示左/上，{0,0} 居中，{1,-1} 右/下）
M.Alignments = {
    LeftTop = { -1, 1 },
    LeftCenter = { -1, 0 },
    LeftBottom = { -1, -1 },
    CenterTop = { 0, 1 },
    CenterCenter = { 0, 0 },
    CenterBottom = { 0, -1 },
    RightTop = { 1, 1 },
    RightBottom = { 1, -1 },
}

-- ===================== Flex 布局（CSS flexbox 实现） =====================

---margin 的 P.FLEX_BASIS.AUTO 哨兵值。设某方向 margin 为 AUTO 即启用自动边距模式：
---该方向 margin 会吸收所有剩余空间（优先级高于 justify-content）。
---用法：`node.margin[2] = Core.UI.Layout.Flex.AUTO` （右侧 auto，元素被推到左边）
local AUTO = math.huge

---@class Core.UI.Layout.Flex : Core.UI.Child
local Flex = Core.Class(Core.UI.Child)
M.Flex = Flex

Flex:addSerializeSimple(Core.UI.Child,
        "padding", "gap", "row_gap", "column_gap",
        "flex_direction", "flex_wrap", "justify_content", "align_items", "align_content",
        "locked_scale")
Flex:addSerializeOrder("padding", Core.Lib.Json.Encode)
Flex:addDeserializeOrder("padding", Core.Lib.Json.Decode)

---margin auto 哨兵值。设 `node.margin[2] = Flex.AUTO` 表示右侧 margin 为 auto（吸收剩余空间）。
Flex.AUTO = AUTO
M.AUTO = AUTO

---@param layer number
function Flex:init(layer)
    Core.UI.Child.init(self, "Layout.Flex", layer)
    self._name = "Layout.Flex"
    self.is_layout = true
    self._is_dirty = true
    ---内边距 {上, 右, 下, 左}
    self.padding = { 0, 0, 0, 0 }
    ---主轴/交叉轴间隙（gap 同时设置两者；row_gap/column_gap 可单独覆盖）
    self.gap = 0
    self.row_gap = 0
    self.column_gap = 0
    self.flex_direction = P.FLEX_DIRECTION.ROW
    self.flex_wrap = P.FLEX_WRAP.NOWRAP
    self.justify_content = P.JUSTIFY_CONTENT.FLEX_START
    self.align_items = P.ALIGN_ITEMS.STRETCH
    self.align_content = P.JUSTIFY_CONTENT.FLEX_START
    ---拉伸时是否锁定宽高比（游戏 sprite 友好；CSS 默认不锁，这里默认不锁以贴近 CSS）
    self.locked_scale = false
end

---@return self
function Flex:setPadding(top, bottom, left, right)
    self.padding = { top or 0, right or 0, bottom or 0, left or 0 }
    self:setDirty()
    return self
end

---覆盖基类：返回基于子节点内容计算的内在尺寸（max-content 近似）。
---用于 flex-basis:auto 且无显式尺寸时的回退，避免容器因 width/height=0 被布局视为零尺寸。
---注意：这是简化实现（不处理文字换行、百分比等复杂情况），对游戏 UI 场景足够。
---@return number, number intrinsic_width, intrinsic_height
function Flex:getContentSize()
    -- 如果有显式尺寸，直接使用（不被内容撑开）
    if self.width > 0 and self.height > 0 then
        return self.width, self.height
    end
    local isRow = self.flex_direction == P.FLEX_DIRECTION.ROW or self.flex_direction == P.FLEX_DIRECTION.ROW_REVERSE
    local pad = self.padding
    local gap = self.gap
    -- 收集流式子项
    local flow = {}
    for _, c in ipairs(self.children) do
        if not c.exclude_from_layout and c.position ~= P.POSITION.ABSOLUTE and c.display ~= P.DISPLAY.NONE then
            table.insert(flow, c)
        end
    end
    if #flow == 0 then
        return self.width, self.height
    end
    -- 主轴内在尺寸 = 子项主轴尺寸之和 + gap + padding
    local mainSum = 0
    local crossMax = 0
    for i, c in ipairs(flow) do
        local cw, ch = c:getContentSize()
        -- 子项自身也可能是容器，递归取其内在尺寸
        if cw == 0 and ch == 0 and c.getContentSize ~= M.getContentSize then
            cw, ch = c:getContentSize()
        end
        local cMain = isRow and max(cw, 0) or max(ch, 0)
        local cCross = isRow and max(ch, 0) or max(cw, 0)
        -- 加外边距
        local mMain = isRow and (c.margin[4] + c.margin[2]) or (c.margin[1] + c.margin[3])
        local mCross = isRow and (c.margin[1] + c.margin[3]) or (c.margin[4] + c.margin[2])
        mainSum = mainSum + cMain + mMain
        crossMax = max(crossMax, cCross + mCross)
        if i > 1 then
            mainSum = mainSum + gap
        end
    end
    -- 加 padding
    local innerW, innerH
    if isRow then
        innerW = mainSum + pad[2] + pad[4]
        innerH = crossMax + pad[1] + pad[3]
    else
        innerW = crossMax + pad[2] + pad[4]
        innerH = mainSum + pad[1] + pad[3]
    end
    -- 与显式尺寸合并（某一轴有显式值时优先用显式值）
    local w = self.width > 0 and self.width or innerW
    local h = self.height > 0 and self.height or innerH
    return w, h
end

---设置间隙（gap）。可传单一数值（同时作用于两轴）或两个数值（主, 交）。
---@overload fun(gap:number):self
---@overload fun(mainGap:number, crossGap:number):self
function Flex:setSpacing(a, b)
    self.gap = a or 0
    if b then
        self.row_gap = a
        self.column_gap = b
    end
    self:setDirty()
    return self
end

---兼容旧 API：{h, v} 形式的整体对齐 → 映射为 justify/align
---@param alignment Core.UI.Layout.Alignment
function Flex:setAlignment(alignment)
    local h, v = alignment[1], alignment[2]
    self.justify_content = h == -1 and P.JUSTIFY_CONTENT.FLEX_START or h == 1 and P.JUSTIFY_CONTENT.FLEX_END or P.JUSTIFY_CONTENT.CENTER
    self.align_items = v == 1 and P.JUSTIFY_CONTENT.FLEX_START or v == -1 and P.JUSTIFY_CONTENT.FLEX_END or P.JUSTIFY_CONTENT.CENTER
    self:setDirty()
    return self
end

---@return self
function Flex:setDirty()
    if self._is_dirty then
        return self
    end
    self._is_dirty = true
    if self.parent and self.parent.setDirty then
        self.parent:setDirty()
    end
    return self
end

function Flex:rebuild()
    self:applyLayout()
end

function Flex:update()
    self._hscale, self._vscale = self:getScale()
    if self._is_dirty then
        self:rebuild()
        self._is_dirty = false
    end
    Core.UI.Child.update(self)
end

---把 flex-space（左上原点、x 向右、y 向下，内容盒范围 [0,cw]x[0,ch]）中
---以 (fcx, fcy) 为"中心"的点，转换为相对容器中心的坐标。
---注意：渲染层使用 y 向上坐标（原点左下，+y 向上），所以 y 需要取反：
---  flex-space 顶部(fcy≈0) → 正 arranged_y（容器中心上方→屏幕上方，+y）
---  flex-space 底部(fcy≈ch) → 负 arranged_y（容器中心下方→屏幕下方，-y）
---@return number, number
local function flexCenterToArranged(cw, ch, fcx, fcy)
    return fcx - cw / 2, ch / 2 - fcy
end

---把 "50%" 这类百分比字符串按 ref 解析为数值；非字符串原样返回。
local function resolvePct(v, ref)
    if type(v) == "string" then
        local n = v:match("([%d%.%+%-]+)%%")
        if n then
            return ref * (tonumber(n) or 0) / 100
        end
    end
    return v
end

---核心：实现一个较完整的 CSS flexbox 行布局算法。
function Flex:applyLayout()
    local isRow = self.flex_direction == P.FLEX_DIRECTION.ROW or self.flex_direction == P.FLEX_DIRECTION.ROW_REVERSE
    local reverseMain = self.flex_direction == P.FLEX_DIRECTION.ROW_REVERSE or self.flex_direction == P.FLEX_DIRECTION.COLUMN_REVERSE
    local wrap = self.flex_wrap ~= P.FLEX_WRAP.NOWRAP

    local pad = self.padding
    local cw = max(self.width - pad[2] - pad[4], 0)
    local ch = max(self.height - pad[1] - pad[3], 0)

    local gapMain = isRow and (self.column_gap ~= 0 and self.column_gap or self.gap) or (self.row_gap ~= 0 and self.row_gap or self.gap)
    local gapCross = isRow and (self.row_gap ~= 0 and self.row_gap or self.gap) or (self.column_gap ~= 0 and self.column_gap or self.gap)

    -- 收集流式子项（排除绝对定位、显式排除、display:none）
    ---@type Core.UI.Child[]
    local flow = {}
    for idx, c in ipairs(self.children) do
        if not c.exclude_from_layout and c.position ~= P.POSITION.ABSOLUTE and c.display ~= P.DISPLAY.NONE then
            c._flow_idx = #flow + 1  -- 记录在 flow 中的原始顺序（用于稳定排序）
            table.insert(flow, c)
        end
    end
    table.sort(flow, function(a, b)
        local oa, ob = a.order or 0, b.order or 0
        if oa ~= ob then return oa < ob end
        -- order 相同时保持 flow 数组中的原始插入顺序（稳定排序）
        return (a._flow_idx or 0) < (b._flow_idx or 0)
    end)

    -- 主/交叉轴尺寸访问器（统一用 main/cross 视角，避免方向混淆）
    local function mainOf(c)
        return c:getMainSize(isRow)
    end
    local function crossOf(c)
        return c:getCrossSize(isRow)
    end
    local function outerMain(c)
        return c:getOuterMainSize(isRow)
    end
    local function outerCross(c)
        return c:getOuterCrossSize(isRow)
    end
    local function mainMarginStart(c)
        return isRow and c.margin[4] or c.margin[1]
    end
    local function mainMarginEnd(c)
        return isRow and c.margin[2] or c.margin[3]
    end
    local function crossMarginStart(c)
        return isRow and c.margin[1] or c.margin[4]
    end
    local function crossMarginEnd(c)
        return isRow and c.margin[3] or c.margin[2]
    end

    -- 1) 假设的（hypothetical）主轴尺寸（支持百分比 flex-basis / width / height）
    --    当尺寸为 0 时回退到内在内容尺寸（max-content 近似），避免零尺寸子项无法参与布局。
    local mainRef = isRow and cw or ch
    for _, c in ipairs(flow) do
        local basis
        if c.flex_basis == P.FLEX_BASIS.AUTO then
            basis = isRow and resolvePct(c.width, cw) or resolvePct(c.height, ch)
        else
            basis = resolvePct(c.flex_basis, mainRef)
        end
        if type(basis) ~= "number" then
            basis = c:getMainSize(isRow)
        end
        -- 回退：basis 为 0 且节点无显式主轴尺寸时，使用内在内容尺寸
        if (basis or 0) == 0 then
            local iw, ih = c:getContentSize()
            local intrinsic = isRow and iw or ih
            if (intrinsic or 0) > 0 then
                basis = intrinsic
            end
        end
        c._flex_main = c:clampMainSize(basis or 0, isRow)
        -- _flex_outerMain：参与空间计算的占用尺寸。
        --   AUTO 边距（math.huge 哨兵）在此用 0 占位，避免 ∞ 污染后续算术；
        --   真正的 auto 吸收在步骤 3 底部（摆放阶段）才解析。
        local ms = mainMarginStart(c)
        local me = mainMarginEnd(c)
        c._flex_outerMain = c._flex_main + (ms == AUTO and 0 or ms) + (me == AUTO and 0 or me)
    end

    -- 2) 分行（仅 wrap 时）
    ---@type Core.UI.Child[][]
    local lines = {}
    local cur = {}
    local curMain = 0
    local mainAxisSize = isRow and cw or ch  -- row 按宽换行，column 按高换行
    for _, c in ipairs(flow) do
        if wrap and #cur > 0 and curMain + gapMain + c._flex_outerMain > mainAxisSize then
            table.insert(lines, cur)
            cur = {}
            curMain = 0
        end
        table.insert(cur, c)
        curMain = curMain + (#cur > 1 and gapMain or 0) + c._flex_outerMain
    end
    if #cur > 0 then
        table.insert(lines, cur)
    end

    -- 3) 每行主轴空间分配（grow / shrink / justify）
    for _, line in ipairs(lines) do
        local n = #line
        local sumOuter = 0
        local sumGrow, sumShrinkBase = 0, 0
        for _, c in ipairs(line) do
            sumOuter = sumOuter + c._flex_outerMain
            sumGrow = sumGrow + (c.flex_grow or 0)
            sumShrinkBase = sumShrinkBase + c._flex_main * (c.flex_shrink or 1)
        end
        local mainAxisSize = isRow and cw or ch  -- row 主轴用宽(cw)，column 主轴用高(ch)
        local free = mainAxisSize - sumOuter - gapMain * max(n - 1, 0)

        if free > 0 and sumGrow > 0 then
            -- 正向自由空间按比例分给 grow（v1 单次钳制，足够游戏 UI）
            for _, c in ipairs(line) do
                local add = free * (c.flex_grow or 0) / sumGrow
                c._flex_main = c:clampMainSize(c._flex_main + add, isRow)
            end
        elseif free < 0 and sumShrinkBase > 0 then
            for _, c in ipairs(line) do
                local weight = c._flex_main * (c.flex_shrink or 1) / sumShrinkBase
                local add = free * weight
                c._flex_main = c:clampMainSize(c._flex_main + add, isRow)
            end
        end
        -- 重新计算占用宽度（AUTO 边距仍用 0 占位，避免 ∞ 污染）
        sumOuter = 0
        for _, c in ipairs(line) do
            local ms = mainMarginStart(c)
            local me = mainMarginEnd(c)
            c._flex_outerMain = c._flex_main + (ms == AUTO and 0 or ms) + (me == AUTO and 0 or me)
            sumOuter = sumOuter + c._flex_outerMain
        end
        local used = sumOuter + gapMain * max(n - 1, 0)
        local remain = mainAxisSize - used

        -- ═══ Auto Margins（优先级高于 justify-content）═══
        -- CSS 规范：auto margin 吸收剩余空间。每行的所有 auto margin 均分 remain。
        -- 有任何 auto margin 时，justify-content 的 offset/extraGap 被忽略。
        local hasAutoMargin = false
        local nAutoStart, nAutoEnd = 0, 0
        for _, c in ipairs(line) do
            if mainMarginStart(c) == AUTO then nAutoStart = nAutoStart + 1; hasAutoMargin = true end
            if mainMarginEnd(c) == AUTO then nAutoEnd = nAutoEnd + 1; hasAutoMargin = true end
        end
        local autoSize = (nAutoStart + nAutoEnd > 0) and (remain / (nAutoStart + nAutoEnd)) or 0

        -- justify_content 决定主轴上剩余空间的分配（仅当无 auto margin 时生效）
        local offset, extraGap = 0, 0
        if not hasAutoMargin then
            local jc = self.justify_content
            if jc == P.JUSTIFY_CONTENT.FLEX_END then
                offset = remain
            elseif jc == P.JUSTIFY_CONTENT.CENTER then
                offset = remain / 2
            elseif jc == P.JUSTIFY_CONTENT.SPACE_BETWEEN then
                if n > 1 then extraGap = remain / (n - 1) end
            elseif jc == P.JUSTIFY_CONTENT.SPACE_AROUND then
                extraGap = remain / n
                offset = extraGap / 2
            elseif jc == P.JUSTIFY_CONTENT.SPACE_EVENLY then
                extraGap = remain / (n + 1)
                offset = extraGap
            end
        else
            -- 有 auto margin 时，offset 固定为 0。
            -- 每个子项的主轴位置由各自的 ms（已替换为 autoSize）自然决定，
            -- 不需要额外偏移；若加 nAutoStart*autoSize 会导致 start margin 被重复计算。
            offset = 0
        end

        -- 摆放该行内每个子项（flex-space 主轴上坐标 = 内容盒左/上 0 起）
        local pos = offset
        for _, c in ipairs(line) do
            local ms = mainMarginStart(c)
            local me = mainMarginEnd(c)
            -- auto margin 替换为解析后的值
            if ms == AUTO then ms = autoSize end
            if me == AUTO then me = autoSize end
            c._flex_mainStart = pos + ms
            c._flex_outerMain = c._flex_main + ms + me  -- 更新 outerMain 以便后续交叉轴计算正确
            pos = pos + c._flex_outerMain + gapMain + extraGap
        end
    end

    -- 4) 计算每行的交叉轴尺寸
    -- 单行容器：行交叉尺寸等于整个容器交叉尺寸（这样 align-items:stretch 才能填满容器）
    -- 多行容器：每行交叉尺寸等于该行内最大子项交叉尺寸
    local lineCross = {}
    local crossAxisSize = isRow and ch or cw  -- row 的交叉轴是高(ch)，column 的交叉轴是宽(cw)
    if #lines == 1 then
        lineCross[1] = crossAxisSize
    else
        for i, line in ipairs(lines) do
            local mx = 0
            for _, c in ipairs(line) do
                mx = max(mx, outerCross(c))
            end
            lineCross[i] = mx
        end
    end
    local totalCross = 0
    for _, v in ipairs(lineCross) do
        totalCross = totalCross + v
    end
    totalCross = totalCross + gapCross * max(#lines - 1, 0)

    -- 5) align_content 决定多行在交叉轴上的分布
    local crossOffset, crossExtra = 0, 0
    local ac = self.align_content
    local crossRemain = ch - totalCross
    if #lines > 1 then
        if ac == P.JUSTIFY_CONTENT.FLEX_END then
            crossOffset = crossRemain
        elseif ac == P.JUSTIFY_CONTENT.CENTER then
            crossOffset = crossRemain / 2
        elseif ac == P.ALIGN_ITEMS.STRETCH then
            local add = crossRemain / #lines
            for i = 1, #lines do
                lineCross[i] = lineCross[i] + add
            end
        elseif ac == P.JUSTIFY_CONTENT.SPACE_BETWEEN then
            crossExtra = crossRemain / (#lines - 1)
        elseif ac == P.JUSTIFY_CONTENT.SPACE_AROUND then
            crossExtra = crossRemain / #lines
            crossOffset = crossExtra / 2
        elseif ac == P.JUSTIFY_CONTENT.SPACE_EVENLY then
            crossExtra = crossRemain / (#lines + 1)
            crossOffset = crossExtra
        end
    end

    -- 6) 逐行摆放（flex-space 交叉轴从内容盒顶 0 向下递增）
    local crossPos = crossOffset
    for i, line in ipairs(lines) do
        local lineH = lineCross[i]
        for _, c in ipairs(line) do
            local ai = c.align_self or self.align_items
            local cStart, cSize
            if ai == P.ALIGN_ITEMS.STRETCH then
                -- 拉伸交叉轴填满该行（无确定交叉尺寸时）
                cStart = crossPos + crossMarginStart(c)
                cSize = lineH - crossMarginStart(c) - crossMarginEnd(c)
            elseif ai == P.JUSTIFY_CONTENT.FLEX_END then
                cStart = crossPos + lineH - outerCross(c) + crossMarginStart(c)
                cSize = crossOf(c)
            elseif ai == P.JUSTIFY_CONTENT.CENTER then
                cStart = crossPos + (lineH - outerCross(c)) / 2 + crossMarginStart(c)
                cSize = crossOf(c)
            else -- flex-start
                cStart = crossPos + crossMarginStart(c)
                cSize = crossOf(c)
            end
            c._flex_crossStart = cStart
            c._flex_crossSize = cSize
        end
        crossPos = crossPos + lineH + gapCross + crossExtra
    end

    -- 7) 先写回尺寸（让 width/height 反映 flex 分配的空间），再算 scale
    for _, line in ipairs(lines) do
        for _, c in ipairs(line) do
            local cMain = mainOf(c)
            local cCross = crossOf(c)
            -- flex-space 中内容盒中心（注意 row 与 column 的主/交叉轴不同）
            local mainCenter = c._flex_mainStart + c._flex_main / 2
            local crossCenter = c._flex_crossStart + c._flex_crossSize / 2
            local fcx = isRow and mainCenter or crossCenter
            local fcy = isRow and crossCenter or mainCenter
            local ax, ay = flexCenterToArranged(cw, ch, fcx, fcy)
            c.arranged_x = ax
            c.arranged_y = ay

            -- 7a) 写回：将 flex 分配的尺寸写回 width/height。
            --     主轴：零尺寸时写回（让节点占据分配到的主轴空间）。
            --     交叉轴：stretch 时始终写回（CSS 行为：stretch 拉伸到填满容器，
            --           即使子项有显式尺寸也被拉伸覆盖；否则非 stretch 回退内在尺寸）。
            if isRow then
                if cMain == 0 and c._flex_main > 0 then
                    c.width = c._flex_main
                    cMain = c._flex_main
                end
                if (c.align_self or self.align_items) == P.ALIGN_ITEMS.STRETCH then
                    -- stretch 强制写回交叉轴高度（覆盖显式 height）
                    if c._flex_crossSize > 0 then
                        c.height = c._flex_crossSize
                        cCross = c._flex_crossSize
                    end
                elseif cCross == 0 then
                    local cross = c._flex_crossSize
                    if (cross or 0) <= 0 then
                        local iw, ih = c:getContentSize()
                        cross = ih or 0
                    end
                    if cross > 0 then
                        c.height = cross
                        cCross = cross
                    end
                end
            else
                if cMain == 0 and c._flex_main > 0 then
                    c.height = c._flex_main
                    cMain = c._flex_main
                end
                if (c.align_self or self.align_items) == P.ALIGN_ITEMS.STRETCH then
                    -- stretch 强制写回交叉轴宽度（覆盖显式 width）
                    if c._flex_crossSize > 0 then
                        c.width = c._flex_crossSize
                        cCross = c._flex_crossSize
                    end
                elseif cCross == 0 then
                    local cross = c._flex_crossSize
                    if (cross or 0) <= 0 then
                        local iw, ih = c:getContentSize()
                        cross = iw or 0
                    end
                    if cross > 0 then
                        c.width = cross
                        cCross = cross
                    end
                end
            end

            -- 7b) 主轴缩放：让节点占据分配到的主轴尺寸
            local mainScale = cMain > 0 and c._flex_main / cMain or 1
            local crossScale = 1
            if (c.align_self or self.align_items) == P.ALIGN_ITEMS.STRETCH and cCross > 0 then
                crossScale = c._flex_crossSize / cCross
                if self.locked_scale then
                    crossScale = min(mainScale, crossScale)
                    mainScale = crossScale
                end
            end
            if isRow then
                c.arranged_hscale = mainScale
                c.arranged_vscale = crossScale
            else
                c.arranged_hscale = crossScale
                c.arranged_vscale = mainScale
            end
        end
    end

    -- 8) 绝对定位子项：相对内容盒用 inset 定位（物理轴：left/right=x，top/bottom=y）
    for _, c in ipairs(self.children) do
        if c.position == P.POSITION.ABSOLUTE and not c.exclude_from_layout and c.display ~= P.DISPLAY.NONE then
            local left, right = c.inset_left, c.inset_right
            local top, bottom = c.inset_top, c.inset_bottom
            local pw = resolvePct(c.width, cw)
            local ph = resolvePct(c.height, ch)
            if type(pw) ~= "number" then
                pw = c.width
            end
            if type(ph) ~= "number" then
                ph = c.height
            end
            local x0, x1, y0, y1
            if left and right then
                x0, x1 = left, cw - right
            elseif left then
                x0, x1 = left, left + pw
            elseif right then
                x1, x0 = cw - right, cw - right - pw
            else
                x0, x1 = (cw - pw) / 2, (cw + pw) / 2
            end
            if top and bottom then
                y0, y1 = top, ch - bottom
            elseif top then
                y0, y1 = top, top + ph
            elseif bottom then
                y1, y0 = ch - bottom, ch - bottom - ph
            else
                y0, y1 = (ch - ph) / 2, (ch + ph) / 2
            end
            local fcx = (x0 + x1) / 2
            local fcy = (y0 + y1) / 2
            c.arranged_x, c.arranged_y = flexCenterToArranged(cw, ch, fcx, fcy)
            local derivedW = x1 - x0
            local derivedH = y1 - y0
            -- 当节点自身尺寸为 0 时，用 inset 推导的尺寸作为缩放基准。
            -- 注意：必须调用 setWH() 而非直接赋值 width/height，
            -- 因为 Draw.Rect 等子类有独立的 draw_width 需要同步。
            local sx = derivedW / max(pw, 1e-6)
            local sy = derivedH / max(ph, 1e-6)
            if pw == 0 and derivedW > 0 then
                if c.setWH then c:setWH(derivedW, c.height) else c.width = derivedW end
                sx = 1
            end
            if ph == 0 and derivedH > 0 then
                if c.setWH then c:setWH(c.width, derivedH) else c.height = derivedH end
                sy = 1
            end
            if self.locked_scale then
                sx, sy = min(sx, sy), min(sx, sy)
            end
            c.arranged_hscale, c.arranged_vscale = sx, sy
        end
    end

    -- 方向翻转：row-reverse / column-reverse 仅镜像主轴（交叉轴不受影响）
    if reverseMain then
        for _, line in ipairs(lines) do
            for _, c in ipairs(line) do
                if isRow then
                    c.arranged_x = -c.arranged_x
                else
                    c.arranged_y = -c.arranged_y
                end
            end
        end
    end

    -- 9) position: relative 偏移（物理轴，不参与方向翻转）
    for _, line in ipairs(lines) do
        for _, c in ipairs(line) do
            if c.position == P.POSITION.RELATIVE then
                c.arranged_x = c.arranged_x + ((c.inset_left or 0) - (c.inset_right or 0))
                c.arranged_y = c.arranged_y + ((c.inset_top or 0) - (c.inset_bottom or 0))
            end
        end
    end
end

---@class Core.UI.Layout.Vertical : Core.UI.Layout.Flex
local Vertical = Core.Class(Flex)
M.Vertical = Vertical
function Vertical:init(layer)
    Flex.init(self, layer)
    self._name = "Layout.Vertical"
    self.flex_direction = P.FLEX_DIRECTION.COLUMN
    return self
end

---@class Core.UI.Layout.Horizontal : Core.UI.Layout.Flex
local Horizontal = Core.Class(Flex)
M.Horizontal = Horizontal
function Horizontal:init(layer)
    Flex.init(self, layer)
    self._name = "Layout.Horizontal"
    self.flex_direction = P.FLEX_DIRECTION.ROW
    return self
end

-- ===================== Grid 布局 =====================

---@class Core.UI.Layout.Grid : Core.UI.Child
local Grid = Core.Class(Core.UI.Child)
M.Grid = Grid
Grid:addSerializeSimple(Core.UI.Child, "padding", "spacing_h", "spacing_v", "horizontal_count", "vertical_count", "weight_data", "grid_data")
Grid:addSerializeOrder("padding", Core.Lib.Json.Encode)
Grid:addDeserializeOrder("padding", Core.Lib.Json.Decode)
Grid:addSerializeOrder("grid_data", Core.Lib.Json.Encode)
Grid:addDeserializeOrder("grid_data", Core.Lib.Json.Decode)
Grid:addSerializeOrder("weight_data", Core.Lib.Json.Encode)
Grid:addDeserializeOrder("weight_data", Core.Lib.Json.Decode)

---@param horizontal_count number
---@param vertical_count number
---@param layer number
function Grid:init(horizontal_count, vertical_count, layer)
    Core.UI.Child.init(self, "Layout.Grid", layer)
    self._name = "Layout.Grid"
    self.is_layout = true
    self._is_dirty = true
    self.padding = { 0, 0, 0, 0 }
    self:setGrid(horizontal_count, vertical_count)
    self:setSpacing()
end

---@overload fun(h:number, v:number):self
---@overload fun(spacing:number):self
function Grid:setSpacing(h, v)
    self.spacing_h = h or 0
    self.spacing_v = v or h or 0
    self:setDirty()
    return self
end

---@param alignment Core.UI.Layout.Alignment
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

---@param enable boolean
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
        y = {},
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

---@param i number
---@param j number
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

function Grid:setDirty()
    if self._is_dirty then
        return self
    end
    self._is_dirty = true
    if self.parent and self.parent.setDirty then
        self.parent:setDirty()
    end
    return self
end

function Grid:rebuild()
    self:applyLayout()
end

function Grid:update()
    self._hscale, self._vscale = self:getScale()
    if self._is_dirty then
        self:rebuild()
        self._is_dirty = false
    end
    Core.UI.Child.update(self)
end

function Grid:applyLayout()
    local pad = self.padding
    local cw = max(self.width - pad[2] - pad[4], 0)
    local ch = max(self.height - pad[1] - pad[3], 0)
    local count = { self.horizontal_count, self.vertical_count }
    local spacing = { self.spacing_h, self.spacing_v }
    local available = {
        cw - spacing[1] * (count[1] - 1),
        ch - spacing[2] * (count[2] - 1),
    }
    local weight = { 0, 0 }
    for i = 1, self.horizontal_count do
        weight[1] = weight[1] + self.weight_data.x[i]
    end
    for i = 1, self.vertical_count do
        weight[2] = weight[2] + self.weight_data.y[i]
    end

    local Pos = { 0, 0 }
    local childP = 1
    local function getChild()
        local cur = self.children[childP]
        if cur then
            childP = childP + 1
            if cur.exclude_from_layout then
                return getChild()
            else
                return cur
            end
        else
            return nil
        end
    end

    for j = 1, self.vertical_count do
        local realSize = { 0, 0 }
        for i = 1, self.horizontal_count do
            local cur = getChild()
            if cur then
                local data = self.grid_data[i][j]
                data.childID = childP - 1
                local w = {
                    self.weight_data.x[i] / weight[1],
                    self.weight_data.y[j] / weight[2],
                }
                realSize = { available[1] * w[1], available[2] * w[2] }
                cur.arranged_x = Pos[1] - cw / 2
                cur.arranged_y = Pos[2] + ch / 2
                Pos[1] = Pos[1] + realSize[1] + spacing[1]
                local picSize = { cur.width, cur.height }
                local scale = { realSize[1] / picSize[1] * data.scale, realSize[2] / picSize[2] * data.scale }
                if data.lock_aspect_ratio then
                    local p = min(scale[1], scale[2])
                    scale = { p, p }
                end
                cur.arranged_hscale = scale[1]
                cur.arranged_vscale = scale[2]
                local halign, valign = data.align[1], data.align[2]
                local offset = { halign * (realSize[1] - picSize[1]), -valign * (realSize[2] - picSize[2]) }
                cur.arranged_x = cur.arranged_x + offset[1] + realSize[1] / 2
                cur.arranged_y = cur.arranged_y + offset[2] - realSize[2] / 2
            else
                return
            end
        end
        Pos[1] = 0
        Pos[2] = Pos[2] - realSize[2] - spacing[2]
    end
end
