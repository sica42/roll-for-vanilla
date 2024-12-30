RollFor = RollFor or {}
local m = RollFor

if m.Interface then return end

local M = {}
---@diagnostic disable-next-line: undefined-global
local debugstack = debugstack

---@param implementation table
---@param i1 table
---@param i2 table | nil
---@param i3 table | nil
---@param i4 table | nil
---@param i5 table | nil
function M.validate( implementation, i1, i2, i3, i4, i5, i6, i7, i8, i9 )
  assert( type( implementation ) == "table", "'implementation' must be a table." )

  for _, interface in ipairs( { i1, i2, i3, i4, i5, i6, i7, i8, i9 } ) do
    for method_name, expected_type in pairs( interface ) do
      local v = implementation[ method_name ]

      if type( v ) ~= expected_type then
        if debugstack then
          error( string.format( "'%s' must be a %s, got %s.", method_name, expected_type, type( v ) ) .. "\n" .. debugstack(), 2 )
        else
          error( string.format( "'%s' must be a %s, got %s.", method_name, expected_type, type( v ), debug.traceback() ), 2 )
        end
      end
    end
  end
end

---@param implementation table
---@param n1 string
---@param n2 string | nil
---@param n3 string | nil
---@param n4 string | nil
---@param n5 string | nil
---@param n6 string | nil
---@param n7 string | nil
---@param n8 string | nil
---@param n9 string | nil
function M.assert_members( implementation, n1, n2, n3, n4, n5, n6, n7, n8, n9 )
  assert( type( implementation ) == "table", "'implementation' must be a table." )

  for _, member_name in ipairs( { n1, n2, n3, n4, n5, n6, n7, n8, n9 } ) do
    if implementation[ member_name ] == nil then
      if debugstack then
        error( string.format( "Member '%s' is not present.", member_name ) .. "\n" .. debugstack(), 2 )
      else
        error( string.format( "Member '%s' is not present.", member_name, debug.traceback() ), 2 )
      end
    end
  end
end

function M.noop() end

function M.mock( interface )
  local result = {}

  for k, v in pairs( interface ) do
    if v == "function" then result[ k ] = M.noop end
  end

  return result
end

m.Interface = M
return M
