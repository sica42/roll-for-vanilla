---@diagnostic disable-next-line: undefined-global
local libStub = LibStub
local modules = libStub( "RollFor-Modules" )
if modules.CustomPopup then return end

local blue = modules.colors.blue

local M = {}

function M.builder()
  local options = {}

  local function create_popup()
    local edge_size = 18
    local button_padding = 10
    local default_button_width = 80
    local default_button_height = 24
    local default_button_scale = 0.76

    local function create_main_frame()
      local frame = modules.api.CreateFrame( "Frame", options.name, modules.api.UIParent )
      frame:Hide()
      frame:SetWidth( options.width or 280 )
      frame:SetHeight( options.height or 100 )
      frame:SetPoint( "CENTER", 0, 150 )

      if options.frame_level then
        frame:SetFrameLevel( options.frame_level )
      else
        frame:SetFrameStrata( "DIALOG" )
      end

      frame:SetBackdrop( {
        bgFile = options.bg_file or "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        tile = true,
        tileSize = 22,
        edgeSize = edge_size,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
      } )

      if options.backdrop_color then
        local c = options.backdrop_color
        frame:SetBackdropColor( c.r, c.g, c.b, c.a or 1 )
      else
        frame:SetBackdropColor( 0, 0, 0, 0.7 )
      end

      return frame
    end

    local function create_button( parent, label, width, height, scale )
      local button = modules.api.CreateFrame( "Button", nil, parent, "StaticPopupButtonTemplate" )
      button:SetWidth( width or default_button_width )
      button:SetHeight( height or default_button_height )
      button:SetText( label )
      button:SetScale( scale or default_button_scale )
      button:GetFontString():SetPoint( "CENTER", 0, -1 )

      return button
    end

    local function create_buttons( parent )
      if not parent.buttons_frame then
        local frame = modules.api.CreateFrame( "Frame", nil, parent )
        frame:SetPoint( "BOTTOM", 0, 11 )
        parent.buttons_frame = frame
      end

      local total_width = 0
      local max_height = 0
      local last_anchor = nil

      for _, settings in ipairs( options.buttons or {} ) do
        local width = settings.width or default_button_width
        local height = settings.height or default_button_height
        local scale = settings.scale or default_button_scale
        if height > max_height then max_height = height end

        local button = create_button( parent.buttons_frame, settings.name, width, height, scale )

        if not last_anchor then
          button:SetPoint( "LEFT", parent.buttons_frame, "LEFT", 0, 0 )
          last_anchor = button
          total_width = total_width + (width * scale)
        else
          button:SetPoint( "LEFT", last_anchor, "RIGHT", button_padding, 0 )
          total_width = total_width + button_padding + (width * scale)
        end

        if settings.on_click then
          local click = settings.on_click -- Fucking lua 5.0 closures
          local frame = parent
          button:SetScript( "OnClick", function() click( frame ) end )
        end
      end

      parent.buttons_frame:SetWidth( total_width )
      parent.buttons_frame:SetHeight( max_height )
    end

    local function configure_main_frame( frame )
      if options.with_sound then
        frame:SetScript( "OnShow", function()
          modules.api.PlaySound( "igMainMenuOpen" )
        end )

        frame:SetScript( "OnHide", function()
          modules.api.PlaySound( "igMainMenuClose" )
        end )
      end

      frame:SetMovable( false )
      frame:EnableMouse( true )

      if options.esc then
        modules.api.tinsert( modules.api.UISpecialFrames, frame:GetName() )
      end
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
    create_buttons( frame )
    create_title_frame( frame )
    configure_main_frame( frame )

    return frame
  end

  local function with_name( self, name )
    options.name = name
    return self
  end

  local function with_height( self, height )
    options.height = height
    return self
  end

  local function with_width( self, width )
    options.width = width
    return self
  end

  local function with_sound( self )
    options.with_sound = true
    return self
  end

  local function with_frame_level( self, frame_level )
    options.frame_level = frame_level
    return self
  end

  local function with_button( self, name, on_click, width, height )
    options.buttons = options.buttons or {}
    table.insert( options.buttons, { name = name, on_click = on_click, width = width, height = height } )
    return self
  end

  local function with_esc( self )
    options.esc = true
    return self
  end

  local function build()
    return create_popup()
  end

  local function with_backdrop_color( self, r, g, b, a )
    options.backdrop_color = { r = r, g = g, b = b, a = a }
    return self
  end

  local function with_bg_file( self, bg_file )
    options.bg_file = bg_file
    return self
  end

  return {
    with_name = with_name,
    with_height = with_height,
    with_width = with_width,
    with_button = with_button,
    with_sound = with_sound,
    with_frame_level = with_frame_level,
    with_backdrop_color = with_backdrop_color,
    with_bg_file = with_bg_file,
    with_esc = with_esc,
    build = build
  }
end

modules.CustomPopup = M
return M
