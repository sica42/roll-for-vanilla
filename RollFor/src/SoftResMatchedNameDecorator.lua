local modules = LibStub( "RollFor-Modules" )
if modules.SoftResMatchedNameDecorator then return end

local M = {}

local map = modules.map
local no_nil = modules.no_nil

-- I decorate given softres class with matched name logic.
-- Some players make typos in SoftRes.it and then their names don't match
-- their in-game names. NameMatcher fixes that.
function M.new( name_matcher, softres )
  local f = no_nil( name_matcher.get_matched_name )

  local function get( item_id )
    return map( softres.get( item_id ), f, "name" )
  end

  local function is_player_softressing( player_name, item_id )
    local name = name_matcher.get_softres_name( player_name ) or player_name
    return softres.is_player_softressing( name, item_id )
  end

  local function get_all_softres_player_names()
    return map( softres.get_all_softres_player_names(), f )
  end

  local decorator = modules.clone( softres )
  decorator.get = get
  decorator.is_player_softressing = is_player_softressing
  decorator.get_all_softres_player_names = get_all_softres_player_names

  return decorator
end

modules.SoftResMatchedNameDecorator = M
return M
