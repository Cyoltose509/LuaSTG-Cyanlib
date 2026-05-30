---@class Core.World
local M = {
    l = -100,
    r = 100,
    b = -100,
    t = 100,
    boundL = -100,
    boundR = 100,
    boundB = -100,
    boundT = 100,
}
Core.World = M
M.__index = M

---@type Core.World
M.CurrentWorld = nil

function M.GetMain()
    return M.CurrentWorld or M
end

function M.New(left, right, bottom, top, outside)
    ---@type Core.World
    local self = setmetatable({}, M)
    self.l = left
    self.r = right
    self.b = bottom
    self.t = top
    outside = outside or 0
    self.boundL = left - outside
    self.boundR = right + outside
    self.boundB = bottom - outside
    self.boundT = top + outside
    return self
end

function M:set(left, right, bottom, top, outside)
    self.l = left
    self.r = right
    self.b = bottom
    self.t = top
    outside = outside or 0
    self.boundL = left - outside
    self.boundR = right + outside
    self.boundB = bottom - outside
    self.boundT = top + outside
end

function M:setBound(outside)
    self.boundL = self.l - outside
    self.boundR = self.r + outside
    self.boundB = self.b - outside
    self.boundT = self.t + outside
end

---@return number, number, number, number
function M:getBound()
    return self.boundL, self.boundR, self.boundB, self.boundT
end

function M:getParams()
    return {
        l = self.l,
        r = self.r,
        b = self.b,
        t = self.t,
        boundL = self.boundL,
        boundR = self.boundR,
        boundB = self.boundB,
        boundT = self.boundT,
        centerX = (self.l + self.r) / 2,
        centerY = (self.b + self.t) / 2,
        width = self.r - self.l,
        height = self.t - self.b,
        boundWidth = self.boundR - self.boundL,
        boundHeight = self.boundT - self.boundB,
    }
end

---应用出屏边界
---Applies the out-of-screen boundary.
function M:apply()
    lstg.SetBound(self.boundL, self.boundR, self.boundB, self.boundT)
    M.CurrentWorld = self
end

---限制坐标在世界边界
---Clamps the coordinates to the world boundary.
---@overload fun(x:number, y:number):number, number
---@overload fun(obj:lstg.GameObject|table):number, number
function M:clamp(x, y)
    if not y then
        if Core.Object.IsValid(x) then
            x = x.x
            y = x.y
        elseif x.x and x.y then
            x, y = x.x, x.y
        else
            error("invalid argument")
        end
    end
    return clamp(x, self.l, self.r), clamp(y, self.b, self.t)
end

---判断是否在世界内
---Judges whether the point (x, y) or the object is inside the world.
---@overload fun(x:number, y:number):boolean
---@overload fun(obj:lstg.GameObject|table):boolean
function M:isInside(x, y)
    if not y then
        if Core.Object.IsValid(x) then
            return Core.Object.BoxCheck(x, self.l, self.r, self.b, self.t)
        elseif x.x and x.y then
            x, y = x.x, x.y
        else
            return false
        end
    end
    return self.l <= x and x <= self.r and self.b <= y and y <= self.t
end

---判断是否在出屏边界内
---Judges whether the point (x, y) or the object is inside the out-of-screen boundary.
---@overload fun(x:number, y:number):boolean
---@overload fun(obj:lstg.GameObject|table):boolean
function M:isInBound(x, y)
    if not y then
        if Core.Object.IsValid(x) then
            return Core.Object.BoxCheck(x, self.boundL, self.boundR, self.boundB, self.boundT)
        elseif x.x and x.y then
            x, y = x.x, x.y
        else
            return false
        end
    end
    return self.boundL <= x and x <= self.boundR and self.boundB <= y and y <= self.boundT
end

---@type table<string, fun(obj:lstg.GameObject, world:Core.World, offset:table):boolean, string, number>
local ShuttleCommand = {
    ["l"] = function(obj, world, offset)
        return obj.x < world.l + offset.x, "x", world.l + offset.x
    end,
    ["r"] = function(obj, world, offset)
        return obj.x > world.r - offset.x, "x", world.r - offset.x
    end,
    ["b"] = function(obj, world, offset)
        return obj.y < world.b + offset.y, "y", world.b + offset.y
    end,
    ["t"] = function(obj, world, offset)
        return obj.y > world.t - offset.y, "y", world.t - offset.y
    end
}
---@type table<string, fun(obj:lstg.GameObject, world:Core.World, offset:table):boolean, string, string, number>
local ReboundCommand = {
    ["l"] = function(obj, world, offset)
        return obj.x < world.l + offset.x, "vx", "x", world.l + offset.x
    end,
    ["r"] = function(obj, world, offset)
        return obj.x > world.r - offset.x, "vx", "x", world.r - offset.x
    end,
    ["b"] = function(obj, world, offset)
        return obj.y < world.b + offset.y, "vy", "y", world.b + offset.y
    end,
    ["t"] = function(obj, world, offset)
        return obj.y > world.t - offset.y, "vy", "y", world.t - offset.y
    end
}
local DefaultOffset = { x = 0, y = 0 }

---处理反弹事件
---Handles the rebound event.
---@param obj lstg.GameObject
---@param boundaries string@要反弹的边界，"l"表示左边界，"r"表示右边界，"b"表示下边界，"t"表示上边界，"lrbt"表示全部方向，"all"表示全部方向
---@param offset table@{x,y}偏移值
---@param command fun(obj:lstg.GameObject)@反弹时执行指令
function M:handleRebound(obj, boundaries, offset, command)
    offset = offset or DefaultOffset
    offset.x = offset.x or 0
    offset.y = offset.y or 0
    if not boundaries or boundaries == "all" then
        boundaries = "lrbt"
    end
    for i = 1, #boundaries do
        local factor, v, pos, pos2 = ReboundCommand[boundaries:sub(i, i)](obj, self, offset)
        if factor then
            obj[v] = -obj[v]
            obj[pos] = pos2 * 2 - obj[pos]
            if command then
                command(obj)
            end
        end
    end
end

---处理穿板事件
---Handles the shuttle event.
---@param obj lstg.GameObject
---@param boundaries string @要穿板的边界，"l"表示左边界，"r"表示右边界，"b"表示下边界，"t"表示上边界，"lrbt"表示全部方向，"all"表示全部方向
---@param offset table @{x,y}偏移值
---@param command fun(obj:lstg.GameObject) @穿板时执行指令
function M:handleShuttle(obj, boundaries, offset, command)
    offset = offset or DefaultOffset
    offset.x = offset.x or 0
    offset.y = offset.y or 0
    if not boundaries or boundaries == "all" then
        boundaries = "lrbt"
    end
    for i = 1, #boundaries do
        local factor, pos, pos2 = ShuttleCommand[boundaries:sub(i, i)](obj, self, offset)
        if factor then
            obj[pos] = pos2 * 2 - obj[pos]
            obj[pos] = -obj[pos]
            if command then
                command(obj)
            end
            return
        end
    end
end




-- TODO: 如果将来需要物理反弹，这里可以加上物理反弹相关代码

