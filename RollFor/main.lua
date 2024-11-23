local lib_stub = LibStub
local modules = lib_stub( "RollFor-Modules" )
local version = modules.get_addon_version()

local M = lib_stub:NewLibrary( string.format( "RollFor-%s", version.major ), version.minor )
if not M then return end

local pretty_print = modules.pretty_print
local hl = modules.colors.highlight
local RollType = modules.Api.RollType

---@diagnostic disable-next-line: deprecated
local getn = table.getn

local m_rolling_logic

local function reset()
  m_rolling_logic = nil
end

local function get_roll_announcement_chat_type( use_raid_warning )
  local chat_type = modules.get_group_chat_type()
  if not use_raid_warning then return chat_type end

  local rank = modules.my_raid_rank()

  if chat_type == "RAID" and rank > 0 then
    return "RAID_WARNING"
  else
    return chat_type
  end
end

local function announce( text, use_raid_warning )
  M.api().SendChatMessage( text, get_roll_announcement_chat_type( use_raid_warning ) )
end

local function clear_data()
  M.dropped_loot.clear()
  M.awarded_loot.clear()
  M.softres_gui.clear()
  M.name_matcher.clear( true )
  M.softres.clear( true )
  M.minimap_button.set_icon( M.minimap_button.ColorType.White )
end

local function update_minimap_icon()
  local result = M.softres_check.check_softres( true )

  if result == M.softres_check.ResultType.NoItemsFound then
    M.minimap_button.set_icon( M.minimap_button.ColorType.White )
  elseif result == M.softres_check.ResultType.SomeoneIsNotSoftRessing then
    M.minimap_button.set_icon( M.minimap_button.ColorType.Orange )
  elseif result == M.softres_check.ResultType.FoundOutdatedData then
    M.minimap_button.set_icon( M.minimap_button.ColorType.Red )
  else
    M.minimap_button.set_icon( M.minimap_button.ColorType.Green )
  end
end

local function on_softres_status_changed()
  update_minimap_icon()
end

local function trade_complete_callback( recipient, items_given, items_received )
  for i = 1, getn( items_given ) do
    local item = items_given[ i ]
    if item then
      local item_id = M.item_utils.get_item_id( item.link )
      local item_name = M.dropped_loot.get_dropped_item_name( item_id )

      if item_name then
        M.award_item( recipient, item_id, item_name, item.link )
      end
    end
  end

  for i = 1, getn( items_received ) do
    local item = items_received[ i ]
    if item then
      local item_id = M.item_utils.get_item_id( item.link )

      if M.awarded_loot.has_item_been_awarded( recipient, item_id ) then
        M.unaward_item( recipient, item_id, item.link )
      end
    end
  end
end

local function create_components()
  local m = modules

  M.ace_timer = lib_stub( "AceTimer-3.0" )
  M.api = function() return m.api end
  M.present_softres = function( softres ) return m.SoftResPresentPlayersDecorator.new( M.group_roster, softres ) end
  M.absent_softres = function( softres ) return m.SoftResAbsentPlayersDecorator.new( M.group_roster, softres ) end

  M.item_utils = m.ItemUtils
  M.version_broadcast = m.VersionBroadcast.new( M.db, version.str )
  M.awarded_loot = m.AwardedLoot.new( M.db )
  M.group_roster = m.GroupRoster.new( M.api )
  M.unfiltered_softres = m.SoftRes.new( M.db )
  M.name_matcher = m.NameManualMatcher.new(
    M.db, M.api,
    M.absent_softres( M.unfiltered_softres ),
    m.NameAutoMatcher.new( M.group_roster, M.unfiltered_softres, 0.57, 0.4 ),
    on_softres_status_changed
  )
  M.matched_name_softres = m.SoftResMatchedNameDecorator.new( M.name_matcher, M.unfiltered_softres )
  M.awarded_loot_softres = m.SoftResAwardedLootDecorator.new( M.awarded_loot, M.matched_name_softres )
  M.softres = M.present_softres( M.awarded_loot_softres )
  M.dropped_loot = m.DroppedLoot.new( M.db )
  M.master_loot_tracker = m.MasterLootTracker.new()
  M.softres_check = m.SoftResCheck.new( M.matched_name_softres, M.group_roster, M.name_matcher, M.ace_timer,
    M.absent_softres, M.db )
  M.dropped_loot_announce = m.DroppedLootAnnounce.new( announce, M.dropped_loot, M.master_loot_tracker, M.softres )
  M.master_loot_frame = m.MasterLootFrame.new()
  M.master_loot = m.MasterLoot.new( M.group_roster, M.dropped_loot, M.award_item, M.master_loot_frame, M.master_loot_tracker )
  M.softres_gui = m.SoftResGui.new( M.api, M.import_encoded_softres_data, M.softres_check, M.softres, clear_data, M.dropped_loot_announce.reset )

  M.trade_tracker = m.TradeTracker.new(
    M.ace_timer,
    trade_complete_callback
  )

  M.usage_printer = m.UsagePrinter.new()
  M.minimap_button = m.MinimapButton.new( M.api, M.db, M.softres_gui.toggle, M.softres_check )
  M.master_loot_warning = m.MasterLootWarning.new( M.api, M.db )
  M.auto_loot = m.AutoLoot.new( M.api, M.db )
end

function M.import_softres_data( softres_data )
  M.unfiltered_softres.import( softres_data )
  M.name_matcher.auto_match()
end

local function on_softres_rolls_available( rollers )
  local remaining_rollers = modules.reindex_table( rollers )

  local transform = function( player )
    local rolls = player.rolls == 1 and "1 roll" or string.format( "%s rolls", player.rolls )
    return string.format( "%s (%s)", player.name, rolls )
  end

  local message = modules.prettify_table( remaining_rollers, transform )
  announce( string.format( "SR rolls remaining: %s", message ) )
end

local function raid_roll_rolling_logic( item )
  return modules.RaidRollRollingLogic.new( announce, M.ace_timer, M.group_roster, item, M.master_loot_frame )
end

local function non_softres_rolling_logic( item, count, info, seconds, on_rolling_finished )
  return modules.NonSoftResRollingLogic.new( announce, M.ace_timer, M.group_roster, item, count, info, seconds, on_rolling_finished, M.master_loot_frame )
end

local function soft_res_rolling_logic( item, count, info, seconds, on_rolling_finished )
  local softressing_players = M.softres.get( item.id )

  if getn( softressing_players ) == 0 then
    return non_softres_rolling_logic( item, count, info, seconds, on_rolling_finished )
  end

  return modules.SoftResRollingLogic.new( announce, M.ace_timer, softressing_players, item, count, seconds, on_rolling_finished,
    on_softres_rolls_available, M.master_loot_frame )
end

function M.import_encoded_softres_data( data, data_loaded_callback )
  local sr = modules.SoftRes
  local softres_data = sr.decode( data )

  if not softres_data and data and string.len( data ) > 0 then
    pretty_print( "Could not load soft-res data!", modules.colors.red )
    return
  elseif not softres_data then
    M.minimap_button.set_icon( M.minimap_button.ColorType.White )
    return
  end

  M.import_softres_data( softres_data )

  pretty_print( "Soft-res data loaded successfully!" )
  if data_loaded_callback then data_loaded_callback( softres_data ) end

  update_minimap_icon()
end

function M.there_was_a_tie( item, count, winners, top_roll, rerolling )
  local players = winners.players
  table.sort( players )
  local top_rollers_str = modules.prettify_table( players )
  local top_rollers_str_colored = modules.prettify_table( players, hl )

  local message = function( rollers )
    return string.format( "The %shighest %sroll was %d by %s.", not rerolling and top_roll and "" or "next ",
      rerolling and "re-" or "", winners.roll, rollers )
  end

  pretty_print( message( top_rollers_str_colored ) )
  announce( message( top_rollers_str ) )

  local prefix = count > 1 and string.format( "%sx", count ) or ""
  local suffix = count > 1 and string.format( " %s top rolls win.", count ) or ""

  m_rolling_logic = modules.TieRollingLogic.new( announce, players, item, count, M.on_rolling_finished )
  M.ace_timer.ScheduleTimer( M,
    function()
      m_rolling_logic.announce_rolling( string.format( "%s /roll for %s%s now.%s", top_rollers_str, prefix, item.link, suffix ) )
    end, 2 )
end

-- This should probably not be here.
function M.on_rolling_finished( item, count, winners, rerolling )
  local announce_winners = function( v, top_roll )
    local roll = v.roll
    local players = v.players
    table.sort( players )
    local os = v.offspec and " (OS)" or ""

    pretty_print( string.format( "%s %srolled the %shighest (%s) for %s%s.", modules.prettify_table( players, hl ),
      rerolling and "re-" or "", top_roll and "" or "next ", hl( roll ), item.link, os ) )
    announce(
      string.format( "%s %srolled the %shighest (%d) for %s%s.", modules.prettify_table( players ),
        rerolling and "re-" or "", top_roll and "" or "next ", roll, item.link, os ) )

    for _, player_name in ipairs( players ) do
      M.master_loot_frame.mark_winner( player_name, item.name )
    end
  end

  if getn( winners ) == 0 then
    pretty_print( string.format( "Nobody rolled for %s.", item.link ) )
    announce( string.format( "Nobody rolled for %s.", item.link ) )

    if M.db.char.auto_raid_roll then
      m_rolling_logic = raid_roll_rolling_logic( item )
      m_rolling_logic.announce_rolling()
    elseif m_rolling_logic and not m_rolling_logic.is_rolling() then
      pretty_print( string.format( "Rolling for %s has finished.", item.link ) )
    end

    return
  end

  local items_left = count

  for i = 1, getn( winners ) do
    if items_left == 0 then
      if not m_rolling_logic.is_rolling() then
        pretty_print( string.format( "Rolling for %s has finished.", item.link ) )
      end

      return
    end

    local v = winners[ i ]
    local player_count = getn( v.players )

    if player_count > 1 and player_count > items_left then
      M.there_was_a_tie( item, items_left, winners[ i ], i == 1 )
      return
    end

    items_left = items_left - player_count
    announce_winners( winners[ i ], i == 1 )
  end

  if not m_rolling_logic.is_rolling() then
    pretty_print( string.format( "Rolling for %s has finished.", item.link ) )
  end
end

local function announce_hr( item )
  announce( string.format( "%s is hard-ressed.", item ), true )
end

local function parse_args( args )
  for item_count, item_link, seconds, info in string.gmatch( args, "(%d*)[xX]?%s*(|%w+|Hitem.+|r)%s*(%d*)%s*(.*)" ) do
    local count = (not item_count or item_count == "") and 1 or tonumber( item_count )
    local item_id = M.item_utils.get_item_id( item_link )
    local item_name = M.item_utils.get_item_name( item_link )
    local item = { id = item_id, link = item_link, name = item_name }
    local secs = seconds and seconds ~= "" and seconds ~= " " and tonumber( seconds ) or 8

    return item, count, secs <= 3 and 4 or secs, info
  end
end

---@diagnostic disable-next-line: unused-local, unused-function
local function toggle_ml_warning()
  if M.db.char.disable_ml_warning then
    M.db.char.disable_ml_warning = nil
    M.master_loot_warning.on_player_target_changed()
  else
    M.db.char.disable_ml_warning = 1
    M.master_loot_warning.hide()
  end

  pretty_print( string.format( "Master Loot warning %s.", M.db.char.disable_ml_warning and hl( "disabled" ) or hl( "enabled" ) ) )
end

local function toggle_auto_loot()
  if M.db.char.auto_loot then
    M.db.char.auto_loot = nil
  else
    M.db.char.auto_loot = 1
  end

  pretty_print( string.format( "Auto-loot %s.", M.db.char.auto_loot and hl( "enabled" ) or hl( "disabled" ) ) )
end

local function print_auto_raid_roll_status()
  pretty_print( string.format( "Auto raid-roll is %s.", M.db.char.auto_raid_roll and hl( "enabled" ) or hl( "disabled" ) ) )
end

local function toggle_auto_raid_roll()
  if M.db.char.auto_raid_roll then
    M.db.char.auto_raid_roll = nil
  else
    M.db.char.auto_raid_roll = 1
  end

  print_auto_raid_roll_status()
end

local function on_roll_command( roll_type )
  local normal_roll = roll_type == RollType.NormalRoll
  local raid_roll = roll_type == RollType.RaidRoll

  return function( args )
    if normal_roll and args == "ml" then
      toggle_ml_warning()
      return
    end

    if normal_roll and args == "autoloot" then
      toggle_auto_loot()
      return
    end

    if raid_roll and args == "auto" then
      toggle_auto_raid_roll()
      return
    end

    if m_rolling_logic and m_rolling_logic.is_rolling() then
      pretty_print( "Rolling already in progress." )
      return
    end

    local item, count, seconds, info = parse_args( args )

    if not item then
      M.usage_printer.print_usage( roll_type )
      return
    end

    --TODO: What if we wanted to bypass the hard-res?
    if M.softres.is_item_hardressed( item.id ) then
      announce_hr( item.link )
      return
    end

    if normal_roll then
      m_rolling_logic = soft_res_rolling_logic( item, count, info, seconds, M.on_rolling_finished )
    elseif roll_type == RollType.NoSoftResRoll then
      m_rolling_logic = non_softres_rolling_logic( item, count, info, seconds, M.on_rolling_finished )
    elseif raid_roll then
      m_rolling_logic = raid_roll_rolling_logic( item )
    else
      pretty_print( string.format( "Unsupported command: %s", hl( roll_type and roll_type.slash_command or "?" ) ) )
      return
    end

    M.master_loot_frame.clear_winners()
    m_rolling_logic.announce_rolling()
  end
end

local function on_re_raid_roll_command()
  if not m_rolling_logic or m_rolling_logic.get_roll_type() ~= RollType.RaidRoll then
    pretty_print( "There is nothing to re-raid-roll.", nil, "RaidRoll" )
    return
  end

  if m_rolling_logic.is_rolling() then
    pretty_print( "Raid-rolling is in progress.", nil, "RaidRoll" )
    return
  end

  m_rolling_logic.re_roll()
end

local function on_show_sorted_rolls_command( args )
  if not m_rolling_logic then
    pretty_print( "No rolls have been recorded." )
    return
  end

  if m_rolling_logic.is_rolling() then
    pretty_print( "Rolling is in progress." )
    return
  end

  if args then
    for limit in string.gmatch( args, "(%d+)" ) do
      m_rolling_logic.show_sorted_rolls( tonumber( limit ) )
      return
    end
  end

  m_rolling_logic.show_sorted_rolls( 5 )
end

local function is_rolling_check( f )
  ---@diagnostic disable-next-line: unused-vararg
  return function( ... )
    if not m_rolling_logic or not m_rolling_logic.is_rolling() then
      pretty_print( "Rolling not in progress." )
      return
    end

    f( unpack( arg ) )
  end
end

local function in_group_check( f )
  ---@diagnostic disable-next-line: unused-vararg
  return function( ... )
    if not M.api().IsInGroup() then
      pretty_print( "Not in a group." )
      return
    end

    f( unpack( arg ) )
  end
end

local function on_cancel_roll_command()
  m_rolling_logic.cancel_rolling()
end

local function on_finish_roll_command()
  m_rolling_logic.stop_accepting_rolls( true )
end

local function setup_storage()
  M.db = lib_stub( "AceDB-3.0" ):New( "RollForDb" )

  if not M.db.global.version then
    M.db.global.version = version.str
  end
end

local function on_softres_command( args )
  if args == "init" then
    clear_data()
  end

  M.softres_gui.toggle()
end

local function on_roll( player, roll, min, max )
  if m_rolling_logic and m_rolling_logic.is_rolling() then
    m_rolling_logic.on_roll( player, roll, min, max )
  end
end

function M.on_chat_msg_system( message )
  for player, roll, min, max in string.gmatch( message, "([^%s]+) rolls (%d+) %((%d+)%-(%d+)%)" ) do
    on_roll( player, tonumber( roll ), tonumber( min ), tonumber( max ) )
  end
end

---@diagnostic disable-next-line: unused-local, unused-function
local function simulate_loot_dropped( args )
  ---@diagnostic disable-next-line: unused-function
  local function mock_table_function( name, values )
    M.api()[ name ] = function( key )
      local value = values[ key ]

      if type( value ) == "function" then
        return value()
      else
        return value
      end
    end
  end

  ---@diagnostic disable-next-line: unused-function
  local function make_loot_slot_info( count, quality )
    local result = {}

    for i = 1, count do
      table.insert( result, function()
        if i == count then
          modules.api = modules.real_api
          modules.real_api = nil
        end

        return nil, nil, nil, quality or 4
      end )
    end

    return result
  end

  local item_links = M.item_utils.parse_all_links( args )

  if modules.real_api then
    pretty_print( "Mocking in progress." )
    return
  end

  modules.real_api = modules.api
  modules.api = modules.clone( modules.api )
  M.api()[ "GetNumLootItems" ] = function() return getn( item_links ) end
  M.api()[ "UnitName" ] = function() return tostring( modules.lua.time() ) end
  M.api()[ "GetLootThreshold" ] = function() return 4 end
  mock_table_function( "GetLootSlotLink", item_links )
  mock_table_function( "GetLootSlotInfo", make_loot_slot_info( getn( item_links ), 4 ) )

  M.dropped_loot_announce.on_loot_opened()
end

function M.on_loot_opened()
  M.auto_loot.on_loot_opened()
  M.dropped_loot_announce.on_loot_opened()
  M.master_loot.on_loot_opened()
end

function M.on_loot_closed()
  M.master_loot.on_loot_closed()
end

local function show_how_to_roll()
  announce( "How to roll:" )
  announce( "For main-spec, type: /roll" )
  announce( "For off-spec, type: /roll 99" )
end

local function setup_slash_commands()
  -- Roll For commands
  SLASH_RF1 = RollType.NormalRoll.slash_command
  M.api().SlashCmdList[ "RF" ] = in_group_check( on_roll_command( RollType.NormalRoll ) )
  SLASH_ARF1 = RollType.NoSoftResRoll.slash_command
  M.api().SlashCmdList[ "ARF" ] = in_group_check( on_roll_command( RollType.NoSoftResRoll ) )
  SLASH_RR1 = RollType.RaidRoll.slash_command
  M.api().SlashCmdList[ "RR" ] = in_group_check( on_roll_command( RollType.RaidRoll ) )
  SLASH_RRR1 = "/rrr"
  M.api().SlashCmdList[ "RRR" ] = in_group_check( on_re_raid_roll_command )
  SLASH_HTR1 = "/htr"
  M.api().SlashCmdList[ "HTR" ] = in_group_check( show_how_to_roll )
  SLASH_CR1 = "/cr"
  M.api().SlashCmdList[ "CR" ] = is_rolling_check( on_cancel_roll_command )
  SLASH_FR1 = "/fr"
  M.api().SlashCmdList[ "FR" ] = is_rolling_check( on_finish_roll_command )
  SLASH_SSR1 = "/ssr"
  M.api().SlashCmdList[ "SSR" ] = on_show_sorted_rolls_command

  -- Soft Res commands
  SLASH_SR1 = "/sr"
  M.api().SlashCmdList[ "SR" ] = on_softres_command
  SLASH_SRS1 = "/srs"
  M.api().SlashCmdList[ "SRS" ] = M.softres_check.show_softres
  SLASH_SRC1 = "/src"
  M.api().SlashCmdList[ "SRC" ] = M.softres_check.check_softres
  SLASH_SRO1 = "/sro"
  M.api().SlashCmdList[ "SRO" ] = M.name_matcher.manual_match
  SLASH_RFM1 = "/rfm"
  M.api().SlashCmdList[ "RFM" ] = M.minimap_button.toggle
  SLASH_RFL1 = "/rfl"
  M.api().SlashCmdList[ "RFL" ] = M.minimap_button.toggle_lock

  --SLASH_DROPPED1 = "/DROPPED"
  --M.api().SlashCmdList[ "DROPPED" ] = simulate_loot_dropped
end

function M.on_first_enter_world()
  reset()
  setup_storage()
  create_components()
  setup_slash_commands()

  pretty_print( string.format( "Loaded (%s).", hl( string.format( "v%s", version.str ) ) ) )

  if M.db.char.auto_loot then
    pretty_print( "Auto-loot is enabled.", modules.colors.orange )
  end

  M.version_broadcast.broadcast()
  M.import_encoded_softres_data( M.db.char.softres_data )
  M.softres_gui.load( M.db.char.softres_data )
end

---@diagnostic disable-next-line: unused-local, unused-function
local function on_party_message( message, player )
  for name, roll in string.gmatch( message, "(%a+) rolls (%d+)" ) do
    --M:Print( string.format( "Party: %s %s", name, message ) )
    on_roll( name, tonumber( roll ), 1, 100 )
  end
  for name, roll in string.gmatch( message, "(%a+) rolls os (%d+)" ) do
    --M:Print( string.format( "Party: %s %s", name, message ) )
    on_roll( name, tonumber( roll ), 1, 99 )
  end
end

function M.award_item( player, item_id, item_name, item_link_or_colored_item_name )
  M.awarded_loot.award( player, item_id, item_name )
  pretty_print( string.format( "%s received %s.", hl( player ), item_link_or_colored_item_name ) )
end

---@diagnostic disable-next-line: unused-local
function M.unaward_item( player, item_id, item_link_or_colored_item_name )
  --TODO: Think if we want to do this.
  --m_awarded_items = remove_from_awarded_items( player, item_id )
  --M.db.awarded_items = m_awarded_items
  pretty_print( string.format( "%s returned %s.", hl( player ), item_link_or_colored_item_name ) )
end

function M.on_group_changed()
  M.name_matcher.auto_match()
  update_minimap_icon()
end

function M.on_loot_changed()
  if modules.is_player_master_looter() and modules.is_master_loot() then
    print_auto_raid_roll_status()
  end
end

function M.on_chat_msg_addon( name, message )
  if name ~= "RollFor" then return end

  for ver in string.gmatch( message, "VERSION::(.-)" ) do
    M.version_broadcast.on_version( ver )
  end
end

modules.EventHandler.handle_events( M )
return M
