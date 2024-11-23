local modules = LibStub( "RollFor-Modules" )
if modules.DroppedLoot then return end

local M = {}

---@diagnostic disable-next-line: deprecated
local getn = table.getn

function M.new( db )
  local dropped_items = db.char.dropped_items or {}

  local function get_dropped_item_id( item_name )
    for _, item in pairs( dropped_items ) do
      if item.name == item_name then return item.id end
    end

    return nil
  end

  local function get_dropped_item_name( item_id )
    for _, item in pairs( dropped_items ) do
      if item.id == item_id then return item.name end
    end

    return nil
  end

  local function add( item_id, item_name )
    table.insert( dropped_items, { id = item_id, name = item_name } )
  end

  local function persist()
    db.char.dropped_items = dropped_items
  end

  local function clear()
    if getn( dropped_items ) == 0 then return end
    dropped_items = {}
    persist()
  end

  return {
    get_dropped_item_id = get_dropped_item_id,
    get_dropped_item_name = get_dropped_item_name,
    add = add,
    persist = persist,
    clear = clear
  }
end

modules.DroppedLoot = M
return M
