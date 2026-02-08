---@class STG.Shots.Bullet : STG.Shots.Bullet.Utils
---@field Resource STG.Shots.Bullet.Resource
local M = {}
STG.Shots.Bullet = M

M.DEFAULT_FOG_IMAGE = "stg:bullet_fog"
M.DEFAULT_FOG_TIME = 11

---@alias STG.Shots.Bullet.Type string

local Object = STG.Object

local function onDelete(self, drop_p)
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

---@class STG.Shots.Bullet.Base : Core.Object.Base
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
        onDelete(self, true)
    end
end
function Base:del()
    if self.del_new then
        self:del_new()
    else
        onDelete(self)
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

---@param type string
---@param index number
---@param stay boolean
---@param destroyable boolean
---@param fogTime number@雾化时间
function Base:init(type, index, stay, destroyable, fogTime)

    self._blend, self._a, self._r, self._g, self._b = "", 255, 255, 255, 255
    self._layer = Object.Layer.EnemyBullet
    ---弹型换底公式（迫真
    self.logclass = self.class

    -- self.smear = {}
    self.group = (destroyable ~= false) and Object.Group.EnemyBullet or Object.Group.InDes
    self.fog_time = fogTime or M.DEFAULT_FOG_TIME
    M.ChangeImage(self, type, index)
    self.colli = true
    self.stay = stay ~= false
    self.type_name = type
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
---@param type STG.Shots.Bullet.Type
---@param color number
function M.ChangeImage(self, type, color)
    color = clamp(color, 1, 16)
    local imgclass = M.Resource.Datas[type]
    assert(imgclass, "Bullet type " .. type .. " not found!")
    self.type_name = type
    if self.class == self.imgclass then
        self.class = imgclass
        self.imgclass = imgclass
    else
        self.imgclass = imgclass
    end
    self._index = color
    self._fog_img = M.DEFAULT_FOG_IMAGE .. self._index
    imgclass.init(self, self._index)
    M.SetLayer(self)
end

---取消雾化效果
function M.RemoveFog(self)
    self.timer = self.fog_time
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

function M.SetDefaultFogImage(img)
    M.DEFAULT_FOG_IMAGE = img or "stg:bullet_fog"
end
function M.SetDefaultFogTime(time)
    M.DEFAULT_FOG_TIME = time or 11
end

---@class STG.Shots.Bullet.TypeBase
local TypeBase = Object.Define()
M.TypeBase = TypeBase
function TypeBase:frame()
    if not self.stay then
        if not (self._forbid_ref) then
            self._forbid_ref = true
            self.logclass.frame(self)
            self._forbid_ref = nil
        end--??
    else
        self.vx = self.vx - self.ax
        self.vy = self.vy - self.ay
        self.vy = self.vy + self.ag
        self.x = self.x - self.vx
        self.y = self.y - self.vy
        self.rot = self.rot - self.omega
        -- self.stop_setVindex = true
    end
    if self.timer == self.fog_time then
        self.class = self.logclass
        self.layer = self._layer - self.imgclass.size * 0.001 + self._index * 0.00001
        if self.stay then
            self.timer = -1
        end
    end
end
function TypeBase:del()
    STG.Effect.Fade(self._fog_img, self.x, self.y, self.rot, self.dx, self.dy, 0, self.layer, self._blend, 11, self.imgclass.size)
end
function TypeBase:kill()
    Base.del(self)
    M.BreakEff(self.x, self.y, self._index)
    STG.Item.Drop(STG.Item.DropPoint, self.x, self.y)
end
function TypeBase:render()
    Core.Render.SetImageState(self._fog_img, self._blend, 255 * self.timer / self.fog_time, self._r, self._g, self._b)
    Core.Render.Image(self._fog_img, self.x, self.y, self.rot, ((self.fog_time - self.timer) / self.fog_time * 3 + 1) * self.imgclass.size)
end

local FadeType = Object.Define(TypeBase)
M.FadeType = FadeType
function FadeType:render()
    Core.Render.SetImageState(self.img, self._blend, 255 * self.timer / self.fog_time, 255, 255, 255)
    Core.Render.Image(self.img, self.x, self.y, self.rot, self.hscale * ((self.fog_time - self.timer) / self.fog_time + 1))
end
function FadeType:del()
    STG.Effect.Fade(self.img, self.x, self.y, self.rot, self.dx, self.dy, self.omega, self.layer, self._blend)
end
function FadeType:kill()
    STG.Effect.Fade(self.img, self.x, self.y, self.rot, self.dx, self.dy, self.omega, self.layer, self._blend)
    M.BreakEff(self.x, self.y, self._index)
    STG.Item.Drop(STG.Item.DropPoint, self.x, self.y)
end

require("STG.Scripts.Shots.Bullet.Resource")