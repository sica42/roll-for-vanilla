---@diagnostic disable-next-line: undefined-global
local modules = LibStub( "RollFor-Modules" )
if modules.WinnerTracker then return end

local M = {}

local EventType = {
  RollingStarted = "RollingStarted",
  WinnerFound = "WinnerFound"
}

function M.new( db )
  local callbacks = {
    [ EventType.RollingStarted ] = {},
    [ EventType.WinnerFound ] = {}
  }

  db.char.winner_tracker = db.char.winner_tracker or {}
  local winners = db.char.winner_tracker.winners or {}

  -- roll_type -> Types.RollType
  local function notify_winner_found( winner_name, item_link, roll_type, winning_roll )
    for _, callback in ipairs( callbacks[ EventType.WinnerFound ] ) do
      callback( winner_name, item_link, winning_roll, roll_type )
    end
  end

  local function persist()
    db.char.winner_tracker.winners = winners
  end

  -- roll_type -> Types.RollType
  local function track( winner_name, item_link, roll_type, winning_roll )
    winners[ item_link ] = winners[ item_link ] or {}
    winners[ item_link ][ winner_name ] = {
      winning_roll = winning_roll,
      roll_type = roll_type
    }

    persist()
    notify_winner_found( winner_name, item_link, roll_type, winning_roll )
  end

  local function untrack( winner_name, item_link )
    winners[ item_link ] = winners[ item_link ] or {}
    winners[ item_link ][ winner_name ] = nil

    persist()
  end

  local function find_winners( item_link )
    local result = {}

    for winner_name, details in pairs( winners[ item_link ] or {} ) do
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
    winners[ item_link ] = {}
    persist()

    for _, callback in ipairs( callbacks[ EventType.RollingStarted ] ) do
      callback()
    end
  end

  local function clear()
    winners = {}
    persist()
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
