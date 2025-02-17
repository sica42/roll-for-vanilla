fRollFor = RollFor or {}
local m = RollFor

if m.OptionsPopup then return end

local info = m.pretty_print
local gui

---@class OptionsPopup
---@field show fun()
---@field hide fun()

local M = m.Module.new( "OptionsPopup" )

M.debug.enable( true )
M.center_point = { point = "CENTER", relative_point = "CENTER", x = 0, y = 150 }

---@param popup_builder PopupBuilder
---@param awarded_loot AwardedLoot
---@param db table
---@param config Config
function M.new( popup_builder, awarded_loot, db, config )
  local popup
  local active_area

  local function SetNestedValue(root, str, value)
    local current = root
    local lastKey

    for part in string.gmatch(str, "[^%.]+") do
      if lastKey then
        if not current[lastKey] then
          current[lastKey] = {}
        end
          current = current[lastKey]
      end
      lastKey = part
    end
    current[lastKey] = value
  end

  local function GetNestedValue(root, str)
    local current = root

    for part in string.gmatch(str, "[^%.]+") do
      if not current[part] then
        return nil
      end
      current = current[part]
    end
    return current
  end

  local function create_popup()
    M.debug.add( "Create popup" )
    local e = m.OptionsGuiElements

    local function notify()
      config.notify_subscribers( this:GetParent().config, this:GetChecked() )
    end

    local function notifyAwards()
      config.notify_subscribers( 'award_filter' )
    end

    local function CreateGUIEntry( title, populate )
      if not gui.frames[title] then
        gui.frames[title] = e.CreateTabFrame(gui.frames, title)
        gui.frames[title].area = e.CreateArea(gui.frames, title, populate, active_area )
      end
    end


    local function CreateConfig( caption, config, widget, ufunc )
      if not caption then return end

      if this.objectCount == nil then
        this.objectCount = 0
      else
        this.objectCount = this.objectCount + 1
      end

      local frame = CreateFrame( "Frame", nil, this )
      --frame:SetWidth( this.parent:GetRight()-this.parent:GetLeft()-20 )
      frame:SetWidth( 361 )
      frame:SetHeight( 22 )
      frame:SetPoint( "TOPLEFT", this, "TOPLEFT", 5, (this.objectCount*-23)-5 )
      frame.config = config


      if not widget or (widget and widget ~= "button") then

        if widget ~= "header" then
          frame:SetScript("OnUpdate", e.EntryUpdate)
          frame.tex = frame:CreateTexture(nil, "BACKGROUND")
          frame.tex:SetTexture(1,1,1,.05)
          frame.tex:SetAllPoints()
          frame.tex:Hide()
        end

        frame.caption = frame:CreateFontString( "Status", "LOW", "GameFontWhite" )
        frame.caption:SetPoint( "LEFT", frame, "LEFT", 3, 1 )
        frame.caption:SetJustifyH( "LEFT" )
        frame.caption:SetText( caption )
      end

      if widget == "header" then
        frame:SetBackdrop(nil)
        frame:SetHeight(40)
        this.objectCount = this.objectCount + 1
        frame.caption:SetJustifyH("LEFT")
        frame.caption:SetJustifyV("BOTTOM")
        frame.caption:SetTextColor(.2,1,.8,1)
        frame.caption:SetAllPoints(frame)
      end

      if not widget or widget == "text" then
        frame.input = CreateFrame("EditBox", nil, frame)
        m.OptionsGuiElements.CreateBackdrop(frame.input, nil, true)
        frame.input:SetTextInsets(5, 5, 5, 5)
        frame.input:SetTextColor(.2,1,.8,1)
        frame.input:SetJustifyH("RIGHT")
        frame.input:SetWidth(50)
        frame.input:SetHeight(18)
        frame.input:SetPoint("RIGHT" , -3, 0)
        frame.input:SetFontObject(GameFontNormal)
        frame.input:SetAutoFocus(false)
        frame.input:SetText(db[config])
        frame.input:SetScript("OnEscapePressed", function(self)
          this:ClearFocus()
        end)

        frame.input:SetScript("OnTextChanged", function(self)
          if ufunc then
            ufunc()
          else
            if ( type and type ~= "number" ) or tonumber( this:GetText() ) then
              if tonumber( this:GetText() ) ~= db[config] then
                db[config] = tonumber( this:GetText() )
                if ufunc then ufunc() end
              end
              this:SetTextColor(.2,1,.8,1)
            else
              this:SetTextColor(1,.3,.3,1)
            end
          end
        end)
      end

      if widget == "checkbox" then
        frame.input = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
        frame.input:SetNormalTexture("")
        frame.input:SetPushedTexture("")
        frame.input:SetHighlightTexture("")
        m.OptionsGuiElements.CreateBackdrop(frame.input, nil, true)
        frame.input:SetWidth(14)
        frame.input:SetHeight(14)
        frame.input:SetPoint("RIGHT" , -5, 1)
        frame.input:SetScript("OnClick", function ()
          if this:GetChecked() then
            SetNestedValue( db, config, true )
          else
            SetNestedValue( db, config, false )
          end

          if ufunc then ufunc() end
        end)

        if GetNestedValue( db, config ) == true then frame.input:SetChecked() end
      end

      if widget == "button" then
        frame.button = CreateFrame("Button", "rfButton", frame, "UIPanelButtonTemplate")
        e.CreateBackdrop(frame.button, nil, true)
        frame.button:SetNormalTexture("")
        frame.button:SetHighlightTexture("")
        frame.button:SetPushedTexture("")
        frame.button:SetDisabledTexture("")
        frame.button:SetText(caption)
        local w = frame.button:GetTextWidth() + 10
        frame.button:SetWidth( w )
        frame.button:SetHeight(20)
        frame.button:SetPoint("TOPLEFT", (this.parent:GetWidth() / 2 - w / 2)+10, -5)
        frame.button:SetTextColor(1,1,1,1)
        frame.button:SetScript("OnClick", ufunc)
        frame.button:SetScript("OnEnter", function()
          this:SetBackdropBorderColor( .2, 1, .8, 1 )          
        end)
        frame.button:SetScript("OnLeave", function()
          this:SetBackdropBorderColor(.2, .2, .2, 1 )          
        end)
      end

      return frame
    end

    gui = CreateFrame( "Frame", "rfOptionsFrame", m.api.UIParent )
    gui:SetMovable( true )
    gui:EnableMouse( true )
    gui:RegisterForDrag( "LeftButton" )
    gui:SetWidth( 400 )
    gui:SetHeight( 350 )
    gui:SetFrameStrata( "DIALOG" )
    gui:SetPoint( "CENTER", 0, 0 )
    gui:Hide()
    

    gui:SetScript("OnShow",function()
      print("Show options")
    end)

    gui:SetScript("OnHide",function()
      print("Hide options")
      gui:Hide()
    end)

    gui:SetScript( "OnDragStart", function()
      this:StartMoving()
    end)

    gui:SetScript("OnDragStop",function()
      this:StopMovingOrSizing()
    end)

    e.CreateBackdrop(gui, nil, true, .85)
    --CreateBackdropShadow(gui)    
    m.api.tinsert( m.api.UISpecialFrames, "rfOptionsFrame" )
    
    local header = gui:CreateFontString( nil, "ARTWORK", "GameFontNormalSmall" )
    header:SetTextColor( 1, 1, 1 )
    header:SetText( "|cff209ff9RollFor|r" )
    header:SetPoint( "TOPLEFT", gui, "TOPLEFT", 8, -8 )

    local close = CreateFrame("Button", "rfOptionsClose", gui )
    close:SetPoint("TOPRIGHT", -7, -7 )
    e.CreateBackdrop( close )
    close:SetHeight( 10 )
    close:SetWidth( 10 )
    close.texture = close:CreateTexture( "rfOptionsCloseTex" )
    close.texture:SetTexture( "Interface\\AddOns\\RollFor\\assets\\close.tga", "ARTWORK" )
    close.texture:ClearAllPoints()
    close.texture:SetAllPoints( close )
    close.texture:SetVertexColor( 1, .25, .25, 1 )
    close:SetScript("OnEnter", function ()
      this.backdrop:SetBackdropBorderColor(1,.25,.25,1)
    end)

    close:SetScript("OnLeave", function ()
      e.CreateBackdrop( this )
    end)

    close:SetScript("OnClick", function()
      this:GetParent():Hide()
    end)

    gui.frames = {}
    gui.frames.area = CreateFrame("Frame", "area", gui )
    gui.frames.area:SetPoint( "TOPLEFT", header, "BOTTOMLEFT", 0, -7 )
    gui.frames.area:SetPoint( "BOTTOMRIGHT", -7, 7 )
    e.CreateBackdrop( gui.frames.area )

    CreateGUIEntry("About", function()
      this.title = this:CreateFontString( "Status", "LOW", "GameFontWhite" )
      this.title:SetFont( "FONTS\\FRIZQT__.TTF", 18 )
      this.title:SetPoint( "TOPLEFT", 0, -50 )
      this.title:SetPoint( "RIGHT", this.parent, "RIGHT", 0, 0)
      this.title:SetJustifyH ( "CENTER" )
      this.title:SetText( "|cff209ff9RollFor|r" )

      this.versionc = this:CreateFontString( "Status", "LOW", "GameFontWhite" )
      this.versionc:SetPoint( "TOPLEFT", 150, -80 )
      this.versionc:SetWidth( 100 )
      this.versionc:SetJustifyH ( "LEFT" )
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

    end)

    CreateGUIEntry("Settings", function()
      local header = CreateConfig( "General settings", nil, "header")
      header:GetParent().objectCount = header:GetParent().objectCount - 1
      header:SetHeight(20)
      CreateConfig("Master loot frame rows", "master_loot_frame_rows", "text", function()
        local v = tonumber( this:GetText() )
        if v and v >= 5 and v <= 20 then
          if db.master_loot_frame_rows ~= v then
            db.master_loot_frame_rows = v
            config.notify_subscribers( "master_loot_frame_rows" )
            print("rows changed")
          end
          this:SetTextColor(.2,1,.8,1)
        else
          this:SetTextColor(1,.3,.3,1)
        end
      end)
      CreateConfig( "Master loot warning", "show_ml_warning", "checkbox", notify )
      CreateConfig( "Auto raid-roll", "auto_raid_roll", "checkbox", notify )
      CreateConfig( "Auto group loot", "auto_group_loot", "checkbox", notify )
      CreateConfig( "Auto master loot", "auto_master_loot", "checkbox", notify )
      CreateConfig( "Rolling popup lock", "rolling_popup_lock", "checkbox", notify )
      CreateConfig( "Show Raid roll again button", "raid_roll_again", "checkbox", notify )
      CreateConfig( "Position loot frame at cursor", "loot_frame_cursor", "checkbox", function()
        config.notify_subscribers( 'reset_loot_frame' )
      end)
      CreateConfig( "Reset loot frame position", nil, "button", function()
        info( "Loot frame position has been reset." )
        config.notify_subscribers( "reset_loot_frame" )
      end)

      CreateConfig( "Minimap", nil, "header")
      CreateConfig( "Hide minimap icon", "minimap_button_hidden", "checkbox", notify )
      CreateConfig( "Lock minimap icon", "minimap_button_locked", "checkbox", notify )

    end)
    CreateGUIEntry("Rolling", function()
      local header = CreateConfig( "Roll settings", nil, "header")
      header:GetParent().objectCount = header:GetParent().objectCount - 1
      header:SetHeight(20)

      CreateConfig("Default rolling time", "default_rolling_time_seconds", "text", function()
        local v = tonumber( this:GetText() )
        if v and v >= 4 and v <= 15 then
          db.default_rolling_time_seconds = v
          this:SetTextColor(.2,1,.8,1)
        else
          this:SetTextColor(1,.3,.3,1)
        end
      end)
      CreateConfig( "MainSpec rolling threshold", "ms_roll_threshold" )
      CreateConfig( "OffSpec rolling threshold", "os_roll_threshold" )
      CreateConfig( "Enable transmog rolling", "tmog_rolling_enabled", "checkbox" )
      CreateConfig( "Transmog rolling threshold", "tmog_roll_threshold" )
      CreateConfig( "Reset rolling popup position", nil, "button", function()
        info( "Rolling popup position has been reset." )
        config.notify_subscribers( "reset_rolling_popup" )
      end)
    end)

    CreateGUIEntry("Awards popup", function()
      local header = CreateConfig( "General", nil, "header")
      header:GetParent().objectCount = header:GetParent().objectCount - 1
      header:SetHeight(20)

      CreateConfig( "Always keep awards data", "keep_award_data", "checkbox" )
      CreateConfig( "Reset awards data", nil, "button", function()        
        awarded_loot.clear( true )
      end)

      local header = CreateConfig( "Item quality filter", nil, "header")
      CreateConfig( "Poor", "award_filter.itemQuality.Poor", "checkbox", notifyAwards )
      CreateConfig( "Common", "award_filter.itemQuality.Common", "checkbox", notifyAwards )
      CreateConfig( "Uncommon", "award_filter.itemQuality.Uncommon", "checkbox", notifyAwards )
      CreateConfig( "Rare", "award_filter.itemQuality.Rare", "checkbox", notifyAwards )
      CreateConfig( "Epic", "award_filter.itemQuality.Epic", "checkbox", notifyAwards )
      CreateConfig( "Legendary", "award_filter.itemQuality.Legendary", "checkbox", notifyAwards )

      CreateConfig( "Roll type filter", nil, "header", notifyAwards )
      CreateConfig( "MainSpec", "award_filter.rollType.MainSpec", "checkbox", notifyAwards )
      CreateConfig( "OffSpec", "award_filter.rollType.OffSpec", "checkbox", notifyAwards )
      CreateConfig( "Transmog", "award_filter.rollType.Transmog", "checkbox", notifyAwards )
      CreateConfig( "Soft reserve", "award_filter.rollType.SoftRes", "checkbox", notifyAwards )
      CreateConfig( "Raid roll", "award_filter.rollType.RR", "checkbox", notifyAwards )
      CreateConfig( "Other", "award_filter.rollType.NA", "checkbox", notifyAwards )

    end)

    
    return gui
  end

  local function refresh()
    M.debug.add( "refresh" )
    for id, frame in pairs( gui.frames ) do
      if type(frame) == "table" and frame.area then
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
                child.input:SetChecked( GetNestedValue( db, child.config ) )
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
      on_hide = nil
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
