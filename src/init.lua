SynergyCooldown = SynergyCooldown or {}
local SynCool = SynergyCooldown
SynCool.name = "SynergyCooldown"
SynCool.version = "0.0.1"

local defaultOptions = {
    display = {
        x = GuiRoot:GetWidth() / 5,
        y = 0,
    },
}

---------------------------------------------------------------------
-- Collect messages for displaying later when addon is not fully loaded
SynCool.messages = {}
function SynCool.dbg(msg)
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
    SynCool.dbg("Initializing...")
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
