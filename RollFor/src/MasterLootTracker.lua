local libStub = LibStub
local modules = libStub( "RollFor-Modules" )
if modules.MasterLootTracker then return end

local M = {}
local count_elements = modules.count_elements

function M.new()
  local m_items = {}

  -- item -> ItemUtils.make_item()
  local function add( slot, item )
    m_items[ slot ] = item
  end

  local function remove( slot )
    m_items[ slot ] = nil
  end

  local function count()
    return count_elements( m_items )
  end

  local function clear()
    m_items = {}
  end

  local function get( slot )
    return m_items[ slot ]
  end

  return {
    add = add,
    remove = remove,
    count = count,
    clear = clear,
    get = get
  }
end

modules.MasterLootTracker = M
return M
