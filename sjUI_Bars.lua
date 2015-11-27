
sjUI_Bars = sjUI:NewModule("bars", "AceDebug-2.0")

local _G = getfenv(0)

local button_dim = 36

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

function sjUI_Bars:OnInitialize()
    self:SetDebugging(sjUI.opt.debug)
end

function sjUI_Bars:OnEnable()
    self:InitTables()
    self:InitBars()
end

