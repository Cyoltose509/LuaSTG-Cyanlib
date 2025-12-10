---@class STG.Shots.Laser :STG.Shots.Laser.Utils
---@field Collider STG.Shots.Laser.Collider
---@field Resource STG.Shots.Laser.Resource
---@field Updater STG.Shots.Laser.Updater
local M = {}
STG.Shots.Laser = M

local math = math
local table = table
local coroutine = coroutine
local Object = STG.Object
local Task = Core.Task
local AttributeProxy = Object.AttributeProxy
local Easing = Core.Lib.Easing

if false then
    ---@class STG.Laser.Collider.Chain
    local chain = {
        ---@type STG.Laser.Collider.Base[] @Child colliders
        colliders = {},
        count = 0, -- Number of colliders
        length = 0, -- Length of the chain
        head = { x = 0, y = 0 }, -- Head position
        tail = { x = 0, y = 0 }, -- Tail position
        full_offset_tail = 0, -- Offset begin
        full_offset_head = 0, -- Offset end
    }
end

---@class STG.Shots.Laser.Base.Anchor
local Anchor = {
    Head = 1,
    Center = 2,
    Tail = 3,
}
M.Anchor = Anchor

---@class STG.Shots.Laser.Base.CoroutineIndex
local CoroutineIndex = {
    Alpha = 1,
    Width = 2,
    Length = 3,
    Collision = 4,
    Node = 5,
    Total = 5,
}
M.CoroutineIndex = CoroutineIndex

---@class STG.Shots.Laser.Base
---@author OLC
local Base = Core.Object.Define()
M.Base = Base
function Base:frame()
    if self.___killed then
        Base.UpdateChangingTask(self)
        if self.shooting_speed ~= 0 then
            self.___shooting_offset = self.___shooting_offset - self.shooting_speed
        end
        return
    end
    if self.graze_countdown > 0 then
        self.graze_countdown = self.graze_countdown - 1
    elseif self._graze then
        self._graze = false
    end
    Task.Do(self)
    Base.UpdateChangingTask(self)
    if self.style_data then
        self.style_data:frame(self)
    end
    if self.shooting_speed ~= 0 then
        self.___shooting_offset = self.___shooting_offset - self.shooting_speed
    end
    local open_bound = self.bound
    local bound_status = Object.GetAttr(self, "bound")
    local is_in_bound = Base.CheckIsInBound(self)
    if open_bound and not is_in_bound then
        if not bound_status then
            Object.SetAttr(self, "bound", true)
            for i = 1, #self.___colliders do
                local c = self.___colliders[i]
                if Object.IsValid(c) then
                    Object.SetAttr(c, "bound", true)
                end
            end
        end
    elseif bound_status then
        Object.SetAttr(self, "bound", false)
        for i = 1, #self.___colliders do
            local c = self.___colliders[i]
            if Object.IsValid(c) then
                Object.SetAttr(c, "bound", false)
            end
        end
    end
end
function Base:render()
    if not self.onRender then
        return
    end
    local parts = Base.GetLaserColliderParts(self)
    self.onRender(self, parts)
end
function Base:del()
    if not self.___killed then
        Object.Preserve(self)
        self.___killed = true
        self.colli = false
        Task.Clear(self)
        local alpha = self.alpha
        local d = self.w
        local tasks = self.___changing_task
        tasks[CoroutineIndex.Alpha] = coroutine.create(function()
            for i = 30, 1, -1 do
                self.alpha = alpha * i / 30
                coroutine.yield()
            end
            self.alpha = 0
            Object.Del(self)
        end)
        tasks[CoroutineIndex.Width] = coroutine.create(function()
            for i = 30, 1, -1 do
                self.w = d * i / 30
                coroutine.yield()
            end
            self.w = 0
        end)
    else
        for i = 1, #self.___colliders do
            local c = self.___colliders[i]
            self.___colliders[i] = nil
            if Object.IsValid(c) then
                Object.Del(c)
            end
        end
        for i = 1, #self.___recovery_colliders do
            local c = self.___recovery_colliders[i]
            self.___recovery_colliders[i] = nil
            if Object.IsValid(c) then
                Object.Del(c)
            end
        end
    end
end
function Base:kill()
    if not self.___killed then
        Object.Preserve(self)
        self.___killed = true
        self.colli = false
        Task.Clear(self)
        local alpha = self.alpha
        local d = self.w
        local tasks = self.___changing_task
        tasks[CoroutineIndex.Alpha] = coroutine.create(function()
            for i = 30, 1, -1 do
                self.alpha = alpha * i / 30
                coroutine.yield()
            end
            self.alpha = 0
            Object.Del(self)
        end)
        tasks[CoroutineIndex.Width] = coroutine.create(function()
            for i = 30, 1, -1 do
                self.w = d * i / 30
                coroutine.yield()
            end
            self.w = 0
        end)
        tasks[CoroutineIndex.Collision] = nil
    else
        for i = 1, #self.___colliders do
            local c = self.___colliders[i]
            self.___colliders[i] = nil
            if Object.IsValid(c) then
                Object.Del(c)
            end
        end
        for i = 1, #self.___recovery_colliders do
            local c = self.___recovery_colliders[i]
            self.___recovery_colliders[i] = nil
            if Object.IsValid(c) then
                Object.Del(c)
            end
        end
    end
end
--region Attribute Proxies
local attribute_proxies = {}
Base.___attribute_proxies = attribute_proxies

--region x
local proxy_x = AttributeProxy.Create("x")
attribute_proxies["x"] = proxy_x
function proxy_x:init(key, value, storage)
    storage[key] = value or 0
end

function proxy_x:setter(key, value, storage)
    local old_value = storage[key]
    if value == old_value then
        return
    end
    storage[key] = value
    Object.SetAttr(self, key, value)
    self.___attribute_dirty = true
end

--endregion

--region y
local proxy_y = AttributeProxy.Create("y")
attribute_proxies["y"] = proxy_y
function proxy_y:init(key, value, storage)
    storage[key] = value or 0
end

function proxy_y:setter(key, value, storage)
    local old_value = storage[key]
    if value == old_value then
        return
    end
    storage[key] = value
    Object.SetAttr(self, key, value)
    self.___attribute_dirty = true
end

--endregion

--region rot
local proxy_rot = AttributeProxy.Create("rot")
attribute_proxies["rot"] = proxy_rot
function proxy_rot:init(key, value, storage)
    storage[key] = value or 0
end

function proxy_rot:setter(key, value, storage)
    local old_value = storage[key]
    if value == old_value then
        return
    end
    storage[key] = value
    Object.SetAttr(self, key, value)
    self.___attribute_dirty = true
end

--endregion

--region l1
local proxy_l1 = AttributeProxy.Create("l1")
attribute_proxies["l1"] = proxy_l1
function proxy_l1:init(key, value, storage)
    storage[key] = value or 0
end

function proxy_l1:setter(key, value, storage)
    value = max(value, 0)
    local old_value = storage[key]
    if value == old_value then
        return
    end
    storage[key] = value
    self.___attribute_dirty = true
end

--endregion

--region l2
local proxy_l2 = AttributeProxy.Create("l2")
attribute_proxies["l2"] = proxy_l2
function proxy_l2:init(key, value, storage)
    storage[key] = value or 0
end

function proxy_l2:setter(key, value, storage)
    value = max(value, 0)
    local old_value = storage[key]
    if value == old_value then
        return
    end
    storage[key] = value
    self.___attribute_dirty = true
end

--endregion

--region l3
local proxy_l3 = AttributeProxy.Create("l3")
attribute_proxies["l3"] = proxy_l3
function proxy_l3:init(key, value, storage)
    storage[key] = value or 0
end

function proxy_l3:setter(key, value, storage)
    value = max(value, 0)
    local old_value = storage[key]
    if value == old_value then
        return
    end
    storage[key] = value
    self.___attribute_dirty = true
end

--endregion

--region length
local proxy_length = AttributeProxy.Create("length")
attribute_proxies["length"] = proxy_length
function proxy_length:getter(key, storage)
    return storage["l1"] + storage["l2"] + storage["l3"]
end

function proxy_length:setter(key, value, storage)
    value = max(value, 0)
    if value == 0 then
        storage["l1"] = 0
        storage["l2"] = 0
        storage["l3"] = 0
        self.___attribute_dirty = true
        return
    end
    local l1 = storage["l1"]
    local l2 = storage["l2"]
    local l3 = storage["l3"]
    local sum = l1 + l2 + l3
    if sum ~= 0 then
        l1 = l1 / sum * value
        l2 = l2 / sum * value
        l3 = l3 / sum * value
    else
        l1 = value / 3
        l2 = value / 3
        l3 = value / 3
    end
    storage["l1"] = l1
    storage["l2"] = l2
    storage["l3"] = l3
    self.___attribute_dirty = true
end

--endregion

--region w
local proxy_w = AttributeProxy.Create("w")
attribute_proxies["w"] = proxy_w
function proxy_w:init(key, value, storage)
    storage[key] = value or 0
end

function proxy_w:setter(key, value, storage)
    local old_value = storage[key]
    if value == old_value then
        return
    end
    value = max(value, 0)
    storage[key] = value
    self.___attribute_dirty = true
end

--endregion

--region offset_at_head
local proxy_offset_at_head = AttributeProxy.Create("offset_at_head")
attribute_proxies["offset_at_head"] = proxy_offset_at_head
function proxy_offset_at_head:init(key, value, storage)
    storage[key] = value == nil or value
end

function proxy_offset_at_head:setter(key, value, storage)
    local old_value = storage[key]
    if value == old_value then
        return
    end
    storage[key] = value
    self.___attribute_dirty = true
end

--endregion

--region ___shooting_offset
local proxy_shooting_offset = AttributeProxy.Create("___shooting_offset")
attribute_proxies["___shooting_offset"] = proxy_shooting_offset
function proxy_shooting_offset:init(key, value, storage)
    storage[key] = value or 0
end

function proxy_shooting_offset:setter(key, value, storage)
    local old_value = storage[key]
    if value == old_value then
        return
    end
    storage[key] = value
    self.___attribute_dirty = true
end

--endregion

--region colli
local proxy_colli = AttributeProxy.Create("colli")
attribute_proxies["colli"] = proxy_colli

function proxy_colli:init(key, value, storage)
    storage[key] = value
    Object.SetAttr(self, key, false)
end

function proxy_colli:setter(key, value, storage)
    local old_value = storage[key]
    if value == old_value then
        return
    end
    storage[key] = value
    self.___attribute_dirty = true
end

--endregion

--region group
local proxy_group = AttributeProxy.Create("group")
attribute_proxies["group"] = proxy_group
function proxy_group:init(key, value, storage)
    storage[key] = value or Object.Group.EnemyBullet
    Object.SetAttr(self, key, Object.Group.InDes)
end

function proxy_group:setter(key, value, storage)
    local old_value = storage[key]
    if value == old_value then
        return
    end
    storage[key] = value
    for i = 1, #self.___colliders do
        local c = self.___colliders[i]
        if Object.IsValid(c) then
            Object.SetAttr(c, key, value)
        end
    end
end

--endregion

--region bound
local proxy_bound = AttributeProxy.Create("bound")
attribute_proxies["bound"] = proxy_bound
function proxy_bound:init(key, value, storage)
    storage[key] = value == nil or value
    Object.SetAttr(self, key, false)
end

--endregion

--region anchor
local proxy_anchor = AttributeProxy.Create("anchor")
attribute_proxies["anchor"] = proxy_anchor
function proxy_anchor:init(key, value, storage)
    storage[key] = value or Anchor.Tail
end

function proxy_anchor:setter(key, value, storage)
    local old_value = storage[key]
    if value == old_value then
        return
    end
    storage[key] = value
    self.___attribute_dirty = true
end

--endregion

--region _graze
local proxy_graze = AttributeProxy.Create("_graze")
attribute_proxies["_graze"] = proxy_graze

function proxy_graze:setter(key, value, storage)
    storage[key] = value
    if value then
        self.graze_countdown = 3
    end
end

--endregion
--endregion

---@param x number @Anchor position x
---@param y number @Anchor position y
---@param rot number @Rotation
---@param l1 number @Length of the first part
---@param l2 number @Length of the second part
---@param l3 number @Length of the third part
---@param w number @Width
---@param node number @Node size
---@param head number @Head size
---@param index number @Style index
---@param single_collider boolean @Single collider (Disable collider chain)
---@return STG.Shots.Laser.Base
function M.Create(x, y, rot, l1, l2, l3, w, node, head, index, single_collider)
    ---@type STG.Shots.Laser.Base
    ---@diagnostic disable-next-line: assign-type-mismatch
    local self = Object.New(Base)
    self.group = Object.Group.EnemyBullet            ---Child colliders group
    self.layer = Object.Layer.EnemyBullet            --- Render layer
    self.x = x or 0                            --- Anchor position x
    self.y = y or 0                            --- Anchor position y
    self.rot = rot or 0                        --- Rotation
    self.colli = false                         --- Current collision status (for child colliders)
    self.l1 = l1 or 0                          --- Length of the first part
    self.l2 = l2 or 0                          --- Length of the second part
    self.l3 = l3 or 0                          --- Length of the third part
    self.w = w or 0                            --- Width
    self.node = node or 0                      --- Node size
    self.head = head or 0                      --- Head size
    self.anchor = Anchor.Tail              --- Anchor position
    self.graze_countdown = 0                   --- Graze countdown
    self.shooting_speed = 0                    --- Shooting speed ( -offset per frame )
    self.killed_at_spawn = false               --- Child colliders are killed at spawn
    self.offset_at_head = true                 --- Offset at head
    self.alpha = 0                             --- Render Alpha
    self.enable_valid_check = false            --- Enable valid check
    self.collider_interval = 32
    self.single_collider = single_collider     --- Single collider (Disable collider chain)
    self._blend = "mul+add"                    --- Blend mode
    self._a = 255                              --- Color alpha
    self._r = 255                              --- Color red
    self._g = 255                              --- Color green
    self._b = 255                              --- Color blue
    self.___killed = false                     ---Killed flag
    self.___shooting_offset = 0                --- Shooting offset
    self.___colliders = {}                     --- Child colliders
    self.___offset_colliders = {}              --- Child colliders by offset
    self.___recovery_colliders = {}            --- Recovery child colliders
    self.___changing_task = {}                 --- Changing task
    self.___attribute_dirty = false            --- Attribute dirty
    self.onRender = Base.RenderDefaultLaserStyle                         --- On render callback
    self.onDelCollider = Base.DefaultOnDelCollider                       --- On delete collider callback
    self.onKillCollider = Base.DefaultOnKillCollider                     --- On kill collider callback
    self.onCheckColliderChainValid = Base.DefaultCheckColliderChainValid --- On check collider chain valid callback
    M.SetImage(self, 1, index or 1)
    AttributeProxy.Apply(self, Base.___attribute_proxies)
    Base.UpdateColliders(self)
    M.Updater:addLaser(self)
    return self
end

--region Main Methods
---Preserve a collider if it is child of this laser
---@param collider STG.Laser.Collider.Base
---@return boolean @True if can be processed
function Base:CheckPreserveCollider(collider)
    if not ((self.___colliders[collider] or self.___recovery_colliders[collider]) and Object.IsValid(collider)) then
        return false
    end
    if not self.___killed then
        Object.Preserve(collider)
    end
    if collider.___killed then
        return false
    end
    collider.___killed = true
    return true
end

---Called when a collider is deleted
---@param collider STG.Laser.Collider.Base
---@param args table<string, any>
function Base:DispatchColliderOnDelete(collider, args)
    if not Base.CheckPreserveCollider(self, collider) then
        return
    end
    if self.onDelCollider then
        self.onDelCollider(self, collider, args)
    end
end

---Default value of user defined callback when a collider is deleted
---@param collider STG.Laser.Collider.Base
---@param args table<string, any>
function Base:DefaultOnDelCollider(collider, args)
    local w = Core.World.GetMain()
    if self.index and w:isInBound(collider) then
        STG.Shots.BreakEff(collider.x, collider.y, self.index)
    end
end

---Called when a collider is killed
---@param collider STG.Laser.Collider.Base
---@param args table<string, any>
function Base:DispatchColliderOnKill(collider, args)
    if not Base.CheckPreserveCollider(self, collider) then
        return
    end
    if self.onKillCollider then
        self.onKillCollider(self, collider, args)
    end
end

---Default value of user defined callback when a collider is killed
---@param collider STG.Laser.Collider.Base
---@param args table<string, any>
function Base:DefaultOnKillCollider(collider, args)
    local w = Core.World.GetMain()
    if w:isInBound(collider) then
        --TODO
        if self.index then
            STG.Shots.BreakEff(collider.x, collider.y, self.index)
        end
    end
end

---Check collider chain valid
---@param chains STG.Laser.Collider.Chain[]
function Base:DispatchCheckColliderChainValid(chains)
    if self.enable_valid_check and self.onCheckColliderChainValid then
        for i = 1, #chains do
            if not self.onCheckColliderChainValid(self, chains[i]) then
                for j = 1, chains[i].count do
                    chains[i].colliders[j].___killed = true
                end
            end
        end
    end
end

---Default value of user defined callback when checking collider chain valid
---@param chain STG.Laser.Collider.Chain
function Base:DefaultCheckColliderChainValid(chain)
    return self.shooting_speed ~= 0 or chain.length >= 16
end

---Check if the laser is out of bound
---@return boolean
function Base:CheckIsInBound()
    local w = Core.World.GetMain()
    local is_in_bound = w:isInBound(self)
    if not is_in_bound then
        return false
    end
    for i = 1, #self.___colliders do
        local c = self.___colliders[i]
        if Object.IsValid(c) and not w:isInBound(c) then
            is_in_bound = true
            break
        end
    end
    return is_in_bound
end

---Update laser colliders immediately
function Base:UpdateColliders()
    local colliders = self.___colliders
    local length = self.length
    if length <= 0 then
        for i = 1, #colliders do
            Base.RecoveryCollider(self, colliders[i])
        end
        return
    end
    --
    if self.single_collider then
        local collider = colliders[1]
        for i = 2, #colliders do
            Base.RecoveryCollider(self, colliders[i], true)
        end
        if not collider then
            collider = Base.GenerateCollider(self, 0, self.killed_at_spawn)
            colliders[1] = collider
        end
        if not (Object.IsValid(collider) and Base.UpdateColliderSingle(self, collider, length)) then
            Base.RecoveryCollider(self, collider)
            colliders[1] = nil
        end
        return
    end
    --
    local tail_x, tail_y = Base.GetAnchorPosition(self, Anchor.Tail)
    local total_offset = self.___shooting_offset
    if self.offset_at_head then
        total_offset = total_offset - length
    end
    local interval = self.collider_interval
    local rot = self.rot
    local rot_cos = cos(rot)
    local rot_sin = sin(rot)
    local half_width = self.w / 2
    local colli = self.colli
    local fix_tail_offset = int(total_offset / interval) * interval
    local fix_head_offset = math.ceil((total_offset + length) / interval) * interval
    local have_changed = false
    for part_offset = fix_tail_offset, fix_head_offset, interval do
        local collider = self.___offset_colliders[part_offset]
        if not collider then
            collider = Base.GenerateCollider(self, part_offset, self.killed_at_spawn)
            colliders[#colliders + 1] = collider
            have_changed = true
        end
    end
    if have_changed then
        table.sort(colliders, function(a, b)
            return a.args.offset > b.args.offset
        end)
    end
    for i = #colliders, 1, -1 do
        local collider = colliders[i]
        if not (Object.IsValid(collider) and Base.UpdateCollider(self, collider,
                tail_x, tail_y, length, total_offset, half_width, colli, rot, rot_cos, rot_sin)) then
            Base.RecoveryCollider(self, collider)
            table.remove(colliders, i)
        end
    end
end

---Recovery a collider
---@param collider STG.Laser.Collider.Base
---@param forbid_pool boolean
function Base:RecoveryCollider(collider, forbid_pool)
    if not (self.___colliders[collider] and Object.IsValid(collider)) then
        return
    end
    collider.group = Object.Group.Ghost
    collider.___killed = true
    self.___colliders[collider] = nil
    self.___offset_colliders[collider.args.offset] = nil
    if forbid_pool then
        Object.Del(collider)
        return
    end
    self.___recovery_colliders[#self.___recovery_colliders + 1] = collider
    self.___recovery_colliders[collider] = true
end

---Generate a collider
---@param offset number @Offset
---@param killed boolean @Killed flag
---@return STG.Laser.Collider.Base
function Base:GenerateCollider(offset, killed)
    local collider = table.remove(self.___recovery_colliders)
    if Object.IsValid(collider) then
        collider.group = self.group
        collider.master = self
        collider.args = { offset = offset }
        collider.on_del = Base.DispatchColliderOnDelete
        collider.on_kill = Base.DispatchColliderOnKill
        self.___recovery_colliders[collider] = nil
    else
        collider = M.Collider.Create(self, self.group, { offset = offset },
                Base.DispatchColliderOnDelete, Base.DispatchColliderOnKill)
    end
    collider.___killed = killed == nil or killed
    self.___colliders[collider] = true
    self.___offset_colliders[offset] = collider
    return collider
end

---Update a collider
---@param collider STG.Laser.Collider.Base
---@param tail_x number @Tail position x
---@param tail_y number @Tail position y
---@param total_length number @Total length
---@param total_offset number @Total offset
---@param half_width number @Half width
---@param colli boolean @Collision flag
---@param rot number @Rotation
---@param rot_cos number @Rotation cos (pre-calculated)
---@param rot_sin number @Rotation sin (pre-calculated)
---@return boolean
function Base:UpdateCollider(collider, tail_x, tail_y, total_length, total_offset,
                             half_width, colli, rot, rot_cos, rot_sin)
    local collider_offset = collider.args.offset
    local offset = collider_offset - total_offset
    local interval = self.collider_interval
    local offset_begin = offset - interval / 2
    local offset_end = offset + interval / 2
    if offset_begin > total_length or offset_end < 0 then
        return false
    end
    offset_begin = max(0, offset_begin)
    offset_end = min(total_length, offset_end)
    offset = (offset_begin + offset_end) / 2
    local length = offset_end - offset_begin
    collider.x = tail_x + offset * rot_cos
    collider.y = tail_y + offset * rot_sin
    collider.rot = rot
    collider.a = length / 2
    collider.b = half_width
    collider.colli = colli and length > 0 and not self.___killed
    return true
end

---Update a collider
---@param collider STG.Laser.Collider.Base
---@return boolean
function Base:UpdateColliderSingle(collider, length)
    if length <= 0 then
        return false
    end
    local center_x, center_y = Base.GetAnchorPosition(self, Anchor.Center)
    local offset = 0
    if self.offset_at_head then
        offset = self.___shooting_offset - length / 2
    else
        offset = self.___shooting_offset + length / 2
    end
    collider.args.offset = offset
    collider.x = center_x
    collider.y = center_y
    collider.rot = self.rot
    collider.a = length / 2
    collider.b = self.w / 2
    collider.colli = self.colli and length > 0 and not self.___killed
    return true
end

---Get all laser collider parts
---@return table<number, STG.Laser.Collider.Chain>
function Base:GetLaserColliderParts()
    local colliders = self.___colliders
    local interval = self.collider_interval
    local parts = {}
    local part = {}

    for i = 1, #colliders do
        local c = colliders[i]
        if not c.___killed then
            part[#part + 1] = c
        elseif #part > 0 then
            parts[#parts + 1] = part
            part = {}
        end
    end
    if #part > 0 then
        parts[#parts + 1] = part
    end
    if #parts == 0 then
        return {}
    end
    local chains = {}
    for i = 1, #parts do
        part = parts[i]
        ---@type STG.Laser.Collider.Chain
        local chain = {}
        chain.colliders = part
        chain.count = #part
        local head_node = part[1]
        local tail_node = part[#part]
        if head_node == tail_node then
            chain.length = head_node.a * 2
        else
            chain.length = (head_node.a + tail_node.a) * 2 + max(0, #part - 2) * interval
        end
        chain.head = {
            x = head_node.x + head_node.a * cos(self.rot),
            y = head_node.y + head_node.a * sin(self.rot),
        }
        chain.tail = {
            x = tail_node.x - tail_node.a * cos(self.rot),
            y = tail_node.y - tail_node.a * sin(self.rot),
        }
        if not self.single_collider then
            chain.full_offset_tail = tail_node.args.offset + interval / 2 - tail_node.a * 2
            chain.full_offset_head = chain.full_offset_tail + chain.length
        else
            local length = self.length
            chain.full_offset_tail = self.___shooting_offset - length / 2
            chain.full_offset_head = self.___shooting_offset + length / 2
        end
        chains[#chains + 1] = chain
    end
    return chains
end

---Render a laser collider part (default style)
---@param chains STG.Laser.Collider.Chain[]
function Base:RenderDefaultLaserStyle(chains)
    local data = self.style_data
    if self.node > 0 then
        local x, y = Base.GetAnchorPosition(self, Anchor.Tail)
        local tail = Core.Resource.Image.Get(data.node_img)
        tail:setState(self._blend, Core.Render.Color(self._a * self.alpha, self._r, self._g, self._b))
            :setPos(x, y)
            :setScale(self.node / 16)
            :setRotation(18 * self.timer)
            :draw()
            :setRotation(-18 * self.timer)
            :draw()
    end
    if not chains or #chains == 0 then
        return
    end

    local width = self.w
    local rot = self.rot
    local rot_cos = cos(rot)
    local rot_sin = sin(rot)
    local blend = self._blend
    local color = Core.Render.Color(self._a * self.alpha, self._r, self._g, self._b)
    local color_head = Core.Render.Color(self._a, self._r, self._g, self._b)
    local w = width / data.realW
    local total_length = self.length
    local l1_r = self.l1 / total_length
    local l2_r = self.l2 / total_length
    local l3_r = self.l3 / total_length
    for i = 1, #chains do
        local chain = chains[i]
        if chain.length > 0 then
            local length = chain.length
            local x = chain.tail.x
            local y = chain.tail.y
            if width > 0 then
                local l1 = l1_r * length
                local l2 = l2_r * length
                local l3 = l3_r * length
                Core.Resource.Image.Get(data.img1)
                    :setState(blend, color)
                    :setPos(x, y)
                    :setScale(l1 / data.l1, w)
                    :setRotation(rot)
                    :draw()
                x = x + l1 * rot_cos
                y = y + l1 * rot_sin
                Core.Resource.Image.Get(data.img2)
                    :setState(blend, color)
                    :setPos(x, y)
                    :setScale(l2 / data.l2, w)
                    :setRotation(rot)
                    :draw()
                x = x + l2 * rot_cos
                y = y + l2 * rot_sin
                Core.Resource.Image.Get(data.img3)
                    :setState(blend, color)
                    :setPos(x, y)
                    :setScale(l3 / data.l3, w)
                    :setRotation(rot)
                    :draw()
                x = x + l3 * rot_cos
                y = y + l3 * rot_sin
            else
                x = x + length * rot_cos
                y = y + length * rot_sin
            end
            if self.head > 0 then
                local head = Core.Resource.Image.Get(data.head_img)
                head:setState(blend, color_head)
                    :setPos(x, y)
                    :setRotation(0)
                    :setScale(self.head / 16)
                    :draw()
                    :setScale(0.75 * self.head / 16)
                    :draw()
            end
        end
    end
end

---Update changing task
function Base:UpdateChangingTask()
    local tasks = self.___changing_task
    if not tasks then
        return
    end
    for i = 1, CoroutineIndex.Total do
        local co = tasks[i]
        if co then
            local success, result = coroutine.resume(co)
            if not success then
                error(result)
            end
            if coroutine.status(co) == "dead" then
                tasks[i] = nil
            end
        end
    end
end

---Get anchor position
---@param anchor STG.Shots.Laser.Base.Anchor
---@return number, number
function Base:GetAnchorPosition(anchor)
    local self_anchor = self.anchor
    if self_anchor == anchor then
        return self.x, self.y
    end
    local x = self.x
    local y = self.y
    local length = self.length
    local rot = self.rot
    local rot_cos = length / 2 * cos(rot)
    local rot_sin = length / 2 * sin(rot)
    if self_anchor == Anchor.Tail then
        if anchor == Anchor.Head then
            x = x + 2 * rot_cos
            y = y + 2 * rot_sin
        elseif anchor == Anchor.Center then
            x = x + rot_cos
            y = y + rot_sin
        end
    elseif self_anchor == Anchor.Center then
        if anchor == Anchor.Head then
            x = x + rot_cos
            y = y + rot_sin
        elseif anchor == Anchor.Tail then
            x = x - rot_cos
            y = y - rot_sin
        end
    elseif self_anchor == Anchor.Head then
        if anchor == Anchor.Center then
            x = x - rot_cos
            y = y - rot_sin
        elseif anchor == Anchor.Tail then
            x = x - 2 * rot_cos
            y = y - 2 * rot_sin
        end
    end
    return x, y
end

--endregion

---Apply default laser style
---@param self STG.Shots.Laser.Base
---@param id number|string
---@param index number
function M.SetImage(self, id, index)
    index = clamp(index or self.index, 1, 16)
    self.style_id = id
    self.index = index
    local data = M.Resource.GetData(id, self)
    self.style_data = data
end

---Apply laser changing task about width
---@param self STG.Shots.Laser.Base
---@param width number @Width
---@param time number @Time (0 for immediate)
---@param easing_func function @Easing function
---@overload fun(self:STG.Shots.Laser.Base, width: number) @Immediate change width
---@overload fun(self:STG.Shots.Laser.Base, width: number, time: number) @Change width with time
function M.ToWidth(self, width, time, easing_func)
    if not time or time <= 0 then
        self.w = width
        self.___changing_task[CoroutineIndex.Width] = nil
        return
    end
    easing_func = easing_func or Easing.Linear
    local begin = self.w
    local dp = width - begin
    local tasks = self.___changing_task
    tasks[CoroutineIndex.Width] = coroutine.create(function()
        for i = 1, time do
            self.w = begin + dp * easing_func(i / time)
            coroutine.yield()
        end
    end)
end

---Apply laser changing task about alpha
---@param self STG.Shots.Laser.Base
---@param alpha number @Alpha
---@param time number @Time (0 for immediate)
---@param easing_func function @Easing function
---@overload fun(self:STG.Shots.Laser.Base, alpha: number) @Immediate change alpha
---@overload fun(self:STG.Shots.Laser.Base, alpha: number, time: number) @Change alpha with time
function M.ToAlpha(self, alpha, time, easing_func)
    if not time or time <= 0 then
        self.alpha = alpha
        self.___changing_task[CoroutineIndex.Alpha] = nil
        return
    end
    easing_func = easing_func or Easing.Linear
    local begin = self.alpha
    local dp = alpha - begin
    local tasks = self.___changing_task
    tasks[CoroutineIndex.Alpha] = coroutine.create(function()
        for i = 1, time do
            self.alpha = begin + dp * easing_func(i / time)
            coroutine.yield()
        end
    end)
end

---Apply laser changing task about length
---@param self STG.Shots.Laser.Base
---@param l1 number @Length of the first part
---@param l2 number @Length of the second part
---@param l3 number @Length of the third part
---@param time number @Time (0 for immediate)
---@param easing_func function @Easing function
---@overload fun(self:STG.Shots.Laser.Base, l1: number, l2: number, l3: number) @Immediate change length
---@overload fun(self:STG.Shots.Laser.Base, l1: number, l2: number, l3: number, time: number) @Change length with time
function M.ToLength(self, l1, l2, l3, time, easing_func)
    if not time or time <= 0 then
        self.l1 = l1
        self.l2 = l2
        self.l3 = l3
        self.___changing_task[CoroutineIndex.Length] = nil
        return
    end
    easing_func = easing_func or Easing.Linear
    local begin_l1 = self.l1
    local begin_l2 = self.l2
    local begin_l3 = self.l3
    local dp1 = l1 - begin_l1
    local dp2 = l2 - begin_l2
    local dp3 = l3 - begin_l3
    local tasks = self.___changing_task
    tasks[CoroutineIndex.Length] = coroutine.create(function()
        for i = 1, time do
            self.l1 = begin_l1 + dp1 * easing_func(i / time)
            self.l2 = begin_l2 + dp2 * easing_func(i / time)
            self.l3 = begin_l3 + dp3 * easing_func(i / time)
            coroutine.yield()
        end
    end)
end

---Turn on the laser
---@param self STG.Shots.Laser.Base
---@param width number @Width
---@param time number @Time
---@param open_collider boolean @Open colliders
---@overload fun(self:STG.Shots.Laser.Base, width: number, time: number) @Turn on the laser
function M.TurnOn(self, width, time, open_collider)
    M.ToAlpha(self, 1, time)
    M.ToWidth(self, width, time)
    if open_collider then
        local tasks = self.___changing_task
        tasks[CoroutineIndex.Collision] = coroutine.create(function()
            Task.Wait(time)
            self.colli = true
        end)
    end
end

---Turn on the laser with half alpha
---@param self STG.Shots.Laser.Base
---@param width number @Width
---@param time number @Time
function M.TurnHalfOn(self, width, time)
    M.ToAlpha(self, 0.5, time)
    M.ToWidth(self, width, time)
end

---Turn off the laser
---@param self STG.Shots.Laser.Base
---@param time number @Time
---@param close_colliders boolean @Close colliders
---@overload fun(self:STG.Shots.Laser.Base, time: number) @Turn off the laser
function M.TurnOff(self, time, close_colliders)
    if close_colliders then
        self.___changing_task[CoroutineIndex.Collision] = nil
        self.colli = false
    end
    M.ToAlpha(self, 0, time)
    M.ToWidth(self, 0, time)
end

---Turn off the laser with half alpha
---@param self STG.Shots.Laser.Base
---@param width number @Width
---@param time number @Time
---@param close_colliders boolean @Close colliders
---@overload fun(self:STG.Shots.Laser.Base, width: number, time: number) @Turn off the laser with half alpha
function M.TurnHalfOff(self, width, time, close_colliders)
    if close_colliders then
        self.___changing_task[CoroutineIndex.Collision] = nil
        self.colli = false
    end
    M.ToAlpha(self, 0.5, time)
    M.ToWidth(self, width, time)
end

---Set position and rotation
---@param self STG.Shots.Laser.Base
---@param x number @Position x
---@param y number @Position y
---@param rot number @Rotation
function M.SetPositionAndRotation(self, x, y, rot)
    AttributeProxy.setStorageValue(self, "x", x)
    AttributeProxy.setStorageValue(self, "y", y)
    AttributeProxy.setStorageValue(self, "rot", rot)
    self.___attribute_dirty = true
end

---Set length and width
---@param self STG.Shots.Laser.Base
---@param l1 number @Length of the first part
---@param l2 number @Length of the second part
---@param l3 number @Length of the third part
---@param width number @Width
---@overload fun(self:STG.Shots.Laser.Base, l1: number, l2: number, l3: number) @Set length
function M.SetRectByPart(self, l1, l2, l3, width)
    AttributeProxy.setStorageValue(self, "l1", l1)
    AttributeProxy.setStorageValue(self, "l2", l2)
    AttributeProxy.setStorageValue(self, "l3", l3)
    if width then
        AttributeProxy.setStorageValue(self, "w", width)
    end
    self.___attribute_dirty = true
end

local _field = { "l1", "l2", "l3" }
---生长laser并赋予速度
---Grow the laser and assign its speed
---@param self STG.Shots.Laser.Base
---@param width number 初始宽度
---@param v number 初始速度
---@param time number 生长时间
---@param param number 生长参数
---@param rot number 初始角度
function M.Grow(self, width, v, time, param, rot)
    M.TurnOn(self, width, 0, true)
    self._is_growing = true
    self.___changing_task[CoroutineIndex.Length] = coroutine.create(function()
        local list = { (param - 1) * time / (2 * param) + 1e-12, time / param, (param - 1) * time / (2 * param) }
        local df = { 0, 0, 0 }
        local last = 0
        for j = 3, 1, -1 do
            local part = _field[j]
            self[part] = self[part] - v * last
            for _ = 1, int(list[j] + last) do
                self[part] = self[part] + v
                coroutine.yield()
            end
            local m = list[j] + last - int(list[j] + last)
            df[j] = m
            self[part] = self[part] + v * m
            last = m
        end
        local dx, dy = v * cos(rot) * (1 - last), v * sin(rot) * (1 - last)
        self.x, self.y = self.x + dx, self.y + dy
        coroutine.yield()
        Object.SetV(self, v, rot, true)
        self._is_growing = false
        self.enable_valid_check = true
    end)
    self.___changing_task[CoroutineIndex.Node] = coroutine.create(function()
        Task.Wait(time - 10)
        local node = self.node
        for n = 9, 0, -1 do
            self.node = node * (n / 10)
            coroutine.yield()
        end
        self.node = 0
    end)
end

require("STG.Scripts.Shots.Laser.Collider")
require("STG.Scripts.Shots.Laser.Resource")
require("STG.Scripts.Shots.Laser.Updater")