---@class Core.Object.Utils
local M = {}
Core.Object.Utils = M

M.New = lstg.New
M.SetV = lstg.SetV
M.GetV = lstg.GetV
M.IsValid = lstg.IsValid
--M.Dist = lstg.Dist
--M.Angle = lstg.Angle
M.SetAttr = lstg.SetAttr
M.GetAttr = lstg.GetAttr

M.DefaultRender = lstg.DefaultRenderFunc
M.SetImgState = lstg.SetImgState
M.BoxCheck = lstg.BoxCheck
M.ObjList = lstg.ObjList

---实例化一个对象（？），不是通过New函数创建的
---init函数需要额外执行（这样就能看到参数提示了）
---Instantiate an object that is not created through the New function.
---The init function needs to be executed separately (so that the parameter hints can be seen).
---@generic T
---@param base T
---@return T
function M.Instantiate(base)
    local obj = M.New(Core.Object.Base)
    obj.class = base
    return obj
end

---@param obj lstg.GameObject
function M.RawDel(obj)
    if M.IsValid(obj) then
        obj.status = 'del'
        if obj._servants then
            M.DelServants(obj)
        end
    end
end

---@param obj lstg.GameObject
function M.RawKill(obj)
    if M.IsValid(obj) then
        obj.status = 'kill'
        if obj._servants then
            M.KillServants(obj)
        end
    end
end

---@param obj lstg.GameObject
function M.Preserve(obj)
    obj.status = 'normal'
end

---@param obj lstg.GameObject
function M.Kill(obj)
    if M.IsValid(obj) then
        M.KillServants(obj)
        lstg.Kill(obj)
    end
end

---@param obj lstg.GameObject
function M.Del(obj)
    if M.IsValid(obj) then
        M.DelServants(obj)
        lstg.Del(obj)
    end
end

---@param obj lstg.GameObject
function M.SetA(obj, a, rot)
    obj.ax = a * cos(rot)
    obj.ay = a * sin(rot)
end

---@param obj lstg.GameObject
function M.SetG(obj, g, navi, maxv)
    if navi then
        obj.navi = true
    end
    obj.ag = g
    obj.maxv = maxv or obj.maxv
end

---立即停止运动
---Stop the object's motion immediately.
---@param obj lstg.GameObject
function M.Stop(obj)
    obj.vx, obj.vy = 0, 0
    obj.ax, obj.ay = 0, 0
    obj.ag = 0
end

---绑定主从关系
---Bind the object as a slave to the master.
---@param master lstg.GameObject@
---@param servant lstg.GameObject@
---@param dmg_transfer number@伤害传导比例
---@param con_death boolean@是否连接清理
function M.Connect(master, servant, dmg_transfer, con_death)
    if M.IsValid(master) and M.IsValid(servant) then
        if con_death or con_death == nil then
            master._servants = master._servants or {}
            table.insert(master._servants, servant)
        end
        servant._master = master
        servant._dmg_transfer = dmg_transfer or 0
    end
end

---@param obj lstg.GameObject
function M.KillServants(obj)
    if obj._servants then
        for _, v in pairs(obj._servants) do
            if M.IsValid(v) then
                M.Kill(v)
            end
        end
        obj._servants = {}
    end
end

---@param obj lstg.GameObject
function M.DelServants(obj)
    if obj._servants then
        for _, v in pairs(obj._servants) do
            if M.IsValid(v) then
                M.Del(v)
            end
        end
        obj._servants = {}
    end
end

local OriginalSmearBlend = "mul+add"

---@param obj lstg.GameObject
function M.SmearAdd(obj, alpha)
    if not obj.smear then
        obj.smear = {}
    end
    table.insert(obj.smear, { x = obj.x, y = obj.y, rot = obj.rot, alpha = alpha, img = obj.img, hscale = obj.hscale, vscale = obj.vscale })
end
---@param obj lstg.GameObject
function M.SmearFrame(obj, decay_alpha)
    if obj.smear then
        for i = #obj.smear, 1, -1 do
            local s = obj.smear[i]
            s.alpha = max(s.alpha - decay_alpha, 0)
            if s.alpha == 0 then
                table.remove(obj.smear, i)
            end
        end
    end
end
---@param obj lstg.GameObject
---@param mode lstg.BlendMode
function M.SmearRender(obj, mode, R, G, B)
    mode = mode or OriginalSmearBlend
    R = R or 200
    G = G or 200
    B = B or 200
    if obj.smear then
        for _, s in ipairs(obj.smear) do
            Core.Render.SetImageState(s.img, mode, max(0, s.alpha), R, G, B)
            Core.Render.Image(s.img, s.x, s.y, s.rot, s.hscale, s.vscale)
        end
    end
end

---@param obj lstg.GameObject
---@param mode lstg.BlendMode
function M.SmearRenderAnimation(obj, mode, R, G, B)
    mode = mode or OriginalSmearBlend
    R = R or 200
    G = G or 200
    B = B or 200
    if obj.smear then
        for i, s in ipairs(obj.smear) do
            Core.Render.SetAnimationState(s.img, mode, max(0, s.alpha), R, G, B)
            Core.Render.Animation(s.img, obj.ani + i, s.x, s.y, s.rot, s.hscale, s.vscale)
        end
    end
end

---@param obj lstg.GameObject
function M.SetSize(obj, h, v)
    h = h or 1
    v = v or h
    obj.hscale = h
    obj.vscale = v
end
---@param obj lstg.GameObject
function M.SetCollision(obj, a, b)
    a = a or 0
    b = b or a
    obj.a = abs(a)
    obj.b = abs(b)
end
---@param obj lstg.GameObject
function M.SetSizeCollision(obj, h, v)
    h = h or 1
    v = v or h
    M.SetCollision(obj, h / obj.hscale * obj.a, v / obj.vscale * obj.b)
    M.SetSize(obj, h, v)
end

--TODO
function M.ClearVIndex(obj)
    obj.hsindex = nil
end

--TODO
function M.SetVIndex(obj, index)
    index = max(-1, index)
    if not obj.stop_setVindex then
        obj.hsindex = obj.hsindex or 0
        index = max(-1 - obj.hsindex, index)
        obj.hsindex = obj.hsindex + index

        obj.x = obj.x + obj.vx * index
        obj.y = obj.y + obj.vy * index
        obj.vx = obj.vx + obj.ax * index
        obj.vy = obj.vy + obj.ay * index
        obj.vy = obj.vy - obj.ag * index
    else
        obj.stop_setVindex = nil
    end
end

---对一个对象表进行更新，去除无效的luastg object对象
---@param lst lstg.GameObject[]
function M.UpdateList(lst)
    if lst then
        local n = #lst
        local j = 0
        local z
        for i = 1, n do
            z = lst[i]
            if IsValid(z) then
                j = j + 1
                lst[j] = z
                if i ~= j then
                    lst[i] = nil
                end
            else
                lst[i] = nil
            end
        end
        return j
    end
end

---在对象表中插入一个对象
---@param lst lstg.GameObject[]
---@param obj lstg.GameObject
function M.InsertList(lst, obj)
    if M.IsValid(obj) then
        local n = #lst
        lst[n + 1] = obj
        return n + 1
    end
end

---返回指定对象在对象表中的位置
---@param lst lstg.GameObject[]
---@param obj lstg.GameObject
---@return number
function M.FindObject(lst, obj)
    local n = #lst
    for i = 1, n do
        local z = lst[i]
        if z == obj then
            return i
        end
    end
    return 0
end


local ObjList = lstg.ObjList
local group = Core.Object.Group
---@param func fun(o:lstg.GameObject)
function M.BulletDo(func)
    for _, o in ObjList(group.EnemyBullet) do
        func(o)
    end
    for _, o in ObjList(group.EnemyBullet2) do
        func(o)
    end
end
---@param func fun(o:lstg.GameObject)
function M.IndesDo(func)
    for _, o in ObjList(group.InDes) do
        func(o)
    end
end
---@param func fun(o:lstg.GameObject)
function M.BulletIndesDo(func)
    for _, o in ObjList(group.EnemyBullet) do
        func(o)
    end
    for _, o in ObjList(group.EnemyBullet2) do
        func(o)
    end
    for _, o in ObjList(group.InDes) do
        func(o)

    end
end
---@param func fun(o:lstg.GameObject)
function M.EnemyDo(func)
    for _, o in ObjList(group.Enemy) do
        func(o)
    end
end
---@param func fun(o:lstg.GameObject)
function M.NonColliDo(func)
    for _, o in ObjList(group.NonColli) do
        func(o)
    end
end
---@param func fun(o:lstg.GameObject)
function M.EnemyNonColliDo(func)
    for _, o in ObjList(group.Enemy) do
        func(o)
    end
    for _, o in ObjList(group.NonColli) do
        func(o)
    end
end
---@param func fun(o:lstg.GameObject)
function M.LaserDo(func)
    for _, o in ObjList(group.Laser) do
        func(o)
    end
end
