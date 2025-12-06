---This script is responsible for initializing the game loop.

local Core = Core
local MainLoop = Core.MainLoop
local Label = MainLoop.Label
-----------------------------------
MainLoop.AddEvent("Init", "Default", {
    name = "Core.Load.Settings",
    func = Core.Data.Setting.Load,
})
MainLoop.AddEvent("Init", "Default", {
    name = "Core.Init.Data",
    func = Core.Data.Score.Init,
})
MainLoop.AddEvent("Init", "Default", {
    name = "Core.Set.Splash",
    func = function()
        Core.Display.Window.SetSplash(true)
    end,
})
MainLoop.AddEvent("Init", "Default", {
    name = "Core.Init.Input",
    func = Core.Input.Init,
})
MainLoop.AddEvent("Init", "Default", {
    name = "Core.Init.Audio",
    func = Core.AudioManager.Init,
})
MainLoop.AddEvent("Init", "Default", {
    name = "Core.Init.Object",
    func = Core.Object.InitAll,
})
MainLoop.AddEvent("Init", "Default", {
    name = "Core.Set.VideoMode",
    func = Core.Display.Window.ChangeVideoMode,
})
MainLoop.AddEvent("Init", "Default", {
    name = "Core.Reset.Screen",
    func = Core.Display.Screen.Reset,
})
MainLoop.AddEvent("Init", "Default", {
    name = "Core.Save.Settings",
    func = Core.Data.Setting.Save,
})
MainLoop.AddEvent("Init", "Default", {
    name = "Core.Save.Data",
    func = Core.Data.Score.Save,
})
------------------------------------
------------------------------------

MainLoop.AddEvent("Frame", "Before", {
    name = "Core.Update.Debug",
    func = Core.Lib.Debug.Update,
})
MainLoop.AddEvent("Frame", "Before", {
    name = "Core.Update.Display",
    func = Core.Display.Update,
})
MainLoop.AddEvent("Frame", "Before", {
    name = "Core.Update.Audio",
    func = Core.AudioManager.Update,
})
MainLoop.AddEvent("Frame", "Before", {
    name = "Core.Update.Input",
    func = Core.Input.Update,
})
------------------------------------
MainLoop.AddEvent("Frame", "Gameplay", {
    name = "Core.Object.Before",
    func = function()
        lstg.AfterFrame(2)
    end,
    labels = { Label.Gameplay },
})
MainLoop.AddEvent("Frame", "Gameplay", {
    name = "Core.Update.Camera",
    func = Core.Display.Camera.Frame,
    labels = { Label.Gameplay },
})
MainLoop.AddEvent("Frame", "Gameplay", {
    name = "Core.Screen.RT.Stop",
    func = Core.Render.ScreenRT.Stop,
    labels = { Label.Gameplay },
})
MainLoop.AddEvent("Frame", "Gameplay", {
    name = "Core.Update.Scene",
    func = Core.SceneManager.Update,
    labels = { Label.Gameplay },
})
MainLoop.AddEvent("Frame", "Gameplay", {
    name = "Core.Object.After",
    func = function()
        lstg.ObjFrame(2)
        local nopause = lstg.GetCurrentSuperPause() <= 0
        if nopause then
            lstg.BoundCheck(2)
            Core.Object.Group.CollisionCheck()
        end
    end,
    labels = { Label.Gameplay },
})
------------------------------------
MainLoop.AddEvent("Frame", "After", {
    name = "Core.Update.UI",
    func = Core.UI.Manager.Update,
})
MainLoop.AddEvent("Frame", "After", {
    name = "Core.Update.Debug.Layout",
    func = Core.Lib.Debug.Layout,
})
------------------------------------
------------------------------------
MainLoop.AddEvent("Render", "Default", {
    name = "Core.Screen.RT.Before",
    func = Core.Render.ScreenRT.BeforeRender,
})
MainLoop.AddEvent("Render", "Default", {
    name = "Core.Render.Scene",
    func = Core.Display.Camera.Render,
})
MainLoop.AddEvent("Render", "Default", {
    name = "Core.Render.UI",
    func = Core.UI.Manager.Draw,
})
MainLoop.AddEvent("Render", "Default", {
    name = "Core.Screen.RT.After",
    func = Core.Render.ScreenRT.AfterRender,
})

MainLoop.AddEvent("Render", "Default", {
    name = "Core.Render.Debug",
    func = Core.Lib.Debug.Draw,
})

------------------------------------
------------------------------------
MainLoop.AddEvent("Exit", "Default", {
    name = "Core.Exit.Save.Settings",
    func = Core.Data.Setting.Save,
})
MainLoop.AddEvent("Exit", "Default", {
    name = "Core.Exit.Save.Data",
    func = Core.Data.Score.Save,
})
------------------------------------
------------------------------------
MainLoop.AddEvent("SceneChangeBefore", "Default", {
    name = "Core.Clear.Resource",
    func = function()
        Core.Resource.ClearResourcePool(Core.Resource.PoolType.Stage)
    end,
})
MainLoop.AddEvent("SceneChangeBefore", "Default", {
    name = "Core.Reset.Collision.Pairs",
    func = function()
        Core.Object.Group.ResetCollisionPairs(2)
    end,
})
MainLoop.AddEvent("SceneChangeBefore", "Default", {
    name = "Core.Exit.Save.Data",
    func = Core.Data.Score.Save,
})
MainLoop.AddEvent("SceneChangeBefore", "Default", {
    name = "Core.Reset.Pool",
    func = lstg.ResetPool,
})
