local libStub = LibStub
local modules = libStub( "RollFor-Modules" )
if modules.MasterLoot then return end

local M = {}
local _G = getfenv()
local pretty_print = modules.pretty_print
local hl = modules.colors.hl
local buttons_hooked = false

---@diagnostic disable-next-line: deprecated
local getn = table.getn

local function get_dummy_candidates()
  return {
    { name = "Ohhaimark",    class = "Warrior", value = 1 },
    { name = "Obszczymucha", class = "Druid",   value = 2 },
    { name = "Jogobobek",    class = "Hunter",  value = 3 },
    { name = "Xiaorotflmao", class = "Shaman",  value = 4 },
    { name = "Kacprawcze",   class = "Priest",  value = 5 },
    { name = "Psikutas",     class = "Paladin", value = 6 },
    { name = "Motoko",       class = "Rogue",   value = 7 },
    { name = "Blanchot",     class = "Warrior", value = 8 },
    { name = "Adamsandler",  class = "Druid",   value = 9 },
    { name = "Johnstamos",   class = "Hunter",  value = 10 },
    { name = "Xiaolmao",     class = "Shaman",  value = 11 },
    { name = "Ronaldtramp",  class = "Priest",  value = 12 },
    { name = "Psikuta",      class = "Paladin", value = 13 },
    { name = "Kusanagi",     class = "Rogue",   value = 14 },
    { name = "Chuj",         class = "Priest",  value = 15 },
  }
end

local function get_candidates( group_roster )
  if not group_roster then return get_dummy_candidates() end

  local result = {}
  local players = group_roster.get_all_players_in_my_group()

  for i = 1, 40 do
    local name = modules.api.GetMasterLootCandidate( i )

    for _, p in ipairs( players ) do
      if name == p.name then
        table.insert( result, { name = name, class = p.class, value = i } )
      end
    end
  end

  return result
end

local function sort( candidates )
  table.sort( candidates, function( lhs, rhs )
    if lhs.class < rhs.class then
      return true
    elseif lhs.class > rhs.class then
      return false
    end

    return lhs.name < rhs.name
  end )
end

function M.new( group_roster, dropped_loot, award_item, master_loot_frame, master_loot_tracker )
  local m_confirmed = nil

  local function reset_confirmation()
    m_confirmed = nil
  end

  local function on_loot_slot_cleared( slot )
    if not m_confirmed then return end

    local item_name = modules.api.LootFrame.selectedItemName
    local item_quality = modules.api.LootFrame.selectedQuality
    local item_id = dropped_loot.get_dropped_item_id( item_name )
    local item = master_loot_tracker.get( slot )
    local colored_item_name = modules.colorize_item_by_quality( item_name, item_quality )

    if item_id then
      award_item( m_confirmed.player.name, item_id, item_name, item.link )
      master_loot_tracker.remove( slot )
    else
      pretty_print( string.format( "Cannot determine item id for %s.", colored_item_name ) )
    end

    reset_confirmation()
    master_loot_frame.hide()
  end

  local function on_confirm( slot, player )
    m_confirmed = { slot = slot, player = player }
    modules.api.GiveMasterLoot( slot, player.value )
    master_loot_frame.hide()
  end

  local function normal_loot( button )
    reset_confirmation()
    button:OriginalOnClick()
  end

  local function master_loot( button )
    local item_name = _G[ button:GetName() .. "Text" ]:GetText()
    modules.api.LootFrame.selectedQuality = button.quality
    modules.api.LootFrame.selectedItemName = item_name
    modules.api.LootFrame.selectedSlot = button.slot
    master_loot_frame.create( on_confirm )
    master_loot_frame.hide()

    local candidates = get_candidates( group_roster ) -- remove group_roster for testing (dummy candidates)

    if getn( candidates ) == 0 then
      -- This happened before.
      modules.pretty_print( "Game API didn't return any loot candidates. Restoring original button hook." )
      normal_loot( button )
      return
    end

    sort( candidates )
    master_loot_frame.create_candidate_frames( candidates )
    master_loot_frame.anchor( button )
    master_loot_frame.show()
  end

  local function on_loot_opened()
    if not modules.is_player_master_looter() then
      if buttons_hooked then
        master_loot_frame.restore_loot_buttons()
        buttons_hooked = false
      end

      return
    end

    reset_confirmation()
    master_loot_frame.hook_loot_buttons( reset_confirmation, normal_loot, master_loot, master_loot_frame.hide )
    buttons_hooked = true
  end

  local function on_loot_closed()
    master_loot_frame.hide()
    if not modules.is_player_master_looter() then return end

    local items_left_count = master_loot_tracker.count()

    if not m_confirmed then
      if items_left_count > 0 then pretty_print( "Not all items were distributed." ) end
      return
    end

    if items_left_count == 0 then return end
    local item = master_loot_tracker.get( m_confirmed.slot )

    if items_left_count > 1 then
      pretty_print( string.format( "%s (slot %s) was supposed to be given to %s.", item and item.link or "Item", m_confirmed.slot, m_confirmed.player.name ) )
      return
    end

    if item == nil then
      pretty_print( "A different slot left in the tracker.", "red" )
      return
    end

    award_item( m_confirmed.player.name, item.id, item.name, item.link )
    master_loot_tracker.remove( m_confirmed.slot )
    reset_confirmation()
  end

  local function on_recipient_inventory_full()
    if m_confirmed then
      pretty_print( string.format( "%s's inventory is full and cannot receive the item.", hl( m_confirmed.player.name ) ), "red" )
      reset_confirmation()
    end
  end

  local function on_player_is_too_far()
    if m_confirmed then
      pretty_print( string.format( "%s is too far to receive the item.", hl( m_confirmed.player.name ) ), "red" )
      reset_confirmation()
    end
  end

  local function on_unknown_error_message( message )
    if m_confirmed then
      pretty_print( message, "red" )
      reset_confirmation()
    end
  end

  return {
    on_loot_slot_cleared = on_loot_slot_cleared,
    on_loot_opened = on_loot_opened,
    on_loot_closed = on_loot_closed,
    on_recipient_inventory_full = on_recipient_inventory_full,
    on_player_is_too_far = on_player_is_too_far,
    on_unknown_error_message = on_unknown_error_message
  }
end

modules.MasterLoot = M
return M
