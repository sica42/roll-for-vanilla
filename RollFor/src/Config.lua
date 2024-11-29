---@diagnostic disable-next-line: undefined-global
local modules = LibStub( "RollFor-Modules" )
if modules.Config then return end

local m = modules
local info = m.pretty_print
local print_header = m.print_header
local hl = m.colors.hl
local grey = m.colors.grey

local M = {}

function M.new( db )
  local callbacks = {}

  local function notify_subscribers( event, value )
    if not callbacks[ event ] then return end

    for _, callback in ipairs( callbacks[ event ] ) do
      callback( value )
    end
  end

  local function init()
    if not db.ms_roll_threshold then db.ms_roll_threshold = 100 end
    if not db.os_roll_threshold then db.os_roll_threshold = 99 end
    if not db.tmog_roll_threshold then db.tmog_roll_threshold = 98 end
    if db.tmog_rolling_enabled == nil then db.tmog_rolling_enabled = true end
  end

  local function toggle_auto_loot()
    if db.auto_loot then
      db.auto_loot = false
    else
      db.auto_loot = true
    end

    info( string.format( "Auto-loot is %s.", db.auto_loot and m.msg.enabled or m.msg.disabled ) )
  end

  local function print_master_loot_warning_settings()
    info( string.format( "Master Loot warning %s.", db.disable_ml_warning and m.msg.disabled or m.msg.enabled ) )
  end

  local function toggle_ml_warning()
    if db.disable_ml_warning then
      db.disable_ml_warning = nil
    else
      db.disable_ml_warning = 1
    end

    print_master_loot_warning_settings()
    notify_subscribers( "toggle_ml_warning", db.disable_ml_warning )
  end

  local function print_raid_roll_settings()
    local status = db.auto_raid_roll and m.msg.enabled or m.msg.disabled
    info( string.format( "Auto raid-roll is %s.", status ) )
  end

  local function toggle_auto_raid_roll()
    if db.auto_raid_roll then
      db.auto_raid_roll = false
    else
      db.auto_raid_roll = true
    end

    print_raid_roll_settings()
  end

  local function print_roll_thresholds()
    local ms_threshold = db.ms_roll_threshold
    local os_threshold = db.os_roll_threshold
    local tmog_threshold = db.tmog_roll_threshold
    local tmog_info = string.format( ", %s %s", hl( "TMOG" ), tmog_threshold ) or ""

    info( string.format( "Roll thresholds: %s %s, %s %s%s", hl( "MS" ), ms_threshold, hl( "OS" ), os_threshold, tmog_info ) )
  end

  local function print_transmog_rolling_setting( show_threshold )
    local tmog_rolling_enabled = db.tmog_rolling_enabled
    local threshold = show_threshold and tmog_rolling_enabled and string.format( " (%s)", hl( db.tmog_roll_threshold ) ) or ""
    info( string.format( "Transmog rolling is %s%s.", tmog_rolling_enabled and m.msg.enabled or m.msg.disabled, threshold ) )
  end

  local function print_pfui_integration_setting()
    if not m.uses_pfui() then return end
    info( string.format( "%s integration is %s.", m.msg.pfui, db.pfui_integration_enabled and m.msg.enabled or m.msg.disabled ) )
  end

  local function print()
    print_header( "RollFor Configuration" )
    print_master_loot_warning_settings()
    print_raid_roll_settings()
    print_roll_thresholds()
    print_transmog_rolling_setting()
    print_pfui_integration_setting()
    m.print( string.format( "For more info, type: %s", hl( "/rf config help" ) ) )
  end

  local function configure_ms_threshold( args )
    for value in string.gmatch( args, "config ms (%d+)" ) do
      db.ms_roll_threshold = tonumber( value )
      print_roll_thresholds()
      return
    end

    info( string.format( "Usage: %s <threshold>", hl( "/rf config ms" ) ) )
  end

  local function configure_os_threshold( args )
    for value in string.gmatch( args, "config os (%d+)" ) do
      db.os_roll_threshold = tonumber( value )
      print_roll_thresholds()
      return
    end

    info( string.format( "Usage: %s <threshold>", hl( "/rf config os" ) ) )
  end

  local function configure_tmog_threshold( args )
    if args == "config tmog" then
      db.tmog_rolling_enabled = not db.tmog_rolling_enabled
      print_transmog_rolling_setting( true )
      return
    end

    for value in string.gmatch( args, "config tmog (%d+)" ) do
      db.tmog_roll_threshold = tonumber( value )
      print_roll_thresholds()
      return
    end

    info( string.format( "Usage: %s <threshold>", hl( "/rf config tmog" ) ) )
  end

  local function print_help()
    local v = function( name ) return string.format( "%s%s%s", hl( "<" ), grey( name ), hl( ">" ) ) end

    print_header( "RollFor Configuration Help" )
    m.print( string.format( "%s - show configuration", hl( "/rf config" ) ) )
    m.print( string.format( "%s - toggle minimap icon", hl( "/rf config minimap" ) ) )
    m.print( string.format( "%s - lock/unlock minimap icon", hl( "/rf config minimap lock" ) ) )
    m.print( string.format( "%s - toggle master loot warning", hl( "/rf config ml" ) ) )
    m.print( string.format( "%s - toggle auto raid-roll", hl( "/rf config auto-rr" ) ) )
    m.print( string.format( "%s - show MS rolling threshold ", hl( "/rf config ms" ) ) )
    m.print( string.format( "%s %s - set MS rolling threshold ", hl( "/rf config ms" ), v( "threshold" ) ) )
    m.print( string.format( "%s - show OS rolling threshold ", hl( "/rf config os" ) ) )
    m.print( string.format( "%s %s - set OS rolling threshold ", hl( "/rf config os" ), v( "threshold" ) ) )
    m.print( string.format( "%s - toggle TMOG rolling", hl( "/rf config tmog" ) ) )
    m.print( string.format( "%s %s - set TMOG rolling threshold", hl( "/rf config tmog" ), v( "threshold" ) ) )

    if m.uses_pfui() then
      m.print( string.format( "%s - toggle %s integration", hl( "/rf config pfui" ), m.msg.pfui ) )
    end
  end

  local function toggle_pfui_integration()
    if db.pfui_integration then
      db.pfui_integration = false
    else
      db.pfui_integration = true
    end

    print_pfui_integration_setting()
  end

  local function enable_pfui_integration()
    db.pfui_integration_enabled = true
    db.pf_integration_info_showed = true
  end

  local function disable_pfui_integration()
    db.pfui_integration_enabled = false
    db.pf_integration_info_showed = true
  end

  local function lock_minimap_button()
    db.minimap_button_locked = true
    info( string.format( "Minimap button is %s.", m.msg.locked ) )
    notify_subscribers( "minimap_button_locked", true )
  end

  local function unlock_minimap_button()
    db.minimap_button_locked = false
    info( string.format( "Minimap button is %s.", m.msg.unlocked ) )
    notify_subscribers( "minimap_button_locked", false )
  end

  local function hide_minimap_button()
    db.minimap_button_hidden = true
    notify_subscribers( "minimap_button_hidden", true )
  end

  local function show_minimap_button()
    db.minimap_button_hidden = false
    notify_subscribers( "minimap_button_hidden", false )
  end

  local function on_command( args )
    if args == "config" then
      print()
      return
    end

    if args == "config help" then
      print_help()
      return
    end

    if args == "config ml" then
      toggle_ml_warning()
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
      if db.minimap_button_hidden then
        show_minimap_button()
      else
        hide_minimap_button()
      end

      return
    end

    if args == "config minimap lock" then
      if db.minimap_button_locked then
        unlock_minimap_button()
      else
        lock_minimap_button()
      end

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

    print_help()
  end

  local function subscribe( event, callback )
    callbacks[ event ] = callbacks[ event ] or {}
    table.insert( callbacks[ event ], callback )
  end

  init()

  return {
    toggle_auto_loot = toggle_auto_loot,
    is_auto_loot = function() return db.auto_loot end,
    toggle_ml_warning = toggle_ml_warning,
    ml_warning_disabled = function() return db.disable_ml_warning end,
    toggle_auto_raid_roll = toggle_auto_raid_roll,
    auto_raid_roll = function() return db.auto_raid_roll end,
    enable_pfui_integration = enable_pfui_integration,
    disable_pfui_integration = disable_pfui_integration,
    toggle_pfui_integration = toggle_pfui_integration,
    pfui_integration_enabled = function() return db.pfui_integration_enabled end,
    pf_integration_info_showed = function() return db.pf_integration_info_showed end,
    ms_roll_threshold = function() return db.ms_roll_threshold end,
    os_roll_threshold = function() return db.os_roll_threshold end,
    tmog_roll_threshold = function() return db.tmog_roll_threshold end,
    tmog_rolling_enabled = function() return db.tmog_rolling_enabled end,
    configure_ms_threshold = configure_ms_threshold,
    configure_os_threshold = configure_os_threshold,
    configure_tmog_threshold = configure_tmog_threshold,
    minimap_button_locked = function() return db.minimap_button_locked end,
    minimap_button_hidden = function() return db.minimap_button_hidden end,
    lock_minimap_button = lock_minimap_button,
    unlock_minimap_button = unlock_minimap_button,
    hide_minimap_button = hide_minimap_button,
    show_minimap_button = show_minimap_button,
    print = print,
    print_help = print_help,
    print_raid_roll_settings = print_raid_roll_settings,
    subscribe = subscribe,
    on_command = on_command
  }
end

modules.Config = M
return M
