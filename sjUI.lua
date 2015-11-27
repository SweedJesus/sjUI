
local _G = getfenv(0)

sjUI = AceLibrary("AceAddon-2.0"):new(
"AceConsole-2.0",
"AceDebug-2.0",
"AceDB-2.0",
"AceEvent-2.0",
"AceModuleCore-2.0")

local ADDON = "Interface\\AddOns\\sjUI\\"

local RED, YELLOW, GREEN = "ff0000", "ffff00", "00ff00"

local compstat_formatter = "%u fps | |cff%s%u|r ms"
local money_formatter = "%u|cffffd700g|r %u|cffc7c7cfs|r %u|cffeda55fc|r"

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

function sjUI_OnLoad()
end

function sjUI:OnInitialize()
    self:RegisterDB("sjUI_DB")
    self:RegisterDefaults("profile", { debug = true })
    self.opt = self.db.profile

    self:RegisterChatCommand({ "/sjUI" }, {
        type = "group",
        args = {
            frame = {
                name = "Frame",
                desc = "Toggle frame display",
                type = "execute",
                func = function()
                    if sjUI_Menu:IsVisible() then
                        sjUI_Menu:Hide()
                    else
                        sjUI_Menu:Show()
                    end
                end
            }
        }
    })
end

function sjUI:OnEnable()
    self:SetDebugging(self.opt.debug)

    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("PLAYER_MONEY", "UpdateMoney")

    self:InitComponents()
    self:InitMainFrame()
    self:InitRightBar()

    self:Bar_Init()

    -- FPS & Latency
    local compstat_update_interval = 2 or PERFORMANCEBAR_UPDATE_INTERVAL
    self:ScheduleRepeatingEvent(sjUI.UpdateTime, 1)

    -- Clock
    self:ScheduleRepeatingEvent(sjUI.UpdateCompStat, compstat_update_interval)
end

function sjUI:PLAYER_ENTERING_WORLD()
    --MainMenuBar:Hide()
    -- Micro
    self:InitMicroButtons()

    -- Move this into a general "hide vanilla frames" function
    MainMenuBar:Hide()

    -- Right
    self.UpdateCompStat()
    self.UpdateTime()
    self.UpdateMoney()

    -- Bar
    self:Bar_PositionAll()
end

function sjUI:InitComponents()
    self.backdrop = {
        bgFile = ADDON.."media\\img\\background",
        tile = true,
        tileSize = 8,
        edgeFile = ADDON.."media\\img\\border-small",
        edgeSize = 8,
        insets = {left = 0, right = 0, top = 0, bottom = 0}
    }
    self.font = ADDON.."media\\font\\pixelmix.ttf"
    self.font_size = 6
end

function sjUI:InitMainFrame()
    local f
    CreateFrame("Frame", "sjUI_Menu", UIParent)
    sjUI_Menu:SetPoint("TOP", 0, -10)
    sjUI_Menu:SetWidth(200)
    sjUI_Menu:SetHeight(24)
    sjUI_Menu:SetBackdrop(self.backdrop)
    sjUI_Menu:SetBackdropColor(1, 1, 1, 0.75)
    sjUI_Menu:EnableMouse(true)
    sjUI_Menu:RegisterForDrag("LeftButton")
    sjUI_Menu:SetMovable(true)
    sjUI_Menu:SetScript("OnDragStart", function()
        sjUI_Menu:StartMoving()
    end)
    sjUI_Menu:SetScript("OnDragStop", function()
        sjUI_Menu:StopMovingOrSizing()
    end)
    f = CreateFrame("Button", nil, sjUI_Menu, "UIPanelCloseButton")
    f:SetPoint("RIGHT", 0, 0)
    f = sjUI_Menu:CreateFontString(nil, "LOW")
    f:SetPoint("CENTER", 0, 0)
    f:SetFontObject(GameFontHighlight)
    f:SetText("sjUI Main Frame")
end

function sjUI.InitRightBar()
    CreateFrame("Frame", "sjUI_Right", sjUI_Menu)
    sjUI_Right:SetFrameStrata("LOW")
    sjUI_Right:SetWidth(250)
    sjUI_Right:SetHeight(16)
    sjUI_Right:ClearAllPoints()
    sjUI_Right:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -4, 4)
    sjUI_Right:SetBackdrop(sjUI.backdrop)
    sjUI_Right:SetBackdropColor(1, 1, 1, 0.75)
    sjUI_Right:EnableMouse(true)
    sjUI_Right:RegisterForDrag("LeftButton")
    sjUI_Right:SetMovable(true)
    sjUI_Right:SetScript("OnDragStart", function()
        sjUI_Right:StartMoving()
    end)
    sjUI_Right:SetScript("OnDragStop", function()
        sjUI_Right:StopMovingOrSizing()
    end)

    -- Left: FPS/Latency (reuse performance bar)
    sjUI_CompStat = MainMenuBarPerformanceBarFrameButton
    sjUI_CompStat:SetParent(sjUI_Right)
    sjUI_CompStat:ClearAllPoints()
    sjUI_CompStat:SetPoint("LEFT", 0, 0)
    sjUI_CompStat:SetWidth(90)
    sjUI_CompStat:SetHeight(16)
    sjUI_CompStat:SetHitRectInsets(2, -2, 2, -2)
    sjUI_CompStat:CreateFontString("sjUI_CompStatLabel", "LOW")
    sjUI_CompStatLabel:SetFont(sjUI.font, sjUI.font_size)
    sjUI_CompStatLabel:SetPoint("LEFT", 7, 1)
    sjUI_CompStat:SetScript("OnUpdate", nil)

    -- Center: Time
    sjUI_Right:CreateFontString("sjUI_TimeLabel", "LOW")
    sjUI_TimeLabel:SetFont(sjUI.font, sjUI.font_size)
    sjUI_TimeLabel:SetPoint("CENTER", 0, 1)

    -- Right: Money
    sjUI_Right:CreateFontString("sjUI_MoneyLabel", "LOW")
    sjUI_MoneyLabel:SetFont(sjUI.font, sjUI.font_size)
    sjUI_MoneyLabel:SetPoint("RIGHT", -7, 1)
end

function sjUI.InitMicroButtons()
    -- Character
    MicroButtonPortrait:Hide()

    local micro_buttons = {
        CharacterMicroButton, SpellbookMicroButton, TalentMicroButton,
        QuestLogMicroButton, SocialsMicroButton, WorldMapMicroButton,
        MainMenuMicroButton, HelpMicroButton
    }

    for i, f in micro_buttons do
        f:SetParent(sjUI_Menu)
        f:ClearAllPoints()
        f:SetWidth(22)
        f:SetHeight(16)
        f:SetHitRectInsets(0, 0, 0, 0)
        -- Textures
        f:SetNormalTexture(nil)
        f:SetHighlightTexture(nil)
        f:SetPushedTexture(nil)
        -- Backdrop
        f:SetBackdrop(sjUI.backdrop)
        f:SetBackdropColor(1, 1, 1, 0.75)
        local function MakeHandler(frame, b, old)
            return function()
                frame:SetBackdropBorderColor(1, 1, b, 1)
                if old then
                    old()
                end
            end
        end
        f:SetScript("OnEnter", MakeHandler(f, 0, f:GetScript("OnEnter")))
        f:SetScript("OnLeave", MakeHandler(f, 1, f:GetScript("OnLeave")))
        -- Label
        local t = f:CreateFontString(f:GetName().."Label", "OVERLAY")
        t:SetFont(ADDON.."media\\font\\pixelmix.ttf", 6)
        t:SetText(string.sub(f:GetName(), 1, 2))
        t:SetPoint("CENTER", 0, 1)
    end

    for i=8, 1, -1 do
        local f = micro_buttons[i]
        if i < 8 then
            f:SetPoint("RIGHT", micro_buttons[i+1], "LEFT", -2, 0)
            --f:SetPoint("BOTTOM", micro_buttons[i+1], "TOP", 0, 2)
        else
            f:SetPoint("RIGHT", sjUI_Right, "LEFT", -2, 0)
            --f:SetPoint("BOTTOMRIGHT", sjUI_Right, "TOPRIGHT", 0, 2)
        end
    end
end

function sjUI.UpdateCompStat()
    local _, _, latency = GetNetStats()
    local color
    if latency > PERFORMANCEBAR_MEDIUM_LATENCY then
        color = RED
    elseif latency > PERFORMANCEBAR_LOW_LATENCY then
        color = YELLOW
    else
        color = GREEN
    end
    sjUI_CompStatLabel:SetText(format(compstat_formatter, GetFramerate(), color, latency))
end

function sjUI.UpdateTime()
    sjUI_TimeLabel:SetText(date("%H:%M:%S"))
end

function sjUI.UpdateMoney()
    local money = GetMoney()
    local gold = floor(abs(money/10000))
    local silver = floor(abs(mod(money/100, 100)))
    local copper = floor(abs(mod(money, 100)))
    sjUI_MoneyLabel:SetText(format(money_formatter, gold, silver, copper))
end

-------------------------------------------------------------------------------
-- Bars
-------------------------------------------------------------------------------

local function StyleBar(bar)
    local num_buttons = getn(bar.buttons)
    local size
    if num_buttons == 12 then
        size = 36
    else
        size = 30
    end
    bar:SetWidth(num_buttons*size+(num_buttons-1)*sjUI.bar.spacing+2*sjUI.bar.padding)
    bar:SetHeight(size+2*sjUI.bar.padding)
    bar:SetBackdrop(sjUI.backdrop)
    bar:SetBackdropColor(1, 1, 1, 0.75)
end

local function StyleButton(button)
end

function sjUI:Bar_Init()
    self.bar = {}
    self.bar.spacing = 2
    self.bar.padding = 4
    self.bar.is_zoom = true
    --self.bar.all_action_buttons = {}
    self.bar.all_buttons = {}
    self.bar.all_icons = {}
    --self.bar.all_normal_textures = {}
    self.bar.all_bars= {}

    local spacing = self.bar.spacing
    local padding = self.bar.padding
    local bar, button, f, pushed, highlight, _

    for i = 1, 7 do
        bar = CreateFrame("Frame", "Bar"..i, UIParent)
        bar.buttons = {}
        table.insert(self.bar.all_bars, bar)
        for j = 1, 12 do
            if i < 6 or j < 11 then
                button = _G["Bar"..i.."Button"..j]
                button.normal = button:GetNormalTexture()
                button.pushed = button:GetPushedTexture()
                button.highlight = button:GetHighlightTexture()
                table.insert(bar.buttons, button)
                --table.insert(self.bar.all_action_buttons, button)
                table.insert(self.bar.all_buttons, button)
                table.insert(self.bar.all_icons, _G["Bar"..i.."Button"..j.."Icon"])
                --table.insert(self.bar.all_normal_textures, _G["Bar"..i.."Button"..j.."NT"])
            end
        end
    end

    -- Set parents
    for i = 1, 12 do
        _G["Bar1Button"..i]:SetParent("Bar1")
    end
    MultiBarBottomLeft:SetParent("Bar2")
    MultiBarBottomRight:SetParent("Bar3")
    MultiBarRight:SetParent("Bar4")
    MultiBarLeft:SetParent("Bar5")
    for i = 1, 10 do
        _G["Bar6Button"..i]:SetParent("Bar6")
        _G["Bar7Button"..i]:SetParent("Bar7")
    end

    for i, bar in self.bar.all_bars do
        MakeMovable(bar)
        -- Label frame
        --f = CreateFrame("Frame", nil, bar)
        --f:SetWidth(16)
        --f:SetHeight(16)
        --f:SetBackdrop(self.backdrop)
        --f:SetBackdropColor(1, 1, 1, 0.75)
        --f:SetPoint("TOPRIGHT", bar, "TOPLEFT", -2, 0)
        -- Label
        --f = f:CreateFontString(nil, "LOW")
        --f:SetFont(self.font, self.font_size)
        --f:SetText(i)
        --f:SetPoint("CENTER", 0, 1)
        -- Buttons
        for j, button in bar.buttons do
            button:ClearAllPoints()
            local button_size
            if i < 6 then
                button_size = 36
            else
                button_size = 30
            end
            button:SetPoint("LEFT", bar, "LEFT", (j-1)*(button_size+spacing)+padding, 0)
        end
    end

    self:Bar_StyleAll()
    self:Bar_HideTextures()
    self:Bar_SetButtonZoom(self.bar.is_zoom)
end

function sjUI:Bar_StyleAllBars()
    for i, bar in self.bar.all_bars do
        StyleBar(bar)
    end
end

function sjUI:Bar_StyleAllButtons()
    --for i, button in self.bar.all_buttons do
        --StyleButton(button)
    --end
end

function sjUI:Bar_StyleAll()
    sjUI:Bar_StyleAllBars()
    sjUI:Bar_StyleAllButtons()
end

function sjUI:Bar_PositionAll()
    for i, bar in self.bar.all_bars do
        bar = _G["Bar"..i]
        bar:ClearAllPoints()
        bar:SetPoint("CENTER", 0, -(i-1)*(36+2*self.bar.padding+4))
        bar:Show()
    end
end

function sjUI:Bar_HideTextures()
    for i, button in self.bar.all_buttons do
        button.normal:SetAlpha(0)
        button.pushed:SetAlpha(0)
        button.highlight:SetAlpha(0)
    end
end

function sjUI:Bar_SetButtonZoom(is_zoom)
    for i, v in self.bar.all_icons do
        if is_zoom then
            v:SetTexCoord(0.07, 0.93, 0.07, 0.93) -- Zoomed
        else
            v:SetTexCoord(0, 1, 0, 1) -- Normal
        end
    end
end

