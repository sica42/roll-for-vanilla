RollFor = RollFor or {}
local m = RollFor

if m.TooltipReader then return end


local M = {}
local _G = getfenv( 0 )
local BindType = m.ItemUtils.BindType

local function create_tooltip_frame()
  local frame = m.api.CreateFrame( "GameTooltip", "RollForTooltipFrame", nil, "GameTooltipTemplate" )
  frame:SetOwner( m.api.WorldFrame, "ANCHOR_NONE" );

  return frame
end

---@class TooltipReader
---@field get_slot_bind_type fun( slot: number ): BindType
---@field get_slot_classes fun( slot: number ): table<number, PlayerClass>|nil

---@param api table
function M.new( api )
  local m_frame

  local function ensure_frame()
    if m_frame then return end
    m_frame = create_tooltip_frame()
  end

  ---@param slot number?
  local function set_loot_slot( slot )
    ensure_frame()

    m_frame:SetOwner( m.api.WorldFrame, "ANCHOR_NONE" )
    m_frame:ClearLines()
    m_frame:SetLootItem( slot )
  end

  ---@return BindType
  local function get_item_type_from_tooltip()
    local num_lines = m_frame:NumLines()

    if num_lines < 2 then
      return BindType.None
    end

    local line = _G[ "RollForTooltipFrameTextLeft2" ]:GetText()

    if line == api.ITEM_BIND_ON_PICKUP or line == api.ITEM_SOULBOUND then
      return BindType.BindOnPickup
    elseif line == api.ITEM_BIND_ON_EQUIP then
      return BindType.BindOnEquip
    elseif line == api.ITEM_BIND_QUEST then
      return BindType.Quest
    else
      return BindType.None
    end
  end

  ---@return table<number, PlayerClass>|nil
  local function get_item_classes_from_tooltip()
    local num_lines = m_frame:NumLines()

    for i = 1, num_lines do
      local line = _G[ "RollForTooltipFrameTextLeft" .. i ]:GetText()

      for classes in string.gmatch( line, "Classes: (.+)" ) do
        local result = {}

        for class in string.gmatch( classes, "([^, ]+)" ) do
          table.insert( result, class )
        end

        return result
      end
    end
    return nil
  end

  local function get_slot_bind_type( slot )
    set_loot_slot( slot )

    return get_item_type_from_tooltip()
  end

  local function get_slot_classes( slot )
    set_loot_slot( slot )

    return get_item_classes_from_tooltip()
  end

  ---@type TooltipReader
  return {
    get_slot_bind_type = get_slot_bind_type,
    get_slot_classes = get_slot_classes
  }
end

m.TooltipReader = M
return M
