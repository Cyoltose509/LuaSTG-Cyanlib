---@class STG.Menu.Settings
local M = {}
STG.Menu.Settings = M

local Menu = Core.Menu
local Config = STG.Config

function M.Show()
    local menu = Menu.Base()

    local settings = {
        { key = "difficulty", label = "Difficulty", values = { "EASY", "NORMAL", "HARD", "LUNATIC" } },
        { key = "starting_lives", label = "Starting Lives", values = { 1, 2, 3, 5, 7 } },
        { key = "starting_bombs", label = "Starting Bombs", values = { 0, 1, 2, 3, 5 } },
    }

    local selected = 1

    function menu:updateInput()
        local Input = Core.Input
        if Input.ButtonDown("Player.MoveUp") then
            selected = (selected - 2) % #settings + 1
            if selected < 1 then selected = #settings end
        elseif Input.ButtonDown("Player.MoveDown") then
            selected = selected % #settings + 1
        elseif Input.ButtonDown("Player.MoveLeft") then
            local s = settings[selected]
            local cur = Config.Get(s.key)
            local idx = M._indexOf(s.values, cur)
            idx = idx - 1
            if idx < 1 then idx = #s.values end
            Config.Set(s.key, s.values[idx])
            Config.Save()
        elseif Input.ButtonDown("Player.MoveRight") then
            local s = settings[selected]
            local cur = Config.Get(s.key)
            local idx = M._indexOf(s.values, cur)
            idx = idx + 1
            if idx > #s.values then idx = 1 end
            Config.Set(s.key, s.values[idx])
            Config.Save()
        elseif Input.ButtonDown("Player.Pause") or Input.ButtonDown("Player.Bomb") then
            Menu.Pop()
        end
    end

    function menu:render()
        local Render = Core.Render
        -- Title
        Render.Utils.SimpleText("default", "Settings", 0, 200, 0.6, Render.Color.White)
        for i, s in ipairs(settings) do
            local color = (i == selected) and Render.Color.White or Render.Color.ARGB(160, 200, 200, 200)
            local val = tostring(Config.Get(s.key))
            local text = (i == selected) and ("> " .. s.label .. ": " .. val .. " <") or (s.label .. ": " .. val)
            Render.Utils.SimpleText("default", text, 0, 120 - i * 30, 0.4, color)
        end
    end

    Menu.Push(menu)
end

function M._indexOf(tbl, val)
    for i, v in ipairs(tbl) do
        if v == val then
            return i
        end
    end
    return 1
end

return M
