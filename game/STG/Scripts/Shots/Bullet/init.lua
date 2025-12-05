---@class STG.Shots.Bullet : STG.Shots.Bullet.Utils
---@field Style STG.Shots.Bullet.Style
---@field Resource STG.Shots.Bullet.Resource
local M = {}
STG.Shots.Bullet = M

local Object = Core.Object

local function DelBulletFunc(self, drop_p)
    local w = Core.World.GetMain()
    local inbound = w:isInBound(self)
    if self._index and inbound then
        STG.Shots.BreakEff(self.x, self.y, self._index)
    end
    if self.imgclass and self.imgclass.size == 2.0 then
        self.imgclass.del(self)
    end
    if drop_p then
        STG.Item.Drop(STG.Item.DropPoint, self.x, self.y)
    end
end

---@class STG.Bullet.Base : Core.Object.Base
local Base = Object.Define()
M.Base = Base
function Base:frame()
    if self.frame_new then
        self:frame_new()
    else
        Core.Task.Do(self)
    end
end
function Base:kill()
    if self.kill_new then
        self:kill_new()
    else
        DelBulletFunc(self, true)
    end
end
function Base:del()
    if self.del_new then
        self:del_new()
    else
        DelBulletFunc(self)
    end
end
function Base:render()
    if self.render_new then
        self:render_new()
    else
        Object.SetImgState(self, self._blend, self._a, self._r, self._g, self._b)
        Object.DefaultRender(self)
    end
end
---@param imgclass bulletStyle
---@param index number
---@param stay boolean
---@param destroyable boolean
---@param fogTime number@雾化时间
function Base:init(imgclass, index, stay, destroyable, fogTime)
    self._blend, self._a, self._r, self._g, self._b = "", 255, 255, 255, 255
    self._layer = Object.Layer.EnemyBullet
    ---弹型换底公式（迫真
    self.logclass = self.class
    self.imgclass = imgclass
    self.class = imgclass
    -- self.smear = {}
    self.group = (destroyable ~= false) and Object.Group.EnemyBullet or Object.Group.InDes
    self.fogtime = fogTime or 11
    if tonumber(index) then
        self.colli = true
        self.stay = stay ~= false
        index = int(clamp(index, 1, 16))
        self.layer = self._layer + 100 - imgclass.size * 0.001 + index * 0.00001
        self._index = index
        self.index = int((index + 1) / 2)
    end
    imgclass.init(self, index)
end

---@param self lstg.GameObject
---@param layer number
---@param real boolean@图层真正是这个(可能会被覆盖)
function M.SetLayer(self, layer, real)
    if real then
        self.layer = layer
    else
        self._layer = layer or Object.Layer.EnemyBullet
        self.layer = self._layer + ((self.class == self.logclass) and 0 or 100) - self.imgclass.size * 0.001 + self._index * 0.00001
    end
end

---@param self lstg.GameObject
---@param imgclass STG.Shots.Bullet.Style.Base
---@param color number
function M.ChangeImage(self, imgclass, color)
    if self.class == self.imgclass then
        self.class = imgclass
        self.imgclass = imgclass
    else
        self.imgclass = imgclass
    end
    self._index = color
    imgclass.init(self, self._index)
    --self.smearImageRender = CheckRes("img", self.img)
end

---取消雾化效果
function M.RemoveFog(self)
    self.timer = self.fogtime
end

---重新雾化
function M.RestartFog(self)
    self.class = self.imgclass
    self.timer = 0
end

local OriginalSmearBlend = Core.Render.BlendMode.MulAdd
M.SmearAdd = Core.Object.SmearAdd
M.SmearFrame = Core.Object.SmearFrame
---@param self lstg.GameObject
function M.SmearRender(self, mode, R, G, B)
    mode = mode or OriginalSmearBlend
    R = R or 200
    G = G or 200
    B = B or 200
    if self.smear then
        if self.imgclass.used_ani then
            for i, s in ipairs(self.smear) do
                Core.Render.SetAnimationState(self.img, mode, max(0, s.alpha), R, G, B)
                Core.Render.Animation(self.img, self.ani + i, s.x, s.y, s.rot, s.hscale, s.vscale)
            end
        else
            for _, s in ipairs(self.smear) do
                Core.Render.SetImageState(self.img, mode, max(0, s.alpha), R, G, B)
                Core.Render.Image(self.img, s.x, s.y, s.rot, s.hscale, s.vscale)
            end
        end
    end

end


require("STG.Scripts.Shots.Bullet.Style")
require("STG.Scripts.Shots.Bullet.Resource")