---@diagnostic disable-next-line: undefined-global
local modules = LibStub( "RollFor-Modules" )
if modules.PfIntegrationDialog then return end

local M = {}

local confirmation_dialog_key = "ROLLFOR_PFUI_INTEGRATION_CONFIRMATION_DIALOG"
local blue = modules.colors.blue
local hl = modules.colors.hl
local info = modules.pretty_print
local pfui = modules.msg.pfui

function M.new( db )
  local function create_custom_dialog()
    modules.api.StaticPopupDialogs[ confirmation_dialog_key ] = {
      text = string.format(
        "Would your like to integrate %s with %s?\n" ..
        "This will add %s and %s click support to roll and raid-roll items.\n" ..
        "It will also replace master loot frame with roll winner tracking.\n" ..
        "You can always enable/disable the integration using %s.",
        blue( "RollFor" ),
        pfui,
        hl( "shift" ),
        hl( "alt" ),
        hl( "/rf config pfui" )
      ),
      button1 = modules.api.YES,
      button2 = modules.api.NO,
      OnAccept = function()
        db.char.pfui_integration = true
        info( string.format( "%s integration is now %s. Disable using %s.", pfui, modules.msg.enabled, hl( "/rf config pfui" ) ) )
      end,
      OnCancel = function()
        db.char.pfui_integration = false
        info( string.format( "%s integration is now %s. Enable using %s.", pfui, modules.msg.disabled, hl( "/rf config pfui" ) ) )
      end,
      timeout = 0,
    }
  end

  local function on_master_loot()
    if not modules.uses_pfui() or db.char.pfui_integration ~= nil then return end
    create_custom_dialog()
    modules.api.StaticPopup_Show( confirmation_dialog_key )
  end

  return {
    on_master_loot = on_master_loot
  }
end

modules.PfIntegrationDialog = M
return M
