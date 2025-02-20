RollFor = RollFor or {}
local m = RollFor

if m.OptionsPopup then return end

local info = m.pretty_print

---@class OptionsPopup
---@field show fun( area: string )
---@field hide fun()

local M = m.Module.new( "OptionsPopup" )

M.center_point = { point = "CENTER", relative_point = "CENTER", x = 0, y = 150 }

---@param frame_builder FrameBuilderFactory
---@param awarded_loot AwardedLoot
---@param db table
---@param config Config
function M.new( frame_builder, awarded_loot, db, config )
  ---@class Frame
  local gui
  local popup
  local active_area

  local function is_out_of_bounds( x, y, frame_width, frame_height, screen_width, screen_height )
    local width = frame_width / 2
    local height = frame_height / 2
    local left = x - width
    local right = x + width
    local top = y + height
    local bottom = y - height

    return left < 0 or
        right > screen_width or
        top > 0 or
        bottom < -screen_height
  end

  local function on_drag_stop()
    if not popup then return end
    local width, height = popup:GetWidth(), popup:GetHeight()
    local screen_width, screen_height = m.api.GetScreenWidth(), m.api.GetScreenHeight()
    local _, _, _, x, y = popup:get_anchor_point()

    if is_out_of_bounds( x, y, width, height, screen_width, screen_height ) then
      db.point = M.center_point
      popup:position( M.center_point )

      return
    end

    local anchor_point, _, anchor_relative_point, anchor_x, anchor_y = popup:get_anchor_point()
    db.point = { point = anchor_point, relative_point = anchor_relative_point, x = anchor_x, y = anchor_y }
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
      config.notify_subscribers( this:GetParent().config, this:GetChecked() )
    end

    local function notify_awards()
      config.notify_subscribers( 'award_filter' )
    end

    ---@param title string
    ---@param populate function
    local function create_gui_entry( title, populate )
      if not gui.frames[ title ] then
        gui.frames[ title ] = e.CreateTabFrame( gui.frames, title )
        gui.frames[ title ].area = e.CreateArea( gui.frames, title, populate, active_area )
      end
    end

    ---@param caption string
    ---@param setting string
    ---@param widget string
    ---@param ufunc? function
    ---@return Frame
    local function create_config( caption, setting, widget, ufunc )
      if this.object_count == nil then
        this.object_count = 0
      else
        this.object_count = this.object_count + 1
      end

      local frame = m.api.CreateFrame( "Frame", nil, this )
      --frame:SetWidth( this.parent:GetRight()-this.parent:GetLeft()-20 )
      frame:SetWidth( 361 )
      frame:SetHeight( 22 )
      frame:SetPoint( "TOPLEFT", this, "TOPLEFT", 5, (this.object_count * -23) - 5 )
      frame.config = setting

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
        frame.caption:SetTextColor( .2, 1, .8, 1 )
        frame.caption:SetAllPoints( frame )
      end

      if not widget or widget == "text" then
        frame.input = m.api.CreateFrame( "EditBox", nil, frame )
        e.create_backdrop( frame.input, nil, true )
        frame.input:SetTextInsets( 5, 5, 5, 5 )
        frame.input:SetTextColor( .2, 1, .8, 1 )
        frame.input:SetJustifyH( "RIGHT" )
        frame.input:SetWidth( 50 )
        frame.input:SetHeight( 18 )
        frame.input:SetPoint( "RIGHT", -3, 0 )
        frame.input:SetFontObject( "GameFontNormal" )
        frame.input:SetAutoFocus( false )
        frame.input:SetText( db[ setting ] )
        frame.input:SetScript( "OnEscapePressed", function( self )
          this:ClearFocus()
        end )

        frame.input:SetScript( "OnTextChanged", function( self )
          if ufunc then
            ufunc()
          else
            if (type and type ~= "number") or tonumber( this:GetText() ) then
              if tonumber( this:GetText() ) ~= db[ setting ] then
                db[ setting ] = tonumber( this:GetText() )
                if ufunc then ufunc() end
              end
              this:SetTextColor( .2, 1, .8, 1 )
            else
              this:SetTextColor( 1, .3, .3, 1 )
            end
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
            set_nested_value( db, setting, true )
          else
            set_nested_value( db, setting, false )
          end

          if ufunc then ufunc() end
        end )

        if get_nested_value( db, setting ) == true then frame.input:SetChecked() end
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
        frame.button:SetPoint( "TOPLEFT", (this.parent:GetWidth() / 2 - w / 2) + 10, -5 )
        frame.button:SetTextColor( 1, 1, 1, 1 )
        frame.button:SetScript( "OnClick", ufunc )
        frame.button:SetScript( "OnEnter", function()
          this:SetBackdropBorderColor( .2, 1, .8, 1 )
        end )
        frame.button:SetScript( "OnLeave", function()
          this:SetBackdropBorderColor( .2, .2, .2, 1 )
        end )
      end

      return frame
    end

    local builder = frame_builder.new()
        :name( "rfOptionsFrame" )
        :width( 400 )
        :height( 350 )
        :bg_file( "Interface/Buttons/WHITE8x8" )
        :sound()
        :backdrop_color( 0, 0, 0, .85 )
        :gui_elements( m.GuiElements )
        :frame_style( "PrincessKenny" )
        :border_color( .2, .2, .2, 1 )
        :movable()
        :on_drag_stop( on_drag_stop )
        :esc()
        :self_centered_anchor()

    gui = builder:build()

    ---@diagnostic disable-next-line: undefined-field
    local title = gui:CreateFontString( nil, "ARTWORK", "GameFontNormalSmall" )
    title:SetTextColor( 1, 1, 1 )
    title:SetText( "|cff209ff9RollFor|r" )
    title:SetPoint( "TOPLEFT", gui, "TOPLEFT", 8, -8 )

    local close = m.api.CreateFrame( "Button", "rfOptionsClose", gui )
    close:SetPoint( "TOPRIGHT", -7, -7 )
    e.create_backdrop( close )
    close:SetHeight( 10 )
    close:SetWidth( 10 )
    close.texture = close:CreateTexture( "rfOptionsCloseTex" )
    close.texture:SetTexture( "Interface\\AddOns\\RollFor\\assets\\close.tga", "ARTWORK" )
    close.texture:ClearAllPoints()
    close.texture:SetAllPoints( close )
    close.texture:SetVertexColor( 1, .25, .25, 1 )
    close:SetScript( "OnEnter", function()
      this.backdrop:SetBackdropBorderColor( 1, .25, .25, 1 )
    end )

    close:SetScript( "OnLeave", function()
      e.create_backdrop( this )
    end )

    close:SetScript( "OnClick", function()
      this:GetParent():Hide()
    end )

    gui.frames = {}
    gui.frames.area = m.api.CreateFrame( "Frame", "area", gui )
    gui.frames.area:SetPoint( "TOPLEFT", title, "BOTTOMLEFT", 0, -7 )
    gui.frames.area:SetPoint( "BOTTOMRIGHT", -7, 7 )
    e.create_backdrop( gui.frames.area )

    create_gui_entry( "About", function()
      this.title = this:CreateFontString( "Status", "LOW", "GameFontWhite" )
      this.title:SetFont( "FONTS\\FRIZQT__.TTF", 18 )
      this.title:SetPoint( "TOPLEFT", 0, -50 )
      this.title:SetPoint( "RIGHT", this.parent, "RIGHT", 0, 0 )
      this.title:SetJustifyH( "CENTER" )
      this.title:SetText( "|cff209ff9RollFor|r" )

      this.versionc = this:CreateFontString( "Status", "LOW", "GameFontWhite" )
      this.versionc:SetPoint( "TOPLEFT", 150, -80 )
      this.versionc:SetWidth( 100 )
      this.versionc:SetJustifyH( "LEFT" )
      this.versionc:SetText( "Version:" )

      this.version = this:CreateFontString( "Status", "LOW", "GameFontWhite" )
      this.version:SetPoint( "TOPRIGHT", 230, -80 )
      this.version:SetWidth( 100 )
      this.version:SetJustifyH( "RIGHT" )
      this.version:SetText( m.get_addon_version().str )

      this.info = this:CreateFontString( "Status", "LOW", "GameFontWhite" )
      this.info:SetPoint( "TOPLEFT", 0, -120 )
      this.info:SetPoint( "RIGHT", this.parent, "RIGHT", 0, 0 )
      this.info:SetJustifyH( "CENTER" )
      this.info:SetText( "Check the minimap icon for new commands.\n\nBe a responsible Master Looter.\n\nHappy rolling! o7" )

      --[[
      local github = CreateFrame("Button", nil, this, "StaticPopupButtonTemplate" )
      github:SetPoint("TOPLEFT", 170, -200)
      github:SetWidth(100)
      github:SetHeight(20)
      github:SetText("GitHub")
      github:SetScript("OnClick", function()

      end)
      ]]
    end )

    create_gui_entry( "Settings", function()
      create_config( "General settings", "", "header" )
      create_config( "Master loot warning", "show_ml_warning", "checkbox", notify )
      create_config( "Auto raid-roll", "auto_raid_roll", "checkbox", notify )
      create_config( "Auto group loot", "auto_group_loot", "checkbox", notify )
      create_config( "Auto master loot", "auto_master_loot", "checkbox", notify )

      create_config( "Looting", "", "header" )
      create_config( "Master loot frame rows", "master_loot_frame_rows", "text", function()
        local v = tonumber( this:GetText() )
        if v and v >= 5 and v <= 20 then
          if db.master_loot_frame_rows ~= v then
            db.master_loot_frame_rows = v
            config.notify_subscribers( "master_loot_frame_rows" )
          end
          this:SetTextColor( .2, 1, .8, 1 )
        else
          this:SetTextColor( 1, .3, .3, 1 )
        end
      end )
      create_config( "Position loot frame at cursor", "loot_frame_cursor", "checkbox", function()
        config.notify_subscribers( 'reset_loot_frame' )
      end )
      create_config( "Reset loot frame position", "", "button", function()
        info( "Loot frame position has been reset." )
        config.notify_subscribers( "reset_loot_frame" )
      end )

      create_config( "Minimap", "", "header" )
      create_config( "Hide minimap icon", "minimap_button_hidden", "checkbox", notify )
      create_config( "Lock minimap icon", "minimap_button_locked", "checkbox", notify )
    end )
    create_gui_entry( "Rolling", function()
      create_config( "Roll settings", "", "header" )
      create_config( "Default rolling time", "default_rolling_time_seconds", "text", function()
        local v = tonumber( this:GetText() )
        if v and v >= 4 and v <= 15 then
          db.default_rolling_time_seconds = v
          this:SetTextColor( .2, 1, .8, 1 )
        else
          this:SetTextColor( 1, .3, .3, 1 )
        end
      end )
      create_config( "Rolling popup lock", "rolling_popup_lock", "checkbox", notify )
      create_config( "Show Raid roll again button", "raid_roll_again", "checkbox", notify )
      create_config( "MainSpec rolling threshold", "ms_roll_threshold", "text" )
      create_config( "OffSpec rolling threshold", "os_roll_threshold", "text" )
      create_config( "Enable transmog rolling", "tmog_rolling_enabled", "checkbox" )
      create_config( "Transmog rolling threshold", "tmog_roll_threshold", "text" )
      create_config( "Reset rolling popup position", "", "button", function()
        info( "Rolling popup position has been reset." )
        config.notify_subscribers( "reset_rolling_popup" )
      end )
    end )

    create_gui_entry( "Awards popup", function()
      create_config( "General", "", "header" )
      create_config( "Always keep awards data", "keep_award_data", "checkbox" )
      create_config( "Reset awards data", "", "button", function()
        awarded_loot.clear( true )
        notify_awards()
      end )

      create_config( "Item quality filter", "", "header" )
      create_config( "Poor", "award_filter.item_quality.Poor", "checkbox", notify_awards )
      create_config( "Common", "award_filter.item_quality.Common", "checkbox", notify_awards )
      create_config( "Uncommon", "award_filter.item_quality.Uncommon", "checkbox", notify_awards )
      create_config( "Rare", "award_filter.item_quality.Rare", "checkbox", notify_awards )
      create_config( "Epic", "award_filter.item_quality.Epic", "checkbox", notify_awards )
      create_config( "Legendary", "award_filter.item_quality.Legendary", "checkbox", notify_awards )

      create_config( "Roll type filter", "", "header" )
      create_config( "MainSpec", "award_filter.roll_type.MainSpec", "checkbox", notify_awards )
      create_config( "OffSpec", "award_filter.roll_type.OffSpec", "checkbox", notify_awards )
      create_config( "Transmog", "award_filter.roll_type.Transmog", "checkbox", notify_awards )
      create_config( "Soft reserve", "award_filter.roll_type.SoftRes", "checkbox", notify_awards )
      create_config( "Raid roll", "award_filter.roll_type.RR", "checkbox", notify_awards )
      create_config( "Other", "award_filter.roll_type.NA", "checkbox", notify_awards )
    end )

    return gui
  end

  local function refresh()
    M.debug.add( "refresh" )
    for id, frame in pairs( gui.frames ) do
      if type( frame ) == "table" and frame.area then
        if active_area ~= "" then
          if id == active_area then
            M.debug.add( "showing " .. id )
            frame.area:Show()
          else
            frame.area:Hide()
          end
        end
        if frame.area.scroll.content.setup then
          for _, child in ipairs( { frame.area.scroll.content:GetChildren() } ) do
            if child.config and child.input then
              if child.input:GetFrameType() == "CheckButton" then
                child.input:SetChecked( get_nested_value( db, child.config ) )
              elseif child.input:GetFrameType() == "EditBox" then
                child.input:SetText( db[ child.config ] )
              end
            end
          end
        end
      end
    end
  end

  local function show( area )
    if area == "" then area = "About" end
    M.debug.add( "show" )
    active_area = area
    if not popup then
      popup = create_popup()
    else
      refresh()
    end
    popup:Show()
  end

  local function hide()
    M.debug.add( "hide" )

    if popup then
      popup:Hide()
    end
  end

  local function get_frame()
    if not popup then
      create_popup()
    end

    return popup
  end

  local function ping()
    m.api.PlaySound( "igMainMenuOpen" )
  end

  ---@type OptionsPopup
  return {
    show = show,
    hide = hide,
    get_frame = get_frame,
    ping = ping
  }
end

m.OptionsPopup = M
return M
