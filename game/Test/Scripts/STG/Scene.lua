---@class Test.STG.Scene : Core.SceneManager.Scene
local M = Core.SceneManager.NewScene("Test.STG")
Test.STG.Scene = M

function M:init()
    Core.Resource.LazyLoader.DoAll()

    local sx, sy = Core.Display.Screen.GetSize()
    local wx, wy = Core.Display.Window.GetSize()
    self.stg_camera = Core.Display.Camera2D():register(0)
    self.stg_camera:setViewport(0, wx, 0, wy)
    self.stg_camera:setView(0, 0, sx, sy)
    self.stg_camera:captureLayers("STG", -10000, 10000)
    self.stg_camera:addRenderObjects("collider", 100, function()
        -- lstg.RenderGroupCollider(1,Core.Render.Color(100,255,255,255))
    end)
    self.ui_root = Test.STG.UI.Main(self)
    local world = self.stg_camera:getWorld(16):apply()
    --[[
        self.stg_camera2 = Core.Display.Camera2D():register(1)
        self.stg_camera2:setViewport(0, wx, 0, wy)
        self.stg_camera2:setView(0, 0, -sx, -sy)
        self.stg_camera2:captureLayers("STG", -10000, 10000)--]]


    for a in Core.Math.PointSet.AngleIterator(0, 19) do
        STG.Shots.BulletStraight(0, 0, STG.Shots.Bullet.Style.ArrowBig, 6, 3, a)
    end
    for a in Core.Math.PointSet.AngleIterator(0, 16) do
        STG.Shots.LaserStraight(0, 0, 2, 15, a + 30, 20, 16)
        STG.Shots.LaserRadial(0, 0, 4, 16, 60, a, 15, 35, true)
        STG.Shots.LaserCurve(0, 0, 2, 60, 16, 6, a)
    end

    Core.Task.New(self, function()
        Core.Task.Wait(50)
        Core.Object.BulletDo(function(b)
            if Core.Math.Dist(b, 0, -300) < 100 then
                Core.Object.Del(b)
            end
        end)
    end)
end

function M:frame()
    if self.camera_controller then
        self.camera_controller:frame()
    end
    Core.Display.Window.SetTitle("STG test | Objects: " .. lstg.GetnObj())
end

function M:del()
    self.ui_root:release()
    self.camera:release()
end