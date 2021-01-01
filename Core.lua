local ADDON, NS = ...

local TILE_SIZE = 23
local SCALE = 1

local Hekili = _G["Hekili"]

AttaQR = LibStub("AceAddon-3.0"):NewAddon(ADDON, "AceConsole-3.0", "AceEvent-3.0")

local function AttaQR_OnUpdate(_, elapsed)
  AttaQR.updateElapsed = AttaQR.updateElapsed + elapsed
  if AttaQR.updateElapsed >= 0.1 then
    AttaQR.updateElapsed = 0
    local recommendation = AttaQR.hekiliDisplay.Recommendations[1]
    local abilityKey = recommendation.keybind
    if abilityKey and abilityKey ~= AttaQR.nextAbility then
      AttaQR.nextAbility = abilityKey
      if abilityKey and recommendation.time == 0 then
        AttaQR:SetCode(abilityKey)
      else
        AttaQR:ClearCode()
      end
    end
  end
end

function AttaQR:OnInitialize()
  self.updateElapsed = 0
  self.frame = self:CreateQRFrame()
  self:ClearCode()
end

function AttaQR:OnEnable()
  self:RegisterEvent("PLAYER_REGEN_DISABLED")
  self:RegisterEvent("PLAYER_REGEN_ENABLED")
end

function AttaQR:PLAYER_REGEN_DISABLED()
  self:Activate()
end

function AttaQR:PLAYER_REGEN_ENABLED()
  self:Deactivate()
end

-- Prevent client from interrupting channeled spells.
function AttaQR:SPELL_UPDATE_COOLDOWN()
  local isChanneling = UnitChannelInfo("player")
  if isChanneling then
    self:ClearCode()
  end
end

function AttaQR:PLAYER_TARGET_CHANGED()
  if UnitIsEnemy("player","target") and UnitAffectingCombat("player") then
    self:Activate()
  else
    self:Deactivate()
  end
end

function AttaQR:Activate()
  if self.frame:IsShown() then
    self:ClearCode()
    self.hekiliDisplay = Hekili.DisplayPool["Primary"]
    self.frame:SetScript("OnUpdate", AttaQR_OnUpdate)
    self:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    self:RegisterEvent("PLAYER_TARGET_CHANGED")
  end
end

function AttaQR:Deactivate()
  self:ClearCode()
  self.frame:SetScript("OnUpdate", nil)
  self:UnregisterEvent("SPELL_UPDATE_COOLDOWN")
  self:UnregisterEvent("PLAYER_TARGET_CHANGED")
end

function AttaQR:SetCode(code)
  local coords = NS.Keys[code] or NS.Keys["noop"]
  self.frame.QRTexture:SetTexCoord(unpack(coords))
end

function AttaQR:ClearCode()
  self.nextAbility = nil
  self:SetCode('noop')
end

function AttaQR:CreateQRFrame()
  local frame = CreateFrame("Frame", ADDON .. "Frame", UIParent, UIPanelButtonTemplate)
  frame:SetFrameStrata("TOOLTIP")
  frame:SetWidth(TILE_SIZE * SCALE)
  frame:SetHeight(TILE_SIZE * SCALE)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:SetPoint("BOTTOMLEFT", 8, 8) -- TODO: Save Posi tion
  frame:RegisterForDrag("LeftButton")
  frame:SetScript(
    "OnDragStart",
    function(self)
      self:StartMoving()
    end
  )
  frame:SetScript(
    "OnDragStop",
    function(self)
      self:StopMovingOrSizing()
    end
  )
  
  local texture = frame:CreateTexture(nil, "OVERLAY")
  texture:SetTexture("Interface\\Addons\\" .. ADDON .. "\\Keys", "CLAMPTOWHITE", "CLAMPTOWHITE", "NEAREST")
  texture:SetAllPoints(frame)

  frame.QRTexture = texture

  return frame
end

local AttaQRLDB =
  LibStub("LibDataBroker-1.1"):NewDataObject(
  "AttaQR",
  {
    type = "data source",
    text = "",
    label = "AttaQR",
    icon = "Interface\\AddOns\\" .. ADDON .. "\\Icon",
    OnClick = function()
      if AttaQR.frame:IsShown() then
        AttaQR.frame:Hide()
        AttaQR:Deactivate()
      else
        AttaQR.frame:Show()
        AttaQR:Activate()
      end
    end,
    OnTooltipShow = function(tt)
      tt:AddLine("AttaQR")
      tt:AddLine(" ")
      tt:AddLine("Click to toggle AttaQR.")
    end
  }
)
