---@diagnostic disable-next-line: undefined-global
local modules = LibStub( "RollFor-Modules" )
if modules.PfUiIntegrationDialog then return end

local M = {}

local confirmation_dialog_key = "ROLLFOR_PFUI_INTEGRATION_CONFIRMATION_DIALOG"
local blue = modules.colors.blue
local hl = modules.colors.hl
local info = modules.pretty_print
local pfui = modules.msg.pfui

function M.new( config )
  local function create_custom_dialog()
    modules.api.StaticPopupDialogs[ confirmation_dialog_key ] = {
      text = string.format(
        "Would your like to integrate %s with %s?\n" ..
        "This will add %s and %s click support for roll and raid-rolling items.\n" ..
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
        config.enable_pfui_integration()
        info( string.format( "%s integration is now %s. Disable using %s.", pfui, modules.msg.enabled, hl( "/rf config pfui" ) ) )
      end,
      OnCancel = function()
        config.disable_pfui_integration()
        info( string.format( "%s integration is now %s. Enable using %s.", pfui, modules.msg.disabled, hl( "/rf config pfui" ) ) )
      end,
      timeout = 0,
    }
  end

  local function on_master_loot()
    if not modules.uses_pfui() or config.pfui_integration_enabled() then return end
    create_custom_dialog()
    modules.api.StaticPopup_Show( confirmation_dialog_key )
  end

  return {
    on_master_loot = on_master_loot
  }
end

modules.PfUiIntegrationDialog = M
return M
