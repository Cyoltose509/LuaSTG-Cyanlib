---@class STG.Shots.Bullet.Style : STG.Bullet.Style.Registered
local M = {}
STG.Shots.Bullet.Style = M

---@class STG.Shots.Bullet.Style.Base
local Base = Core.Object.Define()
function Base:frame()
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
    if self.timer == self.fogtime then
        self.class = self.logclass
        self.layer = self._layer - self.imgclass.size * 0.001 + self._index * 0.00001
        if self.stay then
            self.timer = -1
        end
    end
end
function Base:del()
    STG.Effect.Fade('stg:bullet_preimg' .. self._index, self.x, self.y, 0,
            self.dx, self.dy, 0, self.layer, self._blend, 11, self.imgclass.size)
end
function Base:kill()
    Base.del(self)
    M.BreakEff(self.x, self.y, self._index)
    STG.Item.Drop(STG.Item.DropPoint, self.x, self.y)
end
function Base:render()
    Core.Render.SetImageState('stg:bullet_preimg' .. self._index, self._blend, 255 * self.timer / self.fogtime, self._r, self._g, self._b)
    Core.Render.Image('stg:bullet_preimg' .. self._index, self.x, self.y, self.rot,
            ((self.fogtime - self.timer) / self.fogtime * 3 + 1) * self.imgclass.size)
end

---@class STG.Bullet.Style.Registered
---@field ArrowBig STG.Shots.Bullet.Style.Base
---@field ArrowBig2 STG.Shots.Bullet.Style.Base
---@field ArrowBig3 STG.Shots.Bullet.Style.Base
---@field ArrowMid STG.Shots.Bullet.Style.Base
---@field ArrowSmall STG.Shots.Bullet.Style.Base
---@field ArrowSmall2 STG.Shots.Bullet.Style.Base
---@field Gun STG.Shots.Bullet.Style.Base
---@field Butterfly STG.Shots.Bullet.Style.Base
---@field Square STG.Shots.Bullet.Style.Base
---@field Mildew STG.Shots.Bullet.Style.Base
---@field Ellipse STG.Shots.Bullet.Style.Base
---@field StarSmall STG.Shots.Bullet.Style.Base
---@field StarBig STG.Shots.Bullet.Style.Base
---@field BallSmall STG.Shots.Bullet.Style.Base
---@field BallMid STG.Shots.Bullet.Style.Base
---@field BallMid2 STG.Shots.Bullet.Style.Base
---@field BallBig STG.Shots.Bullet.Style.Base
---@field BallHuge STG.Shots.Bullet.Style.Base
---@field BallLight STG.Shots.Bullet.Style.Base
---@field Grain STG.Shots.Bullet.Style.Base
---@field Grain2 STG.Shots.Bullet.Style.Base
---@field Grain3 STG.Shots.Bullet.Style.Base
---@field Grain4 STG.Shots.Bullet.Style.Base
---@field Knife STG.Shots.Bullet.Style.Base
---@field Knife2 STG.Shots.Bullet.Style.Base
---@field Music STG.Shots.Bullet.Style.Base
---@field WaterDrop STG.Shots.Bullet.Style.Base
---@field Diamond STG.Shots.Bullet.Style.Base
---@field Silence STG.Shots.Bullet.Style.Base
---@field Heart STG.Shots.Bullet.Style.Base
---@field Money STG.Shots.Bullet.Style.Base
---@field MoneyBig STG.Shots.Bullet.Style.Base
local Registered = {}
--setmetatable(M, { __index = Registered })

---@param name string
---@param opt STG.Shots.Bullet.Style.Base
function M.Register(name, opt)
    ---@type STG.Shots.Bullet.Style.Base
    local cls = Core.Object.Define(Base)

    cls.size = opt.size or 1
    cls.eight_color = opt.eight_color or false
    cls.used_img = opt.used_img
    cls.used_ani = opt.used_ani
    cls.colli_a = opt.colli_a or 0
    cls.colli_b = opt.colli_b or cls.colli_a
    cls.colli_rect = opt.colli_rect or false
    cls.blend = opt.blend or Core.Render.BlendMode.Default

    ---是否不允许设置速度时调整方向（得自己用这个变量，不会完全覆盖设置）
    cls.disable_navi = opt.disable_navi or false

    if opt.init then
        cls.init = opt.init
    else
        cls.init = function(self, index)
            if cls.used_img then
                local idx = cls.eight_color and math.ceil(index / 2) or index
                self.img = cls.used_img .. idx
                self.a = cls.colli_a
                self.b = cls.colli_b
                self.rect = cls.colli_rect
                self._blend = cls.blend
            elseif cls.used_ani then
                local idx = cls.eight_color and math.ceil(index / 2) or index
                self.img = cls.used_ani .. idx
                self.a = cls.colli_a
                self.b = cls.colli_b
                self.rect = cls.colli_rect
                self._blend = cls.blend
            end
        end
    end
    if opt.frame then
        cls.frame = opt.frame
    end
    if opt.render then
        cls.render = opt.render
    end
    if opt.del then
        cls.del = opt.del
    end
    if opt.kill then
        cls.kill = opt.kill
    end

    Registered[name] = cls
    M[name] = cls
    return cls
end

local FadeType = {}
M.FadeType = FadeType
function FadeType.render(self)
    Core.Render.SetImageState(self.img, self._blend, 255 * self.timer / self.fogtime, 255, 255, 255)
    Core.Render.Image(self.img, self.x, self.y, self.rot, self.hscale * ((self.fogtime - self.timer) / self.fogtime + 1))
end
function FadeType.del(self)
    STG.Effect.Fade(self.img, self.x, self.y, self.rot, self.dx, self.dy, self.omega, self.layer, self._blend)
end
function FadeType.kill(self)
    STG.Effect.Fade(self.img, self.x, self.y, self.rot, self.dx, self.dy, self.omega, self.layer, self._blend)
    M.BreakEff(self.x, self.y, self._index)
    STG.Item.Drop(STG.Item.DropPoint, self.x, self.y)
end

M.Register("ArrowBig", {
    size = 0.6,
    used_img = "stg:arrow_big",
    colli_a = 5,
})
M.Register("ArrowBig2", {
    size = 0.61,
    used_img = "stg:arrow_big_b",
    colli_a = 5,
})
M.Register("ArrowBig3", {
    size = 0.59,
    used_img = "stg:arrow_big_c",
    colli_a = 5,
})
M.Register("ArrowMid", {
    size = 0.61,
    used_img = "stg:arrow_mid",
    colli_a = 5,
})
M.Register("ArrowSmall", {
    size = 0.407,
    used_img = "stg:arrow_small",
    colli_a = 5,
})
M.Register("ArrowSmall2", {
    size = 0.406,
    used_img = "stg:arrow_small_b",
    colli_a = 5,
})
M.Register("Gun", {
    size = 0.4,
    used_ani = "stg:gun_bullet",
    colli_a = 5,
})
M.Register("Butterfly", {
    size = 0.7,
    used_img = "stg:butterfly",
    colli_a = 8,
})
M.Register("Square", {
    size = 0.8,
    used_img = "stg:square",
    colli_a = 6,
})
M.Register("Mildew", {
    size = 0.401,
    used_img = "stg:mildew",
    colli_a = 4,
})
M.Register("Ellipse", {
    size = 0.701,
    used_img = "stg:ellipse",
    colli_a = 9,
})
M.Register("StarSmall", {
    size = 0.5,
    used_img = "stg:star_small",
    colli_a = 4,
    disable_navi = true,
})
M.Register("StarBig", {
    size = 0.998,
    used_img = "stg:star_big",
    colli_a = 11,
    disable_navi = true,
})
M.Register("BallSmall", {
    size = 0.402,
    used_img = "stg:ball_small",
    colli_a = 3.5,
})
M.Register("BallMid", {
    size = 0.75,
    used_img = "stg:ball_mid",
    colli_a = 8,
})
M.Register("BallMid2", {
    size = 0.752,
    used_img = "stg:ball_mid_c",
    colli_a = 8,
})
M.Register("BallBig", {
    size = 1,
    used_img = "stg:ball_big",
    colli_a = 16,
})
M.Register("BallHuge", {
    size = 1.5,
    used_img = "stg:ball_huge",
    colli_a = 27,
    blend = Core.Render.BlendMode.MulAdd,
    render = FadeType.render,
    del = FadeType.del,
    kill = FadeType.kill,
})
M.Register("BallLight", {
    size = 2,
    used_img = "stg:ball_light",
    colli_a = 23,
    blend = Core.Render.BlendMode.MulAdd,
    render = FadeType.render,
    del = FadeType.del,
    kill = FadeType.kill,
})
M.Register("Grain", {
    size = 0.403,
    used_img = "stg:grain_a",
    colli_a = 4,
})
M.Register("Grain2", {
    size = 0.404,
    used_img = "stg:grain_b",
    colli_a = 4,
})
M.Register("Grain3", {
    size = 0.405,
    used_img = "stg:grain_c",
    colli_a = 4,
})
M.Register("Grain4", {
    size = 0.406,
    used_img = "stg:grain_d",
    colli_a = 4,
})
M.Register("Knife", {
    size = 0.754,
    used_img = "stg:knife",
    colli_a = 8,
})
M.Register("Knife2", {
    size = 0.755,
    used_img = "stg:knife_b",
    colli_a = 7,
})
M.Register("Music", {
    size = 0.8,
    used_ani = "stg:music",
    colli_a = 8,
    eight_color = true,
    disable_navi = true,
})
M.Register("WaterDrop", {
    size = 0.702,
    used_ani = "stg:water_drop",
    colli_a = 8,
    blend = Core.Render.BlendMode.MulAdd,
})
M.Register("Diamond", {
    size = 0.406,
    used_img = "stg:diamond",
    colli_a = 5,
})
M.Register("Silence", {
    size = 0.8,
    used_img = "stg:silence",
    colli_a = 9,
})
M.Register("Heart", {
    size = 1,
    used_img = "stg:heart",
    colli_a = 16,
})
M.Register("Money", {
    size = 0.753,
    used_img = "stg:money",
    colli_a = 8,
    disable_navi = true,
})
M.Register("MoneyBig", {
    size = 0.743,
    used_img = "stg:money_big",
    colli_a = 16,
    disable_navi = true,
})

