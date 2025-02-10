RollFor = RollFor or {}
local m = RollFor

if m.WinnersPopup then return end

local c = m.colorize_player_by_class
local blue = m.colors.blue
---@diagnostic disable-next-line: deprecated
local getn = table.getn
local sort
local sortOrder = 'desc'

local button_defaults = {
  width = 80,
  height = 24,
  scale = 0.76
}

---@class WinnersPopup
---@field show fun()
---@field refresh fun( _, content: RollingPopupData )
---@field hide fun()
---@field border_color fun( _, color: RgbaColor )
---@field backdrop_color fun( _, color: RgbaColor )
---@field get_frame fun(): table
---@field ping fun()

local M = m.Module.new( "WinnersPopup" )

M.debug.enable( true )

M.center_point = { point = "CENTER", relative_point = "CENTER", x = 0, y = 150 }

---@param popup_builder PopupBuilder
---@param content_transformer WinnersPopupContentTransformer
---@param db table
---@param config Config
function M.new( popup_builder, content_transformer, db, awarded_loot, roll_controller, config )
  ---@type Popup?

  --awarded_loot.award('Zombiehunter', 16939, "\124cffa335ee\124Hitem:16939::::::::60:::::\124h[Dragonstalker's Helm]\124h\124r", m.Types.RollType.SoftRes)
  --awarded_loot.award('Kevieboipro', 16939, "\124cffa335ee\124Hitem:16939::::::::60:::::\124h[Dragonstalker's Helm]\124h\124r", m.Types.RollType.SoftRes)

  local popup
  db.point = db.point or M.center_point

  local top_padding = 14

  local function create_popup()
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

    local function get_point()
      if popup then
        local width, height = popup:GetWidth(), popup:GetHeight()
        local screen_width, screen_height = m.api.GetScreenWidth(), m.api.GetScreenHeight()
        local x, y = popup:get_anchor_center()

        if is_out_of_bounds( x, y, width, height, screen_width, screen_height ) then
          return M.center_point
        end
      elseif db.point then
        return db.point
      else
        return M.center_point
      end
    end

    local builder = popup_builder
        :name( "WinnersFrame" )
        :width( 190 )
        :height( 100 )
        :point( get_point() )
        :bg_file( "Interface/Buttons/WHITE8x8" )
        :sound()
        :backdrop_color( 0, 0, 0, 0.6 )
        :gui_elements( m.GuiElements )
        :frame_style( "PrincessKenny" )
        :border_color( 0.125, 0.623, 0.976, 0.2 )
        :movable()
        :on_drag_stop( on_drag_stop )
        :on_hide( function()
          if on_hide then
            on_hide()
          end
        end )
        :self_centered_anchor()

    local result = builder:build() 

    return result
  end

  local function refresh()
    if not popup then popup = create_popup() end
    popup:clear()
    local data =  awarded_loot.winners()
    --m.pretty_print("dump: " ..m.dump( data ))

    local function mySort(a, b)
      if sortOrder == 'asc' then
        return a[sort] < b[sort]
      else
        return a[sort] > b[sort]
      end
    end

    if (sort) then table.sort( data, mySort ) end

    for _, v in ipairs( content_transformer.transform( data ) ) do
      popup.add_line( v.type, function( type, frame, lines )
        if type == "text" then
          frame:SetText( v.value )
        elseif type == "empty_line" then
          frame:SetHeight( v.height or 4 )
        elseif type == "winner_header" then          
          frame['player_header']:SetScript( "OnClick", function()
            sort = 'player_name'
            sortOrder = (sortOrder == 'asc') and 'desc' or 'asc'
            refresh()            
          end)
          
          frame.item_header:SetScript( "OnClick", function()
            sort = 'item_id'
            sortOrder = (sortOrder == 'asc') and 'desc' or 'asc'
            refresh()
          end)

          frame.type_header:SetScript( "OnClick", function()
            sort = 'roll_type'
            sortOrder = (sortOrder == 'asc') and 'desc' or 'asc'
            refresh()
          end)  
        elseif type == "winner" then          
          frame.player_name:SetText( c( v.player_name, v.player_class ) )
          frame.item_link:SetText ( v.link )
          frame.roll_type:SetText( m.roll_type_color( v.roll_type, m.roll_type_abbrev( v.roll_type ) ) .. (v.rolling_strategy or ''))
        elseif type == "button" then
          frame:SetWidth( v.width or button_defaults.width )
          frame:SetHeight( v.height or button_defaults.height )
          frame:SetText( v.label or "" )
          frame:SetScale( v.scale or button_defaults.scale )

          if v.label == "Close" then
            frame:SetScript( "OnClick", function() popup:Hide() end )
          end
        end

        if type ~= "button" then
          local count = getn( lines )

          if count == 0 then
            local y = -top_padding - (v.padding or 0)
            frame:ClearAllPoints()
            frame:SetPoint( "TOP", popup, "TOP", 0, y )
          else
            local line_anchor = lines[ count ].frame
            frame:ClearAllPoints()
            frame:SetPoint( "TOP", line_anchor, "BOTTOM", 0, v.padding and -v.padding or 0 )
          end
        end
      end, 1)
    end    
  end
  
  local function show()
    M.debug.add( "show" )

    if not popup then
      popup = create_popup()
    else
      popup:clear()
    end

    popup:Show()
    sort = nil
    refresh()
  end

  local function hide()
    M.debug.add( "hide" )

    if popup then
      on_hide = nil
      popup:Hide()
    end
  end

  ---@param color RgbaColor
  local function border_color( _, color )
    if not popup then
      popup = create_popup()
    end

    popup:border_color( color.r, color.g, color.b, color.a )
  end

  ---@param color RgbaColor
  local function backdrop_color( _, color )
    if not popup then
      popup = create_popup()
    end

    popup:backdrop_color( color.r, color.g, color.b, color.a )
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

  local function on_loot_awarded()
    m.pretty_print("on loot awarded")
    refresh()
  end

  roll_controller.subscribe( "loot_awarded", on_loot_awarded )

  ---@type WinnersPopup
  return {
    show = show,
    refresh = refresh,
    hide = hide,
    border_color = border_color,
    backdrop_color = backdrop_color,
    get_frame = get_frame,
    ping = ping
  }
end




m.WinnersPopup = M
return M
