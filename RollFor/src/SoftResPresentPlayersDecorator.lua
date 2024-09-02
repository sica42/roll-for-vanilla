local modules = LibStub( "RollFor-Modules" )
if modules.SoftResPresentPlayersDecorator then return end

local M = {}

local filter = modules.filter
local clone = modules.clone

-- I decorate given softres class with present players logic.
-- Example: "give me all players who soft-ressed and are in the group".
function M.new( group_roster, softres )
  local f = group_roster.is_player_in_my_group

  local function get( item_id )
    return filter( softres.get( item_id ), f, "name" )
  end

  local function get_all_softres_player_names()
    return filter( softres.get_all_softres_player_names(), f )
  end

  local decorator = clone( softres )
  decorator.get = get
  decorator.get_all_softres_player_names = get_all_softres_player_names

  return decorator
end

modules.SoftResPresentPlayersDecorator = M
return M
