RollFor = RollFor or {}
local m = RollFor

if m.Client then return end

---@class Client
---@field on_message fun( data: string, sender: string )

local M = m.Module.new( "Client" )

local IU = m.ItemUtils ---@type ItemUtils
local RT = m.Types.RollType
local RS = m.Types.RollingStrategy
local S = m.Types.RollingStatus

local getn = m.getn
local next = next

---@param ace_timer AceTimer
---@param player_info PlayerInfo
---@param rolling_popup RollingPopup
---@param config Config
function M.new( ace_timer, player_info, rolling_popup, config )
  local rolling_popup_data = {} ---@type RollingPopupData[]
  local roll_tracker ---@type RollTracker
  local roll_threshold = {}
  local show_rolling = false
  local player_have_rolled
  local chunked_messages = {}
  local var_names = {
    i = "item",
    t = "type",
    l = "link",
    tx = "texture",
    q = "quality",
    ic = "item_count",
    s = "seconds",
    sl = "seconds_left",
    st = "strategy_type",
    pn = "player_name",
    pc = "player_class",
    rt = "roll_type",
    r = "roll",
    n = "name",
    c = "class",
    th = "roll_threshold",
    sr = "softressing_players",
    ro = "rolls",
    srp = "sr_plus",
    p = "players",
    cl = "classes"
  }
  setmetatable( var_names, { __index = function( _, key ) return key end } );

  local function parse_table( str )
    local function parse_inner( pos )
      local tbl = {}
      local key
      local i = 1

      while pos <= string.len( str ) do
        local char = string.sub( str, pos, pos )

        if char == "{" then
          local newTable, newPos = parse_inner( pos + 1 )
          if key then
            tbl[ var_names[ key ] ] = newTable
            key = nil
          else
            tbl[ i ] = newTable
            i = i + 1
          end
          pos = newPos
        elseif char == "}" then
          return tbl, pos
        elseif char == "[" then
          local _, newPos, extracted_key = string.find( str, '%["*(.-)"*%]', pos )
          key = tonumber( extracted_key ) and tonumber( extracted_key ) or extracted_key
          pos = newPos
        elseif char == "=" then
        elseif char == "," then
          key = nil
        else
          local _, newPos, raw_value = string.find( str, '([^,%]}]+)', pos )
          if raw_value then
            local value = tonumber( raw_value ) and tonumber( raw_value ) or raw_value
            if key then
              tbl[ var_names[ key ] ] = value
              key = nil
            else
              tbl[ i ] = value
              i = i + 1
            end
            pos = newPos
          end
        end
        pos = pos + 1
      end
      return tbl, pos
    end

    local final_table = parse_inner( 1 )
    return final_table[ 1 ]
  end

  ---@param item_id number
  ---@param name string
  ---@param quality number
  local function item_link( item_id, name, quality )
    if not item_id then return end

    local id = tonumber( item_id )
    if not id or id == 0 then return end

    local details = string.format( "item:%d:0:0:0", id )

    return string.format( "%s|H%s|h[%s]|h|r", m.api.ITEM_QUALITY_COLORS[ quality or 0 ].hex, details, name )
  end

  local function close_rolling()
    rolling_popup.hide()
    show_rolling = false
  end

  ---@param strategy_type RollingStrategyType
  ---@param finished boolean?
  local function roll_buttons( strategy_type, finished )
    local buttons = {}

    if not player_have_rolled and not finished then
      if strategy_type == RS.NormalRoll then
        table.insert( buttons, { type = "MSRoll", callback = function() m.api.RandomRoll( 1, roll_threshold[ RT.MainSpec ] ) end } )
        table.insert( buttons, { type = "OSRoll", callback = function() m.api.RandomRoll( 1, roll_threshold[ RT.OffSpec ] ) end } )
        table.insert( buttons, { type = "TMOGRoll", callback = function() m.api.RandomRoll( 1, roll_threshold[ RT.Transmog ] ) end } )
      elseif strategy_type == RS.SoftResRoll or strategy_type == RS.TieRoll then
        table.insert( buttons, { type = "Roll", callback = function() m.api.RandomRoll( 1, 100 ) end } )
      end
    end

    table.insert( buttons, { type = "Close", callback = function() close_rolling() end } )

    return buttons
  end

  ---@param item Item
  ---@param item_count number
  ---@param seconds number?
  ---@param buttons RollingPopupButtonWithCallback[]
  ---@param rolls RollData[]
  ---@param winners WinnerWithAwardCallback[]
  ---@param strategy_type RollingStrategyType
  ---@param waiting_for_rolls boolean?
  local function roll_content( item, item_count, seconds, buttons, rolls, winners, strategy_type, waiting_for_rolls )
    ---@type RollingPopupRollData
    rolling_popup_data[ item.id ] = {
      item_link = item.link,
      item_tooltip_link = IU.get_tooltip_link( item.link ),
      item_texture = item.texture,
      item_count = item_count,
      seconds_left = seconds,
      rolls = rolls,
      winners = winners,
      buttons = buttons,
      strategy_type = strategy_type,
      waiting_for_rolls = waiting_for_rolls,
      type = "Roll"
    }

    rolling_popup:show()
    rolling_popup:refresh( rolling_popup_data[ item.id ] )
  end

  local function tie_content()
    local tracker_data = roll_tracker.get()
    local first_iteration = tracker_data.iterations[ 1 ]
    local waiting = tracker_data.status.type == "Waiting" or false

    local tie_iterations = {}
    for i, iteration in ipairs( tracker_data.iterations ) do
      if i > 1 then
        table.insert( tie_iterations,
          ---@type TieIteration
          {
            tied_roll = iteration.tied_roll,
            rolls = iteration.rolls
          }
        )
      end
    end

    ---@type RollingPopupTieData
    rolling_popup_data[ tracker_data.item.id ] = {
      ---@type RollingPopupRollData
      roll_data = {
        item_link = tracker_data.item.link,
        item_tooltip_link = IU.get_tooltip_link( tracker_data.item.link ),
        item_texture = tracker_data.item.texture,
        item_count = tracker_data.item_count,
        rolls = first_iteration.rolls,
        winners = tracker_data.winners,
        strategy_type = first_iteration.rolling_strategy,
        buttons = roll_buttons( RS.TieRoll ),
        waiting_for_rolls = waiting or false,
        type = "Roll"
      },
      tie_iterations = tie_iterations,
      type = "Tie"
    }

    rolling_popup:show()
    rolling_popup:refresh( rolling_popup_data[ tracker_data.item.id ] )
  end

  local function on_command( command, data )
    if command == "START_ROLL" then
      if next( data.softressing_players ) == nil then
        data.strategy_type = RS.NormalRoll
      elseif not m.find( player_info.get_name(), data.softressing_players, 'name' ) then
        show_rolling = false
        return
      end

      if data.item.classes and next( data.item.classes ) and not m.find( player_info.get_class(), data.item.classes ) then
        show_rolling = false
        return
      end

      player_have_rolled = false
      show_rolling = true

      data.item.texture = "Interface\\Icons\\" .. data.item.texture
      data.item.name = string.gsub( data.item.name, "_", " " )
      data.item.link = item_link( data.item.id, data.item.name, data.item.quality )

      roll_threshold.MainSpec = data.roll_threshold.ms
      roll_threshold.OffSpec = data.roll_threshold.os
      roll_threshold.Transmog = data.roll_threshold.tmog

      roll_tracker = m.RollTracker.new( data.item )

      roll_tracker.start( data.strategy_type, data.item_count, data.seconds, nil, data.softressing_players )

      local tracker_data, current_iteration = roll_tracker.get()
      local strategy_type = current_iteration and current_iteration.rolling_strategy
      local waiting_for_rolls = tracker_data.status.type == "Waiting" or false

      roll_content(
        tracker_data.item,
        tracker_data.item_count,
        not waiting_for_rolls and tracker_data.status.seconds_left or nil,
        roll_buttons( strategy_type ),
        current_iteration.rolls,
        {},
        strategy_type,
        waiting_for_rolls
      )

      local color = m.get_popup_border_color( data.item.quality )
      rolling_popup:border_color( color )
    end

    if show_rolling then
      if command == "ROLL" then
        roll_tracker.add( data.player_name, data.player_class, data.roll_type, data.roll )
        player_have_rolled = data.player_name == player_info.get_name()

        local tracker_data, current_iteration = roll_tracker.get()
        local strategy_type = current_iteration and current_iteration.rolling_strategy

        if strategy_type == "TieRoll" then
          tie_content()
          return
        end

        rolling_popup_data[ tracker_data.item.id ].rolls = current_iteration.rolls
        rolling_popup_data[ tracker_data.item.id ].buttons = roll_buttons( strategy_type )

        rolling_popup:show()
        rolling_popup:refresh( rolling_popup_data[ tracker_data.item.id ] )
      elseif command == "TICK" then
        roll_tracker.tick( data.seconds_left )
        local tracker_data = roll_tracker.get()
        local waiting_for_rolls = tracker_data.status.type == "Waiting" or false

        if tracker_data.status.type == S.Finished or tracker_data.status.type == S.Canceled then
          return
        end

        if data.seconds_left == 1 then
          roll_tracker.waiting_for_rolls()
          ace_timer.ScheduleTimer( M, function()
            on_command( "TICK", { seconds_left = 0 } )
          end, 2 )
        end

        rolling_popup_data[ tracker_data.item.id ].seconds_left = not waiting_for_rolls and data.seconds_left or nil
        rolling_popup_data[ tracker_data.item.id ].waiting_for_rolls = waiting_for_rolls

        rolling_popup:show()
        rolling_popup:refresh( rolling_popup_data[ tracker_data.item.id ] )
      elseif command == "FINISH" then
        roll_tracker.finish( {} )

        local tracker_data, current_iteration = roll_tracker.get()
        local strategy_type = current_iteration and current_iteration.rolling_strategy

        if strategy_type == "TieRoll" then
          tie_content()
          return
        end

        rolling_popup_data[ tracker_data.item.id ].winners = data
        rolling_popup_data[ tracker_data.item.id ].seconds_left = nil
        rolling_popup_data[ tracker_data.item.id ].buttons = roll_buttons( strategy_type, true )

        rolling_popup:show()
        rolling_popup:refresh( rolling_popup_data[ tracker_data.item.id ] )
      elseif command == "CANCEL_ROLL" then
        roll_tracker.rolling_canceled()

        local tracker_data, current_iteration = roll_tracker.get()
        local strategy_type = current_iteration and current_iteration.rolling_strategy

        rolling_popup_data[ tracker_data.item.id ].type = "RollingCanceled"
        rolling_popup_data[ tracker_data.item.id ].buttons = roll_buttons( strategy_type, true )

        rolling_popup:show()
        rolling_popup:refresh( rolling_popup_data[ tracker_data.item.id ] )
      elseif command == "TIE" then
        roll_tracker.tie( data.players, data.roll_type, data.roll )
        tie_content()
      elseif command == "TIESTART" then
        roll_tracker.tie_start()

        local tracker_data = roll_tracker.get()
        local last_iteration = tracker_data.iterations[ getn( tracker_data.iterations ) ]

        if m.find( player_info.get_name(), last_iteration.rolls, 'player_name' ) then
          player_have_rolled = false
        end

        tie_content()
      elseif command == "AWARDED" then
        local tracker_data = roll_tracker.get()

        rolling_popup_data[ tracker_data.item.id ].type = "Awarded"
        rolling_popup_data[ tracker_data.item.id ].awarded = data

        if data.player_name == player_info.get_name() then
          m.api.PlaySound( "QUESTCOMPLETED" )
        end

        rolling_popup:show()
        rolling_popup:refresh( rolling_popup_data[ tracker_data.item.id ] )
      end
    end
  end

  local function on_message( data_str, sender )
    if sender == player_info.get_name() or not config.client_show_roll_popup() then return end

    local command = string.match( data_str, "^(.-)::" )
    data_str = string.gsub( data_str, "^.-::", "" )

    if command == "CHUNK" then
      local chunk_num, total_chunks, chunk_content = string.match( data_str, "^(%d+)::(%d+)::(.+)$" )
      chunked_messages[ sender ] = chunked_messages[ sender ] or {}

      local sender_chunks = chunked_messages[ sender ]
      sender_chunks[ tonumber( chunk_num ) ] = chunk_content

      M.debug.add( (string.format( "Got chunk %d of %d", tonumber( chunk_num ), tonumber( total_chunks ) )) )

      if getn( sender_chunks ) == tonumber( total_chunks ) then
        data_str = table.concat( sender_chunks )
        command = string.match( data_str, "^(.-)::" )
        data_str = string.gsub( data_str, "^.-::", "" )

        chunked_messages[ sender ] = nil
      else
        return
      end
    end

    local data = data_str ~= "" and parse_table( data_str ) or {}

    M.debug.add( string.format("Received command %s", command ) )
    on_command( command, data )
  end

  ---@type Client
  return {
    on_message = on_message
  }
end

m.Client = M
return M
