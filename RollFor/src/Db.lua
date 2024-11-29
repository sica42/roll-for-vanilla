---@diagnostic disable-next-line: undefined-global
local modules = LibStub( "RollFor-Modules" )
if modules.Db then return end

local M = {}

function M.new( db )
  return function( module_name )
    db[ module_name ] = db[ module_name ] or {}

    local proxy = {}
    local mt = {
      __index = function( _, key )
        return db[ module_name ][ key ]
      end,
      __newindex = function( _, key, value )
        db[ module_name ][ key ] = value
      end
    }

    setmetatable( proxy, mt )
    return proxy
  end
end

modules.Db = M
return M
