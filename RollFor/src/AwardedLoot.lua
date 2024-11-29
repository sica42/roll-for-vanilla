---@diagnostic disable-next-line: undefined-global
local modules = LibStub( "RollFor-Modules" )
if modules.AwardedLoot then return end

local M = {}

---@diagnostic disable-next-line: deprecated
local getn = table.getn

function M.new( db )
  local awarded_items = db.awarded_items or {}

  local function persist()
    db.awarded_items = awarded_items
  end

  local function award( player_name, item_id )
    table.insert( awarded_items, { player_name = player_name, item_id = item_id } )
    persist()
  end

  local function has_item_been_awarded( player_name, item_id )
    for _, item in pairs( awarded_items ) do
      if item.player_name == player_name and item.item_id == item_id then return true end
    end

    return false
  end

  local function clear()
    if getn( awarded_items ) == 0 then return end

    awarded_items = {}
    persist()
  end

  local function unaward( player_name, item_id )
    for i = getn( awarded_items ), 1, -1 do
      local awarded_item = awarded_items[ i ]

      if awarded_item.player_name == player_name and awarded_item.item_id == item_id then
        table.remove( awarded_items, i )
        return
      end
    end

    persist()
  end

  return {
    award = award,
    unaward = unaward,
    has_item_been_awarded = has_item_been_awarded,
    clear = clear
  }
end

modules.AwardedLoot = M
return M
