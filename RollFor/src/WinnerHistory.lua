---@diagnostic disable-next-line: undefined-global
local modules = LibStub( "RollFor-Modules" )
if modules.WinnerHistory then return end

local M = {}

function M.new( db )
  local function start_session()
    db.current_session = modules.lua.time()
    db.winners = db.winners or {}
    db.sessions = db.sessions or {}
    db.sessions[ db.current_session ] = {}
    db.sessions[ db.current_session ].zones = {}
    db.sessions[ db.current_session ].winners = {}
  end

  local function store_zone_count( zone_name )
    local count = db.sessions[ db.current_session ].zones[ zone_name ] or 0
    db.sessions[ db.current_session ].zones[ zone_name ] = count + 1
  end

  local function store_session_winner( player_name, item_id, item_link, zone_name, roll_type, winning_roll )
    local player = db.sessions[ db.current_session ].winners[ player_name ] or {}

    table.insert( player, {
      item_id = item_id,
      item_link = item_link,
      zone_name = zone_name,
      timestamp = modules.lua.time(),
      roll_type = roll_type,
      winning_roll = winning_roll
    } )

    db.sessions[ db.current_session ].winners[ player_name ] = player
  end

  local function store_winner( player_name, item_id, item_link, zone_name, roll_type, winning_roll )
    local winners = db.winners or {}
    winners[ player_name ] = winners[ player_name ] or {}

    table.insert( winners[ player_name ], {
      item_id = item_id,
      item_link = item_link,
      zone_name = zone_name,
      timestamp = modules.lua.time(),
      roll_type = roll_type,
      winning_roll = winning_roll
    } )

    db.winners = winners
  end

  local function add( player_name, item_id, item_link, roll_type, winning_roll )
    local zone_name = modules.api.GetRealZoneText()

    store_zone_count( zone_name )
    store_session_winner( player_name, item_id, item_link, zone_name, roll_type, winning_roll )
    store_winner( player_name, item_id, item_link, zone_name, roll_type, winning_roll )
  end

  local function find( player_name, item_id )
    return db.winners[ player_name ] and db.winners[ player_name ][ item_id ]
  end

  return {
    start_session = start_session,
    add = add,
    find = find
  }
end

modules.WinnerHistory = M
return M
