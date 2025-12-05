---This script is responsible for initializing the game loop.

local Core = Core
local MainLoop = Core.MainLoop
local Label = MainLoop.Frame.Label

-----------------------------------
MainLoop.AddStartEvent("Core.Load.Settings", 1, Core.Data.Setting.Load)
MainLoop.AddStartEvent("Core.Init.Data", 1, Core.Data.Score.Init)

MainLoop.AddStartEvent("Core.Set.Splash", 10, function()
    Core.Display.Window.SetSplash(true)
end)

MainLoop.AddStartEvent("Core.Init.Input", 20, Core.Input.Init)
MainLoop.AddStartEvent("Core.Init.Audio", 30, Core.AudioManager.Init)
MainLoop.AddStartEvent("Core.Init.Object", 40, Core.Object.InitAll)
MainLoop.AddStartEvent("Core.Set.Video.Mode", 50, Core.Display.Window.ChangeVideoMode)
MainLoop.AddStartEvent("Core.Reset.Screen", 60, Core.Display.Screen.Reset)

MainLoop.AddStartEvent("Core.Save.Settings", 1000, Core.Data.Setting.Save)
MainLoop.AddStartEvent("Core.Save.Data", 1000, Core.Data.Score.Save)
------------------------------------
------------------------------------
MainLoop.Frame.AddBeforeEvent("Core.Update.Debug", 10, Core.Lib.Debug.Update)
MainLoop.Frame.AddBeforeEvent("Core.Update.Display", 20, Core.Display.Update)
MainLoop.Frame.AddBeforeEvent("Core.Update.Audio", 30, Core.AudioManager.Update)
MainLoop.Frame.AddBeforeEvent("Core.Update.Input", 40, Core.Input.Update)
------------------------------------

MainLoop.Frame.AddGameEvent("Core.Object.Before", 1, function()
    lstg.AfterFrame(2)
end, Label.Gameplay)
MainLoop.Frame.AddGameEvent("Core.Update.Camera", 10, Core.Display.Camera.Frame, Label.Gameplay)
MainLoop.Frame.AddGameEvent("Core.Screen.RT.Stop", 20, Core.Render.ScreenRT.Stop, Label.Gameplay)
MainLoop.Frame.AddGameEvent("Core.Update.Scene", 50, Core.SceneManager.Update, Label.Gameplay)
MainLoop.Frame.AddGameEvent("Core.Object.After", 100, function()
    lstg.ObjFrame(2)
    local nopause = lstg.GetCurrentSuperPause() <= 0
    if nopause then
        lstg.BoundCheck(2)
        Core.Object.Group.CollisionCheck()
    end
end, Label.Gameplay)
------------------------------------
MainLoop.Frame.AddAfterEvent("Core.Update.UI", 60, Core.UI.Manager.Update)
MainLoop.Frame.AddAfterEvent("Core.Update.Debug.Layout", 70, Core.Lib.Debug.Layout)
------------------------------------
------------------------------------
MainLoop.Render.AddEvent("Core.Screen.RT.Before", 0, Core.Render.ScreenRT.BeforeRender)
MainLoop.Render.AddEvent("Core.Render.Scene", 10, Core.Display.Camera.Render)
MainLoop.Render.AddEvent("Core.Render.UI", 20, Core.UI.Manager.Draw)
MainLoop.Render.AddEvent("Core.Screen.RT.After", 1000, Core.Render.ScreenRT.AfterRender)

MainLoop.Render.AddEvent("Core.Render.Debug", 10000, Core.Lib.Debug.Draw)

------------------------------------
------------------------------------
MainLoop.AddExitEvent("Core.Exit.Save.Settings", 10, Core.Data.Setting.Save)
MainLoop.AddExitEvent("Core.Exit.Save.Data", 20, Core.Data.Score.Save)
------------------------------------
------------------------------------
MainLoop.AddOnSceneChangeBeforeEvent("Core.Clear.Resource", 0, function()
    Core.Resource.ClearResourcePool(Core.Resource.PoolType.Stage)
end)
MainLoop.AddOnSceneChangeBeforeEvent("Core.Reset.Collision.Pairs", 1, function()
    Core.Object.Group.ResetCollisionPairs(2)
end)
MainLoop.AddOnSceneChangeBeforeEvent("Core.Exit.Save.Data", 2, Core.Data.Score.Save)
MainLoop.AddOnSceneChangeBeforeEvent("Core.Reset.Pool", 3, lstg.ResetPool)
