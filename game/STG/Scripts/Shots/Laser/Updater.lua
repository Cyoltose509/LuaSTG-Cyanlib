---@class STG.Shots.Laser.Updater
local Updater = {}
STG.Shots.Laser.Updater = Updater

local Object = Core.Object
local Base = STG.Shots.Laser.Base

function Updater:init()
    ---@type STG.Shots.Laser.Base[]
    self.list = {}
    local MainLoop = Core.MainLoop
    MainLoop.AddEvent("SceneChangeBefore", "Default", {
        name = "Laser.Updater.Refresh",
        func = self.Refresh
    })
    MainLoop.AddEvent("Frame", "Gameplay", {
        name = "Laser.Updater.Frame",
        func = self.Frame,
        after = "Core.Object.After",
        labels = { MainLoop.Label.Gameplay }
    })
    MainLoop.AddEvent("Frame", "Gameplay", {
        name = "Laser.Updater.CollisionCheck",
        func = self.CollisionCheck,
        after = "Core.Object.After",
        labels = { MainLoop.Label.Gameplay }
    })
end

function Updater:addLaser(laser)
    self.list[#self.list + 1] = laser
end

function Updater.Refresh()
    Updater.list = {}
end

function Updater.Frame()
    local list = Updater.list
    local i = 0
    while i < #list do
        i = i + 1
        local obj = list[i]
        if Object.IsValid(obj) then
            local x = Object.GetAttr(obj, "x")
            if obj.x ~= x then
                obj.x = x
            end
            local y = Object.GetAttr(obj, "y")
            if obj.y ~= y then
                obj.y = y
            end
            local rot = Object.GetAttr(obj, "rot")
            if obj.rot ~= rot then
                obj.rot = rot
            end
            if obj.___attribute_dirty then
                Base.UpdateColliders(obj)
                obj.___attribute_dirty = false
            end
        else
            table.remove(list, i)
            i = i - 1
        end
    end
end

function Updater.CollisionCheck()
    local list = Updater.list
    for i = 1, #list do
        local obj = list[i]
        if Object.IsValid(obj) and obj.enable_valid_check then
            local chains = Base.GetLaserColliderParts(obj)
            Base.DispatchCheckColliderChainValid(obj, chains)
        end
    end
end

Updater:init()