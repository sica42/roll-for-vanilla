---@diagnostic disable-next-line: undefined-global
local modules = LibStub( "RollFor-Modules" )
if modules.ItemUtils then return end

local M = {}

function M.get_item_id( item_link )
  for item_id in string.gmatch( item_link, "|c%x%x%x%x%x%x%x%x|Hitem:(%d+):.+|r" ) do
    return tonumber( item_id )
  end

  return nil
end

function M.get_item_name( item_link )
  return string.gsub( item_link, "|c%x%x%x%x%x%x%x%x|Hitem:%d+.*|h%[(.*)%]|h|r", "%1" )
end

function M.parse_all_links( item_links )
  local result = {}
  if not item_links then return result end

  for item_link in string.gmatch( item_links, "|c%x%x%x%x%x%x%x%x|Hitem:[^%]]+%]|h|r" ) do
    table.insert( result, item_link )
  end

  return result
end

function M.make_item( id, name, link, quality )
  return { id = id, name = name, link = link, quality = quality }
end

modules.ItemUtils = M
return M
