---@class STG.Replay.UI
local M = {}
STG.Replay.UI = M

local Render = Core.Render

---@class STG.Replay.UI.Overlay
local Overlay = Core.Class()
M.Overlay = Overlay

function Overlay:init(replay_player)
    self.player = replay_player
    self.visible = false
    self.alpha = 0
end

function Overlay:show()
    self.visible = true
end

function Overlay:hide()
    self.visible = false
end

function Overlay:toggle()
    self.visible = not self.visible
end

function Overlay:update(dt)
    self.alpha = Core.Math.ExpInterp(
        self.alpha,
        self.visible and 1 or 0,
        dt * 5
    )
end

function Overlay:render()
    if self.alpha <= 0.01 then
        return
    end
    local a = 255 * self.alpha
    local Draw = Render.Draw
    local status = self.player:getStatus()

    -- Bottom bar
    local w = Core.Display.Screen.GetSize()
    local screen_w = w
    local screen_h = 540
    if type(w) == "table" then
        screen_w = w[1] or 960
        screen_h = w[2] or 540
    end

    local bar_y = -screen_h / 2 + 30
    local bar_w = screen_w * 0.8
    local bar_h = 4

    -- Progress bar background
    Draw.SetState(Render.BlendMode.Default, a * 0.5, 40, 40, 40)
    Draw.Rect(-bar_w / 2, bar_w / 2, bar_y - bar_h, bar_y + bar_h)

    -- Progress fill
    Draw.SetState(Render.BlendMode.Default, a, 100, 200, 255)
    Draw.Rect(-bar_w / 2, -bar_w / 2 + bar_w * status.progress, bar_y - bar_h, bar_y + bar_h)

    -- Frame counter
    local text = string.format("%d / %d  %.1fx%s%s",
        status.current_frame,
        status.total_frames,
        status.speed,
        status.paused and " [PAUSED]" or "",
        status.desynced and " [DESYNC]" or ""
    )
    Render.Utils.SimpleText("default", text, 0, bar_y - 20, 0.4, Render.Color.ARGB(a, 255, 255, 255))

    -- Controls hint
    local hint = "[Space] Pause  [Left/Right] Speed  [Esc] Exit Replay"
    Render.Utils.SimpleText("default", hint, 0, bar_y - 40, 0.3, Render.Color.ARGB(a * 0.7, 180, 180, 180))
end

return M
