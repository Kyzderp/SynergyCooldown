SynergyCooldown = SynergyCooldown or {}
local SynCool = SynergyCooldown

SynCool.SYNERGIES = {
    ["Shard/Orb"] = {
        -- ids = {108799, 108802, 108821, 108924},
        ids = {
            94973, -- Trial dummy / Blessed Shards (Spear Shards)
            95926, -- Holy Shards (Luminous Shards)
            95040, -- Combustion
            95042, -- Healing Combustion
        },
        texture = "esoui/art/icons/ability_undaunted_004.dds",
    },
    ["Conduit"] = {
        -- ids = {108607},
        ids = {43769},
        texture = "esoui/art/icons/ability_sorcerer_liquid_lightning.dds",
    },
    ["Ritual"] = {
        -- ids = {108824},
        ids = {22270},
        texture = "esoui/art/icons/ability_templar_extended_ritual.dds",
    },
    ["Healing Seed"] = {
        -- ids = {108826},
        ids = {85576},
        texture = "esoui/art/icons/ability_warden_007.dds",
    },
    ["Bone Shield"] = {
        -- ids = {108794, 108797},
        ids = {
            39424, -- Bone Wall (Bone Shield)
            42196, -- Spinal Surge (Bone Surge)
        },
        texture = "esoui/art/icons/ability_undaunted_005b.dds",
    },
    ["Blood Altar"] = {
        -- ids = {108782, 108787},
        ids = {
            39519, -- Blood Funnel (Blood Altar)
            41965, -- Blood Feast (Overflowing Altar)
        },
        texture = "esoui/art/icons/ability_undaunted_001_b.dds",
    },
    ["Spooder"] = {
        -- ids = {108788, 108791, 108792},
        ids = {
            39451, -- Spawn Broodling (Trapping Web)
            41997, -- Black Widow (Shadow Silk)
            42019, -- Arachnophobia (Tangling Web)
        },
        texture = "esoui/art/icons/ability_undaunted_003_b.dds",
    },
    ["Radiate"] = {
        -- ids = {108793},
        ids = {41840},
        texture = "esoui/art/icons/ability_undaunted_002_b.dds",
    },
    ["Charged Lightning"] = {
        ids = {48085}, -- Unchanged with SoF
        texture = "esoui/art/icons/ability_sorcerer_storm_atronach.dds",
    },
    ["Shackle"] = {
        -- ids = {108805},
        ids = {67717},
        texture = "esoui/art/icons/ability_dragonknight_006.dds",
    },
    ["Ignite"] = {
        -- ids = {108807},
        ids = {48040},
        texture = "esoui/art/icons/ability_dragonknight_010.dds",
    },
    ["Nova"] = {
        -- ids = {108822, 108823},
        ids = {
            48938, -- Gravity Crush
            48939, -- Supernova
        },
        texture = "esoui/art/icons/ability_templar_solar_disturbance.dds",
    },
    ["Hidden Refresh"] = {
        -- ids = {108808},
        ids = {37729},
        texture = "esoui/art/icons/ability_nightblade_015.dds",
    },
    ["Soul Leech"] = {
        -- ids = {108814},
        ids = {25172},
        texture = "esoui/art/icons/ability_nightblade_018.dds",
    },
    ["Grave Robber"] = {
        -- ids = {125219},
        ids = {115567},
        texture = "esoui/art/icons/ability_necromancer_004.dds",
    },
    ["Pure Agony"] = {
        -- ids = {125220},
        ids = {118610},
        texture = "esoui/art/icons/ability_necromancer_010_b.dds",
    },
    ["Feeding Frenzy"] = {
        -- ids = {58775},
        ids = {58813},
        texture = "esoui/art/icons/ability_werewolf_005_b.dds",
    },
    ["Lady Thorn"] = {
        -- ids = {142318},
        ids = {141971},
        texture = "esoui/art/icons/ability_u23_bloodball_chokeonit.dds",
    },
    ["Icy Escape"] = {
        ids = {88892}, -- Unchanged with SoF
        texture = "esoui/art/icons/ability_warden_005_b.dds",
    },
    ["Gryphon's Reprisal"] = {
        -- ids = {167046},
        ids = {167042},
        texture = "esoui/art/icons/achievement_trial_cr_flavor_3.dds",
    },
}


local isPolling = false

-- Currently used controls for notifications: {[1] = {name = name, expireTime = 123456132}}
local freeControls = {}

-------------------------------------------------------------------------------
-- Reanchor all controls, used when growth direction changes
function SynCool.ReAnchor()
    for i, data in pairs(freeControls) do
        local lineControl = SynCoolContainer:GetNamedChild("Line" .. tostring(i))

        if (SynCool.savedOptions.display.growth == "up") then
            lineControl:SetAnchor(CENTER, SynCoolContainer, CENTER, 0, -44 * (i - 1))
        elseif (SynCool.savedOptions.display.growth == "down") then
            lineControl:SetAnchor(CENTER, SynCoolContainer, CENTER, 0, 44 * (i - 1))
        end
    end
    SynCool.ReAnchorOthers()
end

-------------------------------------------------------------------------------
-- Polling to update display
local function UpdateDisplay()
    local currTime = GetGameTimeMilliseconds()
    local numActive = 0
    local numAfterOffset = 0
    local numRemoved = 0
    local offset = -1
    for i, data in pairs(freeControls) do
        if (data and data.expireTime) then
            local millisRemaining = (data.expireTime - currTime)
            local lineControl = SynCoolContainer:GetNamedChild("Line" .. tostring(i))
            if (millisRemaining < 0) then
                -- Hide
                lineControl:SetHidden(true)
                freeControls[i] = false
                numRemoved = numRemoved + 1
                if (offset == -1) then
                    offset = i - 1
                end
            else
                lineControl:GetNamedChild("Timer"):SetText(string.format("%.1f", millisRemaining / 1000))
                lineControl:GetNamedChild("Bar"):SetValue(millisRemaining)
                numActive = numActive + 1
                if (offset > -1) then
                    numAfterOffset = numAfterOffset + 1
                end
            end
        end
    end

    -- THE ONE THAT'S REMOVED IS NOT GUARANTEED TO BE THE TOPMOST!!
    -- This can happen if topmost get refreshed before the timer ends due to bugginess

    -- If any were removed, the others must be shifted forward
    -- Probably more efficient way to reassign them but I'm unclear on how to not get mem leaks atm...
    if (numRemoved > 0) then
        for i = 1, numAfterOffset do
            -- Transfer the +numRemoved to the current
            freeControls[offset + i] = freeControls[offset + i + numRemoved]
            freeControls[offset + i + numRemoved] = false

            local newControl = SynCoolContainer:GetNamedChild("Line" .. tostring(offset + i))
            local origControl = SynCoolContainer:GetNamedChild("Line" .. tostring(offset + i + numRemoved))
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
local function FindOrCreateControl(name)
    -- Do a first pass to check if there's already one being displayed for this name
    for i, data in pairs(freeControls) do
        if (data and data.name == name) then
            return i
        end
    end

    -- No existing one of the same name
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

    if (SynCool.savedOptions.display.growth == "up") then
        lineControl:SetAnchor(CENTER, SynCoolContainer, CENTER, 0, -44 * (index - 1))
    else
        lineControl:SetAnchor(CENTER, SynCoolContainer, CENTER, 0, 44 * (index - 1))
    end

    return index
end


-------------------------------------------------------------------------------
-- When a synergy is activated, add it to the display
local function OnSynergyActivated(name)
    -- SynCool.dbg("Activated " .. name)

    local index = FindOrCreateControl(name)
    freeControls[index] = {name = name, expireTime = GetGameTimeMilliseconds() + 20000}

    local lineControl = SynCoolContainer:GetNamedChild("Line" .. tostring(index))
    lineControl:GetNamedChild("Icon"):SetTexture(SynCool.SYNERGIES[name].texture)
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
SynCool.OnSynergyActivated = OnSynergyActivated


-------------------------------------------------------------------------------
-- When a synergy is activated, add it to the display
function SynCool:InitializeCore()
    for name, data in pairs(SynCool.SYNERGIES) do
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
    SynCool:InitializeOthers()
end
