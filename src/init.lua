SynergyCooldown = SynergyCooldown or {}
local SynCool = SynergyCooldown
SynCool.name = "SynergyCooldown"
SynCool.version = "0.1.0"

local defaultOptions = {
    display = {
        x = GuiRoot:GetWidth() / 5,
        y = 0,
        growth = "up", -- "down"
    },
    debug = false,
}

---------------------------------------------------------------------
-- Collect messages for displaying later when addon is not fully loaded
SynCool.messages = {}
function SynCool.dbg(msg)
    if (not SynCool.savedOptions.debug) then return end
    if (not msg) then return end
    if (CHAT_SYSTEM.primaryContainer) then
        d("|c66FF66[SC]|r " .. tostring(msg))
    else
        SynCool.messages[#SynCool.messages + 1] = msg
    end
end

---------------------------------------------------------------------
-- Save position after moving
function SynCool:SavePosition()
    local x, y = SynCoolContainer:GetCenter()
    local oX, oY = GuiRoot:GetCenter()
    -- x is the offset from the center
    SynCool.savedOptions.display.x = x - oX
    SynCool.savedOptions.display.y = y - oY
end

---------------------------------------------------------------------
-- Post Load (player loaded)
local function OnPlayerActivated(_, initial)
    -- Soft dependency on pChat because its chat restore will overwrite
    for i = 1, #SynCool.messages do
        d("|c66FF66[SCdelay]|r " .. SynCool.messages[i])
    end
    SynCool.messages = {}
end

---------------------------------------------------------------------
-- Initialize
local function Initialize()
    SynCool.savedOptions = ZO_SavedVars:NewAccountWide("SynergyCooldownSavedVariables", 1, "Options", defaultOptions)
    -- TODO: create settings menu

    SynCoolContainer:SetAnchor(CENTER, GuiRoot, CENTER, SynCool.savedOptions.display.x, SynCool.savedOptions.display.y)

    SLASH_COMMANDS["/scunlock"] = function()
        SynCoolContainer:SetMouseEnabled(true)
        SynCoolContainer:SetMovable(true)
        SynCoolContainerBackdrop:SetHidden(false)
    end

    SLASH_COMMANDS["/sclock"] = function()
        SynCoolContainer:SetMouseEnabled(false)
        SynCoolContainer:SetMovable(false)
        SynCoolContainerBackdrop:SetHidden(true)
    end

    SLASH_COMMANDS["/scgrowth"] = function(arg)
        if (arg ~= "up" and arg ~= "down") then
            d("Usage: /scgrowth up OR /scgrowth down")
            return
        end
        SynCool.savedOptions.display.growth = arg
        SynCool.ReAnchor()
    end

    SLASH_COMMANDS["/sctest"] = function()
        local toActivate = {"Shard/Orb", "Blood Altar", "Ritual", "Conduit"}
        for i, name in ipairs(toActivate) do
            EVENT_MANAGER:RegisterForUpdate(SynCool.name .. "Test" .. name, (i - 1) * 1000, function()
                    SynCool.OnSynergyActivated(name)
                    EVENT_MANAGER:UnregisterForUpdate(SynCool.name .. "Test" .. name)
                end)
        end
    end

    SynCool:InitializeCore()
    EVENT_MANAGER:RegisterForEvent(SynCool.name, EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
end

---------------------------------------------------------------------
-- On load
local function OnAddOnLoaded(_, addonName)
    if (addonName == SynCool.name) then
        EVENT_MANAGER:UnregisterForEvent(SynCool.name, EVENT_ADD_ON_LOADED)
        Initialize()
    end
end

EVENT_MANAGER:RegisterForEvent(SynCool.name, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
