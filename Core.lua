local ADDON, NS = ...

local TILE_PAD = 8
local DELTA = 0.05

local Hekili = _G["Hekili"]

AttaQR = LibStub("AceAddon-3.0"):NewAddon(ADDON, "AceConsole-3.0", "AceEvent-3.0")

local defaults = {
  profile = {
    enabled = true,
    automatic = true,
    label = false,
    tile_size = 36
  }
}


local options = {
  name = ADDON,
  handler = AttaQR,
  type = 'group',
  args = {
    enable = {
      type = 'toggle',
      name = 'Enable ' .. ADDON,
      desc = 'Enable / disable the addon',
      get =  function(info) return AttaQR.db.profile.enabled end,
      set = 'SetEnableAttaQR',
      width = 'full',
      order = 90
    },
    tile_size = {
      type = 'range',
      min = 8,
			max = 128,
			step = 1,
      name = 'Tile Size',
      get = function(info) return AttaQR.db.profile.tile_size end,
      set = 'SetTileSize',
      width = 'double',
      order = 110
    },
    label = {
      type = 'toggle',
      name = 'Show label',
      desc = 'Show current keybind as a text label below the QR code',
      get =  function(info) return AttaQR.db.profile.label end,
      set = 'SetShowLabel',
      width = 'full',
      order = 120
    },
    automatic = {
      type = 'toggle',
      name = 'Auto-Activate',
      desc = 'Automatically activate (and deactivate) with combat',
      get =  function(info) return AttaQR.db.profile.automatic end,
      set = function(info, val) AttaQR.db.profile.automatic = val end,
      width = 'full',
      order = 130
    },
  },
}

local optionsTable = LibStub("AceConfig-3.0"):RegisterOptionsTable(ADDON, options, {"attaqr", "atqr"})
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

LibStub("AceConfigDialog-3.0")

function AttaQR:GetEnableAttaQR(info)
  return self.db.profile.enabled
end

function AttaQR:SetEnableAttaQR(info, val)
  if val then
    self.db.profile.enabled = true
    AttaQR.frame:Show()
    AttaQR:Activate()
  else
    self.db.profile.enabled = false
    AttaQR.frame:Hide()
    AttaQR:Deactivate()
  end
end

function AttaQR:SetShowLabel(info, val)
  if val then
    self.db.profile.label = true
    AttaQR.frame.text:Show()
  else
    self.db.profile.label = false
    AttaQR.frame.text:Hide()
  end
end

function AttaQR:SetTileSize(info, val)
  self.db.profile.tile_size = val
  self.frame:SetWidth(val + TILE_PAD)
  self.frame:SetHeight(val + TILE_PAD)
end

local function AttaQR_OnUpdate(_, elapsed)
  AttaQR.updateElapsed = AttaQR.updateElapsed + elapsed
  if AttaQR.updateElapsed >= DELTA then
    AttaQR.updateElapsed = 0

    if AttaQR.hekiliDisplay.alpha > 0 then
      local recommendation = AttaQR.hekiliDisplay.Recommendations[1]
      local abilityKey = recommendation.keybind
      if abilityKey and abilityKey ~= AttaQR.nextAbility then
        AttaQR.nextAbility = abilityKey
        if abilityKey and recommendation.time <= DELTA
          and not AttaQR.isChanneling
          and not _G['ACTIVE_CHAT_EDIT_BOX'] then
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
  self.db = LibStub("AceDB-3.0"):New(ADDON .. "DB", defaults, true)
  AceConfigDialog:AddToBlizOptions(ADDON, ADDON)

  self.isActive = false
  self.isChanneling = false
  self.updateElapsed = 0
  self.frame = self:CreateQRFrame()
  self:ClearCode()

  if not self.db.profile.enabled then
    AttaQR.frame:Hide()
    AttaQR:Deactivate()
  end

  if not self.db.profile.label then
    AttaQR.frame.text:Hide()
  end
end

function AttaQR:OnEnable()
  self:FixUIScaling()
  self:RegisterChatCommand("atq", "SlashProcessor")
end

-- Prevent interruption of channeled spells.
function AttaQR:SPELL_UPDATE_COOLDOWN()
  self.isChanneling = UnitChannelInfo("player")
end
AttaQR:RegisterEvent("SPELL_UPDATE_COOLDOWN")

function AttaQR:PLAYER_REGEN_ENABLED()
  if self.db.profile.automatic then
    self:Deactivate()
  end
  
end
AttaQR:RegisterEvent("PLAYER_REGEN_ENABLED")

function AttaQR:PLAYER_REGEN_DISABLED()
  if self.db.profile.automatic then
    self:Activate()
  end
end
AttaQR:RegisterEvent("PLAYER_REGEN_DISABLED")

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
  self.frame.text:SetText(code)
  self.frame.qrTexture:SetTexCoord(unpack(coords))
end

function AttaQR:ClearCode()
  self.nextAbility = nil
  self:SetCode('noop')
end

function AttaQR:FixUIScaling()
  local ui_scale = UIParent:GetEffectiveScale()
  local height = select(2, GetPhysicalScreenSize())
  local scale = GetScreenDPIScale()
  local pp_scale = 768 / height / ui_scale * scale
  self.frame:SetScale(pp_scale);
end

function AttaQR:CreateQRFrame()
  local frame = CreateFrame("Frame", ADDON .. "Frame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
  local tile_size = self.db.profile.tile_size
  frame:SetFrameStrata("TOOLTIP")
  frame:SetWidth(tile_size + TILE_PAD)
  frame:SetHeight(tile_size + TILE_PAD)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:SetPoint("BOTTOMLEFT", TILE_PAD, TILE_PAD) -- TODO: Save Position
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

  local backdropInfo =
{
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
 	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
 	tile = true,
 	tileEdge = true,
 	tileSize = TILE_PAD,
 	edgeSize = TILE_PAD,
 	insets = { left = 1, right = 1, top = 1, bottom = 1 },
}

  frame:SetBackdrop(backdropInfo)
  
  local texture = frame:CreateTexture(nil, "ARTWORK")
  texture:SetTexture("Interface\\Addons\\" .. ADDON .. "\\Keys", "CLAMPTOWHITE", "CLAMPTOWHITE", "NEAREST")
  -- texture:SetAllPoints()
  texture:SetPoint("TOPLEFT", frame ,"TOPLEFT", 3, -3)
  texture:SetPoint("BOTTOMRIGHT", frame ,"BOTTOMRIGHT", -3, 3)

  frame.qrTexture = texture

  frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  frame.text:SetPoint("TOP", frame, "BOTTOM", 0, -5)
  frame.text:SetText("...")

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
