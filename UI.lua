-- Wick's Travel Form
-- UI.lua — secure click button + contextual form icon
-- Brand spec: locked palette, 10px L-bracket corners, 1px muted-purple border.
--
-- The secure button is created at file-parse-time (mirroring WicksQuestKey)
-- so it exists before any event handler can reference it. Position and
-- lock state are applied later from saved variables once they're loaded.

local _, ns = ...
local UI = {}
ns.UI = UI

-- =====================================================================
-- Wick brand palette (locked)
-- Fel #4FC778 · Void #0D0A14 · Border #383058 · Off-White #D4C8A1
-- =====================================================================
local C_BG     = { 0.051, 0.039, 0.078, 0.97 }
local C_BORDER = { 0.220, 0.188, 0.345, 1 }
local C_GREEN  = { 0.310, 0.780, 0.471, 1 }
local C_HOVER  = { 0.310, 0.780, 0.471, 0.10 }
local C_MOVE   = { 0.640, 0.210, 0.930, 0.20 }

local BRACKET, ARM = 10, 2

local function newTex(parent, layer, c)
    local t = parent:CreateTexture(nil, layer)
    t:SetColorTexture(unpack(c))
    return t
end

local function addBorder(f)
    local t = newTex(f, "BORDER", C_BORDER); t:SetPoint("TOPLEFT");    t:SetPoint("TOPRIGHT");    t:SetHeight(1)
    local b = newTex(f, "BORDER", C_BORDER); b:SetPoint("BOTTOMLEFT"); b:SetPoint("BOTTOMRIGHT"); b:SetHeight(1)
    local l = newTex(f, "BORDER", C_BORDER); l:SetPoint("TOPLEFT");    l:SetPoint("BOTTOMLEFT");  l:SetWidth(1)
    local r = newTex(f, "BORDER", C_BORDER); r:SetPoint("TOPRIGHT");   r:SetPoint("BOTTOMRIGHT"); r:SetWidth(1)
end

local function addCornerAccents(f)
    for _, anchor in ipairs({ "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT" }) do
        local h = newTex(f, "OVERLAY", C_GREEN); h:SetPoint(anchor); h:SetSize(BRACKET, ARM)
        local v = newTex(f, "OVERLAY", C_GREEN); v:SetPoint(anchor); v:SetSize(ARM, BRACKET)
    end
end

local function shortBind(key)
    if not key or key == "" then return "" end
    return (key:upper()
        :gsub("ALT%-", "a")
        :gsub("CTRL%-", "c")
        :gsub("SHIFT%-", "s")
        :gsub("NUMPAD", "n")
        :gsub("BUTTON1", "M1")
        :gsub("BUTTON2", "M2")
        :gsub("BUTTON3", "M3")
        :gsub("MOUSEWHEELUP", "MwU")
        :gsub("MOUSEWHEELDOWN", "MwD"))
end

local TF_BINDING = "CLICK WicksTravelFormButton:LeftButton"
local locked = true

-- =====================================================================
-- Button creation (top-level — runs at file load)
-- =====================================================================
-- Architecture: a non-secure `host` Frame owns position, scale, and drag.
-- The secure `btn` (SecureActionButton) fills the host. Blizzard's secure-init
-- pipeline reverts SetSize/SetScale on secure frames during the load sequence;
-- by isolating those properties on the host we avoid that revert entirely.
-- This mirrors how WicksTotemsAndThings persists its bar scale.
local REFERENCE_SIZE = 48
local host = CreateFrame("Frame", "WicksTravelFormHost", UIParent)
host:SetSize(REFERENCE_SIZE, REFERENCE_SIZE)
host:SetFrameStrata("MEDIUM")
host:SetClampedToScreen(true)
host:SetMovable(true)
host:SetPoint("CENTER", UIParent, "CENTER", 0, -120)

local btn = CreateFrame("Button", "WicksTravelFormButton", host, "SecureActionButtonTemplate")
btn:SetAllPoints(host)
-- Mirror the WicksQuestKey pattern: type1=macro, both macrotext attrs
-- set, AnyUp+AnyDown registration. The SAB's internal macro processor
-- handles the cast so the keybind fires the same code path as a click.
btn:SetAttribute("type1", "macro")
btn:RegisterForClicks("AnyUp", "AnyDown")

local bg = newTex(btn, "BACKGROUND", C_BG); bg:SetAllPoints(btn)
addBorder(btn)
addCornerAccents(btn)

local icon = btn:CreateTexture(nil, "ARTWORK")
icon:SetPoint("TOPLEFT", 4, -4)
icon:SetPoint("BOTTOMRIGHT", -4, 4)
icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
btn.icon = icon

local bindLabel = btn:CreateFontString(nil, "OVERLAY")
bindLabel:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
bindLabel:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -3, -3)
bindLabel:SetTextColor(1, 1, 1, 1)
btn.bindLabel = bindLabel

local hover = newTex(btn, "HIGHLIGHT", C_HOVER); hover:SetAllPoints(btn)

local moveTint = newTex(btn, "OVERLAY", C_MOVE); moveTint:SetAllPoints(btn); moveTint:Hide()

-- Drag is wired to the host (which owns position). The button is registered
-- for drag and forwards StartMoving/StopMoving to host so the visual is
-- consistent (you grab the button, the whole thing moves).
btn:RegisterForDrag("LeftButton")
btn:SetScript("OnDragStart", function() if not locked then host:StartMoving() end end)
btn:SetScript("OnDragStop",  function()
    host:StopMovingOrSizing()
    if WicksTravelFormDB then
        local point, _, relativePoint, x, y = host:GetPoint(1)
        WicksTravelFormDB.point, WicksTravelFormDB.relativePoint = point, relativePoint
        WicksTravelFormDB.x, WicksTravelFormDB.y = x, y
    end
end)

btn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine("Wick's Travel Form", 0.31, 0.78, 0.47)
    local action = ns.isFlying() and "Cancel flight form" or ("Will cast: " .. ns.predictForm())
    GameTooltip:AddLine(action, 0.83, 0.78, 0.63)
    GameTooltip:AddLine(" ")
    if locked then
        GameTooltip:AddLine("Right-click to unlock for drag and resize.", 0.42, 0.35, 0.54)
    else
        GameTooltip:AddLine("Drag to move · scroll to resize · right-click to lock.", 0.42, 0.35, 0.54)
    end
    GameTooltip:Show()
end)
btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- Mouse wheel resize while unlocked. Step 4px, clamped 32–96.
btn:EnableMouseWheel(true)
btn:SetScript("OnMouseWheel", function(self, delta)
    if locked then return end
    local cur = (WicksTravelFormDB and WicksTravelFormDB.size) or 48
    local step = (delta > 0) and 4 or -4
    local s = cur + step
    if s < (ns.MIN_SIZE or 32) then s = ns.MIN_SIZE or 32 end
    if s > (ns.MAX_SIZE or 96) then s = ns.MAX_SIZE or 96 end
    if s == cur then return end
    if WicksTravelFormDB then WicksTravelFormDB.size = s end
    UI:ApplySize()
end)

-- HookScript so Blizzard's secure OnClick still runs and fires the
-- macrotext for left-click. Right-click toggles lock.
btn:HookScript("OnClick", function(self, button, down)
    if button == "RightButton" and down and not InCombatLockdown() then
        UI:SetLocked(not locked)
    end
end)

-- Button is visible by default. Non-druid characters get it hidden by
-- Core.lua's class check. This way the button appears even if Activate
-- never runs cleanly — failure mode is "button visible, macro stale"
-- rather than "button missing entirely".

-- =====================================================================
-- Methods
-- =====================================================================
function UI:ApplyPosition()
    if not WicksTravelFormDB then return end
    local db = WicksTravelFormDB
    host:ClearAllPoints()
    host:SetPoint(db.point or "CENTER", UIParent, db.relativePoint or "CENTER",
                  db.x or 0, db.y or -120)
end

function UI:ApplySize()
    local s = (WicksTravelFormDB and WicksTravelFormDB.size) or REFERENCE_SIZE
    local lo, hi = ns.MIN_SIZE or 32, ns.MAX_SIZE or 96
    if s < lo then s = lo end
    if s > hi then s = hi end
    host:SetSize(s, s)
end

function UI:UpdateBindLabel()
    btn.bindLabel:SetText(shortBind(GetBindingKey(TF_BINDING)))
end

function UI:Refresh()
    -- Macrotext can only be set out of combat. The macro itself contains
    -- runtime conditionals so the in-combat behavior is still correct
    -- with whatever was set at the last out-of-combat refresh.
    if not InCombatLockdown() then
        local m = ns.buildMacro()
        btn:SetAttribute("macrotext", m)
        btn:SetAttribute("macrotext1", m)
    end
    btn.icon:SetTexture(ns.formIcon(ns.predictForm()))
    self:UpdateBindLabel()
end

function UI:SetLocked(state)
    if InCombatLockdown() then
        print("|cff8a5cf6Wick's Travel Form|r: cannot change lock during combat.")
        return
    end
    locked = state
    if WicksTravelFormDB then WicksTravelFormDB.locked = state end
    if locked then moveTint:Hide() else moveTint:Show() end
end

-- Called by Core.lua at PLAYER_LOGIN once we know we're a druid.
function UI:Activate()
    locked = not (WicksTravelFormDB and WicksTravelFormDB.locked == false)
    if locked then moveTint:Hide() else moveTint:Show() end
    self:ApplyPosition()
    self:ApplySize()
    self:Refresh()
    host:Show()
    btn:Show()
end

-- Called when we know the player isn't a druid — hide the button.
function UI:Deactivate()
    host:Hide()
end

-- Build is kept as an alias for /wstf show — same effect as Activate
-- but doesn't depend on having gone through PLAYER_LOGIN cleanly.
function UI:Build()
    self:Activate()
end
