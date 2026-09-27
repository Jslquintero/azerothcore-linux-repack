local shadowmeldID = 20580
local pendingCombatCast = false
local events = CreateFrame("Frame")

local function IsCombatCooldown()
    local name = GetSpellInfo(shadowmeldID)
    if not name then
        return false
    end

    -- During the aura the cooldown is disabled; remember combat at cast time.
    if UnitBuff("player", name) then
        return AcoreShadowmeldCombatCast == true
    end

    -- After the aura ends (including after relogging), trust the server's cooldown.
    local start, duration, enabled = GetSpellCooldown(shadowmeldID)
    return enabled == 1 and start and duration and duration > 10 and start + duration > GetTime()
end

local function UpdateTooltip(tooltip)
    local name, _, spellID = tooltip:GetSpell()
    if spellID ~= shadowmeldID and (spellID or name ~= GetSpellInfo(shadowmeldID)) then
        return
    end

    local normalText = string.format(SPELL_RECAST_TIME_SEC, 10)
    local combatText = string.format(SPELL_RECAST_TIME_MIN, 2)
    local replacement = IsCombatCooldown() and combatText or normalText
    local prefix = tooltip:GetName()
    if not prefix then
        return
    end

    -- Replace only the base cooldown heading, preserving description and remaining time.
    for line = 1, tooltip:NumLines() do
        for _, side in ipairs({"Left", "Right"}) do
            local text = _G[prefix .. "Text" .. side .. line]
            if text then
                local value = text:GetText()
                if value == normalText or value == combatText then
                    text:SetText(replacement)
                end
            end
        end
    end
end

for _, event in ipairs({"UNIT_SPELLCAST_SENT", "UNIT_SPELLCAST_SUCCEEDED"}) do
    events:RegisterEvent(event)
end

events:SetScript("OnEvent", function(_, event, unit, spellName)
    if unit ~= "player" or spellName ~= GetSpellInfo(shadowmeldID) then
        return
    end

    if event == "UNIT_SPELLCAST_SENT" then
        -- Sanctuary can end combat before SPELLCAST_SUCCEEDED reaches the UI.
        pendingCombatCast = not not UnitAffectingCombat("player")
    else
        AcoreShadowmeldCombatCast = pendingCombatCast
    end
end)

GameTooltip:HookScript("OnTooltipSetSpell", UpdateTooltip)
local elapsedSinceUpdate = 0
GameTooltip:HookScript("OnUpdate", function(tooltip, elapsed)
    elapsedSinceUpdate = elapsedSinceUpdate + elapsed
    if elapsedSinceUpdate >= 0.1 then
        elapsedSinceUpdate = 0
        UpdateTooltip(tooltip)
    end
end)
