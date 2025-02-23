RollFor = RollFor or {}
local m = RollFor

if m.AwardedLoot then return end

local M = m.Module.new( "AwardedLoot" )

local getn = m.getn

---@class AwardedLoot
---@field award fun( player_name: string, item_id: number, winner: table?, item_link: ItemLink?, player_class: PlayerClass?, sr_plus: number? )
---@field unaward fun( player_name: string, item_id: number )
---@field get_winners fun()
---@field has_item_been_awarded fun( player_name: string, item_id: number ): boolean
---@field has_item_been_awarded_to_any_player fun( item_id: ItemId ): boolean
---@field clear fun( force: boolean?)

---@param db table
---@param group_roster GroupRoster
---@param config Config
function M.new( db, group_roster, config )
  db.awarded_items = db.awarded_items or {}

  ---@param player_name string
  ---@param item_id number
  ---@param winner table?
  ---@param item_link ItemLink?
  ---@param player_class PlayerClass?
  ---@param sr_plus number?
  local function award( player_name, item_id, winner, item_link, player_class, sr_plus )
    M.debug.add( "award" )
    if not player_class then
      local player = group_roster.find_player( player_name )
      player_class = player and player.class
    end
    local quality, _ = m.get_item_quality_and_texture( m.api, item_id )
    if not item_link then
      item_link = m.fetch_item_link( item_id, quality )
    end

    table.insert( db.awarded_items, {
      player_name = player_name,
      player_class = player_class,
      item_id = item_id,
      item_link = item_link,
      quality = quality,
      roll_type = winner and winner.roll_type,
      rolling_strategy = winner and winner.rolling_strategy,
      winning_roll = winner and winner.winning_roll,
      sr_plus = sr_plus
    } )
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
    if not config.keep_award_data() or force then
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
