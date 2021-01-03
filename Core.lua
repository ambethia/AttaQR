local ADDON, NS = ...

local TILE_SIZE = 23
local SCALE = 1.42

local Hekili = _G["Hekili"]

AttaQR = LibStub("AceAddon-3.0"):NewAddon(ADDON, "AceConsole-3.0", "AceEvent-3.0")

local function AttaQR_OnUpdate(_, elapsed)
  AttaQR.updateElapsed = AttaQR.updateElapsed + elapsed
  if AttaQR.updateElapsed >= 0.1 then
    AttaQR.updateElapsed = 0

    if AttaQR.hekiliDisplay.alpha > 0 then
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
    else
      AttaQR:ClearCode()
    end
  end
end

function AttaQR:OnInitialize()
  self.isActive = false
  self.updateElapsed = 0
  self.frame = self:CreateQRFrame()
  self:ClearCode()
end

function AttaQR:OnEnable()
  self:FixUIScaling()
  self:RegisterChatCommand("atq", "SlashProcessor")
end

-- Prevent interruption of channeled spells.
function AttaQR:SPELL_UPDATE_COOLDOWN()
  local isChanneling = UnitChannelInfo("player")
  if isChanneling then
    self:ClearCode()
  end
end

function AttaQR:Activate()
  if self.frame:IsShown() then
    self.isActive = true
    self:ClearCode()
    self.hekiliDisplay = Hekili.DisplayPool["Primary"]
    self.frame:SetScript("OnUpdate", AttaQR_OnUpdate)
    self.frame:SetBackdropBorderColor(0, 1, 0)
  end
end

function AttaQR:Deactivate()
  self.isActive = false
  self:ClearCode()
  self.frame:SetScript("OnUpdate", nil)
  self.frame:SetBackdropBorderColor(1, 1, 1)
end

function AttaQR:SlashProcessor()
  if self.isActive then
    AttaQR:Deactivate()
  else
    AttaQR:Activate()
  end
end

function AttaQR:SetCode(code)
  local coords = NS.Keys[code] or NS.Keys["noop"]
  self.frame.Center:SetTexCoord(unpack(coords))
end

function AttaQR:ClearCode()
  self.nextAbility = nil
  self:SetCode('noop')
end

function AttaQR:FixUIScaling()
  local ppUI = 768.0 / GetScreenHeight()
  local uiScale = GetCVar("uiScale")
  local newSize = TILE_SIZE * SCALE + 8 / (ppUI / uiScale)
  self.frame:SetWidth(newSize)
  self.frame:SetHeight(newSize)
end

function AttaQR:CreateQRFrame()
  local frame = CreateFrame("Frame", ADDON .. "Frame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
  frame:SetFrameStrata("TOOLTIP")
  frame:SetWidth(TILE_SIZE * SCALE + 8)
  frame:SetHeight(TILE_SIZE * SCALE + 8)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:SetPoint("BOTTOMLEFT", 8, 8) -- TODO: Save Position
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

  frame:SetBackdrop(BACKDROP_TOOLTIP_12_12_4444)
  frame.Center:SetTexture("Interface\\Addons\\" .. ADDON .. "\\Keys", "CLAMPTOWHITE", "CLAMPTOWHITE", "NEAREST")
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
