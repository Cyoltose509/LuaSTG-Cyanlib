---@class STG.Enemy.Boss
---@field Animator STG.Enemy.Boss.Animator
local M = {}
STG.Enemy.Boss = M

require("STG.Enemy.Boss.Animator")
require("STG.Enemy.Boss.Visual")

local Object = STG.Object
local Enemy = STG.Enemy

-- ========================================
-- Spell Card Definition
-- ========================================

---@class STG.Enemy.Boss.SpellCard
---@field name string Spell card name (displayed on UI)
---@field hp number HP threshold for this spell phase
---@field time_limit number Seconds before timeout (nil = no limit)
---@field bonus number Base spell bonus score
---@field onEnter fun(boss:STG.Enemy.Base)|nil Called when spell activates
---@field onUpdate fun(boss:STG.Enemy.Base, dt:number)|nil Called each frame during spell
---@field onTimeout fun(boss:STG.Enemy.Base)|nil Called when spell times out
---@field onCapture fun(boss:STG.Enemy.Base)|nil Called when spell HP is depleted
---@field onExit fun(boss:STG.Enemy.Base)|nil Called when spell ends (both capture and timeout)
---@field dialogue string|nil Spell card announcement text

---Create a new spell card definition.
---@param opt STG.Enemy.Boss.SpellCard
---@return STG.Enemy.Boss.SpellCard
function M.NewSpellCard(opt)
    opt = opt or {}
    return {
        name = opt.name or "",
        hp = opt.hp or 0,
        time_limit = opt.time_limit,
        bonus = opt.bonus or 0,
        onEnter = opt.onEnter,
        onUpdate = opt.onUpdate,
        onTimeout = opt.onTimeout,
        onCapture = opt.onCapture,
        onExit = opt.onExit,
        dialogue = opt.dialogue,
    }
end

-- ========================================
-- Boss Spell Card Manager (Enemy Component)
-- ========================================

---@class STG.Enemy.Boss.SpellManager : STG.Enemy.ComponentBase
local SpellManager = Core.Class(Enemy.ComponentBase)

function SpellManager:init(enemy, system)
    Enemy.ComponentBase.init(self, enemy, system)
    ---@type STG.Enemy.Boss.SpellCard[]
    self.spell_cards = {}
    self.current_spell_index = 0
    self.spell_active = false
    self.spell_timer = 0
    self.spell_hp_remaining = 0
    self.spell_bonus_remaining = 0
    self.is_boss = true
    self.initial_delay = 0  -- frames to wait before first spell
    self.initial_timer = 0
    self.first_spell_started = false
end

---Load spell cards from a list.
---@param cards STG.Enemy.Boss.SpellCard[]
function SpellManager:setSpellCards(cards)
    self.spell_cards = cards or {}
    self.current_spell_index = 0
    self.spell_active = false
end

---Advance to the next spell card. Returns true if a spell was started.
---@return boolean
function SpellManager:nextSpell()
    self.current_spell_index = self.current_spell_index + 1
    if self.current_spell_index > #self.spell_cards then
        self.spell_active = false
        return false
    end
    local card = self.spell_cards[self.current_spell_index]
    if not card then
        return false
    end
    self.spell_active = true
    self.spell_timer = 0
    self.spell_hp_remaining = card.hp
    self.spell_bonus_remaining = card.bonus or 0

    if card.onEnter then
        card.onEnter(self.enemy)
    end
    STG.Event.Fire(STG.Event.Group.BOSS_SPELL_START, self.enemy, card)
    return true
end

---@return STG.Enemy.Boss.SpellCard|nil
function SpellManager:getCurrentSpell()
    if not self.spell_active or self.current_spell_index < 1 then
        return nil
    end
    return self.spell_cards[self.current_spell_index]
end

---@return number progress 0-1
function SpellManager:getSpellProgress()
    local card = self:getCurrentSpell()
    if not card or card.time_limit == nil then
        return 0
    end
    return clamp(self.spell_timer / card.time_limit, 0, 1)
end

---@return number bonus_remaining
function SpellManager:getSpellBonus()
    return self.spell_bonus_remaining
end

function SpellManager:update()
    local dt = 1  -- Component update is frame-based
    if not self.spell_active then
        -- Handle initial delay before first spell
        if not self.first_spell_started then
            self.initial_timer = self.initial_timer + 1
            if self.initial_timer >= self.initial_delay then
                self.first_spell_started = true
                if #self.spell_cards > 0 then
                    self:nextSpell()
                    return
                end
            end
            return
        end
        -- Check if next spell should auto-start based on boss HP
        local health = self.system.health_system
        if health then
            self:checkAutoSpell(health.hp, health.max_hp)
        end
        return
    end
    local card = self:getCurrentSpell()
    if not card then
        return
    end
    self.spell_timer = self.spell_timer + dt

    -- Update bonus decay
    if card.time_limit and card.bonus then
        local progress = self.spell_timer / card.time_limit
        self.spell_bonus_remaining = max(1, card.bonus * (1 - progress))
    end

    if card.onUpdate then
        card.onUpdate(self.enemy, dt)
    end

    -- Check timeout
    if card.time_limit and self.spell_timer >= card.time_limit then
        self:timeoutSpell()
    end
end

function SpellManager:timeoutSpell()
    local card = self:getCurrentSpell()
    if not card then
        return
    end
    if card.onTimeout then
        card.onTimeout(self.enemy)
    end
    if card.onExit then
        card.onExit(self.enemy)
    end
    STG.Event.Fire(STG.Event.Group.BOSS_SPELL_END, self.enemy, card, false)
    self.spell_active = false
    self.spell_bonus_remaining = 0
end

function SpellManager:captureSpell()
    local card = self:getCurrentSpell()
    if not card then
        return
    end
    local bonus = self.spell_bonus_remaining
    if card.onCapture then
        card.onCapture(self.enemy)
    end
    if card.onExit then
        card.onExit(self.enemy)
    end
    STG.Event.Fire(STG.Event.Group.BOSS_SPELL_END, self.enemy, card, true, bonus)
    self.spell_active = false
    self.spell_bonus_remaining = 0
end

---Called when the spell's HP reaches 0 through damage.
function SpellManager:onSpellHPDepleted()
    if self.spell_hp_remaining <= 0 then
        return
    end
    self:captureSpell()
end

---Reduce spell HP by damage. Returns the overflow damage (to main HP).
---@param dmg number
---@return number overflow
function SpellManager:damageSpell(dmg)
    if not self.spell_active then
        return dmg
    end
    if self.spell_hp_remaining <= 0 then
        return dmg
    end
    local overflow = dmg - self.spell_hp_remaining
    self.spell_hp_remaining = max(0, self.spell_hp_remaining - dmg)
    if self.spell_hp_remaining <= 0 then
        self:onSpellHPDepleted()
    end
    return max(0, overflow)
end

---Check if we should start the next spell based on HP.
---@param current_hp number
---@param max_hp number
function SpellManager:checkAutoSpell(current_hp, max_hp)
    if self.spell_active then
        return
    end
    if self.current_spell_index >= #self.spell_cards then
        return
    end
    local next_card = self.spell_cards[self.current_spell_index + 1]
    if not next_card then
        return
    end
    if next_card.hp and current_hp <= max_hp - next_card.hp then
        self:nextSpell()
    end
end

function SpellManager:onDeath()
    if self.spell_active then
        self:timeoutSpell()
    end
end

function SpellManager:getViewData()
    local card = self:getCurrentSpell()
    return {
        is_boss = true,
        spell_active = self.spell_active,
        spell_name = card and card.name or "",
        spell_progress = self:getSpellProgress(),
        spell_bonus = self:getSpellBonus(),
        spell_index = self.current_spell_index,
        spell_total = #self.spell_cards,
    }
end

-- ========================================
-- Boss HP Bar (rendered Object)
-- ========================================

---@param boss STG.Enemy.Base
---@param width number|nil
---@param y_offset number|nil
local function createHPBar(boss, width, y_offset)
    local w = Core.World.GetMain()
    local bar = Object.New(M.HPBarClass)
    bar.boss = boss
    bar.layer = Object.Layer.Top
    bar.group = Object.Group.Ghost
    bar.bound = false
    bar.bar_width = width or 300
    bar.bar_height = 8
    bar.y_offset = y_offset or 40
    bar.x = (w.l + w.r) / 2
    bar.y = w.t - bar.y_offset
    bar.show_timer = 0
    bar.show = 0
    bar.current_show = 0
    return bar
end

local HPBarClass = Object.Define()
M.HPBarClass = HPBarClass

function HPBarClass:init()
    self.bar_width = 300
    self.bar_height = 8
    self.y_offset = 40
    self.show_timer = 0
    self.show = 0
    self.current_show = 0
    self.boss = nil
    self.spell_text = nil
end

function HPBarClass:frame()
    if not Object.IsValid(self.boss) then
        Object.Del(self)
        return
    end
    local vd = self.boss.sys:getViewData()
    local spell_vd = nil
    local spell_comp = self.boss.sys:getComponent("BossSpellManager")
    if spell_comp then
        spell_vd = spell_comp:getViewData()
    end

    local has_spell = spell_vd and spell_vd.spell_active
    self.show_timer = self.show_timer + (self.boss.time:getDelta() or 0)
    if has_spell then
        self.show_timer = 0
        self.show = 1
    end
    if self.show_timer > 3 then
        self.show = max(0, self.show - 0.02)
    end
end

function HPBarClass:render()
    if self.show <= 0 and self.current_show <= 0 then
        return
    end
    self.current_show = Core.Math.ExpInterp(self.current_show, self.show, 0.1)

    local boss = self.boss
    if not Object.IsValid(boss) then
        return
    end
    local vd = boss.sys:getViewData()
    local health_vd = vd.health
    if not health_vd then
        return
    end

    local alpha = 255 * self.current_show
    local cx = self.x
    local cy = self.y
    local bw = self.bar_width
    local bh = self.bar_height
    local ratio = clamp(health_vd.hp / max(1, health_vd.max_hp), 0, 1)

    local Render = Core.Render
    local Draw = Render.Draw

    -- Background
    Draw.SetState(Render.BlendMode.Default, alpha * 0.5, 40, 40, 40)
    Draw.Rect(cx - bw / 2, cx + bw / 2, cy - bh / 2, cy + bh / 2)

    -- HP bar (red → yellow gradient)
    local r, g = 255, 255 * ratio
    Draw.SetState(Render.BlendMode.Default, alpha, r, g, 40)
    Draw.Rect(cx - bw / 2, cx - bw / 2 + bw * ratio, cy - bh / 2, cy + bh / 2)

    -- Border (draw thin rects around edges)
    local b = 1
    Draw.SetState(Render.BlendMode.Default, alpha, 200, 200, 200)
    Draw.Rect(cx - bw / 2 - b, cx - bw / 2, cy - bh / 2 - b, cy + bh / 2 + b)
    Draw.Rect(cx + bw / 2, cx + bw / 2 + b, cy - bh / 2 - b, cy + bh / 2 + b)
    Draw.Rect(cx - bw / 2, cx + bw / 2, cy - bh / 2 - b, cy - bh / 2)
    Draw.Rect(cx - bw / 2, cx + bw / 2, cy + bh / 2, cy + bh / 2 + b)

    -- Spell name
    local spell_comp = boss.sys:getComponent("BossSpellManager")
    if spell_comp then
        local svd = spell_comp:getViewData()
        if svd and svd.spell_active then
            Render.Utils.SimpleTTF("exo2", svd.spell_name, cx, cy + bh, 0.5, Render.Color.ARGB(alpha, 255, 255, 255))
        end
    end
end

-- ========================================
-- Boss Definition & Spawn API
-- ========================================

---@class STG.Enemy.Boss.Definition
---@field profiles STG.Enemy.Profiles.Default
---@field spell_cards STG.Enemy.Boss.SpellCard[]
---@field onInit fun(boss:STG.Enemy.Base, ...)|nil
---@field replace_subsystem table|nil

---Create a boss definition for use with Spawn.
---@param opt STG.Enemy.Boss.Definition
---@return STG.Enemy.Variant
function M.Define(opt)
    opt = opt or {}
    local variant = Enemy.NewVariant()
    variant.name = opt.name or "boss"
    variant.profiles = opt.profiles or Enemy.Profiles.Default
    variant.onInit = opt.onInit
    if opt.replace_subsystem then
        variant.replace_subsystem = opt.replace_subsystem
    end

    -- Add spell manager component
    local spell_cards = opt.spell_cards or {}
    table.insert(variant.components, {
        BossSpellManager = function(enemy, system)
            local mgr = SpellManager(enemy, system)
            mgr:setSpellCards(spell_cards)
            return mgr
        end,
    })

    return variant
end

---Spawn a boss from a definition.
---@param variant STG.Enemy.Variant
---@param x number
---@param y number
---@param ... any Extra args passed to onInit
---@return STG.Enemy.Base
function M.Spawn(variant, x, y, ...)
    local boss = Enemy.SpawnVariant(variant, x, y, ...)
    -- Add boss default visual: swirling "undefined" (BossWalkImageSystem mode=0)
    boss.sys:addComponent("BossVisual", function(enemy, system) return STG.Enemy.Boss.Visual.New(enemy, system) end)
    -- Set initial delay before first spell (wait for boss to move into position)
    local spell_mgr = boss.sys:getComponent("BossSpellManager")
    if spell_mgr then
        spell_mgr.initial_delay = 150  -- ~2.5 seconds at 60fps
    end
    -- Create HP bar
    createHPBar(boss)
    -- Fire event
    STG.Event.Fire(STG.Event.Group.BOSS_SPAWN, boss)
    return boss
end

return M
