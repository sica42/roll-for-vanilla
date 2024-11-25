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

  local winners = db.char.winners or {}

  local function notify_winner_found( winner_name, item_name )
    for _, callback in ipairs( callbacks[ EventType.WinnerFound ] ) do
      callback( winner_name, item_name )
    end
  end

  local function persist()
    db.char.winners = winners
  end

  local function track( winner_name, item_name )
    winners[ item_name ] = winners[ item_name ] or {}
    winners[ item_name ][ winner_name ] = 1

    persist()
    notify_winner_found( winner_name, item_name )
  end

  local function untrack( winner_name, item_name )
    winners[ item_name ] = winners[ item_name ] or {}
    winners[ item_name ][ winner_name ] = nil

    persist()
  end

  local function find_winners( item_name )
    local result = {}

    for winner_name in pairs( winners[ item_name ] or {} ) do
      table.insert( result, winner_name )
    end

    return result
  end

  local function subscribe( rolling_started_callback, winner_found_callback )
    table.insert( callbacks[ EventType.RollingStarted ], rolling_started_callback )
    table.insert( callbacks[ EventType.WinnerFound ], winner_found_callback )
  end

  local function start_rolling( item_name )
    winners[ item_name ] = {}
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
    subscribe = subscribe,
    clear = clear
  }
end

modules.WinnerTracker = M
return M
