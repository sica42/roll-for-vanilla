RollFor = RollFor or {}
local m = RollFor
if m.LootList then return end

local M = {}
local interface = m.Interface
local clear = m.clear_table

---@class LootList
---@field get_items fun(): DistributableItem[]
---@field get_source_guid fun(): string

---@param loot_facade LootFacade
---@param item_utils ItemUtils
---@return LootList
function M.new( loot_facade, item_utils )
  interface.validate( loot_facade, m.LootFacade.interface )
  interface.validate( item_utils, m.ItemUtils.interface )

  local lf = loot_facade
  local items = {}
  local source_guid

  local function clear_items()
    clear( items )
    items.n = 0
    source_guid = nil
  end

  local function sort()
    table.sort( items, function( a, b )
      if a.coin and not b.coin then return true end
      if b.coin and not a.coin then return false end
      if a.coin and b.coin then return true end

      if a.quality == b.quality then
        return a.name < b.name
      else
        return a.quality > b.quality
      end
    end )
  end

  local function on_loot_opened()
    clear_items()
    source_guid = lf.get_source_guid()

    for slot = 1, lf.get_item_count() do
      if lf.is_coin( slot ) then
        local info = lf.get_info( slot )

        if info then
          table.insert( items, item_utils.make_coin( info.texture, info.name ) )
        end
      else
        local link = lf.get_link( slot )
        local info = lf.get_info( slot )
        local item_id = link and item_utils.get_item_id( link )
        local item_name = link and item_utils.get_item_name( link )

        if item_id and item_name then
          table.insert( items, item_utils.make_distributable_item( item_id, item_name, link, info and info.quality, info and info.texture, slot ) )
        end
      end
    end

    sort()
  end

  local function on_loot_closed()
    clear_items()
  end

  local function on_loot_slot_cleared( slot )
    local index

    for i, item in ipairs( items ) do
      if item.slot == slot then
        index = i
        break
      end
    end

    if index then
      table.remove( items, index )
    end
  end

  local function get_items()
    return items
  end

  loot_facade.subscribe( "LootOpened", on_loot_opened )
  loot_facade.subscribe( "LootClosed", on_loot_closed )
  loot_facade.subscribe( "LootSlotCleared", on_loot_slot_cleared )

  return {
    get_items = get_items,
    get_source_guid = function() return source_guid end
  }
end

m.LootList = M
return M
