

---@class STG
STG = {}

-- ========================================
-- Phase 0: Foundation (zero dependencies)
-- ========================================
require("STG.Constants")
require("STG.Config")
require("STG.Event")

-- Input registration (config-driven)
STG.Config.RegisterInput()

-- ========================================
-- Object & System layer
-- ========================================
require("STG.Object")
require("STG.System")

-- ========================================
-- Utilities
-- ========================================
require("STG.Animator")
require("STG.SE")

-- ========================================
-- Shots (bullets, lasers)
-- ========================================
require("STG.Shots")

-- ========================================
-- Enemy
-- ========================================
require("STG.Enemy")

-- ========================================
-- Player
-- ========================================
require("STG.Player")

-- ========================================
-- Items, Effects, Area, Background
-- ========================================
require("STG.Item")
require("STG.Background")
require("STG.Effect")
require("STG.Area")

-- ========================================
-- Game systems (Replay, Pause)
-- ========================================
require("STG.Replay")
require("STG.Pause")

-- ========================================
-- Data (Score, Achievement)
-- ========================================
require("STG.Data")

-- ========================================
-- Game flow (Run manager)
-- ========================================
require("STG.Run")

-- ========================================
-- Layout (camera, viewport, frame border)
-- ========================================
require("STG.Layout")

-- ========================================
-- Loading scene
-- ========================================
require("STG.Loading")

-- ========================================
-- HUD
-- ========================================
require("STG.HUD")

-- ========================================
-- Menus
-- ========================================
require("STG.Menu")

-- ========================================
-- Test scene
-- ========================================
require("STG.Test")

-- ========================================
-- Global init / reset
-- ========================================

function STG.Init()
    -- Defer config/data loading to after Core Data is initialized
    Core.MainLoop.AddEvent("Init", "Default", {
        name = "STG.LoadConfig",
        func = function()
            STG.Config.Load()
            STG.Data.Init()
        end,
        level = 100,
    })
    STG.Menu.Title.NewScene()
    STG.Loading.SetTarget("STG.Menu.Title")
    STG.Menu.Title.OnStart = function(difficulty, char_index)
        STG.Loading.SetTarget("STG.Test")
        Core.SceneManager.SetScene("STG.Loading")
    end

    Core.SceneManager.SetScene("STG.Loading")
    -- HUD is created lazily via Layout.Setup() per scene
end

function STG.Reset()
    STG.Player.Current = nil
    STG.Pause.ForceResume()
    STG.Run.Current = nil
end


require("STG._Assets")

STG.Init()