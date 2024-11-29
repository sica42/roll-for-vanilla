---@diagnostic disable-next-line: undefined-global
local lib_stub = LibStub
local m = lib_stub( "RollFor-Modules" )
local version = m.get_addon_version()

local M = lib_stub:NewLibrary( string.format( "RollFor-%s", version.major ), version.minor )
if not M then return end

local info = m.pretty_print
local print = m.print
local print_header = m.print_header
local hl = m.colors.highlight
local grey = m.colors.grey
local RollSlashCommand = m.Types.RollSlashCommand
local RollType = m.Types.RollType

---@diagnostic disable-next-line: deprecated
local getn = table.getn

local m_rolling_logic

local function reset()
  m_rolling_logic = nil
end

local function get_roll_announcement_chat_type( use_raid_warning )
  local chat_type = m.get_group_chat_type()
  if not use_raid_warning then return chat_type end

  local rank = m.my_raid_rank()

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
  M.winner_tracker.clear()
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
        M.award_item( recipient, item_id, item.link )
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
  M.ace_timer = lib_stub( "AceTimer-3.0" )
  M.api = function() return m.api end
  M.present_softres = function( softres ) return m.SoftResPresentPlayersDecorator.new( M.group_roster, softres ) end
  M.absent_softres = function( softres ) return m.SoftResAbsentPlayersDecorator.new( M.group_roster, softres ) end

  M.item_utils = m.ItemUtils
  M.version_broadcast = m.VersionBroadcast.new( M.db, version.str )
  M.winner_history = m.WinnerHistory.new( M.db )
  M.awarded_loot = m.AwardedLoot.new( M.db, M.winner_history )
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
  M.winner_tracker = m.WinnerTracker.new( M.db )
  M.dropped_loot_announce = m.DroppedLootAnnounce.new( announce, M.dropped_loot, M.master_loot_tracker, M.softres, M.winner_tracker )
  M.loot_award_popup = m.LootAwardPopup.new( M.item_utils )
  M.winner_tracker.subscribe_for_rolling_started( M.loot_award_popup.hide )
  M.master_loot_correlation_data = m.MasterLootCorrelationData.new( M.item_utils )
  M.roll_finished_logic = m.RollFinishedLogic.new( M.master_loot_correlation_data, M.winner_tracker, M.loot_award_popup )
  M.master_loot_frame = m.MasterLootFrame.new( M.winner_tracker, M.loot_award_popup, M.master_loot_correlation_data, M.roll_finished_logic )
  M.master_loot_candidates = m.MasterLootCandidates.new( M.group_roster ) -- remove group_roster for testing (dummy candidates)
  M.master_loot = m.MasterLoot.new( M.master_loot_candidates, M.award_item, M.master_loot_frame, M.master_loot_tracker, M.db, M.loot_award_popup,
    M.master_loot_correlation_data )
  M.softres_gui = m.SoftResGui.new( M.api, M.import_encoded_softres_data, M.softres_check, M.softres, clear_data, M.dropped_loot_announce.reset )

  M.trade_tracker = m.TradeTracker.new(
    M.ace_timer,
    trade_complete_callback
  )

  M.usage_printer = m.UsagePrinter.new()
  M.minimap_button = m.MinimapButton.new( M.api, M.db, M.softres_gui.toggle, M.softres_check )
  M.master_loot_warning = m.MasterLootWarning.new( M.api, M.db )
  M.auto_loot = m.AutoLoot.new( M.api, M.db )
  M.pfui_integration_dialog = m.PfIntegrationDialog.new( M.db )
  M.new_group_event = m.NewGroupEvent.new( M.db )
  M.new_group_event.subscribe( M.winner_history.start_session )
end

function M.import_softres_data( softres_data )
  M.unfiltered_softres.import( softres_data )
  M.name_matcher.auto_match()
end

local function on_softres_rolls_available( rollers )
  local remaining_rollers = m.reindex_table( rollers )

  local transform = function( player )
    local rolls = player.rolls == 1 and "1 roll" or string.format( "%s rolls", player.rolls )
    return string.format( "%s (%s)", player.name, rolls )
  end

  local message = m.prettify_table( remaining_rollers, transform )
  announce( string.format( "SR rolls remaining: %s", message ) )
end

local function raid_roll_rolling_logic( item )
  return m.RaidRollRollingLogic.new( announce, M.ace_timer, M.group_roster, item, M.winner_tracker, M.master_loot_candidates, M.roll_finished_logic.show_popup )
end

local function non_softres_rolling_logic( item, count, message, seconds, on_rolling_finished )
  return m.NonSoftResRollingLogic.new( announce, M.ace_timer, M.group_roster, item, count, message, seconds, on_rolling_finished, M.db )
end

local function soft_res_rolling_logic( item, count, message, seconds, on_rolling_finished )
  local softressing_players = M.softres.get( item.id )

  if getn( softressing_players ) == 0 then
    return non_softres_rolling_logic( item, count, message, seconds, on_rolling_finished )
  end

  return m.SoftResRollingLogic.new( announce, M.ace_timer, softressing_players, item, count, seconds, on_rolling_finished, on_softres_rolls_available )
end

function M.import_encoded_softres_data( data, data_loaded_callback )
  local sr = m.SoftRes
  local softres_data = sr.decode( data )

  if not softres_data and data and string.len( data ) > 0 then
    info( "Could not load soft-res data!", m.colors.red )
    return
  elseif not softres_data then
    M.minimap_button.set_icon( M.minimap_button.ColorType.White )
    return
  end

  M.import_softres_data( softres_data )

  info( "Soft-res data loaded successfully!" )
  if data_loaded_callback then data_loaded_callback( softres_data ) end

  update_minimap_icon()
end

function M.there_was_a_tie( item, count, winners, top_roll, rerolling )
  local players = winners.players
  table.sort( players )
  local top_rollers_str = m.prettify_table( players )
  local top_rollers_str_colored = m.prettify_table( players, hl )

  local message = function( rollers )
    return string.format( "The %shighest %sroll was %d by %s.", not rerolling and top_roll and "" or "next ",
      rerolling and "re-" or "", winners.roll, rollers )
  end

  info( message( top_rollers_str_colored ) )
  announce( message( top_rollers_str ) )

  local prefix = count > 1 and string.format( "%sx", count ) or ""
  local suffix = count > 1 and string.format( " %s top rolls win.", count ) or ""

  m_rolling_logic = m.TieRollingLogic.new( announce, players, item, count, M.on_rolling_finished )
  M.ace_timer.ScheduleTimer( M,
    function()
      m_rolling_logic.announce_rolling( string.format( "%s /roll for %s%s now.%s", top_rollers_str, prefix, item.link, suffix ) )
    end, 2 )
end

-- This should probably not be here.
function M.on_rolling_finished( item, count, winners, rerolling, there_was_no_rolling )
  local announce_winners = function( v, top_roll )
    local roll = v.roll
    local players = v.players
    table.sort( players )
    local roll_type = v.offspec and " (OS)" or v.tmog and " (TMOG)" or ""

    info( string.format( "%s %srolled the %shighest (%s) for %s%s.", m.prettify_table( players, hl ),
      rerolling and "re-" or "", top_roll and "" or "next ", hl( roll ), item.link, roll_type ) )
    announce(
      string.format( "%s %srolled the %shighest (%d) for %s%s.", m.prettify_table( players ),
        rerolling and "re-" or "", top_roll and "" or "next ", roll, item.link, roll_type ) )

    for _, player_name in ipairs( players ) do
      M.winner_tracker.track( player_name, item.link, v.offspec and RollType.OffSpec or v.tmog and RollType.Transmog or RollType.MainSpec, roll )
    end

    local player = M.master_loot_candidates.find( players[ 1 ] )
    M.roll_finished_logic.show_popup( player, item.link )
  end

  if getn( winners ) == 0 then
    info( string.format( "Nobody rolled for %s.", item.link ) )
    announce( string.format( "Nobody rolled for %s.", item.link ) )

    if M.db.char.auto_raid_roll then
      m_rolling_logic = raid_roll_rolling_logic( item )
      m_rolling_logic.announce_rolling()
    elseif m_rolling_logic and not m_rolling_logic.is_rolling() then
      info( string.format( "Rolling for %s has finished.", item.link ) )
    end

    return
  end

  local items_left = count

  for i = 1, getn( winners ) do
    if items_left == 0 then
      -- This situatin here is weird as fuck

      if i == 1 then
        -- SR winner / no rolling.
        M.winner_tracker.track( winners[ i ], item.link, RollType.SoftRes )
        local player = M.master_loot_candidates.find( winners[ 1 ] )
        M.roll_finished_logic.show_popup( player, item.link )
      end

      if m_rolling_logic.is_rolling() then return end

      if there_was_no_rolling then
        info( string.format( "Use %s %s to roll the item and ignore the softres.", hl( "/arf" ), item.link ), nil, "Tip" )
      else
        info( string.format( "Rolling for %s has finished.", item.link ) )
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
    info( string.format( "Rolling for %s has finished.", item.link ) )
  end
end

local function announce_hr( item )
  announce( string.format( "%s is hard-ressed.", item ), true )
end

local function parse_args( args )
  for item_count, item_link, seconds, message in string.gmatch( args, "(%d*)[xX]?%s*(|%w+|Hitem.+|r)%s*(%d*)%s*(.*)" ) do
    local count = (not item_count or item_count == "") and 1 or tonumber( item_count )
    local item_id = M.item_utils.get_item_id( item_link )
    local item_name = M.item_utils.get_item_name( item_link )
    local item = { id = item_id, link = item_link, name = item_name }
    local secs = seconds and seconds ~= "" and seconds ~= " " and tonumber( seconds ) or 8

    return item, count, secs <= 3 and 4 or secs, message
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

  info( string.format( "Master Loot warning %s.", M.db.char.disable_ml_warning and m.msg.disabled or m.msg.enabled ) )
end

local function print_raid_roll_settings()
  local auto_raidroll = M.db.char.auto_raid_roll and m.msg.enabled or m.msg.disabled
  info( string.format( "Auto raid-roll is %s.", auto_raidroll ) )
end

local function print_roll_thresholds()
  local ms_threshold = M.db.char.ms_roll_threshold
  local os_threshold = M.db.char.os_roll_threshold
  local tmog_threshold = M.db.char.tmog_roll_threshold
  local tmog_info = string.format( ", %s %s", hl( "TMOG" ), tmog_threshold ) or ""

  info( string.format( "Roll thresholds: %s %s, %s %s%s", hl( "MS" ), ms_threshold, hl( "OS" ), os_threshold, tmog_info ) )
end

local function print_transmog_rolling_setting( show_threshold )
  local tmog_rolling_enabled = M.db.char.tmog_rolling_enabled
  local threshold = show_threshold and tmog_rolling_enabled and string.format( " (%s)", hl( M.db.char.tmog_roll_threshold ) ) or ""
  info( string.format( "Transmog rolling is %s%s.", tmog_rolling_enabled and m.msg.enabled or m.msg.disabled, threshold ) )
end

local function print_pfui_integration_setting()
  if not m.uses_pfui() then return end
  info( string.format( "%s integration is %s.", m.msg.pfui, M.db.char.pfui_integration and m.msg.enabled or m.msg.disabled ) )
end

local function print_config()
  print_header( "RollFor Configuration" )
  info( string.format( "Master loot warning is %s.", M.db.char.disable_ml_warning and m.msg.disabled or m.msg.enabled ) )
  info( string.format( "Auto raid-roll is %s.", M.db.char.auto_raid_roll and m.msg.enabled or m.msg.disabled ) )

  print_roll_thresholds()
  print_transmog_rolling_setting()
  print_pfui_integration_setting()
  print( string.format( "For more info, type: %s", hl( "/rf config help" ) ) )
end

local function toggle_auto_loot()
  if M.db.char.auto_loot then
    M.db.char.auto_loot = false
  else
    M.db.char.auto_loot = true
  end

  info( string.format( "Auto-loot is %s.", M.db.char.auto_loot and m.msg.enabled or m.msg.disabled ) )
end

local function toggle_auto_raid_roll()
  if M.db.char.auto_raid_roll then
    M.db.char.auto_raid_roll = false
  else
    M.db.char.auto_raid_roll = true
  end

  print_raid_roll_settings()
end

local function configure_ms_threshold( args )
  for value in string.gmatch( args, "config ms (%d+)" ) do
    M.db.char.ms_roll_threshold = tonumber( value )
    print_roll_thresholds()
    return
  end

  info( string.format( "Usage: %s <threshold>", hl( "/rf config ms" ) ) )
end

local function configure_os_threshold( args )
  for value in string.gmatch( args, "config os (%d+)" ) do
    M.db.char.os_roll_threshold = tonumber( value )
    print_roll_thresholds()
    return
  end

  info( string.format( "Usage: %s <threshold>", hl( "/rf config os" ) ) )
end

local function configure_tmog_threshold( args )
  if args == "config tmog" then
    M.db.char.tmog_rolling_enabled = not M.db.char.tmog_rolling_enabled
    print_transmog_rolling_setting( true )
    return
  end

  for value in string.gmatch( args, "config tmog (%d+)" ) do
    M.db.char.tmog_roll_threshold = tonumber( value )
    print_roll_thresholds()
    return
  end

  info( string.format( "Usage: %s <threshold>", hl( "/rf config tmog" ) ) )
end

local function print_config_help()
  local v = function( name ) return string.format( "%s%s%s", hl( "<" ), grey( name ), hl( ">" ) ) end

  print_header( "RollFor Configuration Help" )
  print( string.format( "%s - show configuration", hl( "/rf config" ) ) )
  print( string.format( "%s - toggle minimap icon", hl( "/rf config minimap" ) ) )
  print( string.format( "%s - lock/unlock minimap icon", hl( "/rf config minimap lock" ) ) )
  print( string.format( "%s - toggle master loot warning", hl( "/rf config ml" ) ) )
  print( string.format( "%s - toggle auto raid-roll", hl( "/rf config auto-rr" ) ) )
  print( string.format( "%s - show MS rolling threshold ", hl( "/rf config ms" ) ) )
  print( string.format( "%s %s - set MS rolling threshold ", hl( "/rf config ms" ), v( "threshold" ) ) )
  print( string.format( "%s - show OS rolling threshold ", hl( "/rf config os" ) ) )
  print( string.format( "%s %s - set OS rolling threshold ", hl( "/rf config os" ), v( "threshold" ) ) )
  print( string.format( "%s - toggle TMOG rolling", hl( "/rf config tmog" ) ) )
  print( string.format( "%s %s - set TMOG rolling threshold", hl( "/rf config tmog" ), v( "threshold" ) ) )
end

local function toggle_pfui_integration()
  if M.db.char.pfui_integration then
    M.db.char.pfui_integration = false
  else
    M.db.char.pfui_integration = true
  end

  print_pfui_integration_setting()
end

local function on_config( args )
  if args == "config" then
    print_config()
    return
  end

  if args == "config help" then
    print_config_help()
    return
  end

  if args == "config ml" then
    toggle_ml_warning()
    return
  end

  if args == "config autoloot" then
    toggle_auto_loot()
    return
  end

  if args == "config auto-rr" then
    toggle_auto_raid_roll()
    return
  end

  if args == "config minimap" then
    M.minimap_button.toggle()
    return
  end

  if args == "config minimap lock" then
    M.minimap_button.toggle_lock()
    return
  end

  if string.find( args, "^config ms" ) then
    configure_ms_threshold( args )
    return
  end

  if string.find( args, "^config os" ) then
    configure_os_threshold( args )
    return
  end

  if string.find( args, "^config tmog" ) then
    configure_tmog_threshold( args )
    return
  end

  if args == "config pfui" and m.uses_pfui() then
    toggle_pfui_integration()
    return
  end

  print_config_help()
end

local function on_roll_command( roll_slash_command )
  local normal_roll = roll_slash_command == RollSlashCommand.NormalRoll
  local raid_roll = roll_slash_command == RollSlashCommand.RaidRoll

  return function( args )
    if m_rolling_logic and m_rolling_logic.is_rolling() then
      info( "Rolling already in progress." )
      return
    end

    if string.find( args, "^config" ) then
      on_config( args )
      return
    end

    if not M.api().IsInGroup() then
      info( "Not in a group." )
      return
    end

    local item, count, seconds, message = parse_args( args )

    if not item then
      M.usage_printer.print_usage( roll_slash_command )
      return
    end

    --TODO: What if we wanted to bypass the hard-res?
    if M.softres.is_item_hardressed( item.id ) then
      announce_hr( item.link )
      return
    end

    if normal_roll then
      m_rolling_logic = soft_res_rolling_logic( item, count, message, seconds, M.on_rolling_finished )
    elseif roll_slash_command == RollSlashCommand.NoSoftResRoll then
      m_rolling_logic = non_softres_rolling_logic( item, count, message, seconds, M.on_rolling_finished )
    elseif raid_roll then
      m_rolling_logic = raid_roll_rolling_logic( item )
    else
      message( string.format( "Unsupported command: %s", hl( roll_slash_command and roll_slash_command.slash_command or "?" ) ) )
      return
    end

    M.winner_tracker.start_rolling( item.link )
    m_rolling_logic.announce_rolling()
  end
end

local function on_show_sorted_rolls_command( args )
  if not m_rolling_logic then
    info( "No rolls have been recorded." )
    return
  end

  if m_rolling_logic.is_rolling() then
    info( "Rolling is in progress." )
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
      info( "Rolling not in progress." )
      return
    end

    f( unpack( arg ) )
  end
end

local function in_group_check( f )
  ---@diagnostic disable-next-line: unused-vararg
  return function( ... )
    if not M.api().IsInGroup() then
      info( "Not in a group." )
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

  if not M.db.char.ms_roll_threshold then M.db.char.ms_roll_threshold = 100 end
  if not M.db.char.os_roll_threshold then M.db.char.os_roll_threshold = 99 end
  if not M.db.char.tmog_roll_threshold then M.db.char.tmog_roll_threshold = 98 end
  if M.db.char.tmog_rolling_enabled == nil then M.db.char.tmog_rolling_enabled = true end
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

local function on_loot_method_changed()
  M.master_loot_warning.on_party_loot_method_changed()
end

local function on_master_looter_changed( player_name )
  if m.my_name() == player_name and m.is_master_loot() then
    M.ace_timer.ScheduleTimer( M, print_raid_roll_settings, 0.1 )

    if M.db.char.pfui_integration == nil then
      M.ace_timer.ScheduleTimer( M, M.pfui_integration_dialog.on_master_loot, 3 )
    end
  end
end

function M.on_chat_msg_system( message )
  for player, roll, min, max in string.gmatch( message, "([^%s]+) rolls (%d+) %((%d+)%-(%d+)%)" ) do
    on_roll( player, tonumber( roll ), tonumber( min ), tonumber( max ) )
    return
  end

  if string.find( message, "^Looting changed to" ) then
    on_loot_method_changed()
    return
  end

  for player_name in string.gmatch( message, "(.-) is now the loot master%." ) do
    on_master_looter_changed( player_name )
    return
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
          m.api = m.real_api
          m.real_api = nil
        end

        return nil, nil, nil, quality or 4
      end )
    end

    return result
  end

  local item_links = M.item_utils.parse_all_links( args )

  if m.real_api then
    info( "Mocking in progress." )
    return
  end

  m.real_api = m.api
  m.api = m.clone( m.api )
  M.api()[ "GetNumLootItems" ] = function() return getn( item_links ) end
  M.api()[ "UnitName" ] = function() return tostring( m.lua.time() ) end
  M.api()[ "GetLootThreshold" ] = function() return 4 end
  mock_table_function( "GetLootSlotLink", item_links )
  mock_table_function( "GetLootSlotInfo", make_loot_slot_info( getn( item_links ), 4 ) )

  M.dropped_loot_announce.on_loot_opened()
end

function M.on_loot_opened()
  M.auto_loot.on_loot_opened()
  M.dropped_loot_announce.on_loot_opened()
  M.master_loot.on_loot_opened()
  M.master_loot_correlation_data.reset()
end

function M.on_loot_closed()
  M.master_loot.on_loot_closed()
  M.master_loot_correlation_data.reset()
end

local function show_how_to_roll()
  announce( "How to roll:" )
  local ms = M.db.char.ms_roll_threshold ~= 100 and string.format( " (%s)", M.db.char.ms_roll_threshold or "100" ) or ""
  announce( string.format( "For main-spec, type: /roll%s", ms ) )
  announce( string.format( "For off-spec, type: /roll %s", M.db.char.os_roll_threshold ) )

  if M.db.char.tmog_rolling_enabled then
    announce( string.format( "For transmog, type: /roll %s", M.db.char.tmog_roll_threshold ) )
  end
end

local function on_reset_dropped_loot_announce_command()
  M.dropped_loot_announce.reset()
end

local function test( args )
  local player = { name = "Psikutas", class = "Hunter", value = 1 }
  local item_link = args and args ~= "" and args or "|cffff8000|Hitem:19019:0:0:0|h[Thunderfury, Blessed Blade of the Windseeker]|h|r"
  M.master_loot_correlation_data.set( item_link, 1 )
  -- M.winner_tracker.clear()
  M.winner_tracker.track( player.name, item_link, RollType.MainSpec, 69 )

  M.roll_finished_logic.show_popup( player, item_link )
end

local function setup_slash_commands()
  -- Roll For commands
  SLASH_RF1 = RollSlashCommand.NormalRoll
  M.api().SlashCmdList[ "RF" ] = on_roll_command( RollSlashCommand.NormalRoll )
  SLASH_ARF1 = RollSlashCommand.NoSoftResRoll
  M.api().SlashCmdList[ "ARF" ] = in_group_check( on_roll_command( RollSlashCommand.NoSoftResRoll ) )
  SLASH_RR1 = RollSlashCommand.RaidRoll
  M.api().SlashCmdList[ "RR" ] = in_group_check( on_roll_command( RollSlashCommand.RaidRoll ) )
  SLASH_HTR1 = "/htr"
  M.api().SlashCmdList[ "HTR" ] = in_group_check( show_how_to_roll )
  SLASH_CR1 = "/cr"
  M.api().SlashCmdList[ "CR" ] = is_rolling_check( on_cancel_roll_command )
  SLASH_FR1 = "/fr"
  M.api().SlashCmdList[ "FR" ] = is_rolling_check( on_finish_roll_command )
  SLASH_SSR1 = "/ssr"
  M.api().SlashCmdList[ "SSR" ] = on_show_sorted_rolls_command
  SLASH_RFR1 = "/rfr"
  M.api().SlashCmdList[ "RFR" ] = on_reset_dropped_loot_announce_command

  -- Soft Res commands
  SLASH_SR1 = "/sr"
  M.api().SlashCmdList[ "SR" ] = on_softres_command
  SLASH_SRS1 = "/srs"
  M.api().SlashCmdList[ "SRS" ] = M.softres_check.show_softres
  SLASH_SRC1 = "/src"
  M.api().SlashCmdList[ "SRC" ] = M.softres_check.check_softres
  SLASH_SRO1 = "/sro"
  M.api().SlashCmdList[ "SRO" ] = M.name_matcher.manual_match

  SLASH_RFTEST1 = "/rftest"
  M.api().SlashCmdList[ "RFTEST" ] = test

  --SLASH_DROPPED1 = "/DROPPED"
  --M.api().SlashCmdList[ "DROPPED" ] = simulate_loot_dropped
end

function M.on_first_enter_world()
  reset()
  setup_storage()
  create_components()
  setup_slash_commands()

  info( string.format( "Loaded (%s).", hl( string.format( "v%s", version.str ) ) ) )

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

function M.award_item( player_name, item_id, item_link )
  M.awarded_loot.award( player_name, item_id )
  local winners = M.winner_tracker.find_winners( item_link )

  if getn( winners ) > 0 then
    for _, winner in ipairs( winners ) do
      if winner.winner_name == player_name then
        M.winner_history.add( player_name, item_id, item_link, winner.roll_type, winner.winning_roll )
      end
    end
  else
    M.winner_history.add( player_name, item_id, item_link )
  end

  info( string.format( "%s received %s.", hl( player_name ), item_link ) )
  M.winner_tracker.untrack( player_name, item_link )
end

function M.unaward_item( player_name, item_id, item_link )
  M.awarded_loot.unaward( player_name, item_id )
  info( string.format( "%s returned %s.", hl( player_name ), item_link ) )
end

function M.on_group_changed()
  M.name_matcher.auto_match()
  update_minimap_icon()
end

function M.on_chat_msg_addon( name, message )
  if name ~= "RollFor" then return end

  for ver in string.gmatch( message, "VERSION::(.-)" ) do
    M.version_broadcast.on_version( ver )
  end
end

m.EventHandler.handle_events( M )
return M
