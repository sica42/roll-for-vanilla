RollFor = RollFor or {}
local m = RollFor

if m.WinnersPopup then return end

local c = m.colorize_player_by_class
local r = m.roll_type_color
local blue = m.colors.blue
---@diagnostic disable-next-line: deprecated
local getn = table.getn
local filter = m.filter
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
---@field get_frame fun(): table
---@field ping fun()

local M = m.Module.new( "WinnersPopup" )

M.debug.enable( true )
M.center_point = { point = "CENTER", relative_point = "CENTER", x = 0, y = 150 }

---@param popup_builder PopupBuilder
---@param db table
---@param awarded_loot AwardedLoot
---@param roll_controller RollController
---@param options_popup OptionsPopup
---@param config Config
function M.new( popup_builder, db, awarded_loot, roll_controller, options_popup, config )
  ---@type Popup?

  --awarded_loot.award('Zombiehunter', 16939, m.Types.RollType.MainSpec)
  --awarded_loot.award('Kevieboipro', 16939, m.Types.RollType.Transmog)
  --awarded_loot.award('Sica', 5504, m.Types.RollType.MainSpec, m.Types.RollingStrategy.RaidRoll)
  --awarded_loot.award('Sica', 10652 )
  --awarded_loot.award('Sica', 19019,  m.Types.RollType.MainSpec, m.Types.RollingStrategy.SoftResRoll)

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
        :name( "rfWinnersFrame" )
        :width( 200 )
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
    M.debug.add( "refresh" )
    if not popup then popup = create_popup() end
    popup:clear()

    local data = awarded_loot.get_winners()
    for _, v in ipairs( data ) do
      if not v.roll_type then
        v.roll_type = "NA"
      elseif v.roll_type == m.Types.RollType.MainSpec and (v.rolling_strategy == m.Types.RollingStrategy.RaidRoll or v.rolling_strategy == m.Types.RollingStrategy.InstaRaidRoll) then
        v.roll_type = "RR"
      end
    end

    local filters = config.award_filter()
    local quality_filter = {}
    for q, v in pairs ( filters.itemQuality ) do
      if v then
        table.insert( quality_filter, m.Types.ItemQuality[q] )
      end
    end

    local rolltype_filter = {}
    for t, v in pairs ( filters.rollType ) do
      if v then
        table.insert( rolltype_filter, t )
      end
    end

    data = filter( data , function( item )
      local quality = item.quality or 0
      return m.table_contains_value(quality_filter, quality) and m.table_contains_value(rolltype_filter, item.roll_type)
    end )

    local function mySort(a, b)
      local valA, valB = a[sort] or '', b[sort] or ''

      if valA ~= valB then
        if sortOrder == 'asc' then
          return valA < valB
        else
          return valA > valB
        end
      end

      return a.item_id < b.item_id
    end

    if (sort) then table.sort( data, mySort ) end

    local content = {}

    table.insert(content, {type = "text", value = "Winners"} )
    table.insert(content, {type = "empty_line"} )
    table.insert(content, {type = "winner_header"} )

    for _, item in pairs( data ) do
      table.insert(content, {type = "winner", player_name = item.player_name, player_class = item.player_class, itemLink = item.itemLink, roll_type = item.roll_type, rolling_strategy = item.rolling_strategy, quality = item.quality})
    end

    table.insert(content, {type = "button", label = "Options" } )
    table.insert(content, {type = "button", label = "Close" } )

    for _, v in ipairs( content ) do
      popup.add_line( v.type, function( type, frame, lines )
        if type == "text" then
          frame:SetText( v.value )
        elseif type == "empty_line" then
          frame:SetHeight( v.height or 6 )
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
          local roll_type_abbrev = v.roll_type == 'RR' and 'RR' or v.roll_type == 'NA' and 'NA' or m.roll_type_abbrev( v.roll_type )
          frame:SetItem( v.itemLink )
          frame.player_name:SetText( c( v.player_name, v.player_class ) )
          frame.roll_type:SetText( r( v.roll_type, roll_type_abbrev ) )
        elseif type == "button" then
          frame:SetWidth( v.width or button_defaults.width )
          frame:SetHeight( v.height or button_defaults.height )
          frame:SetText( v.label or "" )
          frame:SetScale( v.scale or button_defaults.scale )

          if v.label == "Close" then
            frame:SetScript( "OnClick", function()
              popup:Hide()
            end )
          elseif v.label == "Options" then
            frame:SetScript( "OnClick", function()
              options_popup.show('Awards popup')
            end )
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

  local function get_frame()
    if not popup then
      create_popup()
    end

    return popup
  end

  local function ping()
    m.api.PlaySound( "igMainMenuOpen" )
  end

  local function onUpdate()
    if popup and popup:IsVisible() then
      refresh()
    end
  end

  roll_controller.subscribe( "loot_awarded", onUpdate )
  config.subscribe( "award_filter", onUpdate )

  ---@type WinnersPopup
  return {
    show = show,
    refresh = refresh,
    hide = hide,
    get_frame = get_frame,
    ping = ping
  }
end




m.WinnersPopup = M
return M
