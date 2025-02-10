RollFor = RollFor or {}
local m = RollFor

if m.WinnersPopupContentTransformer then return end


local c = m.colorize_player_by_class

---@class WinnersPopupContentTransformer
---@field transform fun( data: RollingPopupData ): table

---@param config Config
---@param group_roster GroupRoster
function M.new( config, group_roster )

    ---@param data WinnersPopupData
    local function transform( data )
        local content = {}

        table.insert(content, {type = "text", value = "Winners"} )
        table.insert(content, {type = "empty_line"} )
        table.insert(content, {type = "winner_header"} )

        for _, item in pairs( data ) do
            local player = group_roster.find_player( item.player_name )
            local class = player and player.class or nil            
            local quality, texture = m.get_item_quality_and_texture( item.item_id )
            local itemLink = m.fetch_item_link(item.item_id, quality)
   
            table.insert(content, {type = "winner", player_name = item.player_name, player_class = class, link = itemLink, roll_type = item.roll_type, rolling_strategy = item.rolling_strategy})
        end

        table.insert(content, {type = "button", label = "Close", on_click = function() popup:Hide() end } )

        return content
    end

    return {
        transform = transform
      }
end

m.WinnersPopupContentTransformer = M
return M