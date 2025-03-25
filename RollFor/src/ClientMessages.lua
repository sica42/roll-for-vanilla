RollFor = RollFor or {}
local m = RollFor

if m.ClientMessages then return end

---@class ClientMessages

local M = m.Module.new( "ClientMessages" )

local RS = m.Types.RollingStrategy

M.debug.enable()

local ADDON_NAME = "RollFor"

---@param roll_controller RollController
---@param softres GroupAwareSoftRes
---@param config Config
function M.new( roll_controller, softres, config )
  ---@param message string
  ---@param data table?
  local function broadcast( message, data )
    local channel = m.api.IsInRaid() and "RAID" or "PARTY"
    local data_str = data and string.gsub( m.dump( data ), "%s+", "" ) or ""

    m.api.SendAddonMessage( ADDON_NAME, string.format( "ROLL::%s::%s", message, data_str ), channel )
  end

  local function cancel_rolling()
    broadcast( "CANCEL_ROLL" )
  end

  ---@param data RollControllerStartData
  local function on_start( data )
    if data.strategy_type ~= RS.NormalRoll and data.strategy_type ~= RS.SoftResRoll then
      return
    end

    local softressing_players = softres.get( data.item.id )
    local sr_players = {}
    for _, player in ipairs( softressing_players ) do
      table.insert( sr_players, {
        t = player.type,
        n = player.name,
        c = player.class,
        ro = player.rolls,
        srp = player.sr_plus
      } )
    end

    broadcast( "START_ROLL", {
      i = {
        t = data.item.type,
        id = data.item.id,
        n = string.gsub(  data.item.name , "%s", "_" ),
        tx = string.gsub( data.item.texture, "Interface\\Icons\\", "" ),
        q = data.item.quality,
        cl = data.item.classes
      },
      ic = data.item_count,
      s = data.seconds,
      st = data.strategy_type,
      sr = sr_players,
      th = {
        ms = config.ms_roll_threshold(),
        os = config.os_roll_threshold(),
        tmog = config.tmog_roll_threshold()
      }
    } )
  end

  ---@param event_data RollingFinishedData
  local function on_finish( event_data )
    if event_data.roll_tracker_data.iterations[1].rolling_strategy ~= RS.NormalRoll and event_data.roll_tracker_data.iterations[1].rolling_strategy ~= RS.SoftResRoll then
      return
    end

    local data = {}
    for _, winner in ipairs( event_data.roll_tracker_data.winners ) do
      table.insert( data, {
        n = winner.name,
        c = winner.class,
        rt = winner.roll_type,
        r = winner.winning_roll,
      } )
    end

    broadcast( "FINISH", data )
  end

  ---@param data { players: RollingPlayer[], item: Item, item_count: number, roll_type: RollType, roll: number, rerolling: boolean?, top_roll: boolean? }
  local function on_tie( data )
    local players = {}
    for _, player in ipairs( data.players ) do
      table.insert( players, {
        n = player.name,
        c = player.class,
        t = player.type,
        ro = player.rolls,
      } )
    end

    broadcast( "TIE", {
      rt = data.roll_type,
      r = data.roll,
      p = players
     } )
  end

  ---@param event_data TieStartData
  local function on_tie_start( event_data )
    broadcast( "TIESTART" )
  end

  local function on_tick( data )
    broadcast( "TICK", {
      sl = data.seconds_left
    } )
  end

  ---@param data LootAwardedData
  local function on_loot_awarded( data )
    broadcast( "AWARDED", {
      pn = data.player_name,
      pc = data.player_class,
      id = data.item_id
    } )
  end

  ---@param data { player_name: PlayerName, player_class: PlayerClass, roll_type: RollType, roll: Roll }
  local function on_roll( data )
    broadcast( "ROLL", {
      pn = data.player_name,
      pc = data.player_class,
      rt = data.roll_type,
      r = data.roll
    } )
  end

  roll_controller.subscribe( "cancel_rolling", cancel_rolling )
  roll_controller.subscribe( "start", on_start )
  roll_controller.subscribe( "finish", on_finish )
  roll_controller.subscribe( "there_was_a_tie", on_tie )
  roll_controller.subscribe( "tie_start", on_tie_start )
  roll_controller.subscribe( "tick", on_tick )
  roll_controller.subscribe( "loot_awarded", on_loot_awarded )
  roll_controller.subscribe( "roll", on_roll )

  ---@type ClientMessages
  return {}
end

m.ClientMessages = M
return M
