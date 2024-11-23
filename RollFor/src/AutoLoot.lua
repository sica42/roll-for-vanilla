local modules = LibStub( "RollFor-Modules" )
if modules.AutoLoot then return end

local M = {}
local pretty_print = modules.pretty_print
local item_utils = modules.ItemUtils
local contains = modules.table_contains_value
---@diagnostic disable-next-line: deprecated
local getn = table.getn

local items = {
  [ "Ragefire Chasm" ] = {
    14149,
    14113, -- Aboriginal Sash of the Whale
    81094  -- Amber Topaz
  },
  [ "Blackwing Lair" ] = {
    18562, -- Elementium Ore
    19183, -- Hourglass Sand
  },
}

function M.new( api, db )
  local frame

  local function find_player_candidate_index()
    for i = 1, 40 do
      local name = modules.api.GetMasterLootCandidate( i )
      if name == api().UnitName( "player" ) then
        return i
      end
    end
  end

  local function on_auto_loot()
    local item_count = api().GetNumLootItems()
    local zone_name = api().GetRealZoneText()
    local item_ids = items[ zone_name ]

    if not item_ids or getn( item_ids ) == 0 then
      return
    end

    local threshold = modules.api.GetLootThreshold()

    for slot = 1, item_count do
      local link = modules.api.GetLootSlotLink( slot )
      local _, _, _, quality = modules.api.GetLootSlotInfo( slot )
      if not quality then quality = 0 end

      if link then
        local item_id = item_utils.get_item_id( link )

        if quality < threshold or db.char.auto_loot and contains( item_ids, item_id ) then
          local index = find_player_candidate_index()

          if index then
            api().GiveMasterLoot( slot, index )
          else
            pretty_print( string.format( "%s cannot be looted.", link ) )
          end
        end
      end
    end
  end

  local function create_frame()
    frame = api().CreateFrame( "BUTTON", nil, api().LootFrame, "UIPanelButtonTemplate" )
    frame:SetWidth( 90 )
    frame:SetHeight( 23 )
    frame:SetText( "Auto Loot" )
    frame:SetPoint( "TOPRIGHT", api().LootFrame, "TOPRIGHT", -75, -44 )
    frame:SetScript( "OnClick", on_auto_loot )
    frame:Show()
  end

  local function on_loot_opened()
    if not frame then create_frame() end

    local zone_name = api().GetRealZoneText()
    local item_ids = items[ zone_name ]

    if not item_ids or getn( item_ids ) == 0 then
      frame:Hide()
    else
      frame:Show()
    end

    on_auto_loot()
    -- end
  end

  return {
    on_loot_opened = on_loot_opened
  }
end

modules.AutoLoot = M
return M
