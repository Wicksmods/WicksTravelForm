-- Wick's Travel Form
-- Core.lua — form decision logic, macro builder, event dispatch

local ADDON, ns = ...
_G.WICKSTRAVELFORM = ns
ns.version = "0.2.0"

local DEFAULTS = {
    point = "CENTER", relativePoint = "CENTER", x = 0, y = -120,
    locked = true,
    size = 48,
}

ns.MIN_SIZE, ns.MAX_SIZE = 32, 96

-- =====================================================================
-- Druid forms (enUS spell names — used directly in macro text)
-- =====================================================================
ns.FORMS = {
    AQUATIC = "Aquatic Form",
    TRAVEL  = "Travel Form",
    CAT     = "Cat Form",
    FLIGHT  = "Flight Form",
    SWIFT   = "Swift Flight Form",
}

local FORM_SPELL_ID = {
    [ns.FORMS.AQUATIC] = 1066,
    [ns.FORMS.TRAVEL]  = 783,
    [ns.FORMS.CAT]     = 768,
    [ns.FORMS.FLIGHT]  = 33943,
    [ns.FORMS.SWIFT]   = 40120,
}

function ns.formIcon(name)
    local _, _, icon = GetSpellInfo(FORM_SPELL_ID[name] or 0)
    return icon
end

-- =====================================================================
-- IsFlyableArea() reports incorrectly for Azeroth zones in TBC, so we
-- maintain our own whitelist. enUS-only for now.
-- =====================================================================
local FLYABLE_ZONES = {
    ["Hellfire Peninsula"]     = true,
    ["Zangarmarsh"]            = true,
    ["Terokkar Forest"]        = true,
    ["Nagrand"]                = true,
    ["Blade's Edge Mountains"] = true,
    ["Netherstorm"]            = true,
    ["Shadowmoon Valley"]      = true,
    ["Isle of Quel'Danas"]     = true,
}

function ns.isFlyableZone()
    local zone = GetRealZoneText()
    return zone and FLYABLE_ZONES[zone] == true
end

-- =====================================================================
-- Cached best flight form. Refreshed on SPELLS_CHANGED so we don't scan
-- the spellbook every press.
-- =====================================================================
local cachedFlightForm = nil

local function scanFlightForm()
    local best = nil
    for tab = 1, GetNumSpellTabs() do
        local _, _, offset, num = GetSpellTabInfo(tab)
        for i = offset + 1, offset + num do
            local n = GetSpellBookItemName(i, BOOKTYPE_SPELL or "spell")
            if n == ns.FORMS.SWIFT then return ns.FORMS.SWIFT end
            if n == ns.FORMS.FLIGHT then best = ns.FORMS.FLIGHT end
        end
    end
    return best
end

function ns.bestFlightForm()
    return cachedFlightForm
end

-- =====================================================================
-- Predict which form a press will resolve to (used for the icon preview
-- and tooltip — the actual cast resolution is done by the macro itself).
-- =====================================================================
function ns.predictForm()
    if IsSwimming() then return ns.FORMS.AQUATIC end
    if IsOutdoors() then
        local fly = ns.bestFlightForm()
        if fly and ns.isFlyableZone() and not InCombatLockdown() then
            return fly
        end
        return ns.FORMS.TRAVEL
    end
    return ns.FORMS.CAT
end

function ns.isFlying()
    -- GetShapeshiftForm returns the index of the current form (1-based).
    -- We match it against the flight form spell IDs to detect airborne state.
    local formIndex = GetShapeshiftForm()
    if formIndex == 0 then return false end
    local _, _, _, spellId = GetShapeshiftFormInfo(formIndex)
    return spellId == 33943 or spellId == 40120  -- Flight Form / Swift Flight Form
end

-- =====================================================================
-- Build the macrotext. The macro itself runs the swim / outdoors /
-- combat conditional checks at click time — those are cheap and always
-- correct. Lua only decides whether to inject the flight clause based
-- on zone + spellbook (rare events), so we don't need any polling.
-- =====================================================================
function ns.buildMacro()
    -- While airborne, the button is cancel-only. Combining /cancelform with a
    -- /cast on the same click powershifts back into flight immediately.
    if ns.isFlying() then
        return "/cancelform"
    end
    local clauses = { "[swimming] !" .. ns.FORMS.AQUATIC }
    local fly = ns.bestFlightForm()
    if fly then
        table.insert(clauses, ("[nocombat,outdoors] !%s"):format(fly))
    end
    table.insert(clauses, "[outdoors] !" .. ns.FORMS.TRAVEL)
    table.insert(clauses, "!" .. ns.FORMS.CAT)
    return "/cast " .. table.concat(clauses, "; ")
end

-- =====================================================================
-- Event dispatcher
-- =====================================================================
local events = {}
function ns:On(event, fn)
    events[event] = events[event] or {}
    table.insert(events[event], fn)
end

local frame = CreateFrame("Frame", "WicksTravelFormEvents")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function(_, event, ...)
    if events[event] then
        for _, fn in ipairs(events[event]) do fn(...) end
    end
end)

-- =====================================================================
-- ADDON_LOADED — SavedVariables init (DB isn't readable before this).
-- =====================================================================
ns:On("ADDON_LOADED", function(loaded)
    if loaded ~= ADDON then return end
    WicksTravelFormDB = WicksTravelFormDB or {}
    for k, v in pairs(DEFAULTS) do
        if WicksTravelFormDB[k] == nil then WicksTravelFormDB[k] = v end
    end
end)

-- =====================================================================
-- One-time setup — runs at the first PLAYER_LOGIN OR PLAYER_ENTERING_WORLD
-- to handle both fresh-login and /reload cases. Class check, event
-- registration, spellbook scan, UI activation.
-- =====================================================================
local inited = false
local function initIfNeeded()
    if inited then return end
    inited = true
    local _, class = UnitClass("player")
    if class ~= "DRUID" then
        if ns.UI and ns.UI.Deactivate then ns.UI:Deactivate() end
        return
    end

    for _, ev in ipairs({
        "ZONE_CHANGED_NEW_AREA",
        "ZONE_CHANGED_INDOORS",
        "ZONE_CHANGED",
        "PLAYER_REGEN_DISABLED",
        "PLAYER_REGEN_ENABLED",
        "UPDATE_SHAPESHIFT_FORM",
        "SPELLS_CHANGED",
        "UPDATE_BINDINGS",
    }) do frame:RegisterEvent(ev) end

    cachedFlightForm = scanFlightForm()
    if ns.UI and ns.UI.Activate then ns.UI:Activate() end
end

ns:On("PLAYER_LOGIN", initIfNeeded)
ns:On("PLAYER_ENTERING_WORLD", function()
    initIfNeeded()
    if ns.UI and ns.UI.Refresh then ns.UI:Refresh() end
end)

local function refresh() if ns.UI and ns.UI.Refresh then ns.UI:Refresh() end end

ns:On("SPELLS_CHANGED",        function() cachedFlightForm = scanFlightForm(); refresh() end)
ns:On("ZONE_CHANGED_NEW_AREA", refresh)
ns:On("ZONE_CHANGED_INDOORS",  refresh)
ns:On("ZONE_CHANGED",          refresh)
ns:On("PLAYER_REGEN_DISABLED", refresh)
ns:On("PLAYER_REGEN_ENABLED",  refresh)
ns:On("UPDATE_SHAPESHIFT_FORM", refresh)
ns:On("UPDATE_BINDINGS",       function() if ns.UI and ns.UI.UpdateBindLabel then ns.UI:UpdateBindLabel() end end)

-- =====================================================================
-- Slash command
-- =====================================================================
SLASH_WICKSTRAVELFORM1 = "/wstf"
SLASH_WICKSTRAVELFORM2 = "/wtravel"
SlashCmdList["WICKSTRAVELFORM"] = function(msg)
    msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    local _, class = UnitClass("player")
    if class ~= "DRUID" then
        print("|cff8a5cf6Wick's Travel Form|r: druids only.")
        return
    end
    if msg == "unlock" or msg == "move" then
        if ns.UI then ns.UI:SetLocked(false) end
        return
    elseif msg == "lock" then
        if ns.UI then ns.UI:SetLocked(true) end
        return
    elseif msg == "reset" then
        WicksTravelFormDB.point, WicksTravelFormDB.relativePoint = "CENTER", "CENTER"
        WicksTravelFormDB.x, WicksTravelFormDB.y = 0, -120
        WicksTravelFormDB.size = 48
        if ns.UI then
            if ns.UI.ApplyPosition then ns.UI:ApplyPosition() end
            if ns.UI.ApplySize then ns.UI:ApplySize() end
        end
        return
    elseif msg:match("^size") then
        local arg = msg:match("^size%s+(%S+)")
        if not arg then
            print(("|cff8a5cf6Wick's Travel Form|r: current size %d. Use /wstf size <%d-%d>."):format(
                WicksTravelFormDB.size or 48, ns.MIN_SIZE, ns.MAX_SIZE))
            return
        end
        local n = tonumber(arg)
        if not n then
            print("|cff8a5cf6Wick's Travel Form|r: size must be a number.")
            return
        end
        if n < ns.MIN_SIZE then n = ns.MIN_SIZE end
        if n > ns.MAX_SIZE then n = ns.MAX_SIZE end
        WicksTravelFormDB.size = n
        if ns.UI and ns.UI.ApplySize then ns.UI:ApplySize() end
        return
    elseif msg == "debug" then
        local zone = GetRealZoneText() or "?"
        print("|cff8a5cf6Wick's Travel Form|r debug:")
        print(("  zone: %s   flyable-zone: %s"):format(zone, tostring(ns.isFlyableZone())))
        print(("  best flight form: %s"):format(tostring(ns.bestFlightForm())))
        print(("  swimming: %s   outdoors: %s   combat: %s"):format(
            tostring(IsSwimming()), tostring(IsOutdoors()), tostring(InCombatLockdown())))
        print(("  predicted form: %s"):format(ns.predictForm()))
        print(("  macro: %s"):format(ns.buildMacro()))
        print(("  ns.UI: %s   button: %s"):format(
            tostring(ns.UI), tostring(_G.WicksTravelFormButton)))
        local h = _G.WicksTravelFormHost
        local b = _G.WicksTravelFormButton
        if h then
            local p, _, rp, x, y = h:GetPoint(1)
            print(("  host shown: %s   pos: %s/%s @ %s,%s   size: %sx%s   db.size: %s"):format(
                tostring(h:IsShown()), tostring(p), tostring(rp), tostring(x), tostring(y),
                tostring(h:GetWidth()), tostring(h:GetHeight()),
                tostring(WicksTravelFormDB and WicksTravelFormDB.size)))
        end
        if b then
            print(("  button shown: %s   visible: %s   macrotext1: %s"):format(
                tostring(b:IsShown()), tostring(b:IsVisible()),
                tostring(b:GetAttribute("macrotext1"))))
        end
        local k1, k2 = GetBindingKey("CLICK WicksTravelFormButton:LeftButton")
        print(("  bind keys: %s | %s"):format(tostring(k1), tostring(k2)))
        return
    elseif msg == "show" then
        -- Force-build and show the button (in case PLAYER_LOGIN didn't fire as expected)
        if ns.UI and ns.UI.Build then ns.UI:Build() end
        if ns.UI and ns.UI.Refresh then ns.UI:Refresh() end
        if _G.WicksTravelFormButton then
            _G.WicksTravelFormButton:Show()
            print("|cff8a5cf6Wick's Travel Form|r: forced show.")
        else
            print("|cff8a5cf6Wick's Travel Form|r: button still not built — check chat for Lua errors.")
        end
        return
    end
    print("|cff8a5cf6Wick's Travel Form|r commands: unlock | lock | reset | size <N> | debug | show")
end

-- Friendly binding header / label
BINDING_HEADER_WICKSTRAVELFORM = "Wick's Travel Form"
_G["BINDING_NAME_CLICK WicksTravelFormButton:LeftButton"] = "Smart travel form"
