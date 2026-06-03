
local function classCreate(instance, class, ...)
    local ctor = rawget(class, "init")
    if ctor then
        ctor(instance, ...)
    else
        local super = rawget(class, "super")
        if super then
            classCreate(instance, super, ...)
        end
    end
end

---声明一个类
---@generic T
---@param base T 基类
---@return T
function Core.Class(base)
    local class = { _mbc = {}, super = base }

    local function new(t, ...)
        local instance = {}
        local meta = {
            __index = t,
            __tostring = class.__tostring,
            __add = class.__add,
            __sub = class.__sub,
            __mul = class.__mul,
            __div = class.__div,
            __mod = class.__mod,
            __pow = class.__pow,
            __unm = class.__unm,
            __len = class.__len,
            __concat = class.__concat,
            __call = class.__call,
            __eq = class.__eq,
            __lt = class.__lt,
            __le = class.__le,
        }
        setmetatable(instance, meta)
        classCreate(instance, t, ...)
        return instance
    end

    local function indexer(t, k)
        local member = t._mbc[k]
        if member == nil then
            if base then
                member = base[k]
                t._mbc[k] = member
            end
        end
        return member
    end
    local meta = {
        __call = new,
        __index = indexer
    }
    setmetatable(class, meta)

    return class
end