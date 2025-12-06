---@class STG.Shots.CurveLaser.Updater
local Updater = {}
STG.Shots.CurveLaser.Updater = Updater

local Object = Core.Object

function Updater:init()
    ---@type STG.Shots.CurveLaser.Base[]
    self.list = {}
    local MainLoop = Core.MainLoop
    MainLoop.AddEvent("SceneChangeBefore", "Default", {
        name = "CurveLaser.Updater.Refresh",
        func = self.Refresh
    })
    MainLoop.AddEvent("Frame", "Gameplay", {
        name = "CurveLaser.Updater.Frame",
        func = self.Frame,
        after = "Core.Object.After"
    })
    MainLoop.AddEvent("Frame", "Gameplay", {
        name = "CurveLaser.Updater.CollisionCheck",
        func = self.CollisionCheck,
        after = "Core.Object.After"
    })
end

function Updater:addLaser(laser)
    self.list[#self.list + 1] = laser
end

function Updater.Refresh()
    Updater.list = {}
end

function Updater.Frame()
    for i = #Updater.list, 1, -1 do
        local obj = Updater.list[i]
        if Object.IsValid(obj) then
            table.remove(Updater.list, i)
        end
    end
end

---这个collision check是模拟的，与laser那边的collider不同
---因为如果不是模拟，那么要多创建一倍obj，很诡异啊。
function Updater.CollisionCheck()
    local list = Updater.list
    for _, obj in ipairs(list) do
        if Object.IsValid(obj) and obj.colli then
            local w = obj.w / 2
            for _, plist in ipairs(obj.cutSeg) do
                local n = #plist
                if n == 1 then
                    plist[1].colli = false
                end
                for i = 1, n - 1 do
                    local p1, p2 = plist[i], plist[i + 1]
                    local lx, ly = p2.x - p1.x, p2.y - p1.y
                    local len = sqrt(lx * lx + ly * ly)
                    local rot = atan2(ly, lx)
                    local cosr, sinr = cos(rot), sin(rot)
                    for other in Object.Group.GetToCollide(obj) do
                        local dx = other.x - p1.x
                        local dy = other.y - p1.y
                        dx, dy = dx * cosr + dy * sinr, dy * cosr - dx * sinr
                        if dx > len * 0.04 and dx < len * 0.96 then
                            --TODO：仅支持圆形碰撞
                            if abs(dy) < w + other.a then
                                local d1 = Object.Dist(p1, other)
                                local d2 = Object.Dist(p2, other)
                                if d1 < d2 then
                                    other.class[5](other, p1)
                                else
                                    other.class[5](other, p2)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

Updater:init()