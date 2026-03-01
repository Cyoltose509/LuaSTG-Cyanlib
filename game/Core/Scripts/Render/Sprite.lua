---@class Core.Render.Sprite
local M = Core.Class()
Core.Render.Sprite = M

local render_func = {
    function(self)
        lstg.Render(self.res_name, self.x, self.y, self.rot, self.hscale, self.vscale, self.z)
    end,
    function(self)
        local r = self.rect
        lstg.RenderRect(self.res_name, r[1], r[2], r[3], r[4])
    end,
    function(self)
        local r = self.quad
        lstg.Render4V(self.res_name,
                r[1], r[2], r[3], r[4], r[5], r[6],
                r[7], r[8], r[9], r[10], r[11], r[12])
    end
}

function M:init(s)
    ---@type Core.Resource.Sprite
    self.res = nil
    ---@type string
    self.res_name = nil
    self._blend = Core.Render.BlendMode.Default
    self._color1 = Core.Render.Color.Default
    self._color2 = nil
    self._color3 = nil
    self._color4 = nil
    self.x = 0
    self.y = 0
    self.z = 0.5
    self.rot = 0
    self.hscale = 1
    self.vscale = 1
    self.rect = { 0, 0, 0, 0 }
    self.quad = {
        0, 0, 0,
        0, 0, 0,
        0, 0, 0,
        0, 0, 0
    }
    self.mode = 1
    if s then
        self:setSprite(s)
    end
end
---@param s string|Core.Resource.Sprite
function M:setSprite(s)
    if type(s) == "string" then
        s = Core.Resource.Sprite.Get(s)
    end
    self.res = s
    self.res_name = s.name
end
---@overload fun(blend:string, c1:lstg.Color, c2:lstg.Color, c3:lstg.Color, c4:lstg.Color)
---@overload fun(blend:string, color:lstg.Color)
---@overload fun(blend:string)
function M:setState(blend, c1, c2, c3, c4)
    if not blend and not c1 then
        return self
    end
    self._blend = blend or self._blend
    if c2 then
        self._color1 = c1
        self._color2 = c2
        self._color3 = c3
        self._color4 = c4
    else
        self._color1 = c1 or self._color1
        self._color2 = nil
        self._color3 = nil
        self._color4 = nil

    end
    return self
end

function M:setPosition(x, y, z)
    self.x = x or self.x
    self.y = y or self.y
    self.z = z or self.z
    self.mode = 1
    return self
end

function M:setRotation(rot)
    self.rot = rot or self.rot
    self.mode = 1
    return self
end

function M:setScale(hscale, vscale)
    self.hscale = hscale or self.hscale
    self.vscale = vscale or hscale or self.vscale
    self.mode = 1
    return self
end

function M:setRect(left, right, bottom, top)
    local r = self.rect
    r[1] = left or r[1]
    r[2] = right or r[2]
    r[3] = bottom or r[3]
    r[4] = top or r[4]
    self.mode = 2
    return self
end

function M:set4V(x1, y1, z1, x2, y2, z2, x3, y3, z3, x4, y4, z4)
    local q = self.quad
    q[1] = x1 or q[1]
    q[2] = y1 or q[2]
    q[3] = z1 or q[3]
    q[4] = x2 or q[4]
    q[5] = y2 or q[5]
    q[6] = z2 or q[6]
    q[7] = x3 or q[7]
    q[8] = y3 or q[8]
    q[9] = z3 or q[9]
    q[10] = x4 or q[10]
    q[11] = y4 or q[11]
    q[12] = z4 or q[12]
    self.mode = 3
    return self
end

function M:draw()
    if not self.res then
        return
    end
    if self._color2 then
        lstg.SetImageState(self.res_name, self._blend, self._color1, self._color2, self._color3, self._color4)
    else
        lstg.SetImageState(self.res_name, self._blend, self._color1)
    end
    render_func[self.mode](self)
end