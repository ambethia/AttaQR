local ADDON, NS = ...
local qrcode = NS.qrcode

local BLOCK_SIZE = 2
local BLOCK_COUNT = 21
local PADDING = 16

local AttaQR = LibStub("AceAddon-3.0"):NewAddon(ADDON, "AceEvent-3.0")
local AttaQRFrame = CreateFrame("Frame", ADDON .. "Frame", UIParent, UIPanelButtonTemplate)

local updateElapsed = 0

local function AttaQR_OnUpdate(_, elapsed)
  updateElapsed = updateElapsed + elapsed
  if updateElapsed >= 0.1 then
    updateElapsed = 0
    local abilityKey = AttaQR.hekiliDisplay.Recommendations[1].keybind
    if abilityKey and abilityKey ~= AttaQR.nextAbility then
      AttaQR.nextAbility = abilityKey
      if abilityKey then
        AttaQR:SetCode(abilityKey)
      else
        AttaQR:ClearCode()
      end
    end
  end
end

function AttaQR:SetCode(message)
  local ok, tab_or_message = qrcode(message)
  if not ok then
    print(tab_or_message)
  else
    local tab = tab_or_message
    local size = #tab
    for x = 1, #tab do
      for y = 1, #tab do
        if tab[x][y] > 0 then
          AttaQRFrame.QR.SetBlack((y - 1) * size + x - 1 + 1)
        else
          AttaQRFrame.QR.SetWhite((y - 1) * size + x - 1 + 1)
        end
      end
    end
  end
end

function AttaQR:ClearCode()
  for i = 1, BLOCK_COUNT * BLOCK_COUNT do
    AttaQRFrame.QR.SetWhite(i)
  end
end

function AttaQR:SetupKeybinds()
  local keyMap = {}
  for slot = 1, 120 do
    local actionType, id, subtype = GetActionInfo(slot)
    local key = AttaQR:GetKeyBinding(slot)
    if actionType == "spell" and key and id then
      keyMap[id] = key
    end
  end
  self.keyMap = keyMap
end

function AttaQR:SetupFrame()
  local f = AttaQRFrame
  f:SetFrameStrata("TOOLTIP")
  f:SetWidth(BLOCK_COUNT * BLOCK_SIZE + PADDING)
  f:SetHeight(BLOCK_COUNT * BLOCK_SIZE + PADDING)
  f:SetMovable(true)
  f:EnableMouse(true)
  local t = f:CreateTexture(nil, "OVERLAY")
  t:SetAllPoints(f)
  t:SetColorTexture(1, 1, 1)
  f:SetPoint("CENTER", 0, 0)
  f:RegisterForDrag("LeftButton")
  f:SetScript(
    "OnDragStart",
    function(self)
      self:StartMoving()
    end
  )
  f:SetScript(
    "OnDragStop",
    function(self)
      self:StopMovingOrSizing()
    end
  )
end

function AttaQR:SetupQR()
  local qr = CreateFrame("Frame", ADDON .. "QRFrame", AttaQRFrame)

  local function CreateBlock(idx)
    local t = CreateFrame("Frame", nil, qr)
    t:SetWidth(BLOCK_SIZE)
    t:SetHeight(BLOCK_SIZE)
    t.texture = t:CreateTexture(nil, "OVERLAY")
    t.texture:SetAllPoints(t)
    local x = (idx % BLOCK_COUNT) * BLOCK_SIZE
    local y = (math.floor(idx / BLOCK_COUNT)) * BLOCK_SIZE
    t:SetPoint("TOPLEFT", qr, x, -y)
    return t
  end

  qr:SetWidth(BLOCK_COUNT * BLOCK_SIZE)
  qr:SetHeight(BLOCK_COUNT * BLOCK_SIZE)
  qr:SetPoint("CENTER", 0, 0)
  qr.boxes = {}

  qr.SetBlack = function(idx)
    qr.boxes[idx].texture:SetColorTexture(0, 0, 0)
  end

  qr.SetWhite = function(idx)
    qr.boxes[idx].texture:SetColorTexture(1, 1, 1)
  end

  for i = 1, 441 do
    tinsert(qr.boxes, CreateBlock(i - 1))
  end
  AttaQRFrame.QR = qr
end

function AttaQR:Enable()
  AttaQRFrame:Show()
  AttaQRFrame:SetScript("OnUpdate", AttaQR_OnUpdate)
  self.hekiliDisplay = Hekili.DisplayPool["Primary"]
end

function AttaQR:Disable()
  AttaQRFrame:Hide()
  AttaQRFrame:SetScript("OnUpdate", nil)
end

function AttaQR:OnInitialize()
  if (not IsAddOnLoaded("Blizzard_DebugTools")) then
    LoadAddOn("Blizzard_DebugTools")
  end

  self:SetupFrame()
  self:SetupQR()
  self:Disable()
  self.nextAbility = nil
end

AttaQRLDB =
  LibStub("LibDataBroker-1.1"):NewDataObject(
  "AttaQR",
  {
    type = "data source",
    text = "",
    label = "AttaQR",
    icon = "Interface\\AddOns\\AttaQR\\icon",
    OnClick = function()
      if AttaQRFrame:IsShown() then
        AttaQR:Disable()
      else
        AttaQR:Enable()
      end
    end,
    OnTooltipShow = function(tt)
      tt:AddLine("AttaQR")
      tt:AddLine(" ")
      tt:AddLine("Click to toggle AttaQR Code")
    end
  }
)
