---@class STG.Shots.CurveLaser
---@field Updater STG.Shots.CurveLaser.Updater
---@field Resource STG.Shots.CurveLaser.Resource
local M = {}
STG.Shots.CurveLaser = M

local Task = Core.Task
local Object = STG.Object

local AttributeProxy = Object.AttributeProxy

local bent_unit = Object.Define()
function bent_unit:init(x, y, master)
    --bullet.init(self, star_small, master.index, false, true)
    self.group = Object.Group.EnemyBullet
    self.master = master
    self._index = master.index
    self.x = x
    self.y = y
    self.fog_time = 0
    self.hide = true
    self.bound = false
    self._graze = true
    self._vx = 0
    self._vy = 0
    self.rect = true
    self._curveLaser_unit = true
    self.a, self.b = 1, 1
end
function bent_unit:frame()
    if Object.IsValid(self.master) then
        Task.Do(self)
    else
        Object.RawDel(self)
    end
end
bent_unit.del = STG.Shots.Bullet.Base.del
bent_unit.kill = STG.Shots.Bullet.Base.kill

---@class STG.Shots.CurveLaser.Base
local Base = Object.Define()

local attribute_proxies = {}
Base.___attribute_proxies = attribute_proxies
--region bound
local proxy_bound = AttributeProxy.Create("bound")
attribute_proxies["bound"] = proxy_bound

function proxy_bound:init()
    Object.SetAttr(self, "bound", false)
end

function proxy_bound:getter(key, storage)
    return Object.GetAttr(self, key)
end
function proxy_bound:setter(key, value, storage)
    rawset(self, '_bound', value)
end

--endregion


function Base:frame()
    Task.Do(self)
    if self.sampleData then
        self.sampleData:frame(self)
    end
    do
        for i = #self.cutSeg, 1, -1 do
            self.cutSeg[i] = nil
        end
        local curList = {}
        for _, v in ipairs(self.data) do
            if Object.IsValid(v) then
                curList[#curList + 1] = v
            elseif #curList > 0 then
                self.cutSeg[#self.cutSeg + 1] = curList
                curList = {}
            end
        end
        if #curList > 0 then
            self.cutSeg[#self.cutSeg + 1] = curList
        end
    end--处理断截线段
    self.v = Object.GetV(self)
    if self._bound then
        local flag = false
        local w = Core.World.GetMain()
        for _, v in ipairs(self.data) do
            if Object.IsValid(v) then
                flag = flag or w:isInBound(v)
            end
        end
        if not flag then
            Object.RawDel(self)
        end
    end
end

---@param self STG.Shots.CurveLaser.Base
local function render_laser(self)
    local data = self.sampleData
    local tLeft, tTop = data.x, data.y
    local tWidth, tHeight = data.w, data.h
    local wRatio = data.wRatio
    local tex = Core.Resource.Texture.Get(data.tex)
    local color = Core.Render.Color(self._a, self._r, self._g, self._b)
    local band_width = self.w * wRatio
    local half_width = band_width / 2
    local z = 0.5
    for _, plist in ipairs(self.cutSeg) do
        local n = #plist
        if n >= 2 then

            -- 先计算每个点的切线
            local tangents = {}
            for i = 1, n do
                local dx, dy
                if i == 1 then
                    dx = plist[2].x - plist[1].x
                    dy = plist[2].y - plist[1].y
                elseif i == n then
                    dx = plist[n].x - plist[n - 1].x
                    dy = plist[n].y - plist[n - 1].y
                else
                    dx = plist[i + 1].x - plist[i - 1].x
                    dy = plist[i + 1].y - plist[i - 1].y
                end
                local len = sqrt(dx * dx + dy * dy)
                if len == 0 then
                    len = 1
                end
                tangents[i] = { dx / len, dy / len }
            end
            -- 计算线段长度和总长
            local segments = {}
            local totalLen = 0
            for i = 1, n - 1 do
                local p1, p2 = plist[i], plist[i + 1]
                local dx, dy = p2.x - p1.x, p2.y - p1.y
                local len = sqrt(dx * dx + dy * dy)
                -- 每个端点法线为切线旋转90度
                local n1x, n1y = -tangents[i][2], tangents[i][1]
                local n2x, n2y = -tangents[i + 1][2], tangents[i + 1][1]

                segments[#segments + 1] = {
                    p1.x, p1.y, p2.x, p2.y,
                    n1x, n1y, n2x, n2y,
                    len
                }
                totalLen = totalLen + len
            end

            -- 渲染
            local accLen = 0

            for _, seg in ipairs(segments) do
                local x1, y1 = seg[1], seg[2]
                local x2, y2 = seg[3], seg[4]
                local n1x, n1y = seg[5], seg[6]
                local n2x, n2y = seg[7], seg[8]
                local len = seg[9]

                local cx, cy = (x1 + x2) * 0.5, (y1 + y2) * 0.5
                local tx, ty = (x2 - x1) / len, (y2 - y1) / len

                local u1 = tLeft + (accLen / totalLen) * tWidth
                local u2 = tLeft + ((accLen + len) / totalLen) * tWidth
                accLen = accLen + len

                local x1u = cx - tx * len * 0.5 + n1x * half_width
                local y1u = cy - ty * len * 0.5 + n1y * half_width
                local x2u = cx + tx * len * 0.5 + n2x * half_width
                local y2u = cy + ty * len * 0.5 + n2y * half_width
                local x2d = cx + tx * len * 0.5 - n2x * half_width
                local y2d = cy + ty * len * 0.5 - n2y * half_width
                local x1d = cx - tx * len * 0.5 - n1x * half_width
                local y1d = cy - ty * len * 0.5 - n1y * half_width
                tex:setUV1(x1u, y1u, z, u1, tTop, color)
                   :setUV2(x1d, y1d, z, u1, tTop + tHeight, color)
                   :setUV3(x2d, y2d, z, u2, tTop + tHeight, color)
                   :setUV4(x2u, y2u, z, u2, tTop, color)
                   :setBlend(self._blend)
                   :draw()
            end
        end
    end

end

function Base:render()
    if self.node > 0 then
        local pr = max(0, 1 - self.timer / self.l)
        local n = self.node * pr
        local img = self.sampleData.node_img
        Core.Render.SetImageState(img, self._blend, self._a, self._r, self._g, self._b)
        Core.Render.Image(img, self.prex, self.prey, 18 * self.timer, n / 8)
        Core.Render.Image(img, self.prex, self.prey, -18 * self.timer, n / 8)
    end
    render_laser(self)


end

function Base:Del()
    for _, v in ipairs(self.data) do
        if Object.IsValid(v) then
            Object.Del(v)
        end
    end
end

function Base:Kill()
    for _, v in ipairs(self.data) do
        if Object.IsValid(v) then
            Object.Kill(v)
        end
    end
end

function Base:init(x, y, col, sample, l, w, node)
    self.index = col
    self.x = x
    self.y = y
    self.l = max(int(l), 2)
    self.w = w
    self.group = Object.Group.InDes
    self.layer = Object.Layer.EnemyBullet
    self.bound = false
    self._bound = true
    self.prex = x
    self.prey = y
    self.node = node or 0

    self.a = 0
    self.b = 0
    self._colli = true
    self.IsLaser = true
    self.IsBentLaser = true
    self._blend, self._a, self._r, self._g, self._b = 'mul+add', 255, 255, 255, 255

    self.data = {}
    self.cutSeg = {}
    AttributeProxy.Apply(self, Base.___attribute_proxies)
    M.SetSample(self, sample)
end

---@param self STG.Shots.CurveLaser.Base
---@param sample string|number
---@param index number
function M.SetSample(self, sample, index)
    self.index = index or self.index
    self.sampleData = M.Resource.GetData(sample, self)
    self.sample = sample
end

function M.New(x, y, col, sample, l, w, node, event, interval)
    local obj = Object.New(Base, x, y, col, sample, l, w, node)
    M.Updater:addLaser(obj)
    if event then
        event(obj)
    end
    interval = interval or 4
    Task.New(obj, function()
        for i = 0, obj.l do
            if i % interval == 0 or i == obj.l then
                local unit = Object.New(bent_unit, obj.prex, obj.prey, obj)
                if event then
                    event(unit)
                end
                table.insert(obj.data, unit)
            end
            Task.Wait()
        end
    end)
    return obj
end

require("STG.Scripts.Shots.CurveLaser.Updater")
require("STG.Scripts.Shots.CurveLaser.Resource")