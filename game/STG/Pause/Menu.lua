---@class STG.Pause.Menu
---In-game pause menu overlay with Continue/Retry/Return to Title.
---Renders as HUD UI nodes using screen-space coordinates
---(Core.UI.Camera origin = bottom-left, center = sw/2, sh/2).
local M = {}
STG.Pause.Menu = M

local Render = Core.Render
local Input = Core.Input
local Key = Core.Input.Keyboard.Key

-- Helper: check if key was just pressed this frame (IsDown = keydown edge)
local function keyDown(k)
    return Input.Keyboard.IsDown(k)
end

function M.New(scene, onContinue, onRestart, onTitle)
    local options = {
        { label = "Continue",        action = onContinue or function() STG.Pause.Resume() end },
        { label = "Give up & Retry", action = onRestart or function() Core.SceneManager.Restart() end },
        { label = "Return to Title", action = onTitle },
    }
    local selected = 1
    local confirm_timer = 0
    local visible = false
    local hud_root = nil

    local function show()
        if not visible then
            visible = true
            selected = 1
            confirm_timer = 15
            -- Create HUD root only when first shown (avoids global existence)
            if not hud_root then
                hud_root = Core.UI.Manager.CreateHUDRoot("STG.Pause.Menu", 10)
                hud_root:addChild(Core.UI.Immediate("pause_overlay", 0, function()
                    if not visible then return end

                    local sw, sh = Core.Display.Screen.GetSize()
                    local cx, cy = sw / 2, sh / 2  -- screen center in HUD space

                    -- Darken background (full screen quad)
                    Render.Draw.SetState(Render.BlendMode.Default, Render.Color(120, 0, 0, 0))
                    Render.Draw.Rect(0, sw, 0, sh)

                    -- "Pause" title
                    Render.Utils.SimpleTTF("exo2", "-- PAUSED --", cx, cy + 100, 0.48,
                        Render.Color.ARGB(220, 200, 200, 220), "center")

                    -- Menu options
                    for i, opt in ipairs(options) do
                        local is_sel = (i == selected)
                        local y = cy - (i - 1) * 48
                        local text = is_sel and (">>  " .. opt.label .. "  <<") or ("    " .. opt.label)
                        local color = is_sel and Render.Color.White or Render.Color.ARGB(160, 180, 190, 210)
                        local size = is_sel and 0.45 or 0.38
                        Render.Utils.SimpleTTF("exo2", text, cx, y, size, color, "center")
                    end

                    Render.Utils.SimpleTTF("exo2", "Z: Confirm    Esc: Unpause", cx, cy - 170, 0.22,
                        Render.Color.ARGB(80, 150, 150, 150), "center")
                end))
            end
        end
    end

    local function hide()
        visible = false
    end

    -- Register pause listener
    STG.Event.On(STG.Event.Group.PAUSE, "Pause.Menu.Show", function() show() end)
    STG.Event.On(STG.Event.Group.RESUME, "Pause.Menu.Hide", function() hide() end)

    -- Input handler (register on MainLoop Frame Before)
    Core.MainLoop.AddEvent("Frame", "Before", {
        name = "STG.Pause.Menu.Input",
        func = function()
            if not visible then return end
            if confirm_timer > 0 then confirm_timer = confirm_timer - 1; return end

            if keyDown(Key.Up) then
                selected = selected - 1
                if selected < 1 then selected = #options end
            elseif keyDown(Key.Down) then
                selected = selected + 1
                if selected > #options then selected = 1 end
            elseif keyDown(Key.Z) then
                local opt = options[selected]
                if opt and opt.action then
                    confirm_timer = 15
                    opt.action()
                end
            elseif keyDown(Key.Escape) then
                confirm_timer = 10
                STG.Pause.Resume()
            end
        end,
        level = 100,
    })

    scene._pause_root = hud_root
end

function M.Cleanup(scene)
    if scene._pause_root then
        scene._pause_root:release()
        scene._pause_root = nil
    end
    STG.Event.Off(STG.Event.Group.PAUSE, "Pause.Menu.Show")
    STG.Event.Off(STG.Event.Group.RESUME, "Pause.Menu.Hide")
    Core.MainLoop.RemoveEvent("Frame", "Before", "STG.Pause.Menu.Input")
end

return M
