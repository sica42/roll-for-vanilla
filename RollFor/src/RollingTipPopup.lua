---@diagnostic disable-next-line: undefined-global
local libStub = LibStub
local modules = libStub( "RollFor-Modules" )
if modules.RollingTipPopup then return end

local M = {}

local blue = modules.colors.blue
local green = modules.colors.green
local white = modules.colors.white

function M.new( popup_builder, config )
  local popup

  local function create_popup()
    local frame = popup_builder()
        :with_name( "RollForTipFrame" )
        :with_width( 130 )
        :with_height( 57 )
        ---@diagnostic disable-next-line: undefined-global
        :with_frame_level( LootFrame:GetFrameLevel() )
        :with_bg_file( "Interface/Buttons/WHITE8x8" )
        :with_backdrop_color( 0, 0, 0, 0.6 )
        :build()

    local function create_font_string( parent, text, anchor )
      local font_string = parent:CreateFontString( nil, "ARTWORK", "GameFontNormalSmall" )

      if not anchor then
        font_string:SetPoint( "TOP", parent, "TOP", 0, -20 )
      else
        font_string:SetPoint( "TOP", anchor, "BOTTOM", 0, -2 )
      end

      font_string:SetText( text )

      return font_string
    end

    local text1 = create_font_string( frame, string.format( "%s %s", blue( "Shift" ), white( "click to roll." ) ) )
    create_font_string( frame, string.format( "%s %s", green( "Alt" ), white( "click to raid-roll." ) ), text1 )

    return frame
  end

  local function show()
    if not config.show_rolling_tip() then return end
    if not popup then popup = create_popup() end

    if modules.uses_pfui() and config.pfui_integration_enabled() then
      ---@diagnostic disable-next-line: undefined-global
      popup:SetPoint( "TOPRIGHT", pfLootFrame, "TOPLEFT", -2, 5 )
    else
      ---@diagnostic disable-next-line: undefined-global
      popup:SetPoint( "BOTTOMLEFT", LootFrame, "TOPLEFT", 59, -15 )
      ---@diagnostic disable-next-line: undefined-global
      popup:SetPoint( "BOTTOMLEFT", LootFrame, "TOPLEFT", 59, -15 )
      ---@diagnostic disable-next-line: undefined-global
      popup:SetFrameLevel( LootFrame:GetFrameLevel() - 1 )
    end

    popup:Show()
  end

  local function on_loot_opened()
    if modules.is_player_master_looter() then
      local count_items_to_loot = modules.count_items_to_master_loot()
      if count_items_to_loot == 0 then return end

      show()
    end
  end

  local function on_loot_closed()
    if popup then popup:Hide() end
  end

  return {
    show = show,
    on_loot_opened = on_loot_opened,
    on_loot_closed = on_loot_closed
  }
end

modules.RollingTipPopup = M
return M
