---@diagnostic disable-next-line: undefined-global
local modules = LibStub( "RollFor-Modules" )
if modules.WinnerTracker then return end

local M = {}

local m = modules
local EventType = {
  RollingStarted = "RollingStarted",
  WinnerFound = "WinnerFound"
}

function M.new( db )
  local callbacks = {
    [ EventType.RollingStarted ] = {},
    [ EventType.WinnerFound ] = {}
  }

  db.winners = db.winners or {}

  -- roll_type -> Types.RollType
  local function notify_winner_found( winner_name, item_link, roll_type, winning_roll )
    for _, callback in ipairs( callbacks[ EventType.WinnerFound ] ) do
      callback( winner_name, item_link, winning_roll, roll_type )
    end
  end

  -- roll_type -> Types.RollType
  local function track( winner_name, item_link, roll_type, winning_roll )
    db.winners[ item_link ] = db.winners[ item_link ] or {}
    db.winners[ item_link ][ winner_name ] = {
      winning_roll = winning_roll,
      roll_type = roll_type
    }

    notify_winner_found( winner_name, item_link, roll_type, winning_roll )
  end

  local function untrack( winner_name, item_link )
    db.winners[ item_link ] = db.winners[ item_link ] or {}
    db.winners[ item_link ][ winner_name ] = nil

    if m.count_elements( db.winners[ item_link ] ) == 0 then
      db.winners[ item_link ] = nil
    end
  end

  local function find_winners( item_link )
    local result = {}

    for winner_name, details in pairs( db.winners[ item_link ] or {} ) do
      table.insert( result, { winner_name = winner_name, roll_type = details.roll_type, winning_roll = details.winning_roll } )
    end

    return result
  end

  local function subscribe_for_rolling_started( callback )
    table.insert( callbacks[ EventType.RollingStarted ], callback )
  end

  local function subscribe_for_winner_found( callback )
    table.insert( callbacks[ EventType.WinnerFound ], callback )
  end

  local function start_rolling( item_link )
    db.winners[ item_link ] = {}

    for _, callback in ipairs( callbacks[ EventType.RollingStarted ] ) do
      callback()
    end
  end

  local function clear()
    m.clear_table( db.winners )
  end

  return {
    start_rolling = start_rolling,
    track = track,
    untrack = untrack,
    find_winners = find_winners,
    subscribe_for_rolling_started = subscribe_for_rolling_started,
    subscribe_for_winner_found = subscribe_for_winner_found,
    clear = clear
  }
end

modules.WinnerTracker = M
return M
