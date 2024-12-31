RollFor = RollFor or {}
local m = RollFor

if m.RollingPopupContentTransformer then return end

---@diagnostic disable-next-line: deprecated
local getn = table.getn

---@type RT
local RT = m.Types.RollType
local RS = m.Types.RollingStrategy
-- local S = m.Types.RollingStatus
---@type LT
-- local LT = m.ItemUtils.LootType

local c = m.colorize_player_by_class
local blue = m.colors.blue
local red = m.colors.red
local r = m.roll_type_color
-- local grey = m.colors.grey
-- local hl = m.colors.hl
local article = m.article

local M = m.Module.new( "RollingPopupContentTransformer" )

local top_padding = 11

---@param on_click fun()
local function award_winner_button( on_click )
  return { type = "award_button", label = "Award", width = 90, on_click = on_click, padding = 6 }
end

---@alias RollingPopupButtonType
---| "Roll"
---| "AwardWinner"
---| "AwardOther"
---| "RaidRoll"
---| "InstaRaidRoll"
---| "RaidRollAgain"
---| "Close"
---| "FinishEarly"
---| "Cancel"

---@param content table
---@param message string
---@param padding number?
local function add_text( content, message, padding )
  table.insert( content, { type = "text", value = message, padding = padding } )
end

---@param content table
---@param height number
local function add_empty_line( content, height )
  table.insert( content, { type = "empty_line", height = height } )
end

-- ---@param result table
-- ---@param winner Winner
-- ---@param padding number
-- local function add_raid_roll_winner( result, winner, padding )
--   M.debug.add( "add_insta_raid_roll_winner" )
--   local player = c( winner.name, winner.class )
--   table.insert( result, { type = "text", value = string.format( "%s wins the %s.", player, blue( "raid-roll" ) ), padding = padding } )
-- end
--
-- ---@param result table
-- ---@param winner Winner
-- ---@param padding number
-- local function add_insta_raid_roll_winner( result, winner, padding )
--   M.debug.add( "add_insta_raid_roll_winner" )
--   local player = c( winner.name, winner.class )
--   table.insert( result, { type = "text", value = string.format( "%s wins the %s.", player, blue( "insta raid-roll" ) ), padding = padding } )
-- end
--
-- ---@param winner Winner
-- ---@param padding number?
-- local function sr_content( winner, padding )
--   M.debug.add( "sr_content" )
--   local player = c( winner.name, winner.class )
--   local soft_ressed = r( RT.MainSpec, "soft-ressed" )
--   return { type = "text", value = string.format( "%s %s this item.", player, soft_ressed ), padding = padding or top_padding }
-- end
--
-- ---@param result table
-- ---@param winner Winner
-- ---@param padding number
-- local function add_roll_winner( result, winner, strategy, padding )
--   M.debug.add( "add_roll_winner" )
--   local player = c( winner.name, winner.class )
--   local roll_type = winner.roll_type and r( winner.roll_type )
--   local roll = winner.winning_roll and blue( winner.winning_roll )
--
--   if roll then
--     table.insert( result,
--       { type = "text", value = string.format( "%s wins the %s roll with %s %s.", player, roll_type, article( winner.winning_roll ), roll ), padding = padding } )
--   elseif strategy == RS.SoftResRoll then
--     table.insert( result, sr_content( winner, padding ) )
--   else
--     table.insert( result, { type = "text", value = string.format( "%s %s win the roll.", player, red( "did not" ) ), padding = padding } )
--   end
-- end

---@class RollingPopupContentTransformer
---@field transform fun( data: RollingPopupPreviewData ): table

---@param config Config
---@diagnostic disable-next-line: unused-local
function M.new( config )
  -- local function close_button()
  --   M.debug.add( "close_button" )
  --   return { type = "button", label = "Close", width = 70, on_click = function() popup:hide() end }
  -- end
  --
  -- ---@param player_name string
  -- ---@param candidates ItemCandidate[]
  -- local function is_candidate( player_name, candidates )
  --   return m.table_contains_value( candidates, player_name, function( candidate ) return type( candidate ) == "table" and candidate.name end )
  -- end
  --
  -- ---@param item Item|MasterLootDistributableItem
  -- local function is_item_distributable( item )
  --   return item.type == LT.DroppedItem or item.type == LT.SoftRessedDroppedItem or item.type == LT.HardRessedDroppedItem
  -- end
  --
  -- ---@param result table
  -- ---@param on_click fun()
  -- local function add_bottom_award_winner_button( result, on_click )
  --   M.debug.add( "add_bottom_award_winner_button" )
  --
  --   table.insert( result, {
  --     type = "button",
  --     label = "Award winner",
  --     width = 130,
  --     on_click = on_click
  --   } )
  -- end
  --
  -- ---@param result table
  -- ---@param data RollTrackerData
  -- ---@param strategy RollingStrategyType
  -- local function roll_winner_content( result, data, strategy )
  --   M.debug.add( "roll_winner_content" )
  --   local last_award_button_visible = false
  --   local winner_count = getn( data.winners )
  --   local distributable_item = is_item_distributable( data.item )
  --
  --   for i, winner in ipairs( data.winners ) do
  --     local padding = last_award_button_visible and 8 or i == 1 and top_padding or (top_padding - 6)
  --
  --     add_roll_winner( result, winner, strategy, padding )
  --
  --     if winner_count > 1 and is_candidate( winner.name, data.ml_candidates ) and distributable_item then
  --       local item = data.item --[[@as MasterLootDistributableItem]]
  --       table.insert( result, award_winner_button( function() roll_controller.show_master_loot_confirmation( winner, item, strategy ) end ) )
  --       last_award_button_visible = true
  --     end
  --   end
  --
  --   if winner_count == 1 and is_candidate( data.winners[ 1 ].name, data.ml_candidates ) and distributable_item then
  --     local item = data.item --[[@as MasterLootDistributableItem]]
  --     add_bottom_award_winner_button( result, function() roll_controller.show_master_loot_confirmation( data.winners[ 1 ], item, strategy ) end )
  --   end
  --
  --   if strategy ~= RS.SoftResRoll then
  --     table.insert( result, { type = "button", label = "Raid roll", width = 90, on_click = function() raid_roll( data.item ) end } )
  --   end
  --
  --   table.insert( result, close_button() )
  --
  --   return result
  -- end
  --
  -- ---@param result table
  -- ---@param iterations RollIteration[]
  -- local function make_roll_content( result, iterations )
  --   for _, iteration in ipairs( iterations ) do
  --     if iteration.rolling_strategy == RS.SoftResRoll or iteration.rolling_strategy == RS.NormalRoll then
  --       add_rolls( result, iteration.rolls )
  --     elseif iteration.rolling_strategy == RS.TieRoll then
  --       table.insert( result, { type = "text", value = string.format( "There was a tie (%s):", blue( iteration.tied_roll ) ), padding = top_padding } )
  --       add_rolls( result, iteration.rolls )
  --     end
  --   end
  -- end
  --
  -- ---@param item Item
  -- ---@param count number
  -- local function make_item( item, count ) -- TODO: deprecate this
  --   return { type = "item_link_with_icon", link = item and item.link, texture = item and item.texture, count = count }
  -- end
  --
  -- ---@param data RollTrackerData
  -- ---@param current_iteration RollIteration
  -- local function raid_roll_winners( data, current_iteration )
  --   return data.status.type == S.Finished and current_iteration and current_iteration.rolling_strategy == RS.RaidRoll
  -- end
  --
  -- ---@param data RollTrackerData
  -- ---@param current_iteration RollIteration
  -- local function insta_raid_roll_winners( data, current_iteration )
  --   return data.status.type == S.Finished and current_iteration and current_iteration.rolling_strategy == RS.InstaRaidRoll
  -- end
  --
  -- ---@param data RollTrackerData
  -- local function roll_winners( data )
  --   if data.status.type ~= S.Finished or not data.winners then return false end
  --
  --   for _, winner in ipairs( data.winners ) do
  --     if winner.winning_roll then return true end
  --   end
  --
  --   return false
  -- end
  --
  -- ---@param current_iteration RollIteration
  -- local function softres_roll( current_iteration )
  --   return current_iteration and current_iteration.rolling_strategy == RS.SoftResRoll
  -- end
  --
  -- ---@param winners Winner[]
  -- local function there_were_no_rolls( winners )
  --   for _, winner in ipairs( winners ) do
  --     if winner.winning_roll then return false end
  --   end
  --
  --   return true
  -- end
  --
  -- ---@param data RollTrackerData
  -- ---@param current_iteration RollIteration
  -- local function softres_winners_with_no_rolls( data, current_iteration )
  --   return data.status.type == S.Finished and
  --       data.winners and
  --       getn( data.winners ) == data.item_count and
  --       there_were_no_rolls( data.winners ) and
  --       softres_roll( current_iteration ) or
  --       data.status.type == S.Preview and
  --       data.item.sr_players and
  --       getn( data.item.sr_players ) == data.item_count
  -- end
  --
  -- local function select_player_button()
  --   M.debug.add( "select_player_button" )
  --   return { type = "button", label = "Award...", width = 90, on_click = function() print( "TODO" ) end }
  -- end
  --
  -- ---@param data RollTrackerData
  -- local function roll_button( data ) -- TODO: deprecate
  --   M.debug.add( "roll_button" )
  --   return {
  --     type = "button",
  --     label = "Roll",
  --     width = 70,
  --     on_click = function()
  --       if not data.item_count then
  --         m.trace( "Item count is nil.", data )
  --       end
  --
  --       roll_item( data.item, data.item_count )
  --     end
  --   }
  -- end
  --
  -- ---@param padding number?
  -- ---@param color function?
  -- ---@diagnostic disable-next-line: unused-local, unused-function
  -- local function separator( padding, color )
  --   local col = color or grey
  --   return { type = "text", value = col( "-" ), padding = padding or 3 }
  -- end
  --
  -- ---@param result table
  -- ---@param winners Winner[]
  -- ---@param ml_candidates ItemCandidate[]
  -- ---@param item Item|MasterLootDistributableItem
  -- local function softres_winners_content( result, winners, ml_candidates, item )
  --   local strategy = RS.SoftResRoll
  --   local last_award_button_visible = false
  --   local winner_count = getn( winners )
  --   local distributable_item = is_item_distributable( item )
  --
  --   for i, winner in ipairs( winners ) do
  --     local padding = last_award_button_visible and 8 or i > 1 and 4 or nil
  --     table.insert( result, sr_content( winner, padding ) )
  --
  --     if winner_count > 1 and is_candidate( winner.name, ml_candidates ) and distributable_item then
  --       local dist_item = item --[[@as MasterLootDistributableItem]]
  --       table.insert( result, award_winner_button( function() roll_controller.show_master_loot_confirmation( winner, dist_item, strategy ) end ) )
  --       last_award_button_visible = true
  --     end
  --   end
  --
  --   if winner_count == 1 and is_candidate( winners[ 1 ].name, ml_candidates ) and distributable_item then
  --     local dist_item = item --[[@as MasterLootDistributableItem]]
  --     add_bottom_award_winner_button( result, function() roll_controller.show_master_loot_confirmation( winners[ 1 ], dist_item, strategy ) end )
  --   end
  --
  --   table.insert( result, close_button() )
  --   table.insert( result, select_player_button() )
  --
  --   return result
  -- end
  --
  -- ---@param result table
  -- ---@param data RollTrackerData
  -- ---@param strategy RollingStrategyType
  -- ---@param add_winner fun( result: table, winner: Winner, padding: number )
  -- ---@param roll_again fun( item: Item, item_count: number )
  -- local function raid_roll_content( result, data, strategy, add_winner, roll_again )
  --   local last_award_button_visible = false
  --   local winner_count = getn( data.winners )
  --   local distributable_item = is_item_distributable( data.item )
  --
  --   for i, winner in ipairs( data.winners ) do
  --     local padding = last_award_button_visible and 8 or i > 1 and 2 or 8
  --     add_winner( result, winner, padding )
  --
  --     if winner_count > 1 and is_candidate( winner.name, data.ml_candidates ) and distributable_item then
  --       local item = data.item --[[@as MasterLootDistributableItem]]
  --       table.insert( result, award_winner_button( function() roll_controller.show_master_loot_confirmation( winner, item, strategy ) end ) )
  --       last_award_button_visible = true
  --     end
  --   end
  --
  --   if strategy == RS.RaidRoll and not config.auto_raid_roll() then
  --     table.insert( result,
  --       { type = "info", value = string.format( "Use %s to enable auto raid-roll.", blue( "/rf config auto-rr" ) ), anchor = "RollForRollingFrame" } )
  --   end
  --
  --   if winner_count == 1 and is_candidate( data.winners[ 1 ].name, data.ml_candidates ) and distributable_item then
  --     local item = data.item --[[@as MasterLootDistributableItem]]
  --     add_bottom_award_winner_button( result, function() roll_controller.show_master_loot_confirmation( data.winners[ 1 ], item, strategy ) end )
  --   end
  --
  --   if config.raid_roll_again() then
  --     table.insert( result, {
  --       type = "button",
  --       label = "Raid roll again",
  --       width = 130,
  --       on_click = function()
  --         if not data.item_count then
  --           m.trace( "Item count is nil.", data )
  --         end
  --
  --         roll_again( data.item, data.item_count )
  --       end
  --     } )
  --   end
  --
  --   table.insert( result, close_button() )
  --
  --   return result
  -- end
  --
  -- local function finish_rolling_early_button()
  --   M.debug.add( "finish_rolling_early_button" )
  --   return { type = "button", label = "Finish early", width = 100, on_click = roll_controller.finish_rolling_early }
  -- end
  --
  -- local function cancel_rolling_button()
  --   M.debug.add( "cancel_rolling_button" )
  --   return { type = "button", label = "Cancel", width = 100, on_click = roll_controller.cancel_rolling }
  -- end
  --
  -- local function seconds_left_content( result, data, roll_count )
  --   M.debug.add( "seconds_left_content" )
  --
  --   local seconds = data.status.seconds_left
  --   table.insert( result,
  --     { type = "text", value = string.format( "Rolling ends in %s second%s.", seconds, seconds == 1 and "" or "s" ), padding = top_padding } )
  --
  --   if roll_count == 0 and config.auto_raid_roll() then
  --     table.insert( result, { type = "text", value = string.format( "Auto %s is %s.", blue( "raid-roll" ), m.msg.enabled ) } )
  --   end
  --
  --   table.insert( result, finish_rolling_early_button() )
  --   table.insert( result, cancel_rolling_button() )
  --   return result
  -- end
  --
  -- ---@param result table
  -- ---@param data RollTrackerData
  -- local function preview_no_roll_content( result, data )
  --   M.debug.add( "preview_no_roll_content" )
  --
  --   if data.item_count and data.item_count > 1 then
  --     table.insert( result, { type = "text", value = string.format( "%s top rolls win.", hl( data.item_count ) ), padding = top_padding } )
  --   end
  --
  --   table.insert( result, roll_button( data ) )
  --   table.insert( result, { type = "button", label = "Insta RR", width = 80, on_click = function() insta_raid_roll( data.item, data.item_count ) end } )
  --   table.insert( result, select_player_button() )
  --
  --   return result
  -- end
  --
  -- ---@param result table
  -- ---@param data RollTrackerData
  -- local function preview_with_rolls_content( result, data )
  --   table.insert( result, roll_button( data ) )
  --   table.insert( result, select_player_button() )
  --
  --   return result
  -- end
  --
  -- local function rolling_canceled_content( result )
  --   M.debug.add( "rolling_canceled_content" )
  --   table.insert( result, { type = "text", value = "Rolling has been canceled.", padding = top_padding } )
  --   table.insert( result, close_button() )
  --
  --   return result
  -- end
  --
  -- local function no_one_rolled_content( result, data )
  --   M.debug.add( "no_one_rolled_content" )
  --   table.insert( result, { type = "text", value = "Rolling has finished. No one rolled.", padding = top_padding } )
  --   table.insert( result, { type = "button", label = "Raid roll", width = 90, on_click = function() raid_roll( data.item ) end } )
  --   table.insert( result, close_button() )
  --
  --   return result
  -- end
  --
  -- local function waiting_for_remaining_rolls_content( result )
  --   M.debug.add( "waiting_for_remaining_rolls_content" )
  --   table.insert( result, { type = "text", value = "Waiting for remaining rolls...", padding = top_padding } )
  --   table.insert( result, finish_rolling_early_button() )
  --   table.insert( result, cancel_rolling_button() )
  --
  --   return result
  -- end
  --
  -- local function hard_ressed_item_content( result )
  --   M.debug.add( "hard_ressed_item_content" )
  --   table.insert( result, { type = "text", value = string.format( "This item is %s.", red( "hard-ressed" ) ), padding = top_padding } )
  --   table.insert( result, select_player_button() )
  --   -- table.insert( result, free_roll_button( data ) )
  --   return result
  -- end
  --
  -- ---@param data RollTrackerData
  -- ---@param current_iteration RollIteration
  -- local function generate_content( data, current_iteration )
  --   local result     = {}
  --   local roll_count = current_iteration and current_iteration.rolls and getn( current_iteration.rolls ) or 0
  --   local strategy   = current_iteration and current_iteration.rolling_strategy
  --
  --   table.insert( result, make_item( data.item, data.item_count ) )
  --
  --   local preview = data.status.type == S.Preview
  --
  --   if softres_winners_with_no_rolls( data, current_iteration ) then
  --     if preview then
  --       local winners = data.status.winners
  --       -- TODO: winners are RollingPlayers. Deal this this properly.
  --       ---@diagnostic disable-next-line: param-type-mismatch
  --       return softres_winners_content( result, winners, data.status.ml_candidates, data.item )
  --     else
  --       local winners = data.winners
  --       return softres_winners_content( result, winners, data.ml_candidates, data.item )
  --     end
  --   end
  --
  --   make_roll_content( result, data.iterations )
  --
  --   if preview and roll_count == 0 then return preview_no_roll_content( result, data ) end
  --   if preview then return preview_with_rolls_content( result, data ) end
  --
  --   if data.status.type == S.TieFound then
  --     M.debug.add( "tie_found" )
  --     table.insert( result, { type = "empty_line", height = 5 } )
  --     return result
  --   end
  --
  --   if data.status.type == S.InProgress and current_iteration.rolling_strategy == RS.RaidRoll then
  --     M.debug.add( "raid_rolling" )
  --     table.insert( result, { type = "text", value = "Raid rolling...", padding = 8 } )
  --     table.insert( result, { type = "empty_line", height = 5 } )
  --     return result
  --   end
  --
  --   if data.status.type == S.InProgress and current_iteration.rolling_strategy == RS.InstaRaidRoll then
  --     M.debug.add( "insta_raid_rolling" )
  --     table.insert( result, { type = "text", value = "Insta raid rolling...", padding = 8 } )
  --     return result
  --   end
  --
  --   if raid_roll_winners( data, current_iteration ) then
  --     return raid_roll_content( result, data, RS.RaidRoll, add_raid_roll_winner, raid_roll )
  --   end
  --
  --   if insta_raid_roll_winners( data, current_iteration ) then
  --     return raid_roll_content( result, data, RS.InstaRaidRoll, add_insta_raid_roll_winner, insta_raid_roll )
  --   end
  --
  --   if data.status.type == S.Canceled then
  --     return rolling_canceled_content( result )
  --   end
  --
  --   if data.status.type == S.InProgress and data.status.seconds_left then
  --     return seconds_left_content( result, data, roll_count )
  --   end
  --
  --   if roll_winners( data ) then
  --     return roll_winner_content( result, data, strategy )
  --   end
  --
  --   if data.status.type == S.Finished and (not data.winners or getn( data.winners ) == 0) then
  --     return no_one_rolled_content( result, data )
  --   end
  --
  --   if data.status.type == S.Waiting then
  --     return waiting_for_remaining_rolls_content( result )
  --   end
  --
  --   if data.item.type == LT.HardRessedItem or data.item.type == LT.HardRessedDroppedItem then
  --     return hard_ressed_item_content( result )
  --   end
  --
  --   M.debug.add( "Uncaught content." )
  --   return result
  -- end
  --
  -- local function refresh()
  --   local data, current_iteration = roll_tracker.get()
  --   popup:refresh( generate_content( data, current_iteration ) )
  -- end
  --
  -- local function show_and_refresh()
  --   local data, current_iteration = roll_tracker.get()
  --
  --   if not data or not data.status or not data.item then return end
  --
  --   -- TODO: This entire logic needs to sit in the controller.
  --   local slot = loot_list.get_slot( data.item.id )
  --
  --   if slot and data.status.type == S.Finished and current_iteration and (current_iteration.rolling_strategy == RS.RaidRoll or current_iteration.rolling_strategy == RS.InstaRaidRoll) then
  --     local winners = data.winners
  --     local winner_count = getn( winners )
  --
  --     -- TODO: Think how to award multiple players.
  --     if winner_count == 1 then
  --       local winner = winners[ 1 ]
  --
  --       if winner.is_on_master_loot_candidate_list then
  --         popup:hide()
  --
  --         if data.item.type == LT.DroppedItem or data.item.type == LT.SoftRessedDroppedItem then
  --           local item = assert( data.item --[[@as DroppedItem|SoftRessedDroppedItem]] )
  --           roll_controller.show_master_loot_confirmation( winner, item, current_iteration.rolling_strategy )
  --         else
  --           m.trace( string.format( "Item was of %s type.", data and data.item and data.item.type or "nil" ), data )
  --         end
  --
  --         return
  --       end
  --     end
  --   end
  --
  --   popup:show()
  --   popup:refresh( generate_content( data, current_iteration ) )
  -- end
  --
  -- local function border_color( data )
  --   if not data then return end
  --
  --   local color = data.color
  --   popup:border_color( color.r, color.g, color.b, color.a )
  --   -- popup:border_color( 0, 0, 0, 1 )
  -- end
  --
  -- local function award_aborted()
  --   M.debug.add( "award_aborted" )
  --   local data, current_iteration = roll_tracker.get()
  --
  --   if not data or not data.status or not data.item or not current_iteration then
  --     return
  --   end
  --
  --   popup:show()
  --   popup:refresh( generate_content( data, current_iteration ) )
  -- end
  --
  -- local function loot_opened()
  --   local data = roll_tracker.get()
  --   if not data or not data.status or not data.item then return end
  --
  --   local slot = loot_list.get_slot( data.item.id )
  --   if not slot then return end
  --
  --   show_and_refresh()
  -- end
  --
  -- local function loot_closed()
  --   local data = roll_tracker.get()
  --   if not data or not data.status then return end
  --
  --   refresh()
  -- end

  -- roll_controller.subscribe( "preview", show_and_refresh )
  -- roll_controller.subscribe( "rolling_started", show_and_refresh )
  -- roll_controller.subscribe( "tick", refresh )
  -- roll_controller.subscribe( "winners_found", show_and_refresh )
  -- roll_controller.subscribe( "finish", show_and_refresh )
  -- roll_controller.subscribe( "roll", refresh )
  -- roll_controller.subscribe( "rolling_canceled", refresh )
  -- roll_controller.subscribe( "waiting_for_rolls", refresh )
  -- roll_controller.subscribe( "tie", show_and_refresh )
  -- roll_controller.subscribe( "tie_start", refresh )
  -- roll_controller.subscribe( "TemporaryHack", award_aborted )
  -- -- roll_controller.subscribe( "award_aborted", award_aborted )
  -- roll_controller.subscribe( "not_all_items_awarded", award_aborted )
  -- roll_controller.subscribe( "loot_opened", loot_opened )
  -- roll_controller.subscribe( "loot_closed", loot_closed )

  ---@param content table
  ---@param item_link ItemLink
  ---@param item_tooltip_link TooltipItemLink
  ---@param item_texture ItemTexture
  ---@param item_count number
  local function add_item( content, item_link, item_tooltip_link, item_texture, item_count )
    table.insert( content, {
      type = "item_link_with_icon",
      link = item_link,
      tooltip_link = item_tooltip_link,
      texture = item_texture,
      count = item_count
    } )
  end

  ---@param content table
  local function add_hr_info( content )
    table.insert( content, { type = "text", value = string.format( "This item is %s.", red( "hard-ressed" ) ), padding = top_padding } )
  end

  ---@param result table
  ---@param rolls RollData[]
  local function add_rolls( result, rolls )
    M.debug.add( "rolls_content" )

    for i = 1, getn( rolls ) do
      local roll = rolls[ i ]

      table.insert( result, {
        type = "roll",
        roll_type = roll.roll_type,
        player_name = roll.player_name,
        player_class = roll.player_class,
        roll = roll.roll,
        padding = i == 1 and top_padding or nil
      } )
    end
  end

  ---@param content table
  ---@param player string
  ---@param padding number
  local function add_raid_roll_winner_new( content, player, padding )
    M.debug.add( "add_insta_raid_roll_winner" )
    table.insert( content, { type = "text", value = string.format( "%s wins the %s.", player, blue( "raid-roll" ) ), padding = padding } )
  end

  ---@param content table
  ---@param player string
  ---@param roll_type RollType
  ---@param winning_roll number?
  ---@param padding number
  local function add_roll_winner_new( content, player, roll_type, winning_roll, strategy, padding )
    M.debug.add( "add_roll_winner" )
    local roll = winning_roll and blue( winning_roll )

    if roll then
      table.insert( content,
        { type = "text", value = string.format( "%s wins the %s roll with %s %s.", player, r( roll_type ), article( winning_roll ), roll ), padding = padding } )
    elseif strategy == RS.SoftResRoll then
      local soft_ressed = r( RT.SoftRes, "soft-ressed" )
      table.insert( content, { type = "text", value = string.format( "%s %s this item.", player, soft_ressed ), padding = padding or top_padding } )
    else
      table.insert( content, { type = "text", value = string.format( "%s %s win the roll.", player, red( "did not" ) ), padding = padding } )
    end
  end

  ---@param content table
  ---@param winners WinnerWithAwardCallback[]
  ---@param strategy_type RollingStrategyType
  local function add_winners( content, winners, strategy_type )
    local was_there_award_button = false

    for i, winner in ipairs( winners ) do
      local player = c( winner.name, winner.class )
      local padding = i == 1 and 11 or was_there_award_button and 8 or 2

      if strategy_type == RS.InstaRaidRoll or strategy_type == RS.RaidRoll then
        add_raid_roll_winner_new( content, player, padding )
      else
        add_roll_winner_new( content, player, winner.roll_type, winner.roll, strategy_type, padding )
      end

      if winner.award_callback then
        table.insert( content, award_winner_button( winner.award_callback ) )
        was_there_award_button = true
      else
        was_there_award_button = false
      end
    end
  end

  ---@param content table
  ---@param buttons RollingPopupButtonWithCallback[]
  local function add_buttons( content, buttons )
    local function get_props( type )
      if type == "Roll" then
        return "Roll", 70
      elseif type == "AwardWinner" then
        return "Award", 80
      elseif type == "AwardOther" then
        return "Award...", 90
      elseif type == "RaidRoll" then
        return "Raid roll", 90
      elseif type == "InstaRaidRoll" then
        return "Raid roll", 90
      elseif type == "RaidRollAgain" then
        return "Raid roll again", 130
      elseif type == "Close" then
        return "Close", 70
      elseif type == "FinishEarly" then
        return "Finish early", 100
      elseif type == "Cancel" then
        return "Cancel", 90
      else
        error( string.format( "Unsupported type: %s", type or "nil" ) )
      end
    end

    for _, button in ipairs( buttons ) do
      local label, width = get_props( button.type )

      if not button.should_display_callback or button.should_display_callback() then
        table.insert( content, { type = "button", label = label, width = width, on_click = button.callback } )
      end
    end
  end

  ---@class RollingPopupPreviewData
  ---@field item_link ItemLink
  ---@field item_tooltip_link TooltipItemLink
  ---@field item_texture ItemTexture
  ---@field item_count number
  ---@field hard_ressed boolean
  ---@field winners WinnerWithAwardCallback[]
  ---@field rolls RollData[]
  ---@field strategy_type RollingStrategyType
  ---@field buttons RollingPopupButtonWithCallback[]
  ---@field type "Preview"

  ---@param data RollingPopupPreviewData
  local function preview_content( data )
    local content = {}

    add_item( content, data.item_link, data.item_tooltip_link, data.item_texture, data.item_count )

    if data.hard_ressed then
      add_hr_info( content )
    else
      add_rolls( content, data.rolls )
      add_winners( content, data.winners, data.strategy_type )
    end

    add_buttons( content, data.buttons )

    return content
  end

  ---@class RollingPopupRaidRollData
  ---@field item_link ItemLink
  ---@field item_tooltip_link TooltipItemLink
  ---@field item_texture ItemTexture
  ---@field item_count number
  ---@field winners WinnerWithAwardCallback[]
  ---@field buttons RollingPopupButtonWithCallback[]
  ---@field type "RaidRoll"

  ---@param data RollingPopupRaidRollData
  local function insta_raid_roll_content( data )
    local content = {}

    add_item( content, data.item_link, data.item_tooltip_link, data.item_texture, data.item_count )
    add_winners( content, data.winners, "InstaRaidRoll" )
    add_buttons( content, data.buttons )

    return content
  end

  ---@param content table
  ---@param seconds_left number
  local function seconds_left_content( content, seconds_left )
    add_text( content, string.format( "Rolling ends in %s second%s.", seconds_left, seconds_left == 1 and "" or "s" ), top_padding )
  end

  ---@class RollingPopupRollData
  ---@field item_link ItemLink
  ---@field item_tooltip_link TooltipItemLink
  ---@field item_texture ItemTexture
  ---@field item_count number
  ---@field seconds_left number?
  ---@field rolls RollData[]
  ---@field winners WinnerWithAwardCallback[]
  ---@field buttons RollingPopupButtonWithCallback[]
  ---@field strategy_type RollingStrategyType
  ---@field waiting_for_rolls boolean?
  ---@field type "Roll"

  ---@param data RollingPopupRollData
  local function roll_content( data )
    local content = {}

    add_item( content, data.item_link, data.item_tooltip_link, data.item_texture, data.item_count )

    if not data.seconds_left and getn( data.rolls ) == 0 then
      add_text( content, "Rolling finished. No one rolled.", top_padding )
    else
      add_rolls( content, data.rolls )
    end

    if data.seconds_left then seconds_left_content( content, data.seconds_left ) end

    add_winners( content, data.winners, data.strategy_type )

    if data.waiting_for_rolls then
      add_text( content, "Waiting for remaining rolls...", top_padding )
    end

    add_buttons( content, data.buttons )

    return content
  end

  ---@class RollingPopupRollingCanceledData
  ---@field item_link ItemLink
  ---@field item_tooltip_link TooltipItemLink
  ---@field item_texture ItemTexture
  ---@field item_count number
  ---@field buttons RollingPopupButtonWithCallback[]
  ---@field type "RollingCanceled"

  ---@param data RollingPopupRollingCanceledData
  local function rolling_canceled_content( data )
    local content = {}

    add_item( content, data.item_link, data.item_tooltip_link, data.item_texture, data.item_count )
    add_text( content, "Rolling was canceled.", top_padding )
    add_buttons( content, data.buttons )

    return content
  end

  ---@class RollingPopupRaidRollingData
  ---@field item_link ItemLink
  ---@field item_tooltip_link TooltipItemLink
  ---@field item_texture ItemTexture
  ---@field item_count number
  ---@field type "RaidRolling"

  ---@param data RollingPopupRaidRollingData
  local function raid_rolling_content( data )
    local content = {}

    add_item( content, data.item_link, data.item_tooltip_link, data.item_texture, data.item_count )
    add_text( content, "Raid rolling...", top_padding )
    add_empty_line( content, 5 )

    return content
  end

  ---@class TieIteration
  ---@field tied_roll number
  ---@field rolls RollData[]

  ---@class RollingPopupTieData
  ---@field roll_data RollingPopupRollData
  ---@field tie_iterations TieIteration[]
  ---@field type "Tie"

  ---@param data RollingPopupTieData
  local function tie_content( data )
    local content = {}

    add_item( content, data.roll_data.item_link, data.roll_data.item_tooltip_link, data.roll_data.item_texture, data.roll_data.item_count )
    add_rolls( content, data.roll_data.rolls )

    for _, iteration in ipairs( data.tie_iterations ) do
      add_text( content, string.format( "There was a tie (%s):", blue( iteration.tied_roll ) ), top_padding )
      add_rolls( content, iteration.rolls )
    end

    if data.roll_data.waiting_for_rolls then
      add_text( content, "Waiting for remaining rolls...", top_padding )
    elseif getn( data.roll_data.winners ) == 0 then
      add_empty_line( content, 5 )
    end

    add_buttons( content, data.roll_data.buttons )

    return content
  end

  ---@param data RollingPopupPreviewData|RollingPopupRaidRollData|RollingPopupRollData|RollingPopupRollingCanceledData|RollingPopupRaidRollingData|RollingPopupTieData
  local function transform( data )
    if data.type == "Preview" then
      return preview_content( data )
    end

    if data.type == "RaidRoll" then
      return insta_raid_roll_content( data )
    end

    if data.type == "Roll" then
      return roll_content( data )
    end

    if data.type == "RollingCanceled" then
      return rolling_canceled_content( data )
    end

    if data.type == "RaidRolling" then
      return raid_rolling_content( data )
    end

    if data.type == "Tie" then
      return tie_content( data )
    end

    error( string.format( "Unsupported type: %s", data.type or "nil" ) )
  end

  return {
    transform = transform
  }
end

m.RollingPopupContentTransformer = M
return M
