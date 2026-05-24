---@class Core.Lib.Accessor
local M = Core.Class()
Core.Lib.Accessor = M

function M:init()
    self.fields = {}
    self.root = _G
    self.path = ""
    self.auto_create = true---自动扩建
end
function M:enableAutoCreate(flag)
    self.auto_create = flag
    return self
end
---@param root table
function M:setRoot(root)
    self.root = root or _G
    return self
end
---@param path string
function M:setPath(path)
    self.path = path
    local fields = {}

    for part in path:gmatch("[^%.]+") do
        local key = part:match("^[^%[]+")
        if key then
            fields[#fields + 1] = key
        end
        for index in part:gmatch("%[(.-)%]") do
            local num = tonumber(index)
            if num then
                fields[#fields + 1] = num
            else
                -- 支持 ["xxx"]
                fields[#fields + 1] = index:gsub("^['\"](.-)['\"]$", "%1")
            end
        end
    end
    self.fields = fields
    return self
end
function M:get()
    local obj = self.root
    for i = 1, #self.fields do
        if obj == nil then
            return nil
        end
        obj = obj[self.fields[i]]
    end
    return obj
end

function M:set(value)
    local len = #self.fields
    if len > 0 then
        local obj = self.root
        for i = 1, len - 1 do
            local key = self.fields[i]
            local nextO = obj[key]
            if nextO == nil then
                if self.auto_create then
                    nextO = {}
                    obj[key] = nextO
                else
                    error("Attempt to index a nil value (field '" .. key .. "'")
                end
            elseif type(nextO) ~= "table" then
                error(("Accessor path conflict at '%s' (not a table)"):format(key))
            end
            obj = nextO
        end
        obj[self.fields[len]] = value
    else
        self.root = value
    end
    return self
end

function M.New(root, path)
    local accessor = M()
    accessor:setRoot(root)
    accessor:setPath(path)
    return accessor
end