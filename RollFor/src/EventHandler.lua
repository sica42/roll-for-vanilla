RollFor = RollFor or {}
local m = RollFor

if m.EventHandler then return end

local M = {}

---@diagnostic disable-next-line: undefined-field
local lua50 = table.setn and true or false

function M.handle_events( main )
  local m_first_enter_world

  local function eventHandler( _, _event, _arg1, _arg2, _arg3, _arg4, _arg5 )
    ---@diagnostic disable-next-line: undefined-global
    local event = lua50 and event or _event
    ---@diagnostic disable-next-line: undefined-global
    local arg1 = lua50 and arg1 or _arg1
    ---@diagnostic disable-next-line: undefined-global
    local arg2 = lua50 and arg2 or _arg2
    ---@diagnostic disable-next-line: undefined-global
    local arg3 = lua50 and arg3 or _arg3
    ---@diagnostic disable-next-line: undefined-global
    local arg4 = lua50 and arg4 or _arg4
    ---@diagnostic disable-next-line: undefined-global
    local arg5 = lua50 and arg5 or _arg5

    if event == "PLAYER_LOGIN" then
      m_first_enter_world = false
    elseif event == "PLAYER_ENTERING_WORLD" then
      if not m_first_enter_world then
        main.on_first_enter_world()
        m_first_enter_world = true
      end
    elseif event == "PARTY_MEMBERS_CHANGED" then
      main.version_broadcast.on_group_changed()
      main.on_group_changed()
      main.new_group_event.on_group_changed()
    elseif event == "CHAT_MSG_PARTY" then
      main.roll_for_ad.on_chat_msg_party( arg1, arg2 )
      -- main.on_chat_msg_system( arg1, arg2, arg3, arg4, arg5 )
    elseif event == "CHAT_MSG_RAID" then
      main.roll_for_ad.on_chat_msg_raid( arg1, arg2 )
    elseif event == "CHAT_MSG_RAID_LEADER" then
      main.roll_for_ad.on_chat_msg_raid( arg1, arg2 )
    elseif event == "CHAT_MSG_WHISPER_INFORM" then
      main.roll_for_ad.on_chat_msg_whisper_inform( arg1, arg2 )
    elseif event == "CHAT_MSG_SYSTEM" then
      main.on_chat_msg_system( arg1, arg2, arg3, arg4, arg5 )
    elseif event == "CHAT_MSG_ADDON" then
      main.on_chat_msg_addon( arg1, arg2 )
    elseif event == "TRADE_SHOW" then
      main.trade_tracker.on_trade_show()
    elseif event == "TRADE_PLAYER_ITEM_CHANGED" then
      main.trade_tracker.on_trade_player_item_changed( arg1, arg2, arg3, arg4, arg5 )
    elseif event == "TRADE_TARGET_ITEM_CHANGED" then
      main.trade_tracker.on_trade_target_item_changed( arg1, arg2, arg3, arg4, arg5 )
    elseif event == "TRADE_CLOSED" then
      main.trade_tracker.on_trade_closed()
    elseif event == "TRADE_ACCEPT_UPDATE" then
      main.trade_tracker.on_trade_accept_update( arg1, arg2, arg3, arg4, arg5 )
    elseif event == "TRADE_REQUEST_CANCEL" then
      main.trade_tracker.on_trade_request_cancel()
    elseif event == "PLAYER_TARGET_CHANGED" then
      main.master_loot_warning.on_player_target_changed()
      main.auto_master_loot.on_player_target_changed( arg1 )
    elseif event == "UI_ERROR_MESSAGE" then
      local message = arg1
      if message == "That player's inventory is full" then
        main.master_loot.on_recipient_inventory_full()
        main.roll_controller.player_has_full_bags()
      elseif message == "You are too far away to loot that corpse." then
        main.master_loot.on_player_is_too_far()
      elseif message == "Player has too many of that item already" then
        main.roll_controller.player_already_has_unique_item()
      elseif message == "Player not found" then
        main.roll_controller.player_not_found()
      elseif message == "Can't assign item to that player" then
        main.roll_controller.cant_assign_item_to_that_player()
      else
        main.master_loot.on_unknown_error_message( message )
      end
    end
  end

  local frame = m.api.CreateFrame( "FRAME", "RollForFrame" )

  frame:RegisterEvent( "PLAYER_LOGIN" )
  frame:RegisterEvent( "PLAYER_ENTERING_WORLD" )
  frame:RegisterEvent( "GROUP_JOINED" )
  frame:RegisterEvent( "GROUP_LEFT" )
  frame:RegisterEvent( "GROUP_FORMED" )
  frame:RegisterEvent( "CHAT_MSG_SYSTEM" )
  frame:RegisterEvent( "CHAT_MSG_ADDON" )
  frame:RegisterEvent( "CHAT_MSG_PARTY" )
  frame:RegisterEvent( "CHAT_MSG_RAID" )
  frame:RegisterEvent( "CHAT_MSG_RAID_LEADER" )
  frame:RegisterEvent( "CHAT_MSG_WHISPER_INFORM" )
  frame:RegisterEvent( "OPEN_MASTER_LOOT_LIST" )
  frame:RegisterEvent( "TRADE_SHOW" )
  frame:RegisterEvent( "TRADE_PLAYER_ITEM_CHANGED" )
  frame:RegisterEvent( "TRADE_TARGET_ITEM_CHANGED" )
  frame:RegisterEvent( "TRADE_CLOSED" )
  frame:RegisterEvent( "TRADE_ACCEPT_UPDATE" )
  frame:RegisterEvent( "TRADE_REQUEST_CANCEL" )
  frame:RegisterEvent( "PARTY_MEMBERS_CHANGED" )
  frame:RegisterEvent( "UI_ERROR_MESSAGE" )
  frame:RegisterEvent( "PLAYER_REGEN_DISABLED" )
  frame:RegisterEvent( "PLAYER_TARGET_CHANGED" )
  frame:RegisterEvent( "ZONE_CHANGED" )
  frame:RegisterEvent( "ZONE_CHANGED_NEW_AREA" )
  frame:SetScript( "OnEvent", eventHandler )
end

m.EventHandler = M
return M
