local libStub = LibStub
local modules = libStub( "RollFor-Modules" )
if modules.MasterLootFrame then return end

local M = {}

local _G = getfenv()
local confirmation_dialog_key = "ROLLFOR_MASTER_LOOT_CONFIRMATION_DIALOG"
local button_width = 85
local button_height = 16
local horizontal_padding = 3
local vertical_padding = 5
local rows = 5

---@diagnostic disable-next-line: undefined-field
local mod = math.mod
---@diagnostic disable-next-line: deprecated
local getn = table.getn

local OldLootFrame_OnEvent = LootFrame_OnEvent

function LootFrame_OnEvent( event )
  if event ~= "OPEN_MASTER_LOOT_LIST" then
    OldLootFrame_OnEvent( event )
  end
end

local function highlight( frame )
  frame:SetBackdropColor( frame.color.r, frame.color.g, frame.color.b, 0.3 )
end

local function dim( frame )
  frame:SetBackdropColor( 0.5, 0.5, 0.5, 0.1 )
end

local function press( frame )
  frame:SetBackdropColor( frame.color.r, frame.color.g, frame.color.b, 0.7 )
end

local function hook_loot_buttons( reset_confirmation, normal_loot, master_loot, hide )
  for i = 1, modules.api.LOOTFRAME_NUMBUTTONS do
    local name = "LootButton" .. i
    local button = _G[ name ]

    if not button.OriginalOnClick then button.OriginalOnClick = button:GetScript( "OnClick" ) end

    button:SetScript( "OnClick", function()
      ---@diagnostic disable-next-line: undefined-global
      local self = button
      reset_confirmation()

      if modules.api.IsShiftKeyDown() then
        modules.api.ChatFrameEditBox:Show()
        modules.api.ChatFrameEditBox:SetText( string.format( "/rf %s", modules.api.GetLootSlotLink( self.slot ) ) )
        return
      end

      if modules.api.IsAltKeyDown() then
        modules.api.ChatFrameEditBox:Show()
        modules.api.ChatFrameEditBox:SetText( string.format( "/rr %s", modules.api.GetLootSlotLink( self.slot ) ) )
        return
      end

      if self.hasItem then
        modules.api.CloseDropDownMenus()
        master_loot( self )
        return
      end

      hide()
      normal_loot( self )
    end )
  end
end

local function restore_loot_buttons()
  for i = 1, modules.api.LOOTFRAME_NUMBUTTONS do
    local name = "LootButton" .. i
    local button = _G[ name ]

    if button.OriginalOnClick then button:SetScript( "OnClick", button.OriginalOnClick ) end
  end
end

local function create_main_frame()
  local frame = modules.api.CreateFrame( "Frame", "RollForLootFrame" )
  frame:Hide()
  frame:SetBackdrop( {
    bgFile = "Interface\\Tooltips\\UI-tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
  } )
  frame:SetBackdropColor( 0, 0, 0, 1 )
  frame:SetFrameStrata( "DIALOG" )
  frame:SetWidth( 100 )
  frame:SetHeight( 100 )
  frame:SetPoint( "CENTER", modules.api.UIParent, "Center" )
  frame:EnableMouse( true )
  frame:SetScript( "OnLeave",
    function()
      ---@diagnostic disable-next-line: undefined-global
      local self = this
      local mouse_x, mouse_y = modules.api.GetCursorPosition()
      local x, y = self:GetCenter()
      local width = self:GetWidth()
      local height = self:GetHeight()

      local is_over = mouse_x >= x - width / 2 and mouse_x <= x + width / 2 and mouse_y >= y - height / 2 and
          mouse_y <= y + height / 2

      if not is_over then self:Hide() end
    end )

  return frame
end

local function create_button( parent, index )
  local frame = modules.api.CreateFrame( "Button", "RollForLootFrameButton" .. index, parent )
  local width = 5 + horizontal_padding + modules.api.math.floor( (index - 1) / rows ) * (button_width + horizontal_padding)
  local height = -5 - vertical_padding - (mod( index - 1, rows ) * (button_height + vertical_padding))
  frame:SetWidth( button_width )
  frame:SetHeight( button_height )
  frame:SetPoint( "TOPLEFT", parent, "TOPLEFT", width, height )
  frame:SetBackdrop( { bgFile = "Interface\\Buttons\\WHITE8x8" } )
  frame:SetNormalTexture( "" )
  frame.parent = parent

  local text = frame:CreateFontString( nil, "OVERLAY", "GameFontNormalSmall" )
  text:SetPoint( "CENTER", frame, "CENTER" )
  text:SetText( "" )
  frame.text = text

  frame:SetScript( "OnEnter", function()
    ---@diagnostic disable-next-line: undefined-global
    local self = this
    highlight( self )
  end )

  frame:SetScript( "OnLeave", function()
    ---@diagnostic disable-next-line: undefined-global
    local self = this
    dim( self )
  end )

  frame:SetScript( "OnMouseDown", function()
    ---@diagnostic disable-next-line: undefined-global
    local self = this
    ---@diagnostic disable-next-line: undefined-global
    local button = arg1
    if button == "LeftButton" then press( self ) end
  end )

  frame:SetScript( "OnMouseUp", function()
    ---@diagnostic disable-next-line: undefined-global
    local self = this
    ---@diagnostic disable-next-line: undefined-global
    local button = arg1
    if button == "LeftButton" then
      if modules.api.MouseIsOver( self ) then
        highlight( self )
      else
        dim( self )
      end
    end
  end )

  return frame
end

local function show_confirmation_dialog( item_name, item_quality, player )
  local colored_item_name = modules.colorize_item_by_quality( item_name, item_quality )
  local colored_player_name = modules.colorize_player_by_class( player.name, player.class )
  return modules.api.StaticPopup_Show( confirmation_dialog_key, colored_item_name, colored_player_name );
end

local function create_custom_confirmation_dialog_data( on_confirm )
  modules.api.StaticPopupDialogs[ confirmation_dialog_key ] = {
    text = "Are you sure you want to give %s to %s?",
    button1 = modules.api.YES,
    button2 = modules.api.NO,
    OnAccept = function( data )
      on_confirm( modules.api.LootFrame.selectedSlot, data )
    end,
    timeout = 0,
    hideOnEscape = 1,
  };
end

function M.new()
  local m_frame
  local m_buttons = {}
  local m_dialog

  local function create( on_confirm )
    if m_frame then return end
    m_frame = create_main_frame()
    create_custom_confirmation_dialog_data( on_confirm )
  end

  local function hide_dialog()
    if m_dialog and m_dialog:IsVisible() then
      modules.api.StaticPopup_Hide( confirmation_dialog_key )
    end
  end

  local function create_candidate_frames( candidates )
    local total = getn( candidates )

    local columns = modules.api.math.ceil( total / rows )
    local total_rows = total < 5 and total or rows

    m_frame:SetWidth( (button_width + horizontal_padding) * columns + horizontal_padding + 11 )
    m_frame:SetHeight( (button_height + vertical_padding) * total_rows + vertical_padding + 11 )

    local function loop( i )
      if i > total then
        if m_buttons[ i ] then m_buttons[ i ]:Hide() end
        return
      end

      local candidate = candidates[ i ]

      if not m_buttons[ i ] then
        m_buttons[ i ] = create_button( m_frame, i )
      end

      local button = m_buttons[ i ]
      button.text:SetText( candidate.name )
      local color = modules.api.RAID_CLASS_COLORS[ string.upper( candidate.class ) ]
      button.color = color
      button.value = candidate.value
      button.player = candidate

      if color then
        button.text:SetTextColor( color.r, color.g, color.b )
        dim( button )
      else
        button.text:SetTextColor( 1, 1, 1 )
      end

      button:SetScript( "OnClick", function()
        ---@diagnostic disable-next-line: undefined-global
        local self = button
        local item_name = modules.api.LootFrame.selectedItemName
        local item_quality = modules.api.LootFrame.selectedQuality

        hide_dialog()
        m_dialog = show_confirmation_dialog( item_name, item_quality, self.player )

        if (m_dialog) then
          m_dialog.data = self.player
        end
      end )

      button:Show()
    end

    for i = 1, 40 do
      loop( i )
    end
  end

  local function show()
    if m_frame then m_frame:Show() end
  end

  local function hide()
    if m_frame then m_frame:Hide() end
    hide_dialog()
  end

  local function anchor( frame )
    m_frame:SetPoint( "TOPLEFT", frame, "BOTTOMLEFT", 0, 0 )
  end

  return {
    hook_loot_buttons = hook_loot_buttons,
    restore_loot_buttons = restore_loot_buttons,
    create = create,
    create_candidate_frames = create_candidate_frames,
    show = show,
    hide = hide,
    anchor = anchor
  }
end

modules.MasterLootFrame = M
return M
