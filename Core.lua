-- Wick's Travel Form
-- Core.lua — namespace, saved variables, single event dispatcher

local ADDON, ns = ...
_G.WICKSTRAVELFORM = ns

ns.version = "0.1.0"

-- Saved variables shape
local DEFAULTS = {
    -- Fill in default config here
}

-- Event dispatcher — every module registers a handler here, not its own frame.
local events = {}
function ns:On(event, fn)
    events[event] = events[event] or {}
    table.insert(events[event], fn)
end

local frame = CreateFrame("Frame", "WICKSTRAVELFORMEventFrame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(_, event, ...)
    if events[event] then
        for _, fn in ipairs(events[event]) do fn(...) end
    end
end)

ns:On("ADDON_LOADED", function(loaded)
    if loaded ~= ADDON then return end
    WICKSTRAVELFORMDB = WICKSTRAVELFORMDB or {}
    for k, v in pairs(DEFAULTS) do
        if WICKSTRAVELFORMDB[k] == nil then WICKSTRAVELFORMDB[k] = v end
    end
    if ns.UI and ns.UI.Build then ns.UI:Build() end
end)

-- Slash command
SLASH_WSTF1 = "/wstf"
SlashCmdList["WSTF"] = function(msg)
    if ns.UI and ns.UI.Toggle then ns.UI:Toggle() end
end
