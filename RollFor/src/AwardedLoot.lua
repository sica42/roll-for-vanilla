---@diagnostic disable-next-line: undefined-global
local modules = LibStub( "RollFor-Modules" )
if modules.AwardedLoot then return end

local M = {}

---@diagnostic disable-next-line: deprecated
local getn = table.getn

function M.new( db )
  local awarded_items = db.char.awarded_items or {}

  local function persist()
    db.char.awarded_items = awarded_items
  end

  local function award( player, item_id )
    table.insert( awarded_items, { player = player, item_id = item_id } )
    persist()
  end

  local function has_item_been_awarded( player, item_id )
    for _, item in pairs( awarded_items ) do
      if item.player == player and item.item_id == item_id then return true end
    end

    return false
  end

  local function clear()
    if getn( awarded_items ) == 0 then return end

    awarded_items = {}
    persist()
  end

  return {
    award = award,
    has_item_been_awarded = has_item_been_awarded,
    clear = clear
  }
end

modules.AwardedLoot = M
return M
