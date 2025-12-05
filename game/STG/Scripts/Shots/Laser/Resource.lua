---@class STG.Shots.Laser.Resource
local M = {}
STG.Shots.Laser.Resource = M

local Texture = Core.Resource.Texture
local Image = Core.Resource.Image

function M.LoadImage(name, path, h, l1, l2, l3)
    local tex = Texture.New(name, path)
    ---@type Core.Resource.Image[]
    local imgs = {}
    Core.Lib.Table.Concat(imgs, Image.NewGroup(name .. 1, tex, 0, 0, l1, h, 1, 16))
    Core.Lib.Table.Concat(imgs, Image.NewGroup(name .. 2, tex, l1, 0, l2, h, 1, 16))
    Core.Lib.Table.Concat(imgs, Image.NewGroup(name .. 3, tex, l1 + l2, 0, l3, h, 1, 16))
    for _, m in ipairs(imgs) do
        m:setCenter(0, h / 2)
    end
end

---@type STG.Shots.Laser.Resource.Data[]
M.Datas = {}

---注册激光的样本类
---Registers a sample class for curve lasers.
---@param name string
---@param opt STG.Shots.Laser.Resource.Data
function M.RegisterData(name, opt)
    ---@class STG.Shots.Laser.Resource.Data
    local data = Core.Class()
    function data:init(master)
        self.node_img = opt.node_img or "stg:laser_preimg" .. master.index ---@type string
        self.head_img = opt.head_img or "stg:ball_mid" .. master.index ---@type string
        self.img1 = opt.img1 or "stg:laser1" .. master.index ---@type string
        self.img2 = opt.img2 or "stg:laser2" .. master.index ---@type string
        self.img3 = opt.img3 or "stg:laser3" .. master.index ---@type string
        self.l1 = opt.l1 or 0
        self.l2 = opt.l2 or 0
        self.l3 = opt.l3 or 0
        self.realW = opt.realW or 10
        self:other_init(master)
        self:frame(master)
    end
    ---@type fun(self:STG.Shots.Laser.Resource.Data, master:STG.Shots.Laser.Base)
    data.other_init = opt.other_init or function()
    end
    ---@type fun(self:STG.Shots.Laser.Resource.Data, master:STG.Shots.Laser.Base)
    data.frame = opt.frame or function()
    end
    M.Datas[name] = data
    table.insert(M.Datas, data)
    return data
end

function M.GetData(name, master)
    return M.Datas[name](master)
end