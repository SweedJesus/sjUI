
local _G = getfenv(0)

sjUI = AceLibrary("AceAddon-2.0"):new(
"AceConsole-2.0",
"AceDebug-2.0",
"AceDB-2.0",
"AceEvent-2.0",
"AceHook-2.1")

local ADDON_PATH = "Interface\\AddOns\\sjUI\\"
local IMG_PATH = ADDON_PATH.."media\\img\\"

local WHITE, RED, YELLOW, GREEN = "ffffff", "ff0000", "ffff00", "00ff00"

local max_refresh_rate = { GetRefreshRates() }
max_refresh_rate = max_refresh_rate[getn(max_refresh_rate)]

-- Middle dot digraph: ".M"
local compstat_formatter = "|cff%s%u|r fps · |cff%s%u|r ms"
local time_formatter = "LOCAL %d:%d · SERVER %d:%d"
local money_formatter = "%u|cffffd700g|r %u|cffc7c7cfs|r %u|cffeda55fc|r"

local BAR1, BAR2, BAR3, BAR4, BAR5, PET_BAR = 1, 2, 3, 4, 5, 6

-- ----------------------------------------------------------------------------
-- Utility functions
-- ----------------------------------------------------------------------------

-- https://en.wikipedia.org/wiki/HSL_and_HSL
-- @param h Hue (0-360)
-- @param s Saturation (0-1)
-- @param l Lightness (0-1)
function HSL(h, s, l)
    h, s, l = mod(abs(h), 360) / 60, abs(s), abs(l)
    if s > 1 then s = mod(s, 1) end
    if l > 1 then l = mod(l, 1) end
    local c = (1 - abs(2 * l - 1)) * s
    local x = c * (1 - abs(mod(h, 2) - 1))
    local r, g, b
    if h < 1 then
        r, g, b = c, x, 0
    elseif h < 2 then
        r, g, b = x, c, 0
    elseif h < 3 then
        r, g, b = 0, c, x
    elseif h < 4 then
        r, g, b = 0, x, c
    elseif h < 5 then
        r, g, b = x, 0, c
    else
        r, g, b = c, 0, x
    end
    local m = l - c / 2
    return r + m, g + m, b + m
end

local function MakeMovable(frame)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetMovable(true)
    frame:SetScript("OnDragStart", function()
        frame:StartMoving()
    end)
    frame:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
    end)
end

local function SetScript(key, rawfunc)
    local func, e = loadstring(rawfunc)
    if func then
        setfenv(func, sjUI.env[key])
        sjUI[key] = func
        sjUI.opt[key] = rawfunc
    else
        sjUI:Print('Error in parsing %q! |cffff0000Error|r: %q', rawfunc, e)
    end
end

local function OptPrint(value)
    return function()
        sjUI:Print(value)
    end
end

local function OptGenericGet(key)
    return function()
        return sjUI.opt[key]
    end
end

local function OptGenericSet(key)
    return function(set)
        if set ~= sjUI.opt[key] then
            sjUI.opt[key] = set
        end
    end
end

local function OptColorGet(key)
    return function()
        return
        sjUI.opt[key.."R"],
        sjUI.opt[key.."G"],
        sjUI.opt[key.."B"],
        sjUI.opt[key.."A"]
    end
end

local function OptColorSet(key)
    return function(r, g, b, a)
        if sjUI.opt[key.."R"] ~= r or
            sjUI.opt[key.."G"] ~= g or
            sjUI.opt[key.."B"] ~= b or
            sjUI.opt[key.."A"] ~= a then
            sjUI.opt[key.."R"] = r
            sjUI.opt[key.."G"] = g
            sjUI.opt[key.."B"] = b
            sjUI.opt[key.."A"] = a
        end
    end
end

local function OptScriptSet(key)
    return function(rawfunc)
        SetScript(key, rawfunc)
    end
end

-- ----------------------------------------------------------------------------
-- Internals
-- ----------------------------------------------------------------------------

sjUI.defaults = {
    debug = true,
    useOwnFont = false,
    button_show_hotkey = true,
    button_show_count = true,
    button_show_macro = false,

    -- Left
    scriptLeftXP = "return ':^)'"
}

sjUI.options = {
    type = "group",
    args = {
        useOwnFont = {
            name = "Use own font",
            desc = "Use custom font in place of system fonts",
            type = "toggle",
            get = function()
                return sjUI.opt.useOwnFont
            end,
            set = function(set)
                sjUI.opt.useOwnFont = set
                sjUI:UpdateFonts()
            end
        },
        bar = {
            name = "Bar",
            desc = "Action bar configuration options",
            type = "group",
            args = {
                hotkey = {
                    name = "Show hotkey",
                    desc = "Show action button hotkey labels",
                    type = "toggle",
                    get = function()
                        return sjUI.opt.bar_show_hotkey
                    end,
                    set = function(set)
                        sjUI.opt.bar_show_hotkey = set
                        sjUI.Bar_Update()
                    end
                },
                count = {
                    name = "Show count",
                    desc = "Show action button count labels",
                    type = "toggle",
                    get = function()
                        return sjUI.opt.bar_show_count
                    end,
                    set = function(set)
                        sjUI.opt.bar_show_count = set
                        sjUI.Bar_Update()
                    end
                },
                macro = {
                    name = "Show macro names",
                    desc = "Show action button macro name labels",
                    type = "toggle",
                    get = function()
                        return sjUI.opt.bar_show_macro
                    end,
                    set = function(set)
                        sjUI.opt.bar_show_macro = set
                        sjUI.Bar_Update()
                    end
                }
            }
        },
        reset = {
            name = "Reset",
            desc = "Reset all saved variables to default.",
            type = "execute",
            func = function()
                for k in sjUI.defaults do
                    sjUI.opt[k] = sjUI.defaults[k]
                end
            end
        }
    }
}

local IMG = ADDON_PATH.."media\\img\\"
local background = IMG.."background"
local border     = IMG.."border-small"

sjUI.backdrop = {
    bgFile = background,
    tile = true,
    tileSize = 8,
    edgeFile = border,
    edgeSize = 8,
    insets = { left = 0, right = 0, top = 0, bottom = 0 }
}

sjUI.background = {
    bgFile = background,
    tile = true,
    tileSize = 8,
}

sjUI.border = {
    edgeFile = border,
    edgeSize = 8,
    insets = { left = 0, right = 0, top = 0, bottom = 0 }
}

sjUI.font = ADDON_PATH.."media\\font\\MyriadCondensed.ttf"
sjUI.font_size = 9
sjUI.font_objects = {}

-- ----------------------------------------------------------------------------
-- Event handlers
-- ----------------------------------------------------------------------------

function sjUI:OnInitialize()
    self:RegisterDB("sjUI_DB")
    self:RegisterDefaults("profile", self.defaults)
    self.opt = self.db.profile

    self.env = {}

    self:RegisterChatCommand({ "/sjUI" }, self.options)

    self:Map_Init()
    self:Left_Init()
    self:Right_Init()
    self:Bar_Init()
    self:Micro_Init()
end

function sjUI:OnEnable()
    self:SetDebugging(self.opt.debug)

    self:Map_Enable()
    self:Left_Enable()
    self:Right_Enable()
    self:Bar_Enable()
    self:Micro_Enable()

    self:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function sjUI:PLAYER_ENTERING_WORLD()
    MainMenuBar:Hide()

    self:Micro_Enable()
end

-- ----------------------------------------------------------------------------
-- Minimap
-- ----------------------------------------------------------------------------

function sjUI:Map_Init()
    sjUI.map = {}
    sjUI.map.mask = IMG_PATH.."SquareMiniMapMask"

    -- Zoom
    MinimapZoomIn:Hide()
    MinimapZoomOut:Hide()

    -- Zone
    MinimapBorderTop:Hide()
    MinimapToggleButton:Hide()
    local f = MinimapZoneTextButton
    f:ClearAllPoints()
    f:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 4)
    f:SetWidth(147)
    f:SetHeight(16)
    f:SetBackdrop(sjUI.backdrop)
    f:SetBackdropColor(1, 1, 1, 0.75)
    f = MinimapZoneText
    --f:SetFont
    f:ClearAllPoints()
    f:SetPoint("CENTER", 0, 1)

    -- Minimap & Backdrop
    MinimapBorder:SetTexture(nil)
    f = Minimap
    f:SetMaskTexture(sjUI.map.mask)
    f.backdrop = CreateFrame("Frame", "MinimapBackdrop", UIParent)
    f.backdrop:SetBackdrop(sjUI.backdrop)
    f.backdrop:SetBackdropColor(1, 1, 1, 0.75)
    f.backdrop:SetFrameStrata("BACKGROUND")
    f.backdrop:SetPoint("BOTTOM", MinimapZoneTextButton, "TOP", 0, 2)
    f.backdrop:SetWidth(147)
    f.backdrop:SetHeight(147)
    f:ClearAllPoints()
    f:SetPoint("CENTER", f.backdrop, "CENTER", 1, -1)

    -- Minimap zoom
    local f = CreateFrame("Frame", "MinimapMouseWheelZoomFrame", Minimap)
    f:SetAllPoints()
    f:EnableMouseWheel(true)
    f:SetScript("OnMouseWheel", function()
        if (arg1 > 0) then
            Minimap_ZoomIn()
        else
            Minimap_ZoomOut()
        end
    end)

    -- Tracking
    MiniMapTrackingBorder:Hide()
    f = MiniMapTrackingFrame
    f:SetBackdrop(sjUI.backdrop)
    f:ClearAllPoints()
    f:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", -2, 0)
    f:SetWidth(27)
    f:SetHeight(18)
    f = MiniMapTrackingIcon
    f:ClearAllPoints()
    f:SetPoint("TOPLEFT", 3, -3)
    f:SetPoint("BOTTOMRIGHT", -3, 3)
    f:SetTexCoord(0.2, 0.8, 0.3, 0.7)
    f:SetDrawLayer("ARTWORK")

    -- Mail
    MiniMapMailBorder:Hide()
    f = MiniMapMailFrame
    f:SetBackdrop(sjUI.backdrop)
    f:ClearAllPoints()
    f:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", 0, 0)
    f:SetWidth(27)
    f:SetHeight(18)
    f = MiniMapMailIcon
    f:ClearAllPoints()
    f:SetPoint("TOPLEFT", 3, -3)
    f:SetPoint("BOTTOMRIGHT", -3, 3)
    f:SetTexCoord(0.2, 0.8, 0.3, 0.7)
    f:SetDrawLayer("ARTWORK")

    -- BG
    MiniMapBattlefieldBorder:Hide()
    f = MiniMapBattlefieldFrame
    f:SetBackdrop(sjUI.backdrop)
    f:ClearAllPoints()
    f:SetPoint("BOTTOM", Minimap, "BOTTOM", 0, 0)
    f:SetWidth(27)
    f:SetHeight(18)
    f = MiniMapBattlefieldIcon
    f:ClearAllPoints()
    f:SetPoint("TOPLEFT", 3, -3)
    f:SetPoint("BOTTOMRIGHT", -3, 3)
    f:SetTexCoord(0.22, 0.78, 0.275, 0.625)
    f:SetDrawLayer("ARTWORK")

    -- Time
    GameTimeFrame:Hide()
end

function sjUI:Map_Enable()
end

-------------------------------------------------------------------------------
-- Left info bar
-------------------------------------------------------------------------------

function sjUI:Left_Init()
    local f
    local l = CreateFrame("Frame", "sjUI_Left", UIParent)
    l:SetFrameStrata("LOW")
    l:SetWidth(316)
    l:SetHeight(14)
    l:ClearAllPoints()
    l:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 4, 4)
    l:SetBackdrop(sjUI.backdrop)
    l:SetBackdropColor(1, 1, 1, 0.75)
    l:EnableMouse(true)
    l:RegisterForDrag("LeftButton")
    l:SetMovable(true)

    -- Left: Mail
    -- Center: XP
    f = CreateFrame("Frame", "sjUI_LeftXPFrame", l)
    f:SetPoint("CENTER", 0, 0)
    f:SetWidth(300)
    f:SetHeight(14)
    f:EnableMouse(true)
    --f:SetScript("OnMouseDown", function()
        --sjUI.opt.xpDisplayType = mod(sjUI.opt.xpDisplayType+1, 3)
        --sjUI:Left_UpdateXP()
    --end)
    f = f:CreateFontString("sjUI_LeftXPLabel", "LOW")
    f:SetFontObject(GameFontNormalSmall)
    f:SetJustifyH("CENTER")
    f:SetTextColor(0.6, 0.6, 0.6, 1)
    f:SetAllPoints()
    -- Right: Bag slots
end

function sjUI:Left_Enable()
    self:RegisterEvent("PLAYER_XP_UPDATE", sjUI.Left_UpdateXP)
    self:RegisterEvent("UPDATE_FACTION", sjUI.Left_UpdateXP)
    self:RegisterEvent("CHAT_MSG_COMBAT_FACTION_CHANGE", sjUI.Left_UpdateXP)

    --self.Left_UpdateXP()
end

function sjUI.Left_UpdateXP()
    local numSegments = 40
    local faction, reaction, min, max, cur = GetWatchedFactionInfo()
    local s, bars, r1, g1, b1, r2, g2, b2
    if faction and reaction then
        bars = (cur-min)/(max-min)*numSegments
        r1, g1, b1 = HSL((reaction-1)*30, 1, 0.5)
        r2, g2, b2 = HSL((reaction-1)*30, 0.5, 0.15)
        s = string.format("%3.1fk |cff%02x%02x%02x%s|r|cff%02x%02x%02x%s|r %3.1fk", (cur-min)/1000, 255*r1, 255*g1, 255*b1, string.rep("I", bars), 255*r2, 255*g2, 255*b2, string.rep("I", numSegments-bars), (max-min)/1000)
    else
        cur, max = UnitXP("player"), UnitXPMax("player")
        bars = cur/max*numSegments
        r1, g1, b1 = HSL(270, 1, 0.5)
        r2, g2, b2 = HSL(270, 0.5, 0.15)
        s = string.format("%3.1fk |cff%02x%02x%02x%s|r|cff%02x%02x%02x%s|r %3.1fk", cur/1000, 255*r1, 255*g1, 255*b1, string.rep("I", bars), 255*r2, 255*g2, 255*b2, string.rep("I", numSegments-bars), max/1000)
    end
    sjUI_LeftXPLabel:SetText(s)
end

-------------------------------------------------------------------------------
-- Right info bar
-------------------------------------------------------------------------------

function sjUI:Right_Init()
    local r = CreateFrame("Frame", "sjUI_Right", UIParent)
    r:SetFrameStrata("LOW")
    r:SetWidth(316)
    r:SetHeight(14)
    r:SetPoint("BOTTOMRIGHT", -4, 4)
    r:SetBackdrop(sjUI.backdrop)
    r:SetBackdropColor(1, 1, 1, 0.75)

    -- Left: FPS/Latency (reuse performance bar)
    local f = MainMenuBarPerformanceBarFrameButton
    self.right_performance = f
    f:SetParent(r)
    f:ClearAllPoints()
    f:SetPoint("LEFT", 0, 0)
    f:SetWidth(90)
    f:SetHeight(16)
    f:SetHitRectInsets(2, -2, 2, -2)
    f:SetScript("OnUpdate", nil)
    f.label = f:CreateFontString("sjUI_RightCompStatLabel", "LOW")
    f.label:SetFontObject(GameFontNormalSmall)
    f.label:SetTextColor(0.6, 0.6, 0.6, 1)
    f.label:SetPoint("LEFT", 7, 0)

    -- Center: Time
    f = r:CreateFontString("sjUI_RightTimeLabel", "LOW")
    self.right_time = f
    f:SetFontObject(GameFontNormalSmall)
    f:SetTextColor(0.6, 0.6, 0.6, 1)
    f:SetPoint("CENTER", 0, 0)

    -- Right: Money
    f = r:CreateFontString("sjUI_RightMoneyLabel", "LOW")
    self.right_money = f
    f:SetFontObject(GameFontNormalSmall)
    f:SetTextColor(0.6, 0.6, 0.6, 1)
    f:SetPoint("RIGHT", -7, 0)
end

function sjUI:Right_Enable()
    sjUI:RegisterEvent("PLAYER_MONEY", "Right_UpdateMoney")
    -- FPS & Latency
    local compstat_update_interval = 2 or PERFORMANCEBAR_UPDATE_INTERVAL
    sjUI:ScheduleRepeatingEvent(sjUI.Right_UpdateTime, 3)
    -- Clock
    sjUI:ScheduleRepeatingEvent(sjUI.Right_UpdateCompStat, compstat_update_interval)
    -- Initial update
    sjUI.Right_UpdateCompStat()
    sjUI.Right_UpdateTime()
    sjUI.Right_UpdateMoney()
end

function sjUI.Right_UpdateCompStat()
    local fps, _, _, latency = GetFramerate(), GetNetStats()
    local colorA, colorB
    if fps >= max_refresh_rate then
        colorA = WHITE
    elseif fps >= 60 then
        colorA = GREEN
    elseif fps >= 30 then
        colorA = YELLOW
    else
        colorA = RED
    end
    if latency > PERFORMANCEBAR_MEDIUM_LATENCY then
        colorB = RED
    elseif latency > PERFORMANCEBAR_LOW_LATENCY then
        colorB = YELLOW
    else
        colorB = GREEN
    end
    sjUI_RightCompStatLabel:SetText(format(compstat_formatter, colorA, fps, colorB, latency))
end

function sjUI.Right_UpdateTime()
    local localH, localM = date("%H"), date("%M")
    local serverH, serverM = date("!%H"), date("!%M")
    sjUI_RightTimeLabel:SetText(format(time_formatter, localH, localM, serverH, serverM))
end

function sjUI.Right_UpdateMoney()
    local money = GetMoney()
    local gold = floor(abs(money/10000))
    local silver = floor(abs(mod(money/100, 100)))
    local copper = floor(abs(mod(money, 100)))
    sjUI_RightMoneyLabel:SetText(format(money_formatter, gold, silver, copper))
end

-------------------------------------------------------------------------------
-- Micro buttons
-------------------------------------------------------------------------------

function sjUI:Micro_Init()
    sjUI.micro_buttons = {
        CharacterMicroButton, SpellbookMicroButton, TalentMicroButton,
        QuestLogMicroButton, SocialsMicroButton, WorldMapMicroButton,
        MainMenuMicroButton, HelpMicroButton
    }
    local text = {
        "CHARACTER", "SPELLBOOK", "TALENTS", "QUEST LOG", "SOCIAL",
        "WORLD MAP", "MAIN MENU", "SUPPORT"
    }
    for i, v in sjUI.micro_buttons do
        _G["MicroButton"..i] = v
    end
    -- Style
    local f
    for i, f in sjUI.micro_buttons do
        f:SetWidth(77.5)
        f:SetHeight(14)
        f:SetHitRectInsets(0, 0, 0, 0)
        -- Textures
        f:SetNormalTexture(nil)
        f:SetHighlightTexture(nil)
        f:SetPushedTexture(nil)
        -- Backdrop
        f:SetBackdrop(sjUI.backdrop)
        f:SetBackdropColor(1, 1, 1, 0.75)
        -- Label
        f.label = f:CreateFontString(f:GetName().."Label", "OVERLAY")
        f.label:SetPoint("CENTER", 0, 1)
        tinsert(self.font_objects, f.label)
        f.label:SetFontObject(GameFontNormalSmall)
        f.label:SetTextColor(0.6, 0.6, 0.6, 1)
        f.label:SetText(text[i])
    end
end

function sjUI:Micro_Enable()
    -- Hide character portrait
    MicroButtonPortrait:Hide()
    -- Position buttons
    local f
    for i = 1, 8 do
        f = sjUI.micro_buttons[i]
        f:SetParent(UIParent)
        f:ClearAllPoints()
        if i < 5 then
            f:SetPoint("BOTTOMLEFT", sjUI_Left, "TOPLEFT", (i-1)*(77.5+2), 2)
        else
            f:SetPoint("BOTTOMLEFT", sjUI_Right, "TOPLEFT", (i-5)*(77.5+2), 2)
        end
    end
end

-------------------------------------------------------------------------------
-- Buttons
-------------------------------------------------------------------------------

function sjUI:Bar_Init()
    -- Setup tables and values
    sjUI.bar = {}
    sjUI.bar.all_bars= {}
    sjUI.bar.all_buttons = {}
    sjUI.bar.button_size = 24
    sjUI.bar.skin = {
        normal    = ADDON_PATH.."media\\img\\button_36n.tga",
        pushed    = ADDON_PATH.."media\\img\\button_36p.tga",
        highlight = ADDON_PATH.."media\\img\\button_36h.tga"
    }
    sjUI.bar.is_zoom = true
    sjUI.bar.show_all = true

    -- Left container
    local left = CreateFrame("Frame", "sjUI_ButtonsLeft", UIParent)
    left:SetPoint("BOTTOM", -256, 4)
    left:SetWidth(12*30)
    left:SetHeight(2*30)
    left:SetBackdrop(sjUI.background)
    left:SetBackdropColor(1, 1, 1, 0.75)
    left.texture = left:CreateTexture(nil, "BORDER")
    left.texture:SetPoint("TOPLEFT", 0, 0)
    left.texture:SetWidth(512)
    left.texture:SetHeight(128)
    left.texture:SetTexture(ADDON_PATH.."media\\img\\button-container1")

    -- Right container
    local right = CreateFrame("Frame", "sjUI_ButtonsRight", UIParent)
    right:SetPoint("BOTTOM", 256, 4)
    right:SetWidth(12*30)
    right:SetHeight(2*30)
    right:SetBackdrop(sjUI.background)
    right:SetBackdropColor(1, 1, 1, 0.75)
    right.texture = right:CreateTexture(nil, "BORDER")
    right.texture:SetPoint("TOPLEFT", 0, 0)
    right.texture:SetWidth(512)
    right.texture:SetHeight(128)
    right.texture:SetTexture(ADDON_PATH.."media\\img\\button-container1")

    -- Side container
    local side = CreateFrame("Frame", "sjUI_ButtonsSide", UIParent)
    side:SetPoint("RIGHT", -4, 0)
    side:SetWidth(30)
    side:SetHeight(30*12)
    side:SetBackdrop(sjUI.background)
    side:SetBackdropColor(1, 1, 1, 0.75)
    side.texture = side:CreateTexture(nil, "BORDER")
    side.texture:SetPoint("TOPLEFT", 0, 0)
    side.texture:SetWidth(32)
    side.texture:SetHeight(512)
    side.texture:SetTexture(ADDON_PATH.."media\\img\\button-container2")

    -- Pet container
    local pet = CreateFrame("Frame", "sjUI_ButtonsPet", UIParent)
    pet:SetPoint("RIGHT", side, "LEFT", 0, 0)
    pet:SetWidth(30)
    pet:SetHeight(10*30)
    pet:SetBackdrop(sjUI.background)
    pet:SetBackdropColor(1, 1, 1, 0.75)
    pet.texture = pet:CreateTexture(nil, "BORDER")
    pet.texture:SetPoint("TOPLEFT", 0, 0)
    pet.texture:SetWidth(32)
    pet.texture:SetHeight(512)
    pet.texture:SetTexture(ADDON_PATH.."media\\img\\button-container3")

    -- Setup bars
    CreateFrame("Frame", "Bar1", UIParent)
    Bar2 = MultiBarBottomLeft
    Bar3 = MultiBarBottomRight
    Bar4 = MultiBarLeft
    Bar5 = MultiBarRight
    Bar6 = PetActionBarFrame

    -- Alias buttons
    local bar, button, old, new, num_buttons
    for i,v in {
        "ActionButton",
        "MultiBarBottomLeftButton",
        "MultiBarBottomRightButton",
        "MultiBarLeftButton",
        "MultiBarRightButton",
        "PetActionButton" } do
        bar = _G["Bar"..i]
        bar:SetParent(left)
        if i < 6 then
            num_buttons = 12
        else
            num_buttons = 10
        end
        for j = 1, num_buttons do
            old = v..j
            new = "Bar"..i.."Button"..j
            button = _G[old]
            _G[new] = button
            button:SetParent(bar)
            button:SetWidth(36)
            button:SetHeight(36)
            button:SetScale(5/6)
            button.icon = _G[old.."Icon"]
            button.hotkey = _G[old.."HotKey"]
            button.count = _G[old.."Count"]
            button.macro_text = _G[old.."Name"]
            button.normal = button:GetNormalTexture()
            button.pushed = button:GetPushedTexture()
            button.highlight = button:GetHighlightTexture()
            tinsert(sjUI.bar.all_buttons, button)
        end
    end
    sjUI:Hook("ActionButton_Update")
end

function sjUI:Bar_Enable()
    local button
    -- Position action bar buttons
    -- Order is defined here
    for i, b in { 1, 2, 4, 3 } do
        for j = 1, 12 do
            button = _G["Bar"..b.."Button"..j]
            button:ClearAllPoints()
            if i < 3 then
                button:SetPoint("TOPLEFT", sjUI_ButtonsLeft, "TOPLEFT",
                (j-1)*36, -(i-1)*36)
            else
                button:SetPoint("TOPLEFT", sjUI_ButtonsRight, "TOPLEFT",
                (j-1)*36, -(i-3)*36)
            end
        end
    end
    -- Position side bar buttons
    for j = 1, 12 do
        button = _G["Bar5Button"..j]
        button:ClearAllPoints()
        button:SetPoint("TOP", sjUI_ButtonsSide, "TOP", 0, -(j-1)*36)
    end
    -- Position pet bar buttons
    for j = 1, 10 do
        button = _G["Bar6Button"..j]
        button:ClearAllPoints()
        button:SetPoint("TOP", sjUI_ButtonsPet, "TOP", 0, -(j-1)*36)
    end
    self:RegisterEvent("PET_BAR_UPDATE", sjUI.Bar_Update)
    self:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
    -- Initial update
    self.Bar_Update()
end

function sjUI.Bar_Update()
    if UnitExists("pet") then
        --Bar6:Show()
        sjUI_ButtonsPet:Show()
    else
        --Bar6:Hide()
        sjUI_ButtonsPet:Hide()
    end
    for i, button in sjUI.bar.all_buttons do
        if sjUI.bar.show_all then
            button:Show()
        end
        sjUI.Bar_StyleButton(button)
    end
end

function sjUI.Bar_StyleButton(button)
    -- Icon
    button.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    button.icon:ClearAllPoints()
    button.icon:SetPoint("TOPLEFT", 3, -3)
    button.icon:SetPoint("BOTTOMRIGHT", -3, 3)
    -- Hot key
    button.hotkey:ClearAllPoints()
    button.hotkey:SetPoint("TOPRIGHT", -2, -1)
    --button.hotkey:SetFontObject(NumberFontNormalSmallGray)
    if sjUI.opt.bar_show_hotkey then
        button.hotkey:Show()
    else
        button.hotkey:Hide()
    end
    -- Count
    button.count:ClearAllPoints()
    --button.count:SetPoint("BOTTOMRIGHT", -2, 5)
    button.count:SetPoint("CENTER", 0, 0)
    --button.count:SetFontObject(NumberFontNormalSmall)
    if sjUI.opt.bar_show_count then
        button.count:Show()
    else
        button.count:Hide()
    end
    -- Macro text
    --button.macro_text:SetFontObject(GameFontHighlightSmall)
    if sjUI.opt.bar_show_macro then
        button.macro_text:Show()
    else
        button.macro_text:Hide()
    end
    -- Normal
    button.normal:SetTexture(nil)
    -- Pushed
    button.pushed:SetTexture(sjUI.bar.skin.pushed)
    button.pushed:ClearAllPoints()
    button.pushed:SetPoint("CENTER", 0, 0)
    button.pushed:SetWidth(64)
    button.pushed:SetHeight(64)
    button.pushed:SetAlpha(1)
    -- Highlight
    button.highlight:SetTexture(sjUI.bar.skin.highlight)
    button.highlight:ClearAllPoints()
    button.highlight:SetPoint("CENTER", 0, 0)
    button.highlight:SetWidth(64)
    button.highlight:SetHeight(64)
    button.highlight:SetAlpha(1)
end

function sjUI.ActionButton_Update()
    sjUI.hooks["ActionButton_Update"](arg1)
    sjUI.Bar_Update()
end

function sjUI:Bar_GetBonusActionBarPage()
    local x = GetBonusBarOffset()
    if x == 3 then
        return 9
    elseif x == 2 then
        return 8
    elseif x == 1 then
        return 7
    else
        return 1
    end
end

function sjUI:UPDATE_BONUS_ACTIONBAR()
    BonusActionBarFrame:Hide()
    CURRENT_ACTIONBAR_PAGE = self:Bar_GetBonusActionBarPage()
    ChangeActionBarPage()
end

