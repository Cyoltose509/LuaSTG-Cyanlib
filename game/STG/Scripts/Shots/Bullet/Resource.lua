---@class STG.Shots.Bullet.Resource
local M = {}
STG.Shots.Bullet.Resource = M

---@type STG.Shots.Bullet.TypeBase[]
M.Datas = {}

---@param name string
---@param opt  STG.Shots.Bullet.TypeBase
function M.Register(name, opt)
    if M.Datas[name] then
        error("Bullet Type " .. name .. " already registered!")
    end
    ---@type  STG.Shots.Bullet.TypeBase
    local cls = STG.Object.Define(STG.Shots.Bullet.TypeBase)

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
    M.Datas[name] = cls

    return cls
end