---@class STG.Test.Scene : Core.SceneManager.Scene
local M = Core.SceneManager.NewScene("STG.Test")
STG.Test.Scene = M

local Enemy = STG.Enemy
local Player = STG.Player
local Shots = STG.Shots
local Boss = STG.Enemy.Boss
local Behavior = STG.Enemy.Behavior
local Easing = Core.Lib.Easing
local Task = Core.Task
local Layout = STG.Layout
local HUD = STG.HUD

function M:init()
    Core.System.Log(Core.System.LogType.Info, "[TestScene] init() called")
    local layout = Layout.Setup(self)
    local panel = Layout.GetPanelRect(self)
    if panel then
        Core.System.Log(Core.System.LogType.Info, "[TestScene] panel=" .. tostring(panel.left) .. "," .. tostring(panel.right) .. "," .. tostring(panel.top) .. "," .. tostring(panel.bottom))
        HUD.CreateSidePanel(layout.hud_root, panel)
    else
        Core.System.Log(Core.System.LogType.Warning, "[TestScene] panel is nil!")
    end
    -- Do NOT call HUD.Init() — CreateSidePanel is the primary HUD rendering

    -- Load background as game object (renders in STG 2D camera, layer BG=-700)
    STG.Background.Load("gensokyosora")

    -- Create game run (required for HUD, pause, score tracking)
    local run = STG.Run.New()
    run:start()
    Core.System.Log(Core.System.LogType.Info, "[TestScene] Run created and started, state=" .. run.sm:getCurrentStateName())
    STG.Pause.Menu.New(self, function() STG.Pause.Resume() end,
        function() Core.SceneManager.Restart() end,
        function() Core.SceneManager.SetScene("STG.Menu.Title") end)

    Player.Spawn(0, -180)
    Core.System.Log(Core.System.LogType.Info, "[TestScene] Player spawned")

    -- ========================================
    -- Fairies with behaviors
    -- ========================================
    local e1 = Enemy.Spawn(-80, 160, {
        style_name = "petticoat_lantern_fairy_gray", hp = 80, score = 500,
    })
    e1.sys:addBehavior(Behavior.Sequence(
        Behavior.Parallel(
            Behavior.MoveBy(100, -20, 120, Easing.QuartOut),
            Behavior.Loop(3, Behavior.Sequence(
                Behavior.Shoot.ring(6, 2.5, "arrow_small"),
                Behavior.Wait(20)
            ))
        ),
        Behavior.Loop(-1, Behavior.Sequence(
            Behavior.MoveBy(0, 40, 60, Easing.SineInOut),
            Behavior.Wait(20),
            Behavior.MoveBy(0, -40, 60, Easing.SineInOut),
            Behavior.Wait(20)
        ))
    ))

    local e2 = Enemy.Spawn(80, 180, {
        style_name = "uniform_horn_fairy_purple", hp = 60, score = 300,
    })
    e2.sys:addBehavior(Behavior.Sequence(
        Behavior.Parallel(
            Behavior.MoveBy(-120, -30, 150, Easing.QuadOut),
            Behavior.Shoot.wave(3, 6, 2.5, "ball_small", 12)
        ),
        Behavior.Loop(-1, Behavior.Sequence(
            Behavior.Shoot.aimed(4, 2.5, "arrow_medium", 0, -180, 20),
            Behavior.Wait(30)
        ))
    ))

    local e3 = Enemy.Spawn(-120, 120, {
        style_name = "flower_fairy_small_red", hp = 40, score = 200,
    })
    e3.sys:addBehavior(Behavior.Loop(-1, Behavior.Sequence(
        Behavior.MoveBy(100, 50, 50, Easing.SineInOut),
        Behavior.Shoot.ring(4, 2, "ball_small"),
        Behavior.Wait(30),
        Behavior.MoveBy(-100, -50, 50, Easing.SineInOut),
        Behavior.Shoot.ring(4, 2, "ball_small"),
        Behavior.Wait(30)
    )))

    -- ========================================
    -- Boss: Yinyang Master (spawns after 3s)
    -- ========================================
    local boss_variant = Boss.Define({
        name = "Yinyang Master",
        profiles = { hp = 800, score = 50000, style_name = "yinyang_orb_red", size = 2.5 },
        spell_cards = {
            Boss.NewSpellCard({
                name = "Orbit Sign: Circular Hell", hp = 150, time_limit = 25, bonus = 50000,
                onEnter = function(boss)
                    Task.New(boss, function()
                        while true do
                            for a in Core.Math.PointSet.AngleIterator(0, 18) do
                                Shots.BulletStraight(boss.x, boss.y, "ball_medium", 5, 2.5, a + boss.timer * 2)
                            end
                            Task.Wait(8)
                        end
                    end)
                end,
            }),
            Boss.NewSpellCard({
                name = "Light Sign: Radiant Burst", hp = 200, time_limit = 30, bonus = 80000,
                onEnter = function(boss)
                    Task.New(boss, function()
                        while true do
                            for a in Core.Math.PointSet.AngleIterator(0, 12) do
                                Shots.BulletStraight(boss.x, boss.y, "arrow_big", 12, 3, a + boss.timer * 3)
                            end
                            Task.Wait(15)
                        end
                    end)
                end,
            }),
            Boss.NewSpellCard({
                name = "Yin Yang: Dual Orbit", hp = 250, time_limit = 35, bonus = 100000,
                onEnter = function(boss)
                    Task.New(boss, function()
                        local t = 0
                        while true do
                            t = t + 1
                            for a in Core.Math.PointSet.AngleIterator(0, 6) do
                                Shots.BulletStraight(boss.x, boss.y, "crystal", 8, 2, a + t * 5)
                            end
                            for a in Core.Math.PointSet.AngleIterator(0, 6) do
                                Shots.BulletStraight(boss.x, boss.y, "star", 6, 1.8, -a - t * 5 + 30)
                            end
                            Task.Wait(12)
                        end
                    end)
                end,
            }),
        },
        onInit = function(boss)
            boss.sys:requestMoveTo(0, 120, 120, Easing.QuartOut)
        end,
    })

    Task.New(self, function()
        Task.Wait(180)
        Boss.Spawn(boss_variant, 0, 250)
    end)

    -- ========================================
    -- Bullet test patterns (background noise)
    -- ========================================
    for a in Core.Math.PointSet.AngleIterator(0, 36) do
        Shots.BulletStraight(0, 0, "arrow_small", 10, 2.5, a)
    end

    -- Cleanup off-screen bullets
    Task.New(self, function()
        while true do
            Task.Wait(10)
            STG.Object.BulletDo(function(b)
                if b.y < Layout.WORLD_B - 40 or b.y > Layout.WORLD_T + 40
                        or b.x < Layout.WORLD_L - 40 or b.x > Layout.WORLD_R + 40 then
                    Core.Object.Del(b)
                end
            end)
        end
    end)
end

function M:frame()
    local run = STG.Run.Get()
    if run then
        local state = run.sm:getCurrentStateName()
        if state == "playing" then
            run:update(1)
        elseif state == "paused" then
            -- Still check for unpause input
            STG.Pause.Update()
            if not STG.Pause.IsPaused() then
                run:resume()
            end
        end
    end
    Core.Task.Do(self)
    Core.Display.Window.SetTitle("STG test | Obj: " .. lstg.GetnObj())
end

function M:del()
    STG.Pause.Menu.Cleanup(self)
    Layout.Cleanup(self)
end
