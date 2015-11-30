-- Adding aliases for Bartender2 buttons to help our job :)

local _G = getfenv(0)
local new, old, button

------------------------------ Bar1 ------------------------------
local olds = {
    --[[ 1 ]] "ActionButton%u",
    --[[ 2 ]] "MultiBarBottomLeftButton%u",
    --[[ 3 ]] "MultiBarBottomRightButton%u",
    --[[ 4 ]] "MultiBarRightButton%u",
    --[[ 5 ]] "MultiBarLeftButton%u",
    --[[ 6 ]] "ShapeshiftButton%u",
    --[[ 7 ]] "PetActionButton%u",
}

for i, old in olds do
    for j = 1, 12 do
        new = "Bar"..i.."Button"..j
        old = format(old, j)
        button = _G[old]
        _G[new] = button
        button.icon = _G[old.."Icon"]
        button.hotkey = _G[old.."HotKey"]
        button.normal = button:GetNormalTexture()
        button.pushed = button:GetPushedTexture()
        button.highlight = button:GetHighlightTexture()
    end
end

------------------------------ Bar8 ------------------------------
--Bar8Button1 = CharacterBag3Slot
--Bar8Button2 = CharacterBag2Slot
--Bar8Button3 = CharacterBag1Slot
--Bar8Button4 = CharacterBag0Slot
--Bar8Button5 = MainMenuBarBackpackButton

--Bar8Button1NT = CharacterBag3SlotNormalTexture
--Bar8Button2NT = CharacterBag2SlotNormalTexture
--Bar8Button3NT = CharacterBag1SlotNormalTexture
--Bar8Button4NT = CharacterBag0SlotNormalTexture
--Bar8Button5NT = MainMenuBarBackpackButtonNormalTexture

--Bar8Button1Icon = CharacterBag3SlotIconTexture
--Bar8Button2Icon = CharacterBag2SlotIconTexture
--Bar8Button3Icon = CharacterBag1SlotIconTexture
--Bar8Button4Icon = CharacterBag0SlotIconTexture
--Bar8Button5Icon = MainMenuBarBackpackButtonIconTexture

------------------------------ Bar9 ------------------------------
--Bar9Button1 = CharacterMicroButton
--Bar9Button2 = SpellbookMicroButton
--Bar9Button3 = TalentMicroButton
--Bar9Button4 = QuestLogMicroButton
--Bar9Button5 = SocialsMicroButton
--Bar9Button6 = WorldMapMicroButton or LFGMicroButton
--Bar9Button7 = MainMenuMicroButton
--Bar9Button8 = HelpMicroButton

------------------------------ Others ------------------------------
--Shapebar = Bar6
--Petbar = Bar7
--Bagbar = Bar8
--Microbar = Bar9
