SynergyCooldown = SynergyCooldown or {}
local SynCool = SynergyCooldown

local synergies = {
    ["Shard/Orb"] = {
        ids = {108799, 108802, 108821, 108924},
        texture = "esoui/art/icons/ability_undaunted_004.dds",
    },
    ["Conduit"] = {
        ids = {108607},
        texture = "esoui/art/icons/ability_sorcerer_liquid_lightning.dds",
    },
    ["Ritual"] = {
        ids = {108824},
        texture = "esoui/art/icons/ability_templar_extended_ritual.dds",
    },
    ["Healing Seed"] = {
        ids = {108826},
        texture = "esoui/art/icons/ability_warden_007.dds",
    },
    ["Bone Shield"] = {
        ids = {108794, 108797},
        texture = "esoui/art/icons/ability_undaunted_005b.dds",
    },
    ["Blood Altar"] = {
        ids = {108782, 108787},
        texture = "esoui/art/icons/ability_undaunted_001_b.dds",
    },
    ["Trapping Webs"] = {
        ids = {108788, 108791, 108792},
        texture = "esoui/art/icons/ability_undaunted_003_b.dds",
    },
    ["Radiate"] = {
        ids = {108793},
        texture = "esoui/art/icons/ability_undaunted_002_b.dds",
    },
    ["Charged Lightning"] = {
        ids = {48085},
        texture = "esoui/art/icons/ability_sorcerer_storm_atronach.dds",
    },
    ["Shackle"] = {
        ids = {108805},
        texture = "esoui/art/icons/ability_dragonknight_006.dds",
    },
    ["Ignite"] = {
        ids = {108807},
        texture = "esoui/art/icons/ability_dragonknight_010.dds",
    },
    ["Gravity Crush"] = {
        ids = {108822, 108823},
        texture = "esoui/art/icons/ability_templar_solar_disturbance.dds",
    },
    ["Hidden Refresh"] = {
        ids = {108808},
        texture = "esoui/art/icons/ability_nightblade_015.dds",
    },
    ["Soul Leech"] = {
        ids = {108814},
        texture = "esoui/art/icons/ability_nightblade_018.dds",
    },
    ["Unnerving Boneyard"] = {
        ids = {125219},
        texture = "esoui/art/icons/ability_necromancer_004.dds",
    },
    ["Agony Totem"] = {
        ids = {125220},
        texture = "esoui/art/icons/ability_necromancer_010_b.dds",
    },
    ["Feeding Frenzy"] = {
        ids = {58775},
        texture = "esoui/art/icons/ability_werewolf_005_b.dds",
    },
    ["Sanguine Burst"] = {
        ids = {142318},
        texture = "esoui/art/icons/ability_u23_bloodball_chokeonit.dds",
    },
}


local isPolling = false

-- Currently unused controls for notifications: {[1] = {name = name, expireTime = 123456132}}
local freeControls = {}

-------------------------------------------------------------------------------
-- Polling to update display
local function UpdateDisplay()
    local currTime = GetGameTimeMilliseconds()
    local numActive = 0
    local numRemoved = 0
    for i, data in pairs(freeControls) do
        if (data and data.expireTime) then
            local millisRemaining = (data.expireTime - currTime)
            local lineControl = SynCoolContainer:GetNamedChild("Line" .. tostring(i))
            if (millisRemaining < 0) then
                -- Hide
                lineControl:SetHidden(true)
                freeControls[i] = false
                numRemoved = numRemoved + 1
            else
                numActive = numActive + 1
                lineControl:GetNamedChild("Timer"):SetText(string.format("%.1f", millisRemaining / 1000))
                lineControl:GetNamedChild("Bar"):SetValue(millisRemaining)
            end
        end
    end

    -- If any were removed, the others must be shifted forward
    -- Probably more efficient way to reassign them but I'm unclear on how to not get mem leaks atm...
    if (numRemoved > 0) then
        for i = 1, numActive do
            -- Transfer the +numRemoved to the current
            freeControls[i] = freeControls[i + numRemoved]
            freeControls[i + numRemoved] = false

            local newControl = SynCoolContainer:GetNamedChild("Line" .. tostring(i))
            local origControl = SynCoolContainer:GetNamedChild("Line" .. tostring(i + numRemoved))
            newControl:GetNamedChild("Icon"):SetTexture(origControl:GetNamedChild("Icon"):GetTextureFileName())
            newControl:GetNamedChild("Label"):SetText(origControl:GetNamedChild("Label"):GetText())
            newControl:GetNamedChild("Timer"):SetText(origControl:GetNamedChild("Timer"):GetText())
            newControl:GetNamedChild("Bar"):SetMinMax(0, 20000)
            newControl:GetNamedChild("Bar"):SetValue(origControl:GetNamedChild("Bar"):GetValue())
            newControl:SetHidden(false)
            origControl:SetHidden(true)
        end
    end

    -- Stop polling
    if (numActive == 0) then
        EVENT_MANAGER:UnregisterForUpdate(SynCool.name .. "Poll")
        isPolling = false
    end
end


-------------------------------------------------------------------------------
-- Find a free control to use
local function FindOrCreateControl()
    for i, data in pairs(freeControls) do
        if (data == false) then
            return i
        end
    end

    -- Else, make a new control
    local index = #freeControls + 1
    local lineControl = CreateControlFromVirtual(
        "$(parent)Line" .. tostring(index),     -- name
        SynCoolContainer,                       -- parent
        "SynCool_Line_Template",                -- template
        "")                                     -- suffix
    lineControl:SetAnchor(CENTER, SynCoolContainer, CENTER, 0, -44 * (index - 1))

    return index
end


-------------------------------------------------------------------------------
-- When a synergy is activated, add it to the display
local function OnSynergyActivated(name)
    SynCool.dbg("Activated " .. name)

    local index = FindOrCreateControl()
    freeControls[index] = {name = name, expireTime = GetGameTimeMilliseconds() + 20000}

    local lineControl = SynCoolContainer:GetNamedChild("Line" .. tostring(index))
    lineControl:GetNamedChild("Icon"):SetTexture(synergies[name].texture)
    lineControl:GetNamedChild("Label"):SetText(name)
    lineControl:GetNamedChild("Timer"):SetText("20.0")
    lineControl:GetNamedChild("Bar"):SetMinMax(0, 20000)
    lineControl:GetNamedChild("Bar"):SetValue(20000)
    lineControl:SetHidden(false)

    if (not isPolling) then
        EVENT_MANAGER:RegisterForUpdate(SynCool.name .. "Poll", 100, UpdateDisplay)
        isPolling = true
    end
end


-------------------------------------------------------------------------------
-- When a synergy is activated, add it to the display
function SynCool:InitializeCore()
    for name, data in pairs(synergies) do
        local function OnCombatEvent(_, _, _, _, _, _, _, _, _, _, hitValue)
            if (hitValue == 1) then
                OnSynergyActivated(name)
            end
        end
        for _, id in ipairs(data.ids) do
            EVENT_MANAGER:RegisterForEvent(SynCool.name .. tostring(id), EVENT_COMBAT_EVENT, OnCombatEvent)
            EVENT_MANAGER:AddFilterForEvent(SynCool.name .. tostring(id), EVENT_COMBAT_EVENT, REGISTER_FILTER_COMBAT_RESULT, ACTION_RESULT_EFFECT_GAINED)
            EVENT_MANAGER:AddFilterForEvent(SynCool.name .. tostring(id), EVENT_COMBAT_EVENT, REGISTER_FILTER_TARGET_COMBAT_UNIT_TYPE, COMBAT_UNIT_TYPE_PLAYER)
            EVENT_MANAGER:AddFilterForEvent(SynCool.name .. tostring(id), EVENT_COMBAT_EVENT, REGISTER_FILTER_ABILITY_ID, id)
        end
    end
end
