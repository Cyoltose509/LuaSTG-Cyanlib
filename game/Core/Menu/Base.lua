---@class Core.Menu.Base
local M = Core.Class()
Core.Menu.Base = M

local Smooth   = Core.Math.ExpInterp
local Draw      = Core.Render.Draw
local Color     = Core.Render.Color
local Blend     = Core.Render.BlendMode.Default
local SimpleTTF = Core.Render.SimpleTTF

-- 默认配色（可被子类覆盖）
M.BG_ALPHA       = 180
M.BG_RGB         = {4, 6, 18}
M.TITLE_RGB      = {200, 180, 240}
M.TITLE_SIZE     = 18
M.HINT_RGB       = {120, 160, 160}
M.HINT_ALPHA     = 160
M.HINT_SIZE      = 11

-- ========================================
-- 可复用菜单背景绘制方法
-- ========================================

---绘制菜单半透明背景
---@param sw    number 屏幕宽度（来自 Core.Display.Screen.GetSize()）
---@param alpha number|nil 整体 alpha 乘子（默认 1）
function M:DrawMenuBackground(sw, alpha)
    alpha = alpha or 1
    Draw.SetState(Blend,
        math.floor(self.BG_ALPHA * alpha),
        self.BG_RGB[1],
        self.BG_RGB[2],
        self.BG_RGB[3])
    Draw.Rect(0, sw, 0, sw * 0.5625)
end

---绘制菜单标题（居中）
---@param text  string 标题文字（如 "- Select Difficulty -"）
---@param cx    number 屏幕中心 x
---@param y     number 标题 y 坐标
---@param alpha number|nil 整体 alpha 乘子
function M:DrawMenuTitle(text, cx, y, alpha)
    alpha = alpha or 1
    SimpleTTF("exo2", text, cx, y, self.TITLE_SIZE,
        Color(self.TITLE_RGB[1], self.TITLE_RGB[2], self.TITLE_RGB[3],
               math.floor(255 * alpha)),
        "center")
end

---绘制底部操作提示（居中）
---@param text  string 提示文字（如 "Z:Confirm  X:Back"）
---@param cx    number 屏幕中心 x
---@param y     number 提示 y 坐标
---@param alpha number|nil 整体 alpha 乘子
function M:DrawMenuBottomHint(text, cx, y, alpha)
    alpha = alpha or 1
    SimpleTTF("exo2", text, cx, y, self.HINT_SIZE,
        Color(self.HINT_RGB[1], self.HINT_RGB[2], self.HINT_RGB[3],
               math.floor(self.HINT_ALPHA * alpha)),
        "center")
end

-- ========================================
-- 默认生命周期（子类按需覆盖）
-- ========================================

function M:update(dt)
end

function M:updateClosing(dt, alpha_decay)
    self.alpha = self.alpha or 1
    if self.is_closing then
        self.alpha = math.max(self.alpha - dt * (alpha_decay or 5), 0)
        self.locked = true
        if self.alpha <= 0 then
            Core.Menu.Pop()
        end
    else
        self.alpha = Smooth(self.alpha, 1, dt * 8)
    end
end

function M:close()
    self.is_closing = true
end

function M:release()
end

function M:updateInput(mx, my)
end

function M:render()
end

function M:isKilled()
    return self.is_closing
end
