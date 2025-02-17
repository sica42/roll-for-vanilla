RollFor = RollFor or {}
local m = RollFor

if m.AwardedLoot then return end

local M = m.Module.new( "AwardedLoot" )

---@diagnostic disable-next-line: deprecated
local getn = table.getn

---@class AwardedLoot
---@field award fun( player_name: string, item_id: number )
---@field unaward fun( player_name: string, item_id: number )
---@field get_winners fun()
---@field has_item_been_awarded fun( player_name: string, item_id: number ): boolean
---@field has_item_been_awarded_to_any_player fun( item_id: ItemId ): boolean
---@field clear fun()

function M.new( db, group_roster, config )
  db.awarded_items = db.awarded_items or {}

  ---@param player_name string
  ---@param item_id number
  ---@param item_link string
  ---@param roll_type string
  ---@param rolling_strategy string
  local function award( player_name, item_id, roll_type, rolling_strategy )
    M.debug.add( "award" )
    local player = group_roster.find_player( player_name )
    local class = player and player.class or nil            
    local quality, texture = m.get_item_quality_and_texture( item_id )
    local itemLink = m.fetch_item_link(item_id, quality)

    table.insert( db.awarded_items, { player_name = player_name, item_id = item_id, roll_type = roll_type, rolling_strategy = rolling_strategy, player_class = class, quality = quality, itemLink = itemLink } )
  end

  ---@return table
  local function get_winners()
    return db.awarded_items
  end

  ---@param player_name string
  ---@param item_id number
  ---@return boolean
  local function has_item_been_awarded( player_name, item_id )
    for _, item in pairs( db.awarded_items ) do
      if item.player_name == player_name and item.item_id == item_id then return true end
    end

    return false
  end

  ---@param item_id ItemId
  ---@return boolean
  local function has_item_been_awarded_to_any_player( item_id )
    for _, item in pairs( db.awarded_items ) do
      if item.item_id == item_id then return true end
    end

    return false
  end

  local function clear( force )
    M.debug.add( "clear" )
    if not config.keep_award_data or force then
      m.clear_table( db.awarded_items )
    end
  end

  ---@param player_name string
  ---@param item_id number
  local function unaward( player_name, item_id )
    M.debug.add( "unaward" )
    for i = getn( db.awarded_items ), 1, -1 do
      local awarded_item = db.awarded_items[ i ]

      if awarded_item.player_name == player_name and awarded_item.item_id == item_id then
        table.remove( db.awarded_items, i )
        return
      end
    end
  end

  ---@type AwardedLoot
  return {
    award = award,
    unaward = unaward,
    get_winners = get_winners,
    has_item_been_awarded = has_item_been_awarded,
    has_item_been_awarded_to_any_player = has_item_been_awarded_to_any_player,
    clear = clear
  }
end

m.AwardedLoot = M
return M
