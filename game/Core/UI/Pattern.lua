---@class Core.UI.Pattern
---Flex 布局模式的枚举常量表。
---
---设计要点：每个常量的值，**就是引擎（Core.UI.Layout / Child）内部比较所用的字符串本身**。
---因此把枚举赋给节点的 flex 属性，与手写裸字符串完全等价、行为零变化：
---
---```lua
---local P = Core.UI.Pattern
---box.flex_direction = P.FLEX_DIRECTION.ROW          -- 等价于 "row"
---box.justify_content = P.JUSTIFY_CONTENT.SPACE_BETWEEN -- 等价于 "space-between"
---box.align_items    = P.ALIGN_ITEMS.STRETCH        -- 等价于 "stretch"
---```
---
---相比裸字符串的好处：可读、IDE 可补全、拼写错误立即得到 nil（而非静默走默认分支）。
---取值集合严格对齐引擎实际支持的模式，未臆造引擎不支持的取值。
---
---@field FLEX_DIRECTION Core.UI.Pattern.FLEX_DIRECTION
---@field FLEX_WRAP Core.UI.Pattern.FLEX_WRAP
---@field JUSTIFY_CONTENT Core.UI.Pattern.JUSTIFY_CONTENT
---@field ALIGN_ITEMS Core.UI.Pattern.ALIGN_ITEMS
---@field ALIGN_SELF Core.UI.Pattern.ALIGN_ITEMS
---@field ALIGN_CONTENT Core.UI.Pattern.ALIGN_CONTENT
---@field POSITION Core.UI.Pattern.POSITION
---@field DISPLAY Core.UI.Pattern.DISPLAY
---@field FLEX_BASIS Core.UI.Pattern.FLEX_BASIS
local M = {}
Core.UI.Pattern = M

---主轴方向（flex-direction）
---@class Core.UI.Pattern.FLEX_DIRECTION
M.FLEX_DIRECTION = {
    ---主轴水平，子项从左向右排列
    ROW = "row",
    ---主轴水平，子项从右向左排列（顺序反转）
    ROW_REVERSE = "row-reverse",
    ---主轴垂直，子项从上向下排列
    COLUMN = "column",
    ---主轴垂直，子项从下向上排列（顺序反转）
    COLUMN_REVERSE = "column-reverse",
}

---换行行为（flex-wrap）
---@class Core.UI.Pattern.FLEX_WRAP
M.FLEX_WRAP = {
    ---不换行，空间不足时子项被压缩进同一行/列
    NOWRAP = "nowrap",
    ---空间不足时换到下一行/列
    WRAP = "wrap",
    ---换行，且交叉轴方向整体反转
    WRAP_REVERSE = "wrap-reverse",
}

---主轴对齐（justify-content）
---@class Core.UI.Pattern.JUSTIFY_CONTENT
M.JUSTIFY_CONTENT = {
    ---向主轴起点对齐，首尾不留空隙
    FLEX_START = "flex-start",
    ---向主轴终点对齐，首尾不留空隙
    FLEX_END = "flex-end",
    ---在主轴居中，两侧留白相等
    CENTER = "center",
    ---首尾子项贴边，中间间隙均匀分布（首尾无外侧空隙）
    SPACE_BETWEEN = "space-between",
    ---每个子项两侧间隙相等，首尾外侧空隙为中间空隙的一半
    SPACE_AROUND = "space-around",
    ---所有间隙（含首尾外侧）完全相等
    SPACE_EVENLY = "space-evenly",
}

---交叉轴对齐（align-items / align-self 共用同一取值集合）
---@class Core.UI.Pattern.ALIGN_ITEMS
M.ALIGN_ITEMS = {
    ---拉伸填满交叉轴（默认值；子项无显式交叉轴尺寸时生效）
    STRETCH = "stretch",
    ---向交叉轴起点对齐
    FLEX_START = "flex-start",
    ---向交叉轴终点对齐
    FLEX_END = "flex-end",
    ---在交叉轴居中
    CENTER = "center",
}
---align-self 别名：与 align-items 取值完全相同，便于按属性名引用
---@class Core.UI.Pattern.ALIGN_SELF
M.ALIGN_SELF = M.ALIGN_ITEMS

---多行在交叉轴上的分布（align-content，仅在换行且存在多行时生效）
---@class Core.UI.Pattern.ALIGN_CONTENT
M.ALIGN_CONTENT = {
    ---多行拉伸填满交叉轴
    STRETCH = "stretch",
    ---多行向交叉轴起点堆叠
    FLEX_START = "flex-start",
    ---多行向交叉轴终点堆叠
    FLEX_END = "flex-end",
    ---多行在交叉轴居中
    CENTER = "center",
    ---首行/末行贴边，行间隙均匀分布
    SPACE_BETWEEN = "space-between",
    ---每行两侧间隙相等，首尾外侧空隙为行间空隙的一半
    SPACE_AROUND = "space-around",
    ---所有行间隙（含首尾外侧）完全相等
    SPACE_EVENLY = "space-evenly",
}

---定位方式（position）
---@class Core.UI.Pattern.POSITION
M.POSITION = {
    ---相对定位：按 flex 布局流正常占位
    RELATIVE = "relative",
    ---绝对定位：脱离布局流，使用 inset_* 相对最近定位父容器定位
    ABSOLUTE = "absolute",
}

---显示方式（display）
---@class Core.UI.Pattern.DISPLAY
M.DISPLAY = {
    ---作为 flex 容器参与布局
    FLEX = "flex",
    ---不参与布局且不可见（等价于隐藏）
    NONE = "none",
}

---flex-basis 关键字
---@class Core.UI.Pattern.FLEX_BASIS
M.FLEX_BASIS = {
    ---以 width/height 或内容固有尺寸作为主轴基准尺寸
    AUTO = "auto",
}
