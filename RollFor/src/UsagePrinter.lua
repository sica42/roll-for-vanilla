---@diagnostic disable-next-line: undefined-global
local libStub = LibStub
local modules = libStub( "RollFor-Modules" )
if modules.UsagePrinter then return end

local M = {}
local pretty_print = modules.pretty_print
local hl = modules.colors.hl
local RollSlashCommand = modules.Types.RollSlashCommand

function M.new()
  local function print_usage( roll_type )
    if roll_type == RollSlashCommand.NormalRoll or roll_type == RollSlashCommand.NoSoftResRoll then
      pretty_print( string.format( "Usage: %s <%s> [%s]", roll_type, hl( "item" ), hl( "seconds" ) ) )
    elseif roll_type == RollSlashCommand.RaidRoll then
      pretty_print( string.format( "Usage: %s <%s>", roll_type, hl( "item" ) ), nil, "RaidRoll" )
    else
    end
  end

  return {
    print_usage = print_usage
  }
end

modules.UsagePrinter = M
return M
