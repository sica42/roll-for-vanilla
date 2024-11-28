---@diagnostic disable-next-line: undefined-global
local libStub = LibStub
local modules = libStub( "RollFor-Modules" )
if modules.LootAwardPopup then return end

local utils = require( "test/utils" )

local M = {}

function M.new()
  local function register_confirm_callback( callback )
    utils.register_loot_confirm_callback( callback )
  end

  return {
    show = function() end,
    hide = function() end,
    register_confirm_callback = register_confirm_callback
  }
end

modules.LootAwardPopup = M
return M
