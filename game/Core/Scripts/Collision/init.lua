---@class Core.Collision
---@field Collider Core.Collision.Collider
local M = {}
Core.Collision = M

M.Enable = false

---脚本层接管碰撞逻辑
---默认关闭
---脚本层接管后，object的碰撞回调函数改为onCollide，参数为info
---Take over the collision logic
---The default is closed
---After takes over, the object's collision callback function is changed to "onCollide", and the parameter is info
function M.SetEnable(enable)
    M.Enable = enable
end

local Object = Core.Object

---@alias Core.Collision._Collider Core.Collision.Collider.Base|lstg.GameObject


---@type Core.Collision._Collider[][]
M.Colliders = {}

---@type Core.Collision._Collider[]
---不参与分组规则，始终两两检测
M.FreeColliders = {}

M.CollisionPairs = {}

M.GroupsNotCollide = {}

function M.RegisterCollisionPair(group1, group2)
    assert(group1 ~= group2, "group1 and group2 should not be the same")
    for i = 1, #M.CollisionPairs do
        local v = M.CollisionPairs[i]
        if v[1] == group1 and v[2] == group2 then
            return
        end
    end
    table.insert(M.CollisionPairs, { group1, group2 })
end
function M.UnregisterCollisionPair(group1, group2)
    for i = #M.CollisionPairs, 1, -1 do
        local v = M.CollisionPairs[i]
        if v[1] == group1 and v[2] == group2 then
            table.remove(M.CollisionPairs, i)
            return
        end
    end
end

---禁用组内碰撞
---@param group number
---@param flag boolean
function M.BanWithinGroupCollision(group, flag)
    M.GroupsNotCollide[group] = flag ~= false
end

---@param collider Core.Collision._Collider
---@param group number
function M.AddCollider(collider, group)
    local list = M.FreeColliders
    if group then
        M.Colliders[group] = M.Colliders[group] or {}
        list = M.Colliders[group]
    end
    for _, c in ipairs(list) do
        if c == collider then
            if c._is_trashed_collider then
                c._is_trashed_collider = false
            end
            return
        end
    end
    collider._in_group = list
    collider.group = group or 0
    if not collider._is_custom_collider then
        rawset(collider,"_is_obj_collider",true)
       -- collider._is_obj_collider = true
        collider._collider_type = M.Collider.GetObjectType(collider)
    end
    table.insert(list, collider)
end
function M.RemoveCollider(collider)
    if collider._is_obj_collider then
        if Object.IsValid(collider) then
            if collider._in_group then
                collider.__is_trashed_collider = true
            end
        else
            if collider._in_group then
                rawset(collider,"__is_trashed_collider",true)
            end
        end
    else
        if collider._in_group then
            collider.__is_trashed_collider = true
        end
    end

    --[[
    if collider._in_group then
        for i, c in ipairs(collider._in_group) do
            if c == collider then
                table.remove(collider._in_group, i)
                return
            end
        end
    end--]]
end
function M.BeforeUpdate()
    for i = #M.FreeColliders, 1, -1 do
        local collider = M.FreeColliders[i]
        if collider._is_obj_collider then
            if Object.IsValid(collider) then
                collider._collider_type = M.Collider.GetObjectType(collider)
            else
                rawset(collider,"__is_trashed_collider",true)
            end
        end
        if collider.__is_trashed_collider then
            collider.__is_trashed_collider = false
            collider._in_group = nil
            table.remove(M.FreeColliders, i)
        end
    end
    for _, group in pairs(M.Colliders) do
        for i = #group, 1, -1 do
            local collider = group[i]
            if collider._is_obj_collider then
                if Object.IsValid(collider) then
                    collider._collider_type = M.Collider.GetObjectType(collider)
                else
                    rawset(collider,"__is_trashed_collider",true)
                end
            end
            if collider.__is_trashed_collider then
                collider.__is_trashed_collider = false
                collider._in_group = nil
                table.remove(group, i)
            end
        end
    end
end
function M.Update()
    for i = #M.FreeColliders, 1, -1 do
        local collider = M.FreeColliders[i]
        if collider.colliderUpdate then
            collider:colliderUpdate()
        end
    end
    for _, group in pairs(M.Colliders) do
        for i = #group, 1, -1 do
            local collider = group[i]
            if collider.colliderUpdate then
                collider:colliderUpdate()
            end
        end
    end
end
function M.DrawColliders()
    for _, collider in ipairs(M.FreeColliders) do
        if collider.colli and collider.drawCollider then
            collider:drawCollider()
        end
    end
    for _, group in pairs(M.Colliders) do
        for _, collider in ipairs(group) do
            if collider.colli and collider.drawCollider then
                collider:drawCollider()
            end
        end
    end
end
---@param obj1 Core.Collision._Collider
---@param obj2 Core.Collision._Collider
---@param info Core.Collision.Info
function M.ResolveCollision(obj1, obj2, info)
    -- 先触发回调
    M.OnCollide(obj1, info)
    M.OnCollide(obj2, info:reverse())
    -- 如果任意一个是触发器，只触发事件，不移动
    if obj1._is_trigger or obj2._is_trigger then
        return
    end
    local nx, ny = info.normal.x, info.normal.y
    local d = info.distance
    if obj1._is_kinematic and obj2._is_kinematic then
        -- 都是运动学对象，不移动
        return
    elseif obj1._is_kinematic then
        -- obj1 不动，obj2 挤开
        obj2.x = obj2.x + nx * d
        obj2.y = obj2.y + ny * d
    elseif obj2._is_kinematic then
        -- obj2 不动，obj1 挤开
        obj1.x = obj1.x - nx * d
        obj1.y = obj1.y - ny * d
    else
        -- 双向挤压，平均分配
        local half_d = d * 0.5
        obj1.x = obj1.x - nx * half_d
        obj1.y = obj1.y - ny * half_d
        obj2.x = obj2.x + nx * half_d
        obj2.y = obj2.y + ny * half_d
    end
end
function M.OnCollide(self, info)
    if self.onCollide then
        self:onCollide(info)
    elseif self.class.onCollide then
        self.class.onCollide(self, info)
    end
end

function M.CheckAll()
    ---自由碰撞检测
    for i = 1, #M.FreeColliders do
        local c1 = M.FreeColliders[i]
        for j = i + 1, #M.FreeColliders do
            local c2 = M.FreeColliders[j]
            if c1.colli and c2.colli then
                local info = M.Collider.CheckPair(c1, c2)
                if info then
                    M.ResolveCollision(c1, c2, info)
                end
            end
        end
    end
    ---组碰撞对检测
    local pairs_list = M.CollisionPairs
    for _, pair in ipairs(pairs_list) do
        if M.Colliders[pair[1]] and M.Colliders[pair[2]] then
            for _, c1 in ipairs(M.Colliders[pair[1]]) do
                if c1.colli then
                    for _, c2 in ipairs(M.Colliders[pair[2]]) do
                        if c2.colli then
                            local info = M.Collider.CheckPair(c1, c2)
                            if info then
                                M.ResolveCollision(c1, c2, info)
                            end
                        end
                    end
                end
            end
        end
    end
    ---组内碰撞检测
    for _, group in pairs(M.Colliders) do
        if not M.GroupsNotCollide[group] then
            local n = #group
            for i = 1, n - 1 do
                local a = group[i]
                for j = i + 1, n do
                    local b = group[j]
                    if not a._not_collide_in_group and not b._not_collide_in_group and a.colli and b.colli then
                        local info = M.Collider.CheckPair(a, b)
                        if info then
                            M.ResolveCollision(a, b, info)
                        end
                    end
                end
            end
        end
    end
end

---单个对象碰撞检测
---@param obj Core.Collision._Collider
function M.DoOneCollisionCheck(obj)
    if not obj.colli then
        return
    end
    if obj._in_group == M.FreeColliders then
        for i = 1, #M.FreeColliders do
            local c = M.FreeColliders[i]
            if c ~= obj and c.colli then
                local info = M.Collider.CheckPair(obj, c)
                if info then
                    M.ResolveCollision(obj, c, info)
                end
            end
        end
    else
        for _, pair in ipairs(M.CollisionPairs) do
            if M.Colliders[pair[1]] and obj.group == pair[2] then
                for _, c in ipairs(M.Colliders[pair[1]]) do
                    if c.colli then
                        local info = M.Collider.CheckPair(obj, c)
                        if info then
                            M.ResolveCollision(obj, c, info)
                        end
                    end
                end
            end
            if M.Colliders[pair[2]] and obj.group == pair[1] then
                for _, c in ipairs(M.Colliders[pair[2]]) do
                    if c.colli then
                        local info = M.Collider.CheckPair(obj, c)
                        if info then
                            M.ResolveCollision(obj, c, info)
                        end
                    end
                end
            end
        end
        if not M.GroupsNotCollide[obj.group] then
            for _, other in ipairs(obj._in_group) do
                if other ~= obj and other.colli then
                    local info = M.Collider.CheckPair(obj, other)
                    if info then
                        M.ResolveCollision(obj, other, info)
                    end
                end
            end
        end
    end
end

function M.ResetColliders()
    M.FreeColliders = {}
    M.Colliders = {}
end

function M.SetIsKinematic(obj, flag)
    obj._is_kinematic = flag
end
function M.SetIsTrigger(obj, flag)
    obj._is_trigger = flag
end
function M.SetNotCollideInGroup(obj, flag)
    obj._not_collide_in_group = flag
end

require("Core.Scripts.Collision.Collider")