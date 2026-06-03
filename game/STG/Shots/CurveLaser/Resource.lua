---@class STG.Shots.CurveLaser.Resource
local M = {}
STG.Shots.CurveLaser.Resource = M

---@type STG.Shots.CurveLaser.Resource.Data[]
M.Datas = {}

---注册曲线激光的样本类
---Registers a sample class for curve lasers.
---@param name string
---@param opt STG.Shots.CurveLaser.Resource.Data
function M.Register(name, opt)
    ---@class STG.Shots.CurveLaser.Resource.Data
    local data = Core.Class()
    function data:init(master)
        self.node_img = opt.node_img or "stg:laser_fog" .. master.index ---@type string
        self.tex = opt.tex ---@type string
        self.x = opt.x or 0 ---采样x坐标
        self.y = opt.y or 0 ---采样y坐标
        self.w = opt.w or 0 ---采样宽度
        self.h = opt.h or 0 ---采样高度
        self.wRatio = opt.wRatio or 1 ---采样纹理宽度缩放比例
        self:other_init(master)
        self:frame(master)
    end
    ---@type fun(self:STG.Shots.CurveLaser.Resource.Data, master:STG.Shots.CurveLaser.Base)
    data.other_init = opt.other_init or function()
    end
    ---@type fun(self:STG.Shots.CurveLaser.Resource.Data, master:STG.Shots.CurveLaser.Base)
    data.frame = opt.frame or function()
    end
    M.Datas[name] = data
    table.insert(M.Datas, data)
    return data
end

function M.GetData(name, master)
    return M.Datas[name](master)
end