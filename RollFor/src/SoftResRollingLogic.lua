local modules = LibStub( "RollFor-Modules" )
if modules.SoftResRollingLogic then return end

local M = {}
local map = modules.map
local count_elements = modules.count_elements
local pretty_print = modules.pretty_print
local take = modules.take
local rlu = modules.RollingLogicUtils

---@diagnostic disable-next-line: deprecated
local getn = table.getn

local State = { AfterRoll = 1, TimerStopped = 2, ManualStop = 3 }

local function is_the_winner_the_only_player_with_extra_rolls( rollers, rolls )
  local extra_rolls = rlu.players_with_available_rolls( rollers )
  if getn( extra_rolls ) > 1 then return false end

  local sorted_rolls = rlu.sort_rolls( rolls )
  return getn( sorted_rolls[ 1 ].players ) == 1 and sorted_rolls[ 1 ].players[ 1 ] == extra_rolls[ 1 ].name
end

local function winner_found( rollers, rolls )
  return rlu.has_everyone_rolled( rollers, rolls ) and is_the_winner_the_only_player_with_extra_rolls( rollers, rolls )
end

function M.new( announce, ace_timer, rollers, item, count, seconds, on_rolling_finished, on_softres_rolls_available )
  local rolls = {}
  local rolling = false
  local seconds_left = seconds
  local timer

  local function have_all_rolls_been_exhausted()
    for _, v in pairs( rollers ) do
      if v.rolls > 0 then return winner_found( rollers, rolls ) end
    end

    return true
  end

  local function stop_timer()
    if timer then
      ace_timer:CancelTimer( timer )
      timer = nil
    end
  end

  local function stop_listening()
    rolling = false
    stop_timer()
  end

  local function find_winner( state )
    local rolls_exhausted = have_all_rolls_been_exhausted()
    if state == State.AfterRoll and not rolls_exhausted then return end

    if state == State.ManualStop or rolls_exhausted then
      stop_listening()
    end

    local roll_count = count_elements( rolls )

    if roll_count == 0 then
      stop_listening()
      on_rolling_finished( item, count, {} )
      return
    end

    local sorted_rolls = rlu.sort_rolls( rolls )
    local winners = take( sorted_rolls, count )

    on_rolling_finished( item, count, winners )

    if state ~= State.ManualStop and not rolls_exhausted then
      stop_timer()
      on_softres_rolls_available( rlu.players_with_available_rolls( rollers ) )
    end
  end

  local function on_roll( player_name, roll, min, max )
    if not rolling or min ~= 1 or (max ~= 99 and max ~= 100) then return end
    local offspec = max == 99

    if not rlu.can_roll( rollers, player_name ) then
      pretty_print( string.format( "|cffff9f69%s|r did not SR %s. This roll (|cffff9f69%s|r) is ignored.", player_name, item.link, roll ) )
      return
    end

    if offspec then
      pretty_print( string.format( "|cffff9f69%s|r did SR %s, but rolled OS. This roll (|cffff9f69%s|r) is ignored.", player_name, item.link, roll ) )
      return
    end

    if not rlu.has_rolls_left( rollers, player_name ) then
      pretty_print( string.format( "|cffff9f69%s|r exhausted their rolls. This roll (|cffff9f69%s|r) is ignored.", player_name, roll ) )
      return
    end

    rlu.subtract_roll( rollers, player_name )
    rlu.record_roll( rolls, player_name, roll )

    find_winner( State.AfterRoll )
  end

  local function stop_accepting_rolls( force )
    find_winner( force and State.ManualStop or State.TimerStopped )
  end

  local function on_timer()
    seconds_left = seconds_left - 1

    if seconds_left <= 0 then
      stop_accepting_rolls()
    elseif seconds_left == 3 then
      announce( "Stopping rolls in 3" )
    elseif seconds_left < 3 then
      announce( seconds_left )
    end
  end

  local function accept_rolls()
    rolling = true
    timer = ace_timer.ScheduleRepeatingTimer( M, on_timer, 1.7 )
  end

  local function announce_rolling()
    local name_with_rolls = function( player )
      if getn( rollers ) == count then return player.name end
      local roll_count = player.rolls > 1 and string.format( " [%s rolls]", player.rolls ) or ""
      return string.format( "%s%s", player.name, roll_count )
    end

    local count_str = count > 1 and string.format( "%sx", count ) or ""
    local x_rolls_win = count > 1 and string.format( ". %d top rolls win.", count ) or ""
    local ressed_by = modules.prettify_table( map( rollers, name_with_rolls ) )

    if count == getn( rollers ) then
      announce( string.format( "%s soft-ressed %s.", ressed_by, item.link ), true )
      on_rolling_finished( item, 0, { ressed_by }, false, true )
    else
      announce( string.format( "Roll for %s%s: (SR by %s)%s", count_str, item.link, ressed_by, x_rolls_win ), true )
      accept_rolls()
    end
  end

  local function show_sorted_rolls( limit )
    local function show( prefix, sorted_rolls )
      pretty_print( string.format( "%s rolls:", prefix ) )
      local i = 0

      for _, v in ipairs( sorted_rolls ) do
        if limit and limit > 0 and i > limit then return end

        pretty_print( string.format( "[|cffff9f69%d|r]: %s", v[ "roll" ], modules.prettify_table( v[ "players" ] ) ) )
        i = i + 1
      end
    end

    show( "SR", rlu.sort_rolls( rolls ) )
  end

  local function print_rolling_complete( cancelled )
    pretty_print( string.format( "Rolling for %s has %s.", item.link, cancelled and "been cancelled" or "finished" ) )
  end

  local function cancel_rolling()
    stop_listening()
    print_rolling_complete( true )
  end

  local function is_rolling()
    return rolling
  end

  return {
    announce_rolling = announce_rolling,
    on_roll = on_roll,
    show_sorted_rolls = show_sorted_rolls,
    stop_accepting_rolls = stop_accepting_rolls,
    cancel_rolling = cancel_rolling,
    is_rolling = is_rolling,
    get_roll_type = function() return modules.Api.RollType.NormalRoll end
  }
end

modules.SoftResRollingLogic = M
return M
