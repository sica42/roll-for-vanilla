RollFor = RollFor or {}
local m = RollFor

if m.GuiElements then return end

local hl = m.colors.hl

---@class GuiElements
---@field item_link fun( parent: Frame ): Frame
---@field item_link_with_icon fun( parent: Frame, text: string ): Frame
---@field text fun( parent: Frame, text: string ): Frame
---@field icon fun( parent: Frame, show: boolean, width: number, height: number ): Frame
---@field icon_text fun( parent: Frame, text: string ): Frame
---@field roll fun( parent: Frame ): Frame
---@field button fun( parent: Frame ): Frame
---@field info fun( parent: Frame ): Frame
---@field dropped_item fun( parent: Frame, text: string ): Frame

local M = {}

local function create_text_in_container( type, parent, container_width, alignment, text, inner_field )
  local container = m.create_backdrop_frame( m.api, type, nil, parent )
  container:SetWidth( container_width )
  local label = container:CreateFontString( nil, "ARTWORK", "GameFontNormalSmall" )

  label:SetTextColor( 1, 1, 1 )
  if text then label:SetText( text ) end

  if alignment then label:SetPoint( alignment, 0, 0 ) end
  container:SetHeight( label:GetHeight() )

  if inner_field then
    container[ inner_field ] = label
  else
    container.inner = label
  end

  return container
end

function M.empty_line( parent )
  local result = m.api.CreateFrame( "Frame", nil, parent )
  result:SetWidth( 2 )

  return result
end

function M.item_link_with_icon( parent, text )
  local container = create_text_in_container( "Button", parent, 20, nil, nil, "text" )

  local w = 14
  local h = 14
  local spacing = 10
  local count = 0
  local texture
  local tooltip_link

  container:SetPoint( "TOP", 0, 0 )
  container.icon = M.icon( container, true, w, h )
  container.icon:SetPoint( "LEFT", 0, 0 )
  container.icon:SetTexCoord( 1 / w, (w - 1) / w, 1 / h, (h - 1) / h )
  container.count = M.text( container )
  container.text:SetTextColor( 1, 1, 1 )

  if text then
    container.text:SetText( text )
  else
    container.text:SetText( "PrincessKenny" )
  end

  container:SetHeight( container.text:GetHeight() )

  local function resize()
    if texture then
      container.icon:Show()

      local anchor = container.icon
      local padding = spacing
      local count_width = 0

      if count > 1 then
        container.count:Show()
        container.count:ClearAllPoints()
        container.count:SetPoint( "LEFT", container.icon, "RIGHT", spacing, 0 )
        anchor = container.count
        padding = 0
        count_width = container.count:GetWidth()
      end

      container.text:ClearAllPoints()
      container.text:SetPoint( "LEFT", anchor, "RIGHT", padding, 0 )
      container:SetWidth( container.text:GetWidth() + w + count_width + spacing )
    else
      local anchor = container
      local count_width = 0

      if count > 1 then
        container.count:Show()
        container.count:ClearAllPoints()
        container.count:SetPoint( "LEFT", container.icon, "RIGHT", spacing, 0 )
        anchor = container.count
        count_width = container.count:GetWidth()
      end

      container.icon:Hide()
      container.text:ClearAllPoints()
      container.text:SetPoint( "LEFT", anchor, 0, 0 )
      container:SetWidth( count_width + container.text:GetWidth() )
    end
  end

  container.SetItem = function( _, i, tt_link )
    texture = i.texture
    count = i.count or 0
    tooltip_link = tt_link

    container.text:SetText( i.link )
    container.icon:SetTexture( texture )
    container.count:SetText( count > 1 and hl( string.format( "%sx", count ) ) or nil )

    resize()
  end

  local function on_enter( self )
    if not tooltip_link then return end
    if m.vanilla then self = this end

    m.api.GameTooltip:SetOwner( self, "ANCHOR_CURSOR" )
    m.api.GameTooltip:SetHyperlink( tooltip_link )
    m.api.GameTooltip:Show()
  end

  local function on_leave()
    m.api.GameTooltip:Hide()
  end

  container:SetScript( "OnEnter", on_enter )
  container:SetScript( "OnLeave", on_leave )
  container:SetScript( "OnClick", function()
    if not tooltip_link then return end

    if m.is_ctrl_key_down() then
      m.api.DressUpItemLink( container.text:GetText() )
      return
    end

    if m.is_shift_key_down() then
      m.link_item_in_chat( container.text:GetText() )
    end
  end )

  return container
end

function M.text( parent, text )
  local label = parent:CreateFontString( nil, "ARTWORK", "GameFontNormalSmall" )

  label:SetTextColor( 1, 1, 1 )
  label:SetNonSpaceWrap( false )

  if text then label:SetText( text ) end

  return label
end

function M.icon( parent, show, width, height )
  local icon = parent:CreateTexture( nil, "ARTWORK" )
  if not show then icon:Hide() end
  icon:SetWidth( width or 16 )
  icon:SetHeight( height or 16 )
  icon:SetTexture( "Interface\\AddOns\\RollFor\\assets\\icon-white2.tga" )

  return icon
end

function M.icon_text( parent, text )
  local container = create_text_in_container( "Button", parent, 20, nil, nil, "text" )

  container:SetPoint( "CENTER", 0, 0 )
  container.icon = M.icon( container, true )
  container.icon:SetPoint( "LEFT", 0, 0 )
  container.text:SetPoint( "LEFT", container.icon, "RIGHT", 3, 0 )
  container.text:SetTextColor( 1, 1, 1 )

  if text then container.text:SetText( text ) end

  container.SetText = function( _, v )
    container.text:SetText( v )
    container:SetWidth( container.text:GetWidth() + 19 )
  end

  return container
end

function M.roll( parent )
  local frame = m.create_backdrop_frame( m.api, "Button", nil, parent )
  frame:SetWidth( 170 )
  frame:SetHeight( 14 )
  frame:SetFrameStrata( "DIALOG" )
  frame:SetFrameLevel( parent:GetFrameLevel() + 1 )
  frame:SetBackdrop( {
    bgFile = "Interface/Buttons/WHITE8x8",
    tile = true,
    tileSize = 22,
  } )

  local function blue_hover( a )
    frame:SetBackdropColor( 0.125, 0.624, 0.976, a )
  end

  local function hover()
    if frame.is_selected then
      return
    end

    blue_hover( 0.2 )
  end

  frame.select = function()
    blue_hover( 0.3 )
    frame.is_selected = true
  end

  local function no_hover()
    if frame.is_selected then
      frame.select()
    else
      blue_hover( 0 )
    end
  end

  frame.deselect = function()
    blue_hover( 0 )
    frame.is_selected = false
  end

  frame:deselect()
  frame:SetScript( "OnEnter", function()
    hover()
  end )

  frame:SetScript( "OnLeave", function()
    no_hover()
  end )

  frame:EnableMouse( true )

  local roll_container = create_text_in_container( "Button", frame, 35, "RIGHT" )
  roll_container:SetPoint( "LEFT", 0, 0 )
  frame.roll = roll_container.inner

  local icon = M.icon( frame )
  icon:SetPoint( "LEFT", 22, 0 )
  frame.icon = icon

  roll_container:SetPoint( "LEFT", 0, 0 )
  frame.roll = roll_container.inner

  local player_name = M.text( frame )
  player_name:SetPoint( "CENTER", frame, "CENTER", 0, 0 )
  frame.player_name = player_name

  local roll_type_container = create_text_in_container( "Button", frame, 37, "LEFT" )
  roll_type_container:SetPoint( "RIGHT", 0, 0 )
  frame.roll_type = roll_type_container.inner

  return frame
end

function M.button( parent )
  local template = m.vanilla and "StaticPopupButtonTemplate" or "UIPanelButtonTemplate"
  local height = m.vanilla and 20 or 21

  local button = m.api.CreateFrame( "Button", nil, parent, template )
  button:SetWidth( 100 )
  button:SetHeight( height )
  button:SetText( "" )
  button:GetFontString():SetPoint( "CENTER", 0, -1 )

  return button
end

function M.award_button( parent )
  local template = m.vanilla and "StaticPopupButtonTemplate" or "UIPanelButtonTemplate"
  local height = m.vanilla and 20 or 21

  local button = m.api.CreateFrame( "Button", nil, parent, template )
  button:SetWidth( 100 )
  button:SetHeight( height )
  button:SetText( "" )
  button:GetFontString():SetPoint( "CENTER", 0, -1 )

  return button
end

---@param parent Frame
---@param text string
---@param tooltip string
---@param color table
---@param font_size number
function M.tiny_button( parent, text, tooltip, color, font_size )
  local button = m.api.CreateFrame( "Button", nil, parent )
  button:SetBackdrop( {
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = false,
    tileSize = 0,
    edgeSize = 0.5,
    insets = { left = 0, right = 0, top = 0, bottom = 0 }
  } )
  button:SetBackdropColor( 0, 0, 0, 1 )
  button:SetBackdropBorderColor( .2, .2, .2, 1 )
  button:SetHeight( 10 )
  button:SetWidth( 10 )
  local label = button:CreateFontString( nil, "ARTWORK" )
  label:SetFont( "FONTS\\FRIZQT__.TTF", font_size or 14 )
  label:SetPoint( "CENTER", 0, text == 'R' and 1 or 1.5 )
  label:SetText( text )
  label:SetTextColor( color.r, color.g, color.b, color.a or 1 )

  button:SetScript( "OnEnter", function()
    this:SetBackdropBorderColor( color.r, color.g, color.b, color.a or 1 )
    m.api.GameTooltip:SetOwner( this, "ANCHOR_RIGHT" )
    m.api.GameTooltip:SetText( tooltip )
    m.api.GameTooltip:SetScale( 0.8 )
    m.api.GameTooltip:Show()
  end )
  button:SetScript( "OnLeave", function()
    this:SetBackdropBorderColor( .2, .2, .2, 1 )
    m.api.GameTooltip:SetScale( 1 )
    m.api.GameTooltip:Hide()
  end )

  return button
end

---@param parent Frame
---@param on_start function
---@param on_end function
function M.resize_grip( parent, on_start, on_end )
  local button = m.api.CreateFrame( "Button", nil, parent )
  button:SetWidth( 16 )
  button:SetHeight( 16 )
  button.texture = button:CreateTexture()
  button.texture:SetTexture( "Interface\\AddOns\\RollFor\\assets\\resize-grip.tga", "ARTWORK" )
  button.texture:ClearAllPoints()
  button.texture:SetAllPoints( button )

  button:SetScript( "OnEnter", function()
    this.texture:SetBlendMode( "ADD" )
  end )
  button:SetScript( "OnLeave", function()
    this.texture:SetBlendMode( "BLEND" )
  end )
  button:SetScript( "OnMouseDown", function()
    this:GetParent():StartSizing( "BOTTOMRIGHT" )
    if on_start then on_start() end
  end )
  button:SetScript( "OnMouseUp", function()
    this:GetParent():StopMovingOrSizing()
    if on_end then on_end() end
  end )

  return button
end

function M.checkbox( parent, text, on_change )
  local frame = m.api.CreateFrame( "Frame", nil, parent )
  frame:SetPoint( "LEFT", 5, 0 )
  frame:SetHeight( 14 )

  local cb = m.api.CreateFrame( "CheckButton", nil, frame, "UICheckButtonTemplate" )
  cb:SetWidth( 14 )
  cb:SetHeight( 14 )
  cb:SetPoint( "LEFT", 2, 0 )
  cb:SetNormalTexture( "" )
  cb:SetPushedTexture( "" )
  cb:SetHighlightTexture( "" )
  cb:SetBackdrop( {
    bgFile = "Interface/Buttons/WHITE8x8",
    edgeFile = "Interface/Buttons/WHITE8x8",
    tile = false,
    tileSize = 0,
    edgeSize = 0.5,
    insets = { left = 0, right = 0, top = 0, bottom = 0 }
  } )
  cb:SetBackdropColor( 0, 0, 0, 1 )
  cb:SetBackdropBorderColor( .2, .2, .2, 1 )
  cb:SetScript( "OnClick", function()
    if on_change then on_change( cb:GetChecked() ) end
  end )
  frame.checkbox = cb

  local label = create_text_in_container( "Button", frame, 1, "LEFT", text )
  label.inner:SetJustifyH( "LEFT" )
  label:SetWidth( label.inner:GetWidth() )
  label:SetPoint( "LEFT", cb, "RIGHT", 5, 0 )
  label:SetScript( "OnClick", function()
    cb:SetChecked( not cb:GetChecked() )
    if on_change then on_change( cb:GetChecked() ) end
  end )

  frame:SetWidth( cb:GetWidth() + label:GetWidth() + 5 )

  return frame
end

function M.winners_header( parent, on_click )
  local frame = m.api.CreateFrame( "Frame", nil, parent )
  frame:SetWidth( 250 )
  frame:SetHeight( 14 )
  frame:SetFrameStrata( "DIALOG" )
  frame:SetFrameLevel( parent:GetFrameLevel() + 1 )
  frame:EnableMouse( true )

  local headers = {
    { text = "Player", name = "player_name",  width = 74 },
    { text = "Item",   name = "item_id",      width = 150 },
    { text = "Roll",   name = "winning_roll", width = 25 },
    { text = "Type",   name = "roll_type",    width = 25 }
  }

  for _, v in pairs( headers ) do
    local header = create_text_in_container( "Button", frame, v.width, nil, v.text )
    header.sort = v.name
    header:SetHeight( 14 )
    header.inner:SetPoint( v.name == "winning_roll" and "RIGHT" or "LEFT", v.name == "winning_roll" and -5 or 2, 0 )
    header:SetBackdrop( {
      bgFile = "Interface/Buttons/WHITE8x8",
      tile = true,
      tileSize = 22,
    } )
    header:SetBackdropColor( 0.125, 0.624, 0.976, 0.4 )
    header:SetScript( "OnClick", on_click )
    frame[ v.name .. "_header" ] = header
  end

  frame.player_name_header:SetPoint( "LEFT", 0, 0 )
  frame.roll_type_header:SetPoint( "RIGHT", 0, 0 )
  frame.winning_roll_header:SetPoint( "RIGHT", frame.roll_type_header, "LEFT", -1, 0 )
  frame.item_id_header:SetPoint( "LEFT", frame.player_name_header, "RIGHT", 1, 0 )
  frame.item_id_header:SetPoint( "RIGHT", frame.winning_roll_header, "LEFT", -1, 0 )

  return frame
end

function M.winner( parent )
  local frame = m.api.CreateFrame( "Button", nil, parent )
  frame:SetWidth( 250 )
  frame:SetHeight( 14 )
  frame:SetPoint( "LEFT", parent:GetParent(), "LEFT", 0, 0 )
  frame:SetPoint( "RIGHT", parent:GetParent(), "RIGHT", -13, 0 )
  frame:SetFrameStrata( "DIALOG" )
  frame:SetFrameLevel( parent:GetFrameLevel() + 1 )
  frame:SetBackdrop( {
    bgFile = "Interface/Buttons/WHITE8x8",
    tile = true,
    tileSize = 22,
  } )

  local function blue_hover( a )
    frame:SetBackdropColor( 0.125, 0.624, 0.976, a )
  end

  blue_hover( 0 )
  frame:SetScript( "OnEnter", function()
    blue_hover( 0.2 )
  end )

  frame:SetScript( "OnLeave", function()
    blue_hover( 0 )
  end )

  local player_name = create_text_in_container( "Frame", frame, 74, "LEFT", "dummy" )
  player_name.inner:SetJustifyH( "LEFT" )
  player_name:SetPoint( "LEFT", frame, "LEFT", 2, 0 )
  player_name:SetHeight( 14 )
  frame.player_name = player_name.inner

  local roll_type = create_text_in_container( "Frame", frame, 25, nil, "dummy" )
  roll_type.inner:SetJustifyH( "LEFT" )
  roll_type.inner:SetPoint( "LEFT", 5, 0 )
  roll_type:SetPoint( "RIGHT", 0, 0 )
  roll_type:SetHeight( 14 )
  frame.roll_type = roll_type.inner

  local winning_roll = create_text_in_container( "Frame", frame, 25, nil, "dummy" )
  winning_roll.inner:SetJustifyH( "RIGHT" )
  winning_roll.inner:SetPoint( "RIGHT", -5, 0 )
  winning_roll:SetPoint( "RIGHT", roll_type, "LEFT", -1, 0 )
  winning_roll:SetHeight( 14 )
  frame.winning_roll = winning_roll.inner

  local tooltip_link
  local item_link = create_text_in_container( "Button", frame, 1, "LEFT", "dummy" )
  item_link.inner:SetJustifyH( "LEFT" )
  item_link:SetPoint( "LEFT", player_name, "RIGHT", 1, 0 )
  item_link:SetPoint( "RIGHT", winning_roll, "LEFT", -1, 0 )
  item_link:SetHeight( item_link.inner:GetHeight() )
  frame.item_link = item_link

  frame.SetItem = function( _, itemLink )
    local function truncate_text( font_string, max )
      local item = font_string:GetText()
      local originalText = string.gsub( m.ItemUtils.get_item_name( font_string:GetText() ), "([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1" )
      local truncatedText = originalText

      while font_string:GetStringWidth() > max do
        truncatedText = string.sub( truncatedText, 1, -2 )
        font_string:SetText( "[" .. truncatedText .. "...]" )
      end

      if originalText == truncatedText then
        font_string:SetText( string.gsub( item, originalText, truncatedText ) )
      else
        font_string:SetText( string.gsub( item, originalText, truncatedText .. "..." ) )
      end
    end

    item_link.inner:SetText( itemLink )
    truncate_text( item_link.inner, frame:GetParent():GetParent():GetWidth() - 90 - winning_roll:GetWidth() )

    tooltip_link = m.ItemUtils.get_tooltip_link( itemLink )

    item_link:SetScript( "OnEnter", function()
      blue_hover( 0.2 )
    end )

    item_link:SetScript( "OnLeave", function()
      blue_hover( 0 )
    end )

    item_link:SetScript( "OnClick", function()
      if not tooltip_link then return end

      if m.is_ctrl_key_down() then
        m.api.DressUpItemLink( itemLink )
        return
      end

      if m.is_shift_key_down() then
        m.link_item_in_chat( itemLink )
        return
      end

      m.api.SetItemRef( tooltip_link, tooltip_link, "LeftButton" )
    end )
  end

  return frame
end

function M.create_scroll_frame( parent, name )
  local f = m.api.CreateFrame( "ScrollFrame", name, parent )

  f.slider = m.api.CreateFrame( "Slider", nil, f )
  f.slider:SetOrientation( 'VERTICAL' )
  f.slider:SetPoint( "TOPLEFT", f, "TOPRIGHT", -7, 0 )
  f.slider:SetPoint( "BOTTOMRIGHT", 0, 0 )
  f.slider:SetThumbTexture( "Interface\\AddOns\\RollFor\\assets\\col.tga" )
  f.slider.thumb = f.slider:GetThumbTexture()
  f.slider.thumb:SetHeight( 50 )
  f.slider.thumb:SetTexture( .125, .624, .976, .5 )

  f.slider:SetScript( "OnValueChanged", function()
    f:SetVerticalScroll( this:GetValue() )
    f.update_scroll_state()
  end )

  f.update_scroll_state = function()
    f.slider:SetMinMaxValues( 0, f:GetVerticalScrollRange() )
    f.slider:SetValue( f:GetVerticalScroll() )

    local r = f:GetHeight() + f:GetVerticalScrollRange()
    local v = f:GetHeight()
    local ratio = v / r

    if ratio < 1 then
      local size = math.floor( v * ratio )
      f.slider.thumb:SetHeight( size )
      f.slider:Show()
    else
      f.slider:Hide()
    end
  end

  f.scroll = function( self, step )
    step = step or 0

    local current = f:GetVerticalScroll()
    local max = f:GetVerticalScrollRange()
    local new = current - step

    if new >= max then
      f:SetVerticalScroll( max )
    elseif new <= 0 then
      f:SetVerticalScroll( 0 )
    else
      f:SetVerticalScroll( new )
    end

    f:update_scroll_state()
  end

  f:EnableMouseWheel( 1 )
  f:SetScript( "OnMouseWheel", function()
    this:scroll( arg1 * 10 )
  end )

  return f
end

function M.info( parent )
  local frame = m.api.CreateFrame( "Frame", nil, parent )
  frame:SetWidth( 11 )
  frame:SetHeight( 11 )
  frame:SetFrameStrata( "DIALOG" )
  frame:SetFrameLevel( parent:GetFrameLevel() + 1 )
  frame:EnableMouse( true )

  local icon = frame:CreateTexture( nil, "BACKGROUND" )
  icon:SetWidth( 11 )
  icon:SetHeight( 11 )
  icon:SetTexture( "Interface\\AddOns\\RollFor\\assets\\info.tga" )
  icon:SetPoint( "CENTER", 0, 0 )

  frame:SetScript( "OnEnter", function( self )
    if m.vanilla then self = this end

    self.tooltip_scale = m.api.GameTooltip:GetScale()
    m.api.GameTooltip:SetOwner( self, "ANCHOR_CURSOR" )
    m.api.GameTooltip:AddLine( frame.tooltip_info, 1, 1, 1 )
    m.api.GameTooltip:SetScale( 0.75 )
    m.api.GameTooltip:Show()
  end )

  frame:SetScript( "OnLeave", function( self )
    if m.vanilla then self = this end

    m.api.GameTooltip:Hide()
    m.api.GameTooltip:SetScale( self.tooltip_scale or 1 )
  end )

  return frame
end

local function create_icon_in_container( type, parent, w, h, icon_zoom )
  local result = m.create_backdrop_frame( m.api, type or "Button", nil, parent )
  result:SetWidth( w + 1 )
  result:SetHeight( h )

  result:SetBackdrop( {
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = false,
    tileSize = 0,
    edgeSize = 1,
    insets = { left = 0, right = 0, top = 0, bottom = 0 }
  } )

  result:SetBackdropBorderColor( 0, 0, 0, 1 )
  result:SetBackdropColor( 0, 0, 0, 0 )

  result.texture = M.icon( result, true, w, h )
  result.texture:SetPoint( "CENTER", 0, 0 )
  result.texture:SetTexCoord( icon_zoom / w, (w - icon_zoom) / w, icon_zoom / h, (h - icon_zoom) / h )

  return result
end

---@param parent Frame
function M.dropped_item( parent )
  local container = m.create_loot_button( m.api, parent )

  local w = 22
  local h = 22
  local spacing = 6
  local bind_spacing = 3
  local mouse_down = false
  local icon_zoom = 2

  local item

  container:SetHeight( h )
  container.name = create_text_in_container( "Frame", container, 20, "LEFT", nil, "text" )
  container.name.text:SetJustifyH( "LEFT" )
  container.name.text:SetTextColor( 1, 1, 1 )
  container.index = create_text_in_container( "Frame", container, 20, "CENTER", nil, "text" )
  container.index:SetPoint( "LEFT", 1, 0 )
  container.index:SetWidth( 16 )
  container.index:SetHeight( h )
  container.icon = create_icon_in_container( "Button", container, w, h, icon_zoom )
  container.icon:SetPoint( "LEFT", container.index, "RIGHT", 2, 0 )
  container.quantity = create_text_in_container( "Frame", container.icon, 20, "CENTER", nil, "text" )
  container.quantity:SetPoint( "BOTTOMRIGHT", -2, -1 )
  container.quantity:SetHeight( 16 )
  container.bind = create_text_in_container( "Frame", container, 15, "LEFT", nil, "text" )
  container.bind:SetPoint( "LEFT", container.icon, "RIGHT", 5, 0 )
  container.comment = create_text_in_container( "Button", container, 20, "CENTER", nil, "text" )
  container.comment:SetPoint( "RIGHT", -4, 0 )
  container.comment:SetHeight( 16 )

  local function resize()
    container.icon:Show()

    local index_width = container.index:GetWidth() + 1
    local icon_width = container.icon:GetWidth() + spacing
    local bind_width = item.bind and (container.bind:GetWidth() + bind_spacing) or 0
    local text_width = container.name.text:GetStringWidth() + spacing + 1
    local comment_width = container.comment:IsVisible() and container.comment:GetWidth() + spacing or 0

    local total_width = index_width + icon_width + bind_width + text_width + comment_width

    container:SetWidth( total_width )
    container:SetPoint( "LEFT", 0, 0 )
    container:SetPoint( "RIGHT", 0, 0 )
  end

  local function get_color( multiplier )
    local mult = multiplier or 1
    local color = m.api.ITEM_QUALITY_COLORS[ item.quality or 0 ]
    return color.r * mult, color.g * mult, color.b * mult
  end

  local function hovered_color()
    if not item then return end
    if item.is_selected then return end
    local r, g, b = get_color()
    container:SetBackdropColor( r, g, b, 0.3 )
  end

  local function clicked_color()
    local r, g, b = get_color()
    container:SetBackdropColor( r, g, b, 0.4 )
  end

  local function selected_color()
    if not item then return end
    local r, g, b = get_color()
    container:SetBackdropColor( r, g, b, 0.3 )
  end

  local function not_hovered_color()
    if not item or item.is_selected then return end
    container:SetBackdropColor( 0, 0, 0, 0.1 )
  end

  local function update()
    if not item then return end

    if not item.is_enabled then
      container:SetAlpha( 0.6 )
      return
    end

    if item.is_selected then
      selected_color()
    else
      not_hovered_color()
    end

    container:SetAlpha( 1 )
  end

  ---@param v LootFrameItem
  container.SetItem = function( _, v )
    item = v
    container.index.text:SetText( v.index )
    container.icon.texture:SetTexture( v.texture )
    container.name.text:SetText( m.colorize_item_by_quality( v.name, v.quality ) )

    if v.bind then
      container.bind.text:SetText( v.bind )
      container.bind:SetWidth( container.bind.text:GetStringWidth() )
      container.bind:Show()
      container.name:SetPoint( "LEFT", container.bind, "RIGHT", bind_spacing, 0 )
    else
      container.bind:Hide()
      container.name:SetPoint( "LEFT", container.icon, "RIGHT", spacing, 0 )
    end

    if v.comment then
      container.comment.text:SetText( v.comment )
      container.comment:Show()
      container.name:SetPoint( "RIGHT", container.comment, "LEFT", 0, 0 )
    else
      container.comment:Hide()
      container.name:SetPoint( "RIGHT", container, "RIGHT", 0, 0 )
    end

    if v.quantity and v.quantity > 1 then
      container.quantity:Show()
      container.quantity.text:SetText( v.quantity )
      container.quantity:SetWidth( container.quantity.text:GetStringWidth() )
    else
      container.quantity:Hide()
    end

    local function modifier_fn()
      if m.is_ctrl_key_down() then
        m.api.DressUpItemLink( v.link )
        return
      end

      if m.is_shift_key_down() then
        m.link_item_in_chat( v.link )
        return
      end
    end

    container:SetScript( "OnClick", v.is_enabled and not v.is_selected and v.click_fn or modifier_fn )
    container.icon:SetScript( "OnClick", v.is_enabled and not v.is_selected and v.click_fn or modifier_fn )
    container.comment:SetScript( "OnClick", v.is_enabled and not v.is_selected and v.click_fn or modifier_fn )

    if m.vanilla then
      -- Fucking hell this took forever to figure out. Fuck you Blizzard.
      -- For looting to work in vanilla, the frame must be of a "LootButton" type and
      -- then it comes with the SetSlot function that we need to use to set the slot.
      -- This will probably be a pain in the ass when porting.
      container:SetSlot( v.slot or 0 )
    end

    update()
    resize()
  end

  local function on_enter( self )
    if m.vanilla then self = this end

    if not item then return end
    if item.tooltip_link then
      m.api.GameTooltip:SetOwner( self, "ANCHOR_RIGHT" )
      m.api.GameTooltip:SetHyperlink( item.tooltip_link )
      m.api.GameTooltip:Show()
    end

    if not item.is_enabled then return end
    hovered_color()
  end

  container:SetBackdrop( {
    bgFile = "Interface/Buttons/WHITE8x8",
    tile = false,
    tileSize = 0,
  } )

  not_hovered_color()

  local function on_leave()
    m.api.GameTooltip:Hide()
    mouse_down = false
    not_hovered_color()
  end

  container.comment:SetScript( "OnEnter", function( self )
    if not item then return end
    if item.comment_tooltip then
      if m.vanilla then self = this end

      self.tooltip_scale = m.api.GameTooltip:GetScale()
      m.api.GameTooltip:SetOwner( self, "ANCHOR_RIGHT" )

      local result = ""

      for _, line in ipairs( item.comment_tooltip ) do
        if result ~= "" then result = result .. "\n" end
        result = result .. line
      end

      m.api.GameTooltip:AddLine( result, 1, 1, 1 )
      m.api.GameTooltip:SetScale( 0.9 )
      m.api.GameTooltip:Show()
    end

    if not item.is_enabled then return end
    hovered_color()
  end )

  container.comment:SetScript( "OnLeave", function( self )
    if m.vanilla then self = this end

    m.api.GameTooltip:Hide()
    m.api.GameTooltip:SetScale( self.tooltip_scale or 1 )
    mouse_down = false

    not_hovered_color()
  end )

  container.icon:SetScript( "OnEnter", on_enter )
  container.icon:SetScript( "OnLeave", on_leave )

  container:SetScript( "OnEnter", on_enter )
  container:SetScript( "OnLeave", on_leave )

  local function on_mouse_down()
    if not item then return end
    if not item.is_enabled or item.is_selected then return end

    mouse_down = true
    clicked_color()
  end

  local function on_mouse_up()
    if not item then return end
    if not item.is_enabled or item.is_selected then return end

    if not mouse_down then return end
    hovered_color()
  end

  container:SetScript( "OnMouseUp", on_mouse_up )
  container:SetScript( "OnMouseDown", on_mouse_down )
  container.icon:SetScript( "OnMouseUp", on_mouse_up )
  container.icon:SetScript( "OnMouseDown", on_mouse_down )

  container:SetScript( "OnShow", function()
    mouse_down = false
  end )

  return container
end

m.GuiElements = M
return M
