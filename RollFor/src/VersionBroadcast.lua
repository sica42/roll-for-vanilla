local lib_stub = LibStub
local modules = lib_stub( "RollFor-Modules" )
if modules.VersionBroadcast then return end

local M = {}

local ace_comm = lib_stub( "AceComm-3.0" )
local comm_prefix = "RollFor"

local function strip_dots( v )
  local result, _ = string.gsub( v, "%.", "" )
  return result
end

function M.new( db, version )
  local function version_recently_reminded()
    if not db.char.last_new_version_reminder_timestamp then return false end

    local time = modules.lua.time()

    -- Only remind once a day
    if time - db.char.last_new_version_reminder_timestamp > 3600 * 24 then
      return false
    else
      return true
    end
  end

  local function broadcast_version( channel )
    -- ace_comm:SendCommMessage( comm_prefix, "VERSION::" .. version, type, target )
    modules.api.SendAddonMessage( "RollFor", "VERSION::" .. version, channel )
  end

  local function broadcast_version_to_the_guild()
    if not modules.api.IsInGuild() then return end
    broadcast_version( "GUILD" )
  end

  local function is_new_version( v )
    local myVersion = tonumber( strip_dots( version ) )
    local theirVersion = tonumber( strip_dots( v ) )

    return theirVersion > myVersion
  end

  local function is_old_version( v )
    local myVersion = tonumber( strip_dots( version ) )
    local theirVersion = tonumber( strip_dots( v ) )

    return theirVersion < myVersion
  end

  local function broadcast_version_to_the_group()
    if not modules.api.IsInGroup() and not modules.api.IsInRaid() then return end
    broadcast_version( modules.api.IsInRaid() and "RAID" or "PARTY" )
  end

  local function on_group_changed()
    broadcast_version_to_the_group()
  end

  local function notify_about_new_version( ver )
    db.char.last_new_version_reminder_timestamp = modules.lua.time()
    modules.pretty_print( string.format( "New version (%s) is available!", modules.colors.highlight( string.format( "v%s", ver ) ) ) )
  end

  local function on_version( ver )
    if is_new_version( ver ) and not version_recently_reminded() then
      notify_about_new_version( ver )
    end
  end

  -- OnComm(prefix, message, distribution, sender)
  local function on_comm( prefix, message, _, sender )
    if prefix ~= comm_prefix then return end

    local cmd, value = string.match( message, "^(.*)::(.*)$" )

    if cmd == "VERSION" and is_new_version( value ) and not version_recently_reminded() then
      notify_about_new_version( value )
    elseif cmd == "VERSION" and is_old_version( value ) then
      broadcast_version( "WHISPER", sender )
    end
  end

  local function broadcast()
    broadcast_version_to_the_guild()
    broadcast_version_to_the_group()
  end

  ace_comm:RegisterComm( comm_prefix, on_comm )

  return {
    on_group_changed = on_group_changed,
    broadcast = broadcast,
    on_version = on_version
  }
end

modules.VersionBroadcast = M
return M
