---@diagnostic disable-next-line: undefined-global
local modules = LibStub( "RollFor-Modules" )
if modules.DroppedLoot then return end

local M = {}

---@diagnostic disable-next-line: deprecated
local getn = table.getn

function M.new( db )
  local dropped_items = db.dropped_items or {}

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

  local function clear()
    if getn( dropped_items ) == 0 then return end
    dropped_items = {}
  end

  return {
    get_dropped_item_id = get_dropped_item_id,
    get_dropped_item_name = get_dropped_item_name,
    add = add,
    persist = function() end,
    clear = clear
  }
end

modules.DroppedLoot = M
return M
