---@class STG.Object : Core.Object
---@field Group STG.Object.Group
---@field Layer STG.Object.Layer
local M = {}
STG.Object = M

require("STG.Scripts.Object.Group")
require("STG.Scripts.Object.Layer")




function M.BulletDo(fun)
    for _,obj in lstg.ObjList(M.Group.EnemyBullet) do
        fun(obj)
    end
end

function M.IndesDo(fun)
    for _,obj in lstg.ObjList(M.Group.InDes) do
        fun(obj)
    end
end

function M.BulletIndesDo(fun)
    for _,obj in lstg.ObjList(M.Group.EnemyBullet) do
        fun(obj)
    end
    for _,obj in lstg.ObjList(M.Group.InDes) do
        fun(obj)
    end
end

function M.EnemyDo(fun)
    for _,obj in lstg.ObjList(M.Group.Enemy) do
        fun(obj)
    end
end

function M.NotCollideDo(fun)
    for _,obj in lstg.ObjList(M.Group.NotCollide) do
        fun(obj)
    end
end

function M.EnemyNotCollideDo(fun)
    for _,obj in lstg.ObjList(M.Group.Enemy) do
        fun(obj)
    end
    for _,obj in lstg.ObjList(M.Group.NotCollide) do
        fun(obj)
    end
end

setmetatable(M, { __index = Core.Object })