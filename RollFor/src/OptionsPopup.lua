RollFor = RollFor or {}
local m = RollFor

if m.OptionsPopup then return end

local info = m.pretty_print
local blue = m.colors.blue

---@class OptionsPopup
---@field show fun( area: string )
---@field hide fun()

local M = m.Module.new( "OptionsPopup" )

M.center_point = { point = "CENTER", relative_point = "CENTER", x = 0, y = 150 }

---@param frame_builder FrameBuilderFactory
---@param awarded_loot AwardedLoot
---@param version_broadcast VersionBroadcast
---@param event_bus EventBus
---@param db table
---@param config_db table
---@param config Config
function M.new( frame_builder, awarded_loot, version_broadcast, event_bus, db, config_db, config )
  ---@class Frame
  local popup
  local frames

  local function on_drag_stop()
    if not popup then return end

    if m.is_frame_out_of_bounds( popup ) then
      popup:position( db.point or M.center_point )
      return
    end

    local anchor = popup:get_anchor_point()
    db.point = { point = anchor.point, relative_point = anchor.relative_point, x = anchor.x, y = anchor.y }
  end

  local function set_nested_value( root, str, value )
    local current = root
    local lastKey
    for part in string.gmatch( str, "[^%.]+" ) do
      if lastKey then
        if not current[ lastKey ] then
          current[ lastKey ] = {}
        end
        current = current[ lastKey ]
      end
      lastKey = part
    end
    current[ lastKey ] = value
  end

  local function get_nested_value( root, str )
    local current = root
    for part in string.gmatch( str, "[^%.]+" ) do
      if not current[ part ] then
        return nil
      end
      current = current[ part ]
    end
    return current
  end

  local function create_popup()
    M.debug.add( "Create popup" )
    local e = m.OptionsGuiElements

    local function notify()
      if this:GetObjectType() == "CheckButton" then
        config.notify_subscribers( this:GetParent().config, this:GetChecked() )
      else
        config.notify_subscribers( this:GetParent().config )
      end
    end

    ---@param title string
    ---@param populate function
    local function create_gui_entry( title, populate )
      if not frames[ title ] then
        frames[ title ] = e.create_tab_frame( frames, title )
        frames[ title ].area = e.create_area( frames, title, populate )
      end
    end

    ---@param caption string
    ---@param setting string|nil
    ---@param widget string
    ---@param tooltip string|nil
    ---@param ufunc? function
    ---@return Frame
    local function create_config( caption, setting, widget, tooltip, ufunc )
      local function parse_options()
        local w = string.sub( widget, 1, (string.find( widget, "|", nil, true ) or 0) - 1 )
        local options = {}
        for key, value in string.gmatch( widget, ("|(%a+)=([^|]+)") ) do
          options[ key ] = tonumber( value ) or value
        end

        return w, options
      end

      this.object_count = this.object_count == nil and 0 or this.object_count + 1

      local frame = m.api.CreateFrame( "Frame", nil, this )
      frame:SetWidth( popup:GetWidth() - 40 )
      frame:SetHeight( 22 )
      frame:SetPoint( "TOPLEFT", this, "TOPLEFT", 5, (this.object_count * -23) - 5 )
      frame.config = setting
      frame.tooltip = tooltip

      local options
      widget, options = parse_options()

      if not widget or (widget and widget ~= "button") then
        if widget ~= "header" then
          frame:SetScript( "OnUpdate", e.entry_update )
          frame.tex = frame:CreateTexture( nil, "BACKGROUND" )
          frame.tex:SetTexture( 1, 1, 1, .05 )
          frame.tex:SetAllPoints()
          frame.tex:Hide()
        end

        frame.caption = frame:CreateFontString( "Status", "LOW", "GameFontWhite" )
        frame.caption:SetPoint( "LEFT", frame, "LEFT", 3, 1 )
        frame.caption:SetJustifyH( "LEFT" )
        frame.caption:SetText( caption )
      end

      if widget == "header" then
        frame:SetBackdrop( nil )
        if not this.first_header then
          this.first_header = true
          frame:SetHeight( 20 )
        else
          frame:SetHeight( 40 )
          this.object_count = this.object_count + 1
        end
        frame.caption:SetJustifyH( "LEFT" )
        frame.caption:SetJustifyV( "BOTTOM" )
        frame.caption:SetTextColor( 0.1254, 0.6235, 0.9764, 1 )
        frame.caption:SetAllPoints( frame )
      end

      if setting then
        if not widget or widget == "number" then
          frame.input = m.api.CreateFrame( "EditBox", nil, frame )
          e.create_backdrop( frame.input, nil, true )
          frame.input:SetTextInsets( 5, 5, 5, 5 )
          frame.input:SetTextColor( 0.1254, 0.6235, 0.9764, 1 )
          frame.input:SetJustifyH( "RIGHT" )
          frame.input:SetWidth( 50 )
          frame.input:SetHeight( 18 )
          frame.input:SetPoint( "RIGHT", -3, 0 )
          frame.input:SetFontObject( "GameFontNormal" )
          frame.input:SetAutoFocus( false )
          frame.input:SetText( config_db[ setting ] )
          frame.input:SetScript( "OnEscapePressed", function( self )
            this:ClearFocus()
          end )

          frame.input:SetScript( "OnTextChanged", function( self )
            local v = tonumber( this:GetText() )
            local valid = v and ((not options.min or v >= options.min) and (not options.max or v <= options.max))

            if valid then
              if config_db[ setting ] ~= v then
                config_db[ setting ] = v
                if ufunc then ufunc() end
              end
              this:SetTextColor( 0.1254, 0.6235, 0.9764, 1 )
            else
              this:SetTextColor( 1, .3, .3, 1 )
            end
          end )
        end

        if widget == "checkbox" then
          frame.input = m.api.CreateFrame( "CheckButton", nil, frame, "UICheckButtonTemplate" )
          frame.input:SetNormalTexture( "" )
          frame.input:SetPushedTexture( "" )
          frame.input:SetHighlightTexture( "" )
          e.create_backdrop( frame.input, nil, true )
          frame.input:SetWidth( 14 )
          frame.input:SetHeight( 14 )
          frame.input:SetPoint( "RIGHT", -3, 1 )
          frame.input:SetScript( "OnClick", function()
            if this:GetChecked() then
              set_nested_value( config_db, setting, true )
            else
              set_nested_value( config_db, setting, false )
            end

            if ufunc then ufunc() end
          end )

          if get_nested_value( config_db, setting ) == true then frame.input:SetChecked() end
        end
      end

      if widget == "button" then
        frame.button = m.api.CreateFrame( "Button", "rfButton", frame, "UIPanelButtonTemplate" )
        e.create_backdrop( frame.button, nil, true )
        frame.button:SetNormalTexture( "" )
        frame.button:SetHighlightTexture( "" )
        frame.button:SetPushedTexture( "" )
        frame.button:SetDisabledTexture( "" )
        frame.button:SetText( caption )
        local w = frame.button:GetTextWidth() + 10
        frame.button:SetWidth( w )
        frame.button:SetHeight( 20 )
        frame.button:SetPoint( "TOPLEFT", (popup:GetWidth() / 2 - w / 2 - 10), -5 )
        frame.button:SetTextColor( 1, 1, 1, 1 )
        frame.button:SetScript( "OnClick", ufunc )
        frame.button:SetScript( "OnEnter", function()
          this:SetBackdropBorderColor( 0.1254, 0.6235, 0.9764, 1 )
          if this:GetParent():GetParent():GetParent():GetParent():GetParent():GetParent().show_help then
            if this:GetParent().tooltip then
              m.api.GameTooltip:SetOwner( this, "ANCHOR_TOPLEFT" )
              m.api.GameTooltip:SetText( this:GetParent().tooltip )
              m.api.GameTooltip:Show()
            end
          end
        end )
        frame.button:SetScript( "OnLeave", function()
          this:SetBackdropBorderColor( .2, .2, .2, 1 )
          if m.api.GameTooltip:IsShown() then
            m.api.GameTooltip:Hide()
          end
        end )
      end

      return frame
    end

    local frame = frame_builder.new()
        :name( "rfOptionsFrame" )
        :width( 400 )
        :height( 350 )
        :bg_file( "Interface/Buttons/WHITE8x8" )
        :sound()
        :backdrop_color( 0, 0, 0, .85 )
        :gui_elements( m.GuiElements )
        :frame_style( "Modern" )
        :border_color( .2, .2, .2, 1 )
        :movable()
        :on_drag_stop( on_drag_stop )
        :esc()
        :self_centered_anchor()
        :build()

    local title = frame:CreateFontString( nil, "ARTWORK", "GameFontNormalSmall" )
    title:SetPoint( "TOPLEFT", frame, "TOPLEFT", 8, -8 )
    title:SetText( blue( "RollFor" ) )

    local close_btn = m.GuiElements.tiny_button( frame, "X" )
    close_btn:SetPoint( "TOPRIGHT", -7, -7 )
    close_btn:SetScript( "OnClick", function()
      this:GetParent():Hide()
    end )

    local help_btn = m.GuiElements.tiny_button( frame, "?", "Click this icon and then hover over a field for more information.", "#E6CC40" )
    help_btn:SetPoint( "RIGHT", close_btn, "LEFT", -5, 0 )
    help_btn:SetScript( "OnClick", function()
      this.active = not this.active
      this:GetParent().show_help = this.active
    end )

    frames = {}
    frames.tab_area = m.api.CreateFrame( "Frame", "area", frame )
    frames.tab_area:SetPoint( "TOPLEFT", title, "BOTTOMLEFT", 0, -7 )
    frames.tab_area:SetPoint( "BOTTOMRIGHT", -7, 7 )
    e.create_backdrop( frames.tab_area )

    create_gui_entry( "About", function()
      this.title = this:CreateFontString( "Status", "LOW", "GameFontWhite" )
      this.title:SetFont( "FONTS\\FRIZQT__.TTF", 18 )
      this.title:SetPoint( "TOPLEFT", 0, -50 )
      this.title:SetPoint( "RIGHT", this.parent, "RIGHT", 0, 0 )
      this.title:SetJustifyH( "CENTER" )
      this.title:SetText( blue( "RollFor" ) )

      this.versionc = this:CreateFontString( "Status", "LOW", "GameFontWhite" )
      this.versionc:SetPoint( "TOPLEFT", 140, -80 )
      this.versionc:SetWidth( 100 )
      this.versionc:SetJustifyH( "LEFT" )
      this.versionc:SetText( "Version:" )

      this.version = this:CreateFontString( "Status", "LOW", "GameFontWhite" )
      this.version:SetPoint( "TOPRIGHT", 240, -80 )
      this.version:SetWidth( 100 )
      this.version:SetJustifyH( "RIGHT" )
      this.version:SetText( m.get_addon_version().str )

      local new_version = version_broadcast.new_version_available()
      if new_version and m.is_new_version( m.get_addon_version().str, new_version ) then
        this.newversion = this:CreateFontString( "Status", "LOW", "GameFontWhite" )
        this.newversion:SetPoint( "TOPLEFT", 0, -100 )
        this.newversion:SetPoint( "RIGHT", this.parent, "RIGHT", 0, 0 )
        this.newversion:SetJustifyH( "CENTER" )
        this.newversion:SetText( string.format( "New version (%s) is available!", m.colors.highlight( string.format( "v%s", new_version ) ) ) )
      end

      this.info = this:CreateFontString( "Status", "LOW", "GameFontWhite" )
      this.info:SetPoint( "TOPLEFT", 0, new_version and -140 or -120 )
      this.info:SetPoint( "RIGHT", this.parent, "RIGHT", 0, 0 )
      this.info:SetJustifyH( "CENTER" )
      this.info:SetText( "Check the minimap icon for new commands.\n\nBe a responsible Master Looter.\n\nHappy rolling! o7" )
    end )

    create_gui_entry( "General", function()
      create_config( "General settings", "", "header" )
      create_config( "Classic look", "classic_look", "checkbox", "Toggle classic look. Requires /reload", function()
        event_bus.notify( "config_change_requires_ui_reload", { key = "classic_look" } )
      end )
      create_config( "Master loot warning", "show_ml_warning", "checkbox", "Will show a warning when yada", notify )
      create_config( "Auto raid-roll", "auto_raid_roll", "checkbox", "Automatically do a raid-roll if noone rolls for an item", notify )
      create_config( "Auto group loot", "auto_group_loot", "checkbox", "Automatically sets loot mode back to group loot after boss is looted", notify )
      create_config( "Auto master loot", "auto_master_loot", "checkbox", "Automatically sets loot mode to master looter when a boss is targeted", notify )

      create_config( "Minimap", "", "header" )
      create_config( "Hide minimap icon", "minimap_button_hidden", "checkbox", nil, notify )
      create_config( "Lock minimap icon", "minimap_button_locked", "checkbox", nil, notify )

      create_config( "Awards data", "", "header" )
      create_config( "Always keep awards data", "keep_award_data", "checkbox", "Prevents the addon from clearing award data on disconnects" )
      create_config( "Reset awards data", "", "button", "Clears all the award data", function()
        awarded_loot.clear( true )
      end )
    end )

    create_gui_entry( "Looting", function()
      create_config( "Loot settings", nil, "header" )
      create_config( "Master loot frame rows", "master_loot_frame_rows", "number|min=5|max=20", "Value must be between 5 and 20 rows", notify )
      create_config( "Auto-loot", "auto_loot", "checkbox", "Auto-loot items below loot thresold. BoP items will not be auto looted." )
      create_config( "Auto-loot coins with SuperWow", "superwow_auto_loot_coins", "checkbox" )
      create_config( "Auto-loot messages", "auto_loot_messages", "checkbox" )
      create_config( "Announce auto-looted items", "auto_loot_announce", "checkbox" )
      create_config( "Position loot frame at cursor", "loot_frame_cursor", "checkbox", nil, function()
        config.notify_subscribers( 'reset_loot_frame' )
      end )
      create_config( "Reset loot frame position", nil, "button", nil, function()
        info( "Loot frame position has been reset." )
        config.notify_subscribers( "reset_loot_frame" )
      end )
    end )

    create_gui_entry( "Rolling", function()
      create_config( "Roll settings", nil, "header" )
      create_config( "Default rolling time", "default_rolling_time_seconds", "number|min=4|max=15", "Value must be between 4 and 15 seconds." )
      create_config( "Rolling popup lock", "rolling_popup_lock", "checkbox", nil, notify )
      create_config( "Show Raid roll again button", "raid_roll_again", "checkbox", nil, notify )
      create_config( "MainSpec rolling threshold", "ms_roll_threshold", "number" )
      create_config( "OffSpec rolling threshold", "os_roll_threshold", "number" )
      create_config( "Enable transmog rolling", "tmog_rolling_enabled", "checkbox" )
      create_config( "Transmog rolling threshold", "tmog_roll_threshold", "number" )
      create_config( "Reset rolling popup position", "", "button", nil, function()
        info( "Rolling popup position has been reset." )
        config.notify_subscribers( "reset_rolling_popup" )
      end )
    end )

    return frame
  end

  local function refresh()
    M.debug.add( "refresh" )
    for id, frame in pairs( frames ) do
      if type( frame ) == "table" and frame.area then
        frame.area:Hide()
        if frame.area.scroll.content.setup then
          for _, child in ipairs( { frame.area.scroll.content:GetChildren() } ) do
            if child.config and child.input then
              if child.input:GetFrameType() == "CheckButton" then
                child.input:SetChecked( get_nested_value( config_db, child.config ) )
              elseif child.input:GetFrameType() == "EditBox" then
                child.input:SetText( config_db[ child.config ] )
              end
            end
          end
        end
      end
    end
  end

  local function show( area )
    M.debug.add( "show" )
    if not popup then
      popup = create_popup()
    else
      refresh()
    end

    popup:Show()
    if area == "" then area = "About" end
    frames[ area ].area:Show()
  end

  local function hide()
    M.debug.add( "hide" )

    if popup then
      popup:Hide()
    end
  end

  ---@type OptionsPopup
  return {
    show = show,
    hide = hide
  }
end

m.OptionsPopup = M
return M
