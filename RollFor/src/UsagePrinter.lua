local libStub = LibStub
local modules = libStub( "RollFor-Modules" )
if modules.UsagePrinter then return end

local M = {}
local pretty_print = modules.pretty_print
local hl = modules.colors.hl
local RollType = modules.Api.RollType

function M.new()
  local function print_usage( roll_type )
    if roll_type == RollType.NormalRoll or roll_type == RollType.NoSoftResRoll then
      pretty_print( string.format( "Usage: %s <%s> [%s]", roll_type.slash_command, hl( "item" ), hl( "seconds" ) ) )
    elseif roll_type == RollType.RaidRoll then
      pretty_print( string.format( "Usage: %s <%s>", roll_type.slash_command, hl( "item" ) ), nil, "RaidRoll" )
    else
    end
  end

  return {
    print_usage = print_usage
  }
end

modules.UsagePrinter = M
return M
