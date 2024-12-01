---@diagnostic disable-next-line: undefined-global
local libStub = LibStub
local modules = libStub( "RollFor-Modules" )
if modules.LootAwardPopup then return end

local M = {}
local item_utils = modules.ItemUtils

function M.new( popup_builder )
  local popup
  local on_confirm
  local m_player
  local m_item_link

  local function create_popup()
    local popup_height = 100
    local frame = popup_builder()
        :with_name( "RollFormLootAssignmentFrame" )
        :with_width( 280 )
        :with_height( popup_height )
        :with_sound()
        :with_button( "Yes", function( self )
          if on_confirm then on_confirm( m_player, m_item_link ) end
          self:Hide()
          self:SetItemLink()
          self:SetText1()
          self:SetText2()
          m_player = nil
          m_item_link = nil
        end )
        :with_button( "No", function( self )
          self:Hide()
          self:SetItemLink()
          self:SetText1()
          self:SetText2()
          m_player = nil
          m_item_link = nil
        end )
        :with_esc()
        :build()

    local function create_contents()
      local function create_font_string( parent, anchor )
        local font_string = parent:CreateFontString( nil, "ARTWORK", "GameFontNormalSmall" )
        font_string:SetPoint( "TOP", anchor, "BOTTOM", 0, -2 )
        font_string:SetText( "" )

        return font_string
      end

      local item_string = modules.api.CreateFrame( "Button", nil, frame )
      item_string:SetPoint( "TOP", 0, -15 )
      item_string:SetWidth( 250 )
      item_string:SetHeight( 20 )

      item_string.text = item_string:CreateFontString( nil, "ARTWORK", "GameFontNormalSmall" )
      item_string.text:SetPoint( "CENTER", 0, 0 )
      item_string.text:SetText( "" )
      frame.item_string = item_string
      frame.item = item_string.text

      item_string:SetScript( "OnEnter", function()
        ---@diagnostic disable-next-line: undefined-global
        local self = this
        modules.api.GameTooltip:SetOwner( self, "ANCHOR_CURSOR" )
        modules.api.GameTooltip:SetHyperlink( frame.tooltip_link )
        modules.api.GameTooltip:Show()
      end )

      item_string:SetScript( "OnLeave", function()
        modules.api.GameTooltip:Hide()
      end )

      frame.text1 = create_font_string( frame, item_string )
      frame.text2 = create_font_string( frame, frame.text1 )
    end

    create_contents()

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

    frame.Resize = function()
      local a, b, c = frame.item:GetWidth(), frame.text1:GetWidth(), frame.text2:GetWidth()
      local max = math.max( a, b, c )
      frame:SetWidth( max + 40 )
      frame.item_string:SetWidth( a )

      local txt2 = frame.text2:GetText()

      if not txt2 or txt2 == "" then
        frame:SetHeight( popup_height - frame.text1:GetHeight() )
      else
        frame:SetHeight( popup_height )
      end
    end

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
