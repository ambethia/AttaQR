local ADDON, NS = ...

local DELTA = 0.2
local C = 0.003921

local Hekili = _G["Hekili"]
local SlashCmdList = _G["SlashCmdList"]

AttaQR = LibStub("AceAddon-3.0"):NewAddon(ADDON, "AceConsole-3.0", "AceEvent-3.0")

BINDING_NAME_ATTAQRVERIFY = "Verify AttaQR Functionality"

local isVerifying = false

local defaults = {
  profile = {
    enabled = true,
    automatic = true,
    label = false,
    pixel_size = 4
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
    pixel_size = {
      type = 'range',
      min = 1,
			max = 32,
			step = 1,
      name = 'Pixel Size',
      get = function(info) return AttaQR.db.profile.pixel_size end,
      set = 'SetPixelSize',
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
  else
    self.db.profile.enabled = false
    AttaQR.frame:Hide()
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

function AttaQR:SetPixelSize(info, val)
  self.db.profile.pixel_size = val
  self.frame:SetSize(val, val)
end

local function AttaQR_OnUpdate(_, elapsed)
  if _G['ACTIVE_CHAT_EDIT_BOX'] then
    AttaQR:ClearCode()
    return
  end

  local recommendation = Hekili.DisplayPool["Primary"].Recommendations[1]
  if recommendation.exact_time and recommendation.exact_time - GetTime()<= DELTA then
    AttaQR:SetCode(recommendation.keybind)
  else
    if not isVerifying then
      AttaQR:ClearCode()
    end
  end
end

function AttaQR:OnInitialize()
  self.db = LibStub("AceDB-3.0"):New(ADDON .. "DB", defaults, true)
  AceConfigDialog:AddToBlizOptions(ADDON, ADDON)

  self.frame = self:CreatePixelFrame()
  self:ConfigureSettings()
  self:ConfigureHekili()
  self.frame:SetScript("OnUpdate", AttaQR_OnUpdate)
end

function AttaQR:ConfigureSettings()
  SetCVar("empowerTapControls", 1)
end

function AttaQR:ConfigureHekili()
  AttaQR.hekiliDisplay = Hekili.DisplayPool["Primary"]
  local primary = Hekili.DB.profile.displays.Primary
  primary.primaryWidth = 32
  primary.primaryHeight = 32
  primary.numIcons = 1
  primary.visibility.advanced = true
  primary.visibility.pve.always = 0
  primary.visibility.pve.combat = 0
  primary.visibility.pve.target = 0
  primary.visibility.pve.combatTarget = 1
  primary.visibility.pvp.always = 0
  primary.visibility.pvp.combat = 0
  primary.visibility.pvp.target = 0
  primary.visibility.pvp.combatTarget = 11
  primary.range.type = "xclude"
  Hekili:BuildUI()
end

function AttaQR:SetCode(key)
  if key then
    local mod = 0
    local first = string.sub(key, 1, 1)
    local rest = string.sub(key, 2)

    if string.len(rest) > 0 then
      if first == 'S' then
        mod = NS.Keys['SHIFT']
        key = rest
      end

      if first == 'C' then
        mod = NS.Keys['CTRL']
        key = rest
      end

      if first == 'A' then
        mod = NS.Keys['ALT']
        key = rest
      end
    end

    local code = NS.Keys[key]

    if code then
      self.frame.text:SetText(key .. ' (' .. code .. ')' .. ' ' .. C)
      self.frame.pixel:SetColorTexture(255, mod / 255, code / 255, 1)
    else
      self.frame.pixel:SetColorTexture(0, 0, 0, 1)
      self.frame.text:SetText('!' .. first .. rest)
    end
  else
    self.frame.pixel:SetColorTexture(0, 0, 0, 1)
    self.frame.text:SetText('...')
  end
end

function AttaQR:ClearCode()
  self:SetCode(nil)
end

function AttaQR:Verify()
  local key = GetBindingKey("ATTAQRVERIFY")
  if not key then
    print("AttaQR verification keybind is not configured.")
    return
  end

  C_Timer.After(1, function()
    if isVerifying then
      isVerifying = false
      print("AttaQR might not be running.")
    end
    self:ClearCode()
  end)

  isVerifying = true
  key = key:gsub("CTRL%-", "C"):gsub("ALT%-", "A"):gsub("SHIFT%-", "S")
  print("Testing AttaQR...")
  AttaQR:SetCode(key)
end

SLASH_ATTAQR1 = "/attaqr"
SLASH_ATTAQR2 = "/atq"

SlashCmdList["ATTAQR"] = function()
  AttaQR:Verify()
end

function AttaQR:Verified()
  print("AttaQR is running.")
  isVerifying = false
  self:ClearCode()
end

function AttaQR:CreatePixelFrame()
  local frame = CreateFrame("Frame", ADDON .. "Frame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
  frame:SetFrameStrata("TOOLTIP")
  frame:SetFrameLevel(10000)
  frame:SetPoint("TOPLEFT", 0, 0)
  frame:SetSize(self.db.profile.pixel_size, self.db.profile.pixel_size)

  local texture = frame:CreateTexture()
  texture:SetAllPoints()

  frame.pixel = texture
  frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  frame.text:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 4, -4)
  frame.text:SetText("...")
  if not self.db.profile.label then
    frame.text:Hide()
  end
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
        AttaQR:SetEnableAttaQR(nil, false)
      else
        AttaQR:SetEnableAttaQR(nil, true)
      end
    end,
    OnTooltipShow = function(tt)
      tt:AddLine("AttaQR")
      tt:AddLine(" ")
      tt:AddLine("Click to toggle AttaQR.")
    end
  }
)
