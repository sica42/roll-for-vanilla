RollFor = RollFor or {}
local m = RollFor

if m.WinnersPopup then return end

local c = m.colorize_player_by_class
local r = m.roll_type_color
local filter = m.filter
local sort
local sort_order = "asc"

---@class WinnersPopup
---@field show fun()
---@field refresh fun()
---@field hide fun()
---@field get_frame fun(): table
---@field ping fun()

local M = m.Module.new( "WinnersPopup" )
M.debug.enable()

M.center_point = { point = "CENTER", relative_point = "CENTER", x = 0, y = 150 }

---@param popup_builder PopupBuilder
---@param frame_builder FrameBuilderFactory
---@param db table
---@param awarded_loot AwardedLoot
---@param roll_controller RollController
---@param options_popup OptionsPopup
---@param config Config
function M.new( popup_builder, frame_builder, db, awarded_loot, roll_controller, options_popup, config )
  ---@type Popup?
  local popup
  local refresh
  local is_resizing

  db.point = db.point or M.center_point
  --[[
  awarded_loot.award( 'Zombiehunter', 16939, nil, 'Hunter', { roll_type='SoftRes', rolling_strategy='SoftResRoll', winning_roll=112}, 30 )
  awarded_loot.award( 'Kevieboipro', 16939, nil, 'Warrior', { roll_type='SoftRes', rolling_strategy='SoftResRoll', winning_roll=98}, 20 )
  awarded_loot.award( 'Kevieboipro', 19019, nil, 'Warrior', { roll_type='Transmog', rolling_strategy='NormalRoll', winning_roll=89} )
  awarded_loot.award( 'Dayknight', 5504, nil, 'Paladin', { roll_type='MainSpec', rolling_strategy='NormalRoll', winning_roll=53} )
  awarded_loot.award( 'Celilae', 5504, nil, 'Paladin', { roll_type='MainSpec', rolling_strategy='NormalRoll', winning_roll=78} )
  awarded_loot.award( 'Borazor', 16939, nil, 'Hunter', { roll_type='SoftRes', rolling_strategy='SoftResRoll', winning_roll=112}, 30 )
  awarded_loot.award( 'Ryiana', 16939, nil, 'Warrior', { roll_type='SoftRes', rolling_strategy='SoftResRoll', winning_roll=98}, 20 )
  awarded_loot.award( 'Tornapart', 19019, nil, 'Warrior', { roll_type='Transmog', rolling_strategy='NormalRoll', winning_roll=89} )
  awarded_loot.award( 'Dayknight', 5504, nil, 'Paladin', { roll_type='MainSpec', rolling_strategy='NormalRoll', winning_roll=53} )
  awarded_loot.award( 'Celilae', 5504, nil, 'Paladin', { roll_type='MainSpec', rolling_strategy='NormalRoll', winning_roll=78} )
  ]]
  --awarded_loot.award( 'Borazor', 16936, nil, 'Hunter', { roll_type='SoftRes', rolling_strategy='SoftResRoll', winning_roll=112}, 30 )

  local function filter_winners( data )
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

    return data
  end

  local function sort_winners( a, b )
    local val_a, val_b
    if sort == "winning_roll" then
      val_a, val_b = a[ sort ] or 0, b[ sort ] or 0

      if sort_order == "asc" then
        return val_a > val_b
      else
        return val_a < val_b
      end
    else
      val_a, val_b = a[ sort ] or "", b[ sort ] or ""

      if sort == "player_name" then
        local class_a, class_b = a[ "player_class" ] or "", b[ "player_class" ] or ""
        if class_a ~= class_b then
          return (sort_order == "asc") == (class_a < class_b)
        end
        return a.player_name < b.player_name
      elseif sort == "item_id" then
        local quality_a, quality_b = a[ "quality" ] or 0, b[ "quality" ] or 0
        if quality_a ~= quality_b then
          return (sort_order == "asc") == (quality_a > quality_b)
        end
        return a.item_link < b.item_link
      elseif sort == "roll_type" then
        local roll_order = { SoftRes = 1, MainSpec = 2, OffSpec = 3, Transmog = 4, RR = 5, NA = 6 }
        val_a, val_b = a[ sort ] or "NA", b[ sort ] or "NA"
        if val_a ~= val_b then
          return (sort_order == "asc") == (roll_order[ val_a ] < roll_order[ val_b ])
        end
        return a.item_id < b.item_id
      end
    end
  end

  local function create_popup()
    local function is_out_of_bounds( x, y, frame_width, frame_height, screen_width, screen_height )
      local left = x
      local right = x + frame_width
      local top = y
      local bottom = y - frame_height

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
        popup:position( db.point or M.center_point )
        return
      end

      local anchor_point, _, anchor_relative_point, anchor_x, anchor_y = popup:get_anchor_point()
      db.point = { point = anchor_point, relative_point = anchor_relative_point, x = anchor_x, y = anchor_y }
    end

    local old_width
    local function on_resize( frame )
      if not is_resizing then return end
      local width = this:GetWidth()
      local height = this:GetHeight()

      if width <= 260 then
        width = 260
        this:SetWidth( width )
      end
      if height <= 173 then
        this:SetHeight( 173 )
      end

      if not old_width then old_width = this.scroll.content:GetWidth() end
      this.scroll.content:SetWidth( width - 40 )

      if (math.abs( (width - 40) - old_width ) > 8) then
        old_width = this.scroll.content:GetWidth()
        refresh()
      end
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
        :width( db.width or 290 )
        :height( db.height or 200 )
        :point( get_point() )
        :bg_file( "Interface/Buttons/WHITE8x8" )
        :sound()
        :backdrop_color( 0, 0, 0, .8 )
        :frame_style( "PrincessKenny" )
        :border_color( .2, .2, .2, 1 )
        :movable()
        :on_drag_stop( on_drag_stop )
        :resizable()
        :on_resize( on_resize )

    ---@class Popup
    local main_frame = builder:build()

    local btn_close = m.GuiElements.tiny_button( main_frame, "x", "Close Window", { r = 1, g = .25, b = .25 } )
    btn_close:SetPoint( "TOPRIGHT", -7, -7 )
    btn_close:SetScript( "OnClick", function()
      if popup then popup:Hide() end
    end )

    local btn_options = m.GuiElements.tiny_button( main_frame, "o", "Open Settings", { r = .125, g = .624, b = .976 } )
    btn_options:SetPoint( "RIGHT", btn_close, "LEFT", -5, 0 )
    btn_options:SetScript( "OnMouseUp", function()
      options_popup.show( "Awards popup" )
    end )

    local btn_reset = m.GuiElements.tiny_button( main_frame, "R", "Reset Sorting", { r = .125, g = .976, b = .624 }, 9 )
    btn_reset:SetPoint( "RIGHT", btn_options, "LEFT", -5, 0 )
    btn_reset:SetScript( "OnMouseUp", function()
      sort = nil
      refresh()
    end )

    local btn_resize = m.GuiElements.resize_grip( main_frame,
      function()
        is_resizing = true
      end,
      function()
        is_resizing = false
        db.width = this:GetParent():GetWidth()
        db.height = this:GetParent():GetHeight()
      end
    )
    btn_resize:SetPoint( "BOTTOMRIGHT", 0, 0 )

    local title = m.GuiElements.text( main_frame, "Winners" )
    title:SetPoint( "TOPLEFT", 0, -10 )
    title:SetPoint( "RIGHT", 0, 0 )

    local headers = m.GuiElements.winner_header( main_frame )
    headers:SetPoint( "TOPLEFT", 20, -30 )
    headers:SetPoint( "RIGHT", -20, 0 )
    headers.player_header:SetScript( "OnClick", set_sort )
    headers.item_header:SetScript( "OnClick", set_sort )
    headers.roll_header:SetScript( "OnClick", set_sort )
    headers.type_header:SetScript( "OnClick", set_sort )
    main_frame.headers = headers

    main_frame.scroll = m.OptionsGuiElements.create_scroll_frame( nil, main_frame )
    main_frame.scroll:SetPoint( "TOPLEFT", 20, -45 )
    main_frame.scroll:SetPoint( "BOTTOMRIGHT", -6, 15 )

    local inner_builder = frame_builder.new()
        :parent( main_frame.scroll )
        :name( "rfWinnersFrameInner" )
        :width( 250 )
        :height( 100 )
        :point( { point = "TOPLEFT", relative_point = "TOPLEFT", x = 0, y = 0 } )
        :bg_file( "Interface/Buttons/WHITE8x8" )
        :gui_elements( m.GuiElements )
        :frame_style( "none" )

    ---@class Frame
    main_frame.scroll.content = inner_builder:build()
    main_frame.scroll.content.parent = main_frame.scroll
    main_frame.scroll.content:SetAllPoints( main_frame.scroll )
    main_frame.scroll.content:SetScript( "OnUpdate", function()
      this.parent:UpdateScrollState()
    end )

    main_frame.scroll.content:Show()
    main_frame.scroll:SetScrollChild( main_frame.scroll.content )

    return main_frame
  end

  function refresh()
    M.debug.add( "refresh" )
    if not popup then popup = create_popup() end
    popup.scroll.content:clear()

    local got_sr_plus = false
    local data = awarded_loot.get_winners()

    for _, v in ipairs( data ) do
      if not v.roll_type then
        v.roll_type = "NA"
      elseif v.roll_type == m.Types.RollType.MainSpec and (v.rolling_strategy == m.Types.RollingStrategy.RaidRoll or v.rolling_strategy == m.Types.RollingStrategy.InstaRaidRoll) then
        v.roll_type = "RR"
      end
      if v.sr_plus then got_sr_plus = true end
    end

    got_sr_plus = false --temp

    data = filter_winners( data )
    if (sort) then table.sort( data, sort_winners ) end

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
          winning_roll = item.winning_roll,
          sr_plus = item.sr_plus,
          quality = item.quality
        } )
      end
    end

    popup.headers.roll_header:SetWidth( got_sr_plus and 50 or 25 )

    local line_count = 0
    for _, v in ipairs( content ) do
      popup.scroll.content.add_line( v.type, function( type, frame, lines )
        if type == "winner" then
          local roll_type_abbrev = v.roll_type == "RR" and "RR" or v.roll_type == "NA" and "NA" or m.roll_type_abbrev( v.roll_type )
          local sr_plus = ""

          if got_sr_plus then
            frame.winning_roll:GetParent():SetWidth( 50 )
            if v.sr_plus and v.rolling_strategy == m.Types.RollingStrategy.SoftResRoll and v.roll_type == m.Types.RollType.SoftRes then
              sr_plus = string.format( "(+%s) ", v.sr_plus )
            end
          end

          frame:SetItem( v.item_link )
          frame.player_name:SetText( c( v.player_name, v.player_class ) )
          frame.winning_roll:SetText( string.format( "%s%s", sr_plus, v.winning_roll or "-" ) )
          frame.roll_type:SetText( r( v.roll_type, roll_type_abbrev ) )

          frame:SetPoint( "TOP", popup.scroll.content, "TOP", 0, -line_count * 14 )
          line_count = line_count + 1
        end
      end, 0 )
    end
    popup.scroll:UpdateScrollChildRect()
  end

  local function show()
    M.debug.add( "show" )
    if not popup then
      popup = create_popup()
    end

    popup:Show()
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
      if not sort then
        local max = popup.scroll.content.parent:GetVerticalScrollRange()
        popup.scroll.content.parent:SetVerticalScroll( max )
      end
    end
  end

  local function filter_changed()
    if popup and popup:IsVisible() then
      refresh()
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
