---@diagnostic disable-next-line: undefined-global
local libStub = LibStub
local modules = libStub( "RollFor-Modules" )
if modules.LootAwardPopup then return end

local M = {}
local blue = modules.colors.blue

function M.new( item_utils )
  local popup
  local on_confirm
  local m_player
  local m_item_link

  local function create_popup()
    local edge_size = 18
    local height = 99

    local function create_main_frame()
      local frame = modules.api.CreateFrame( "Frame", "RollFormLootAssignmentFrame", modules.api.UIParent )
      frame:Hide()
      frame:SetWidth( 280 )
      frame:SetHeight( height )
      frame:SetPoint( "CENTER", 0, 150 )

      frame:SetBackdrop( {
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        tile = true,
        tileSize = 22,
        edgeSize = edge_size,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
      } )

      frame:SetBackdropColor( 0, 0, 0, 0.7 )
      return frame
    end

    local function create_font_string( parent, anchor )
      local font_string = parent:CreateFontString( nil, "ARTWORK", "GameFontNormalSmall" )
      font_string:SetPoint( "TOP", anchor, "BOTTOM", 0, -2 )
      font_string:SetText( "" )

      return font_string
    end

    local function create_button( parent, label, x )
      local button = modules.api.CreateFrame( "Button", nil, parent, "StaticPopupButtonTemplate" )
      button:SetWidth( 80 )
      button:SetHeight( 24 )
      button:SetPoint( "BOTTOM", x, 18 )
      button:SetText( label )
      button:SetScale( 0.76 )
      button:GetFontString():SetPoint( "CENTER", 0, -1 )

      return button
    end

    local function create_contents( parent )
      local item_string = modules.api.CreateFrame( "Button", nil, parent )
      item_string:SetPoint( "TOP", 0, -15 )
      item_string:SetWidth( 250 )
      item_string:SetHeight( 20 )

      item_string.text = item_string:CreateFontString( nil, "ARTWORK", "GameFontNormalSmall" )
      item_string.text:SetPoint( "CENTER", 0, 0 )
      item_string.text:SetText( "" )
      parent.item_string = item_string
      parent.item = item_string.text

      item_string:SetScript( "OnEnter", function()
        ---@diagnostic disable-next-line: undefined-global
        local self = this
        modules.api.GameTooltip:SetOwner( self, "ANCHOR_CURSOR" )
        modules.api.GameTooltip:SetHyperlink( parent.tooltip_link )
        modules.api.GameTooltip:Show()
      end )

      item_string:SetScript( "OnLeave", function()
        modules.api.GameTooltip:Hide()
      end )

      parent.text1 = create_font_string( parent, item_string )
      parent.text2 = create_font_string( parent, parent.text1 )

      local yes_button = create_button( parent, "Yes", -50 )
      yes_button:SetScript( "OnClick", function()
        if on_confirm then on_confirm( m_player, m_item_link ) end
        parent:Hide()
        parent:SetItemLink()
        parent:SetText1()
        parent:SetText2()
        m_player = nil
        m_item_link = nil
      end )

      local no_button = create_button( parent, "No", 50 )
      no_button:SetScript( "OnClick", function()
        parent:Hide()
        parent:SetItemLink()
        parent:SetText1()
        parent:SetText2()
        m_player = nil
        m_item_link = nil
      end )
    end

    local function configure_main_frame( frame )
      frame:SetScript( "OnShow", function()
        modules.api.PlaySound( "igMainMenuOpen" )
      end )

      frame:SetScript( "OnHide", function()
        modules.api.PlaySound( "igMainMenuClose" )
      end )

      frame:SetMovable( false )
      frame:EnableMouse( true )

      frame.Resize = function()
        local a, b, c = frame.item:GetWidth(), frame.text1:GetWidth(), frame.text2:GetWidth()
        local max = math.max( a, b, c )
        frame:SetWidth( max + 40 )
        frame.item_string:SetWidth( a )

        local txt2 = frame.text2:GetText()

        if not txt2 or txt2 == "" then
          frame:SetHeight( height - frame.text1:GetHeight() )
        else
          frame:SetHeight( height )
        end
      end

      frame.SetItemLink = function( _, item_link )
        m_item_link = item_link
        frame.tooltip_link = item_link and item_utils.get_tooltip_link( item_link )
        frame.item:SetText( item_link )
      end

      frame.SetText1 = function( _, text )
        frame.text1:SetText( text )
      end

      frame.SetText2 = function( _, text )
        frame.text2:SetText( text )
      end

      modules.api.tinsert( modules.api.UISpecialFrames, frame:GetName() )
    end

    local function create_title_frame( parent )
      local title_frame = modules.api.CreateFrame( "Frame", nil, parent )
      title_frame:SetWidth( 1 )
      title_frame:SetHeight( 1 )
      title_frame:SetPoint( "TOP", parent, "TOP", 0, 2.5 )

      local title = title_frame:CreateFontString( nil, "ARTWORK", "GameFontNormalSmall" )
      title:SetPoint( "TOP", title_frame, "TOP", 0, -1.5 )
      title:SetText( blue( "RollFor" ) )

      local title_bg = modules.api.CreateFrame( "Frame", nil, parent )
      title_bg:SetBackdrop( {
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        edgeSize = edge_size,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
      } )
      title_bg:SetBackdropColor( 0, 0, 0, 0 )
      title_bg:SetWidth( title:GetStringWidth() + 30 )
      title_bg:SetHeight( 23 )
      title_bg:SetPoint( "CENTER", title, "CENTER" )

      local title_bg_bg = modules.api.CreateFrame( "Frame", nil, title_bg )
      title_bg_bg:SetBackdrop( {
        bgFile = "Interface/Buttons/WHITE8x8",
        tile = true,
        tileSize = 8
      } )
      title_bg_bg:SetBackdropColor( 0, 0, 0, 1 )
      title_bg_bg:SetPoint( "TOPLEFT", title_bg, "TOPLEFT", 4, -4 )
      title_bg_bg:SetPoint( "BOTTOMRIGHT", title_bg, "BOTTOMRIGHT", -4, 4 )
      title_bg_bg:SetFrameLevel( title_bg:GetFrameLevel() )
      title_frame:SetFrameLevel( title_bg:GetFrameLevel() + 1 )
    end

    local frame = create_main_frame()
    create_contents( frame )
    create_title_frame( frame )
    configure_main_frame( frame )

    return frame
  end

  -- player -> MasterLootCandidates
  local function show( item_link, player, text1, text2 )
    if not popup then popup = create_popup() end

    m_player = player
    popup:SetItemLink( item_link )
    popup:SetText1( text1 )
    popup:SetText2( text2 )
    popup:Resize()
    popup:Show()
  end

  local function hide()
    if popup then popup:Hide() end
  end

  local function register_confirm_callback( callback_fn )
    on_confirm = callback_fn
  end

  return {
    show = show,
    hide = hide,
    register_confirm_callback = register_confirm_callback
  }
end

modules.LootAwardPopup = M
return M
