RollFor = RollFor or {}
local m = RollFor

if m.OptionsGuiElements then return end


local tabCount = 0

---@class OptionsGuiElements
---@field CreateBackdrop fun( f: Frame, insert: number, legacy: boolean, transp: number, backdropSetting: table )
---@field CreateScrollFrame fun( name: string, parent: Frame ): Frame
---@field CreateScrollChild fun( name: string, parent: Frame ): Frame
---@field CreateTabFrame fun( parent: table, title: string ): Frame
---@field CreateArea fun( parent: table, title: string, func: function ): Frame


local M = {}

local function SetAllPointsOffset(frame, parent, offset)
  frame:SetWidth( 100 )
  frame:SetHeight( 100 )
  frame:SetPoint("TOPLEFT", parent, "TOPLEFT", offset, -offset)
  frame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -offset, offset)  
end

local function GetPerfectPixel()
  if M.pixel then return M.pixel end

  local scale = GetCVar("uiScale")
  local resolution = GetCVar("gxResolution")
  local _, _, screenwidth, screenheight = strfind(resolution, "(.+)x(.+)")

  M.pixel = 768 / screenheight / scale
  M.pixel = M.pixel > 1 and 1 or M.pixel

  return M.pixel
end

local function GetBorderSize()
  local raw = 1
  local scaled = raw * GetPerfectPixel()
  return raw, scaled
end

function M.EntryUpdate()
  -- detect and skip during dropdowns
  local focus = GetMouseFocus()
  if focus and focus.parent and focus.parent.menu then
    if this.over then
      this.tex:Hide()
      this.over = nil
    end
    return
  end

  if MouseIsOver(this) and not this.over then
    this.tex:Show()
    this.over = true
  elseif not MouseIsOver(this) and this.over then
    this.tex:Hide()
    this.over = nil
  end
end

function M.CreateBackdrop( f, insert, legacy, transp, backdropSetting )
  if not f then return end

  local rawborder, border = GetBorderSize()

  if inset then
    rawborder = inset / GetPerfectPixel()
    border = inset
  end

  local br, bg, bb, ba = 0, 0, 0, 1
  local dr, dg, db, da = 0.2, 0.2, 0.2, 1
  local backdrop = {
    bgFile = "Interface\\BUTTONS\\WHITE8X8", tile = false, tileSize = 0,
    edgeFile = "Interface\\BUTTONS\\WHITE8X8", edgeSize = M.pixel,
    insets = {left = -M.pixel, right = -M.pixel, top = -M.pixel, bottom = -M.pixel},
  }

  if transp and transp < tonumber( ba ) then ba = transp end

  if legacy then
    if backdropSetting then f:SetBackdrop( backdropSetting ) end
    f:SetBackdrop( backdrop )
    f:SetBackdropColor( br, bg, bb, ba )
    f:SetBackdropBorderColor( dr, dg, db , da )
  else
    if not f.backdrop then
      if f:GetBackdrop() then f:SetBackdrop(nil) end

      local b = CreateFrame("Frame", nil, f)
      level = f:GetFrameLevel()
      if level < 1 then
        b:SetFrameLevel( level )
      else
        b:SetFrameLevel( level - 1 )
      end

      f.backdrop = b
    end

    f.backdrop:SetPoint( "TOPLEFT", f, "TOPLEFT", -border, border )
    f.backdrop:SetPoint( "BOTTOMRIGHT", f, "BOTTOMRIGHT", border, -border )
    f.backdrop:SetBackdrop( backdrop )
    f.backdrop:SetBackdropColor( br, bg, bb, ba )
    f.backdrop:SetBackdropBorderColor( dr, dg, db , da )
  end
end

function M.CreateScrollFrame(name, parent)
  local f = CreateFrame("ScrollFrame", name, parent)

  -- create slider
  f.slider = CreateFrame("Slider", nil, f)
  f.slider:SetOrientation('VERTICAL')
  f.slider:SetPoint("TOPLEFT", f, "TOPRIGHT", -7, 0)
  f.slider:SetPoint("BOTTOMRIGHT", 0, 0)
  f.slider:SetThumbTexture( "Interface\\AddOns\\RollFor\\assets\\col.tga" )
  f.slider.thumb = f.slider:GetThumbTexture()
  f.slider.thumb:SetHeight(50)
  f.slider.thumb:SetTexture(.3,1,.8,.5)

  f.slider:SetScript("OnValueChanged", function()
    f:SetVerticalScroll(this:GetValue())
    f.UpdateScrollState()
  end)

  f.UpdateScrollState = function()
    f.slider:SetMinMaxValues(0, f:GetVerticalScrollRange())
    f.slider:SetValue(f:GetVerticalScroll())

    local m = f:GetHeight()+f:GetVerticalScrollRange()
    local v = f:GetHeight()
    local ratio = v / m

    if ratio < 1 then
      local size = math.floor(v * ratio)
      f.slider.thumb:SetHeight(size)
      f.slider:Show()
    else
      f.slider:Hide()
    end
  end

  f.Scroll = function(self, step)
    local step = step or 0

    local current = f:GetVerticalScroll()
    local max = f:GetVerticalScrollRange()
    local new = current - step

    if new >= max then
      f:SetVerticalScroll(max)
    elseif new <= 0 then
      f:SetVerticalScroll(0)
    else
      f:SetVerticalScroll(new)
    end

    f:UpdateScrollState()
  end

  f:EnableMouseWheel(1)
  f:SetScript("OnMouseWheel", function()
    this:Scroll(arg1*10)
  end)

  return f
end

function M.CreateScrollChild(name, parent)
  local f = CreateFrame("Frame", name, parent)

  -- dummy values required
  f:SetWidth(1)
  f:SetHeight(1)
  f:SetAllPoints(parent)

  parent:SetScrollChild(f)

  f:SetScript("OnUpdate", function()
    this:GetParent():UpdateScrollState()
  end)

  return f
end

local width, height = 80, 20
function M.CreateTabFrame( parent, title )
  if not parent.area.count then parent.area.count = 0 end

  local f = CreateFrame("Button", nil, parent.area)
  f:SetPoint("TOPLEFT", parent.area, "TOPLEFT", parent.area.count*width, 0)
  f:SetPoint("BOTTOMRIGHT", parent.area, "TOPLEFT", (parent.area.count+1)*width, -height)
  f.parent = parent

  f:SetScript("OnClick", function()
    if this.area:IsShown() then
      return
    else
      for id, name in pairs(this.parent) do
        if type(name) == "table" and name.area and id ~= "parent" then
          name.area:Hide()
        end
      end
      this.area:Show()
    end
  end)

  f.bg = f:CreateTexture(nil, "BACKGROUND")
  f.bg:SetAllPoints()

  f.text = f:CreateFontString(nil, "LOW", "GameFontWhite")
  --f.text:SetFont(pfUI.font_default, C.global.font_size)
  f.text:SetAllPoints()
  f.text:SetText(title)

  parent.area.count = parent.area.count + 1

  return f
end

function M.CreateArea( parent, title, func, active_area )
  local f = CreateFrame("Frame", nil, parent.area)
  f:SetPoint("TOPLEFT", parent.area, "TOPLEFT", 0, -height)
  f:SetPoint("BOTTOMRIGHT", parent.area, "BOTTOMRIGHT", 0, 0)


  if not parent.firstarea and (active_area == "" or active_area == title) then
    parent.firstarea = true
  else
    f:Hide()
  end

  f.button = parent[title]

  f.bg = f:CreateTexture(nil, "BACKGROUND")
  f.bg:SetTexture(1,1,1,.05)
  f.bg:SetAllPoints()

  f:SetScript("OnShow", function()
    this.indexed = true
    this.button.text:SetTextColor(.2,1,.8,1)
    this.button.bg:SetTexture(1,1,1,1)
    this.button.bg:SetGradientAlpha("VERTICAL", 1,1,1,.05,  0,0,0,0)
  end)

  f:SetScript("OnHide", function()
    this.button.text:SetTextColor(1,1,1,1)
    this.button.bg:SetTexture(0,0,0,0)
  end)

  if func then
    f.scroll = M.CreateScrollFrame(nil, f)
    SetAllPointsOffset(f.scroll, f, 2)
    f.scroll.content = M.CreateScrollChild(nil, f.scroll)
    f.scroll.content.parent = f.scroll
    f.scroll.content:SetScript("OnShow", function()      
      if not this.setup then      
        func()
        this.setup = true
      end
    end)
  end

  return f
end

m.OptionsGuiElements = M
return M
