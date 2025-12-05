---@class STG.Shots.Laser.Collider
---@author OLC
local M = {}
STG.Shots.Laser.Collider = M

local Object = Core.Object
local AttributeProxy = Object.AttributeProxy


---@class STG.Laser.Collider.Base
local Base = Object.Define()
M.Base = Base
function Base:del()
    if self.on_del and Object.IsValid(self.master) then
        self.on_del(self.master, self, self.args)
    end
end

function Base:kill()
    if self.on_kill and Object.IsValid(self.master) then
        self.on_kill(self.master, self, self.args)
    end
end
--region Attribute Proxies
local attribute_proxies = {}
Base.___attribute_proxies = attribute_proxies

--region ___killed
local proxy_killed = AttributeProxy.Create("___killed")
attribute_proxies["___killed"] = proxy_killed

function proxy_killed:setter(key, value, storage)
    local old_value = storage[key]
    if value == old_value then
        return
    end
    storage[key] = value
    if Object.IsValid(self.master) then
        Object.SetAttr(self, "colli", self.master.colli and not value)
    else
        Object.SetAttr(self, "colli", false)
    end
end

--endregion

--region _graze
local proxy_graze = AttributeProxy.Create("_graze")
attribute_proxies["_graze"] = proxy_graze

function proxy_graze:getter(key, storage)
    if Object.IsValid(self.master) then
        return self.master._graze
    end
end

function proxy_graze:setter(key, value, storage)
    if Object.IsValid(self.master) then
        self.master._graze = value
    end
end

--endregion

--region colli
local proxy_colli = AttributeProxy.Create("colli")
attribute_proxies["colli"] = proxy_colli

function proxy_colli:getter(key, storage)
    if Object.IsValid(self.master) then
        return self.master.colli and not self.___killed
    end
end

function proxy_colli:setter(key, value, storage)
    if Object.IsValid(self.master) then
        Object.SetAttr(self, "colli", self.master.colli and value and not self.___killed)
    else
        Object.SetAttr(self, "colli", false)
    end
end

--endregion

--region bound
local proxy_bound = AttributeProxy.Create("bound")
attribute_proxies["bound"] = proxy_bound

function proxy_bound:init()
    Object.SetAttr(self, "bound", false)
end

function proxy_bound:getter(key, storage)
    if Object.IsValid(self.master) then
        return self.master.bound
    end
end

function proxy_bound:setter(key, value, storage)
    if Object.IsValid(self.master) then
        self.master.bound = value
    else
        Object.SetAttr(self, "bound", true)
    end
end

--endregion
--endregion

---@param master lstg.GameObject @Master object
---@param group number @Collider group
---@param args table<string, any> @Arguments
---@param on_del fun(master: lstg.GameObject, self: STG.Laser.Collider.Base, args: table<string, any>) @On Del callback
---@param on_kill fun(master: lstg.GameObject, self: STG.Laser.Collider.Base, args: table<string, any>) @On Kill callback
function M.Create(master, group, args, on_del, on_kill)
    local self = Object.New(Base)
    self.group = group or Object.Group.EnemyBullet    --- Collider group
    self.layer = Object.Layer.EnemyBullet             --- Collider layer
    self.rect = true                            --- Use rectangle collider
    self.hide = true                            --- Collider do not render
    self.master = master                        --- Master object
    self.args = args                            --- Arguments
    self.on_del = on_del                        --- On Del callback
    self.on_kill = on_kill                      --- On Kill callback
    AttributeProxy.Apply(self, Base.___attribute_proxies)
    return self
end

