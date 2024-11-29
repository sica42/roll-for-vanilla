---@diagnostic disable-next-line: undefined-global
local modules = LibStub( "RollFor-Modules" )
if modules.WinnerHistory then return end

local M = {}

function M.new( db )
  local function start_session()
    db.global.winner_history = db.global.winner_history or {}
    db.global.winner_history.current_session = modules.lua.time()
    db.global.winner_history.winners = db.global.winner_history.winners or {}
    db.global.winner_history.sessions = db.global.winner_history.sessions or {}
    db.global.winner_history.sessions[ db.global.winner_history.current_session ] = {}
    db.global.winner_history.sessions[ db.global.winner_history.current_session ].zones = {}
    db.global.winner_history.sessions[ db.global.winner_history.current_session ].winners = {}
  end

  local function store_zone_count( zone_name )
    local count = db.global.winner_history.sessions[ db.global.winner_history.current_session ].zones[ zone_name ] or 0
    db.global.winner_history.sessions[ db.global.winner_history.current_session ].zones[ zone_name ] = count + 1
  end

  local function store_session_winner( player_name, item_id, item_link, zone_name, roll_type, winning_roll )
    local player = db.global.winner_history.sessions[ db.global.winner_history.current_session ].winners[ player_name ] or {}

    table.insert( player, {
      item_id = item_id,
      item_link = item_link,
      zone_name = zone_name,
      timestamp = modules.lua.time(),
      roll_type = roll_type,
      winning_roll = winning_roll
    } )

    db.global.winner_history.sessions[ db.global.winner_history.current_session ].winners[ player_name ] = player
  end

  local function store_winner( player_name, item_id, item_link, zone_name, roll_type, winning_roll )
    local winners = db.global.winner_history.winners or {}
    winners[ player_name ] = winners[ player_name ] or {}

    table.insert( winners[ player_name ], {
      item_id = item_id,
      item_link = item_link,
      zone_name = zone_name,
      timestamp = modules.lua.time(),
      roll_type = roll_type,
      winning_roll = winning_roll
    } )

    db.global.winner_history.winners = winners
  end

  local function add( player_name, item_id, item_link, roll_type, winning_roll )
    local zone_name = modules.api.GetRealZoneText()

    store_zone_count( zone_name )
    store_session_winner( player_name, item_id, item_link, zone_name, roll_type, winning_roll )
    store_winner( player_name, item_id, item_link, zone_name, roll_type, winning_roll )
  end

  local function find( player_name, item_id )
    return db.global.winner_history.winners[ player_name ] and db.global.winner_history.winners[ player_name ][ item_id ]
  end

  return {
    start_session = start_session,
    add = add,
    find = find
  }
end

modules.WinnerHistory = M
return M
