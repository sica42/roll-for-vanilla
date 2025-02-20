RollFor = RollFor or {}
local m = RollFor

if m.WinnersPopup then return end

local c = m.colorize_player_by_class
local r = m.roll_type_color
local filter = m.filter
local sort
local sort_order = "asc"

---@diagnostic disable-next-line: deprecated
local getn = table.getn

---@class WinnersPopup
---@field show fun()
---@field refresh fun()
---@field hide fun()
---@field get_frame fun(): table
---@field ping fun()

local M = m.Module.new( "WinnersPopup" )
--M.debug.enable()

M.center_point = { point = "CENTER", relative_point = "CENTER", x = 0, y = 150 }

---@param popup_builder PopupBuilder
---@param frame_builder FrameBuilderFactory
---@param db table
---@param awarded_loot AwardedLoot
---@param roll_controller RollController
---@param config Config
function M.new( popup_builder, frame_builder, db, awarded_loot, roll_controller, config )
  ---@type Popup?
  local popup
  local refresh

  db.point = db.point or M.center_point
  --awarded_loot.award( 'Zombiehunter', 16939, m.Types.RollType.MainSpec )
  --awarded_loot.award( 'Kevieboipro', 16939, m.Types.RollType.Transmog )
  --awarded_loot.award( 'Sica', 5504, m.Types.RollType.OffSpec, m.Types.RollingStrategy.RaidRoll )
  --awarded_loot.award( 'Sica', 10652, nil, nil )
  --awarded_loot.award( 'Sica', 19019, m.Types.RollType.OffSpec, m.Types.RollingStrategy.SoftResRoll )
  --awarded_loot.award( 'Sica', 83484, m.Types.RollType.SoftRes, m.Types.RollingStrategy.SoftResRoll )

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

    local function set_sort()
      if sort == this.sort then
        sort_order = (sort_order == "asc") and "desc" or "asc"
      else
        sort = this.sort
      end
      refresh()
    end

    local builder = popup_builder
        :name( "rfWinnersFrame" )
        :width( 290 )
        :height( 200 )
        :point( get_point() )
        :bg_file( "Interface/Buttons/WHITE8x8" )
        :sound()
        :backdrop_color( 0, 0, 0, .7 )
        :frame_style( "PrincessKenny" )
        :border_color( .2, .2, .2, 1 )
        :movable()
        :on_drag_stop( on_drag_stop )
        :self_centered_anchor()

    ---@class Popup
    local main_frame = builder:build()

    local close = m.GuiElements.close_button( main_frame )
    close:SetPoint( "TOPRIGHT", -7, -7 )
    close:SetScript( "OnClick", function()
      if popup then popup:Hide() end
    end )

    local title = m.GuiElements.text( main_frame, "Winners" )
    title:SetPoint( "TOPLEFT", 0, -10 )
    title:SetPoint( "RIGHT", 0, 0 )

    local header = m.GuiElements.winner_header( main_frame )
    header:SetPoint( "TOPLEFT", 20, -30 )
    header.player_header:SetScript( "OnClick", set_sort )
    header.item_header:SetScript( "OnClick", set_sort )
    header.type_header:SetScript( "OnClick", set_sort )

    main_frame.scroll = m.OptionsGuiElements.CreateScrollFrame( nil, main_frame )
    main_frame.scroll:SetPoint( "TOPLEFT", 20, -45 )
    main_frame.scroll:SetPoint( "BOTTOMRIGHT", -6, 10 )

    local inner_builder = frame_builder.new()
        :parent( main_frame.scroll )
        :name( "rfWinnersFrameInner" )
        :width( 250 )
        :height( 1 )
        :point( { point = "TOPLEFT", relative_point = "TOPLEFT", x = 0, y = -0 } )
        :bg_file( "Interface/Buttons/WHITE8x8" )
        :gui_elements( m.GuiElements )
        :frame_style( "none" )

    ---@class Frame
    main_frame.scroll.content = inner_builder:build()
    main_frame.scroll.content.parent = main_frame.scroll
    main_frame.scroll.content:SetAllPoints( main_frame.scroll )
    main_frame.scroll.content:SetScript( "OnUpdate", function()
      this:GetParent():UpdateScrollState()
    end )

    main_frame.scroll.content:Show()
    main_frame.scroll:SetScrollChild( main_frame.scroll.content )

    return main_frame
  end

  function refresh()
    M.debug.add( "refresh" )
    if not popup then popup = create_popup() end
    popup.scroll.content:clear()

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
    for q, v in pairs( filters.item_quality ) do
      if v then
        table.insert( quality_filter, m.Types.ItemQuality[ q ] )
      end
    end

    local rolltype_filter = {}
    for t, v in pairs( filters.roll_type ) do
      if v then
        table.insert( rolltype_filter, t )
      end
    end

    data = filter( data, function( item )
      local quality = item.quality or 0
      return m.table_contains_value( quality_filter, quality ) and m.table_contains_value( rolltype_filter, item.roll_type )
    end )

    local function my_sort( a, b )
      if sort == "player_name" then
        local val_a, val_b = a[ sort ] or "", b[ sort ] or ""
        local class_a, class_b = a[ "player_class" ] or "", b[ "player_class" ] or ""

        if class_a ~= class_b then
          if sort_order == "asc" then
            return class_a < class_b
          else
            return class_a > class_b
          end
        end
        if sort_order == "asc" then
          return val_a < val_b
        else
          return val_a > val_b
        end
      end

      if sort == "item_id" then
        local val_a, val_b = a[ sort ] or "", b[ sort ] or ""
        local quality_a, quality_b = a[ "quality" ], b[ "quality" ] or 0

        if quality_a ~= quality_b then
          if sort_order == "asc" then
            return quality_a > quality_b
          else
            return quality_a < quality_b
          end
        end
        if sort_order == "asc" then
          return val_a > val_b
        else
          return val_a < val_b
        end
      end

      if sort == "roll_type" then
        local roll_order = { SoftRes = 1, MainSpec = 2, OffSpec = 3, Transmog = 4, RR = 5, NA = 6 }
        local val_a, val_b = a[ sort ] or "NA", b[ sort ] or "NA"

        if val_a ~= val_b then
          if sort_order == "asc" then
            return roll_order[ val_a ] < roll_order[ val_b ]
          else
            return roll_order[ val_a ] > roll_order[ val_b ]
          end
        end
        return a.item_id < b.item_id
      end
    end

    if (sort) then table.sort( data, my_sort ) end

    local content = {}
    for _, item in pairs( data ) do
      if item.item_link then
        table.insert( content, {
          type = "winner",
          player_name = item.player_name,
          player_class = item.player_class,
          item_link = item.item_link,
          roll_type = item.roll_type,
          rolling_strategy = item.rolling_strategy,
          quality = item.quality
        } )
      end
    end

    local line_count = 0
    for _, v in ipairs( content ) do
      popup.scroll.content.add_line( v.type, function( type, frame, lines )
        if type == "winner" then
          local roll_type_abbrev = v.roll_type == "RR" and "RR" or v.roll_type == "NA" and "NA" or m.roll_type_abbrev( v.roll_type )
          frame:SetItem( v.item_link )
          frame.player_name:SetText( c( v.player_name, v.player_class ) )
          frame.roll_type:SetText( r( v.roll_type, roll_type_abbrev ) )
          line_count = line_count + 1
        end

        local count = getn( lines )
        if count == 0 then
          local y = v.padding or 0
          frame:ClearAllPoints()
          frame:SetPoint( "TOP", popup.scroll.content, "TOP", 0, y )
        else
          local line_anchor = lines[ count ].frame
          frame:ClearAllPoints()
          frame:SetPoint( "TOP", line_anchor, "BOTTOM", 0, v.padding and -v.padding or 0 )
        end
      end, 0 )
    end

    local height = 60 + line_count * 14
    popup:SetHeight( math.min( 400, height ) )
  end

  local function show()
    M.debug.add( "show" )

    if not popup then
      popup = create_popup()
    end

    popup:Show()
    sort = nil
    refresh()

  end

  local function hide()
    M.debug.add( "hide" )
    if popup then
      popup:Hide()
    end
  end

  local function get_frame()
    if not popup then
      popup = create_popup()
    end

    return popup
  end

  local function ping()
    m.api.PlaySound( "igMainMenuOpen" )
  end

  local function loot_awarded()
    if popup and popup:IsVisible() then
      refresh()

    end
  end

  local function filter_changed()
    if popup and popup:IsVisible() then
      refresh()
      popup.scroll.content.parent:UpdateScrollState()
      local max = popup.scroll.content.parent:GetVerticalScrollRange()
      print( "max: " .. max)
      popup.scroll.content.parent:SetVerticalScroll( max )
    end
  end

  roll_controller.subscribe( "loot_awarded", loot_awarded )
  config.subscribe( "award_filter", filter_changed )

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
