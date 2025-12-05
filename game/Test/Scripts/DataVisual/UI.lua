---@class Test.DataVisual.UI
local M = {}
Test.DataVisual.UI = M

M.keyTriggerShow = true

local Core = Core
local UI = Core.UI
local Render = Core.Render
local Color = Core.Render.Color

local Debug = Core.Lib.Debug

function M.Main(self)
    --   local root = UI.Manager.CreateHUDRoot("Test.Main", 1)
    local hud_root = UI.Manager.CreateHUDRoot("Test.HUD", 1)
    hud_root:addChild(UI.Immediate("Nodes", -1, function()
        for _, m in ipairs(self.nodes) do
            local s = m.aim
            local A = m.alpha * (0.7 + s * 0.3)
            local r, g, b = m.color[1], m.color[2], m.color[3]
            local rx, ry = UI.Camera:worldToUI(self.camera, m.x, m.y, m.z)
            local size = (m.r + s * 3) * self.camera:getDepthScale(m.x, m.y, m.z)
            Render.Text("exo2", ("%s"):format(m.name), rx, ry - size * 1.4,
                    size * 0.03, Color(size * 8 * A, 255, 255, 255), "centerpoint")

            Core.Resource.Image.Get("pure_circle")
                :setState(Render.BlendMode.Default, Color(size * 8 * A, 0, 0, 0))
                :setPos(rx, ry):setRotation(0):setScale(size / 110):draw()
                :setState(Render.BlendMode.MulAdd, Color(size * 8 * A, r, g, b))
                :setPos(rx, ry):setRotation(0):setScale(size / 125):draw()
            Core.Resource.Image.Get("bright")
                :setState(Render.BlendMode.MulAdd, Color(size * 8 * A, r, g, b))
                :setPos(rx, ry):setRotation(0):setScale(size / 50):draw()--]]

            if m.parent then
                local p = m.parent
                local pr, pg, pb = p.color[1], p.color[2], p.color[3]
                local size2 = (p.r + p.aim * 3) * self.camera:getDepthScale(p.x, p.y, p.z)
                Render.Draw.SetState(Render.BlendMode.MulAdd,
                        Color(size * 0 * A, r, g, b), Color(size2 * 5 * A, pr, pg, pb),
                        Color(size2 * 5 * A, pr, pg, pb), Color(size * 0 * A, r, g, b))
                local px, py = UI.Camera:worldToUI(self.camera, p.x, p.y, p.z)
                Render.Draw.Connect(rx, ry, px, py, 0.3 * size, 0)
            end
        end
    end))
    hud_root:addChild(UI.Immediate("FPS", 0, function()
        local hud = UI.Camera:getView()
        Render.Text("exo2", ("%.1f"):format(lstg.GetFPS()), hud.right - 20, hud.top - 30,
                1, Color(150, 255, 255, 255), "right")
    end))
    local keyShow = UI.Immediate("KeyShow", 0, function()
        local hud = UI.Camera:getView()
        for _, v in ipairs(self.keyTriggerList) do
            Render.Text("exo2", ("%s"):format(v.name), hud.right - 20, hud.bottom + 30 + v.pos * 50,
                    1, Color(v.alpha * 100, 255, 255, 255), "right")
        end
    end)
    hud_root:addChild(keyShow)

    do
        local root = UI.Manager.CreateCameraRoot(self.camera, "Test.Main2", 2)
        local mlayout = UI.Layout.Grid()
                          :setPos(0, 1000)
                          :setWH(1000, 1000)
                          :setGrid(9, 9)
              --  :setSpacing(10)
                          :setLockAspectRatio(false)
        local texture = Core.Resource.Texture.Get("test")
        local w, h = texture:getSize()

        for j = 0, 8 do
            for i = 0, 8 do
                --mlayout:addChild(UI.Image("pure_circle"))

                local m = UI.TextureRect("test")
                m:setUV(w / 9 * i, w / 9 * j, w / 9, w / 9)
                m:setLayer(i + j * 9)
                mlayout:addChild(m)--]]
            end
        end
        local f = io.open("Test/Scripts/mlayout.json", "w")
        f:write(Core.Lib.Json.Serialize(mlayout:serialize()))
        f:close()--]]
        --[[
                local f = io.open("Test/Scripts/mlayout.json", "r")
                local data =Core.Lib.Json.Decode(f:read("*a"))
                f:close()
                local mlayout = UI.Layout.Grid():deserialize(data)--]]
        root:addBeforeEvent("Update", 1, function()
            local t = root.timer
            for i = 1, 9 do
                mlayout:setWeight(2 + sin(i * 27 + t * 2), i)
                mlayout:setWeight(2 + sin(i * 20 + t * 1.5), nil, i)
                --[[
                for j = 1, 9 do
                    mlayout:getChild(i, j):setState(Render.BlendMode.Default, Color.AHSV(150, t * 2 + 30 * sin(i * 32 + t * 2), 0.5, 1))
                end--]]
            end
        end)

        root:addChild(mlayout)
        local text = UI.Text():setPos(0, 0)
                       :setFont("wenkai")
                       :setText(Core.I18n:get("welcome-message"))
                       :setSize(60)
        root:addChild(text)
        local languageList = Core.I18n.GetAvailableLanguages()
        for _, lang in ipairs(languageList) do
            Debug.AddButton("Test", "Switch to language: " .. lang, function()
                Core.I18n.SetLanguage(lang)
                text:setText(Core.I18n:get("welcome-message"))
            end)
        end

    end

    return hud_root
end

function M.PauseMenu(self)

    local root = UI.Manager.CreateHUDRoot("Test.PauseMenu", 2)
    root :addChild(UI.Child("Title", 0, function()
        local A = self.alpha
        local hud = UI.Camera:getView()
        Render.Text("exo2", "Game Paused", hud.centerX, hud.centerY + 100 * (1 - A),
                1, Color(A * 255, 255, 255, 255), "centerpoint")
    end)):addChild(UI.Child("Back", -1, function()
        local A = self.alpha
        local hud = UI.Camera:getView()
        Render.Draw.SetState(Render.BlendMode.Default, Color(A * 100, 0, 0, 0))
        Render.Draw.Rect(hud.left, hud.right, hud.bottom, hud.top)
    end))
    return root
end