RollFor = RollFor or {}
local m = RollFor

if m.RollController then return end

local info = m.pretty_print
local M = m.Module.new( "RollController", 80 )
local S = m.Types.RollingStatus
local RS = m.Types.RollingStrategy
local LAE = m.Types.LootAwardError
local IU = m.ItemUtils ---@type ItemUtils
local getn = table.getn

---@class RollControllerFacade
---@field roll_was_ignored fun( player_name: string, player_class: string?, roll_type: RollType, roll: number, reason: string )
---@field roll_was_accepted fun( player_name: string, player_class: string, roll_type: RollType, roll: number )
---@field tick fun( seconds_left: number )
---@field winners_found fun( item: Item, item_count: number, winners: Winner[], strategy: RollingStrategyType )
---@field finish fun()

---@alias RollControllerPreviewFn fun( item: Item, count: number, seconds: number?, message: string? )

---@class RollController
---@field preview RollControllerPreviewFn
---@field start fun( rolling_strategy: RollingStrategyType, item: Item, count: number, seconds: number?, info: string? )
---@field winners_found fun( item: Item, item_count: number, winners: Winner[], strategy: RollingStrategyType )
---@field finish fun()
---@field tick fun( seconds_left: number )
---@field add fun( player_name: string, player_class: string, roll_type: RollType, roll: number )
---@field add_ignored fun( player_name: string, player_class: string?, roll_type: RollType, roll: number, reason: string )
---@field rolling_canceled fun()
---@field subscribe fun( event_type: string, callback: fun( data: any ) )
---@field there_was_a_tie fun( tied_players: RollingPlayer[], item: Item, item_count: number, roll_type: RollType, roll: number, rerolling: boolean?, top_roll: boolean? )
---@field tie_start fun()
---@field waiting_for_rolls fun()
---@field award_aborted fun( item: Item )
---@field loot_awarded fun( item_id: number, item_link: string, player_name: string, player_class: PlayerClass? )
---@field loot_closed fun()
---@field loot_opened fun()
---@field player_already_has_unique_item fun()
---@field player_has_full_bags fun()
---@field player_not_found fun()
---@field cant_assign_item_to_that_player fun()
---@field rolling_popup_closed fun()
---@field loot_award_popup_closed fun()
---@field loot_list_item_selected fun()
---@field loot_list_item_deselected fun()
---@field finish_rolling_early fun()
---@field cancel_rolling fun()
---@field rolling_started fun( rolling_strategy: RollingStrategyType, item: Item, count: number, seconds: number?, message: string?, rolling_players: RollingPlayer[]? )
---@field award_confirmed fun( player: ItemCandidate|Winner, item: MasterLootDistributableItem )

---@param roll_tracker RollTracker
---@param player_info PlayerInfo
---@param ml_candidates MasterLootCandidates
---@param softres GroupAwareSoftRes
---@param loot_list SoftResLootList
---@param rolling_popup RollingPopup
---@param loot_award_popup LootAwardPopup
---@param player_selection_frame MasterLootCandidateSelectionFrame
function M.new(
    roll_tracker,
    ---@diagnostic disable-next-line: unused-local
    player_info,
    ml_candidates,
    softres,
    loot_list,
    config,
    rolling_popup,
    loot_award_popup,
    player_selection_frame
)
  local callbacks = {}
  local ml_confirmation_data = nil ---@type MasterLootConfirmationData?
  local rolling_popup_item = nil ---@type Item?
  local rolling_popup_data = {} ---@type RollingPopupData[]

  local function notify_subscribers( event_type, data )
    M.debug.add( event_type )

    for _, callback in ipairs( callbacks[ event_type ] or {} ) do
      callback( data )
    end
  end

  ---@class RgbaColor
  ---@field r number
  ---@field g number
  ---@field b number
  ---@field a number

  ---@return RgbaColor
  local function get_color( quality )
    local color = m.api.ITEM_QUALITY_COLORS[ quality ] or { r = 0, g = 0, b = 0, a = 1 }

    local multiplier = 0.5
    local alpha = 0.6
    local c = { r = color.r * multiplier, g = color.g * multiplier, b = color.b * multiplier, a = alpha }

    return c
  end

  ---@class AwardConfirmedData
  ---@field player ItemCandidate|Winner
  ---@field item MasterLootDistributableItem

  ---@param player ItemCandidate|Winner
  ---@param item MasterLootDistributableItem
  local function award_confirmed( player, item )
    notify_subscribers( "award_confirmed", { player = player, item = item } )
  end

  ---@class WinnerWithAwardCallback
  ---@field name string
  ---@field class PlayerClass
  ---@field roll_type RollType
  ---@field roll number?
  ---@field award_callback fun()?

  ---@alias BooleanCallback fun(): boolean

  ---@class RollingPopupButtonWithCallback
  ---@field type RollingPopupButtonType
  ---@field callback fun()
  ---@field should_display_callback BooleanCallback?

  ---@param type RollingPopupButtonType
  ---@param callback fun()
  ---@param should_display_callback BooleanCallback?
  local function button( type, callback, should_display_callback )
    return { type = type, callback = callback, should_display_callback = should_display_callback } ---@type RollingPopupButtonWithCallback
  end

  ---@class RollControllerStartData
  ---@field strategy_type RollingStrategyType
  ---@field item Item
  ---@field item_count number
  ---@field message string?
  ---@field seconds number?

  ---@param item Item
  ---@param item_count number
  ---@param seconds number?
  ---@param buttons RollingPopupButtonWithCallback[]
  ---@param rolls RollData[]
  ---@param winners WinnerWithAwardCallback[]
  ---@param strategy_type RollingStrategyType
  ---@param waiting_for_rolls boolean?
  local function roll_content( item, item_count, seconds, buttons, rolls, winners, strategy_type, waiting_for_rolls )
    ---@type RollingPopupRollData
    rolling_popup_data[ item.id ] = {
      item_link = item.link,
      item_tooltip_link = IU.get_tooltip_link( item.link ),
      item_texture = item.texture,
      item_count = item_count,
      seconds_left = seconds,
      rolls = rolls,
      winners = winners,
      buttons = buttons,
      strategy_type = strategy_type,
      waiting_for_rolls = waiting_for_rolls,
      type = "Roll"
    }

    rolling_popup:show()
    rolling_popup:refresh( rolling_popup_data[ item.id ] )
  end

  local function cancel_rolling()
    notify_subscribers( "cancel_rolling" )
  end

  local function finish_rolling_early()
    notify_subscribers( "finish_rolling_early" )
  end

  ---@return RollingPopupButtonWithCallback[]
  local function roll_in_progress_buttons()
    local buttons = {}

    table.insert( buttons, button( "FinishEarly", function() finish_rolling_early() end ) )
    table.insert( buttons, button( "Cancel", function() cancel_rolling() end ) )

    return buttons
  end

  ---@param item Item
  ---@param item_count number
  local function raid_rolling_content( item, item_count )
    ---@type RollingPopupRaidRollingData
    rolling_popup_data[ item.id ] = {
      item_link = item.link,
      item_tooltip_link = IU.get_tooltip_link( item.link ),
      item_texture = item.texture,
      item_count = item_count,
      type = "RaidRolling"
    }

    rolling_popup:show()
    rolling_popup:refresh( rolling_popup_data[ item.id ] )
  end

  ---@param strategy_type RollingStrategyType
  ---@param item Item
  ---@param item_count number
  ---@param seconds number?
  ---@param message string?
  local function start( strategy_type, item, item_count, seconds, message )
    if ml_confirmation_data then
      info( "Item award confirmation is in progress. Can't start rolling now." )
      return
    end

    notify_subscribers( "start", { strategy_type = strategy_type, item = item, item_count = item_count, message = message, seconds = seconds } )

    if strategy_type == "RaidRoll" then
      raid_rolling_content( item, item_count )
    end
  end

  ---@param buttons RollingPopupButtonWithCallback[]
  ---@param status RollingStatus
  local function add_close_button( buttons, status ) ---@diagnostic disable-line: unused-local -- TODO: leaving for now. Maybe we'll need it.
    table.insert( buttons, button( "Close", function()
      M.debug.add( "on_close" )

      local item_id = rolling_popup_item and rolling_popup_item.id

      if rolling_popup_item then
        rolling_popup_data[ rolling_popup_item.id ] = nil
        rolling_popup_item = nil
      end

      rolling_popup.hide()
      notify_subscribers( "LootFrameDeselect", { item_id = item_id } )
    end ) )
  end

  local function award_aborted( item )
    if ml_confirmation_data then
      ml_confirmation_data = nil
      loot_award_popup.hide()
    end

    notify_subscribers( "award_aborted", { item = item } )

    if rolling_popup_data[ item.id ] then
      rolling_popup:show()
      rolling_popup:refresh( rolling_popup_data[ item.id ] )
      return
    end
  end

  ---@class MasterLootConfirmationData
  ---@field item MasterLootDistributableItem
  ---@field winners Winner[]
  ---@field receiver ItemCandidate
  ---@field strategy_type RollingStrategyType
  ---@field confirm_fn fun()
  ---@field abort_fn fun()
  ---@field error LootAwardError?

  ---@param player ItemCandidate|Winner
  ---@param item MasterLootDistributableItem
  ---@param strategy_type RollingStrategyType
  local function show_master_loot_confirmation( player, item, strategy_type )
    local candidate = ml_candidates.find( player.name )

    if not candidate then
      M.debug.add( "Candidate not found: %s", player.name )
      return
    end

    local winners = roll_tracker.get().winners

    ml_confirmation_data = {
      item = item,
      winners = winners,
      receiver = candidate,
      strategy_type = strategy_type,
      confirm_fn = function() award_confirmed( candidate, item ) end,
      abort_fn = function() award_aborted( item ) end
    }

    rolling_popup.hide()
    loot_award_popup.show( ml_confirmation_data )
  end

  ---@return boolean
  local function should_display_callback()
    return rolling_popup_item and loot_list.is_looting() and loot_list.get_slot( rolling_popup_item.id ) and true or false
  end

  ---@param dropped_item MasterLootDistributableItem?
  ---@param buttons RollingPopupButtonWithCallback[]
  ---@param candidates ItemCandidate[]
  local function add_award_other_button( dropped_item, buttons, candidates )
    if not dropped_item then return end

    table.insert( buttons,
      button( "AwardOther", function()
        ---@type MasterLootCandidate[]
        local players = m.map( candidates,
          ---@param candidate ItemCandidate
          function( candidate )
            ---@type MasterLootCandidate
            return {
              name = candidate.name,
              class = candidate.class,
              is_winner = false,
              confirm_fn = function()
                player_selection_frame.hide()
                show_master_loot_confirmation( candidate, dropped_item, RS.NormalRoll ) -- TODO: why is this NormalRoll here?
              end
            }
          end )

        player_selection_frame.show( players )
        local frame = player_selection_frame.get_frame()
        frame:ClearAllPoints()
        frame:SetPoint( "TOP", rolling_popup.get_frame(), "BOTTOM", 0, -5 )
      end, should_display_callback ) )
  end

  ---@param buttons RollingPopupButtonWithCallback[]
  ---@param item Item
  ---@param item_count number
  ---@param dropped_item MasterLootDistributableItem?
  ---@param candidate_count number
  ---@param candidates ItemCandidate[]
  local function preview_non_soft_ressed_items( buttons, item, item_count, dropped_item, candidate_count, candidates )
    table.insert( buttons, button( "Roll", function() start( RS.NormalRoll, item, item_count, config.default_rolling_time_seconds() ) end ) )
    table.insert( buttons, button( "InstaRaidRoll", function() start( RS.InstaRaidRoll, item, item_count ) end ) )

    if candidate_count > 0 then add_award_other_button( dropped_item, buttons, candidates ) end

    add_close_button( buttons, S.Preview )

    rolling_popup_data[ item.id ] = {
      item_link = item.link,
      item_tooltip_link = IU.get_tooltip_link( item.link ),
      item_texture = item.texture,
      item_count = item_count,
      hard_ressed = false,
      winners = {},
      rolls = {},
      strategy_type = RS.NormalRoll,
      buttons = buttons,
      type = "Preview"
    }

    rolling_popup:show()
    rolling_popup:refresh( rolling_popup_data[ item.id ] )
  end

  ---@param buttons RollingPopupButtonWithCallback[]
  ---@param item Item
  ---@param item_count number
  ---@param dropped_item MasterLootDistributableItem?
  ---@param candidate_count number
  ---@param candidates ItemCandidate[]
  local function preview_hard_ressed_item( buttons, item, item_count, dropped_item, candidate_count, candidates )
    table.insert( buttons, button( "Roll", function() start( RS.SoftResRoll, item, item_count, config.default_rolling_time_seconds() ) end ) )

    if candidate_count > 0 then add_award_other_button( dropped_item, buttons, candidates ) end

    add_close_button( buttons, S.Preview )

    rolling_popup_data[ item.id ] = {
      item_link = item.link,
      item_tooltip_link = IU.get_tooltip_link( item.link ),
      item_texture = item.texture,
      item_count = item_count,
      hard_ressed = true,
      winners = {},
      rolls = {},
      strategy_type = RS.SoftResRoll, -- It don't matter here. Listening to The Miseducation of L.H. :P
      buttons = buttons,
      type = "Preview"
    }

    rolling_popup:show()
    rolling_popup:refresh( rolling_popup_data[ item.id ] )
  end

  ---@param soft_ressers RollingPlayer[]
  ---@param item Item
  ---@param item_count number
  ---@param dropped_item MasterLootDistributableItem?
  ---@param buttons RollingPopupButtonWithCallback[]
  ---@param candidate_count number
  ---@param candidates ItemCandidate[]
  local function preview_sr_items_equal_to_item_count( soft_ressers, item, item_count, dropped_item, buttons, candidate_count, candidates )
    ---@type WinnerWithAwardCallback[]
    local winners = m.map( soft_ressers,
      ---@param player RollingPlayer
      function( player )
        local candidate = ml_candidates.find( player.name )
        local award_callback = candidate and dropped_item and function()
          show_master_loot_confirmation( candidate, dropped_item, RS.SoftResRoll )
        end

        ---@type WinnerWithAwardCallback
        return { name = player.name, class = player.class, roll_type = "SoftRes", award_callback = award_callback }
      end
    )

    if getn( winners ) == 1 and winners[ 1 ].award_callback then
      table.insert( buttons, button( "AwardWinner", winners[ 1 ].award_callback, should_display_callback ) )
      winners[ 1 ].award_callback = nil
    end

    if candidate_count > 0 then add_award_other_button( dropped_item, buttons, candidates ) end

    add_close_button( buttons, S.Preview )

    rolling_popup_data[ item.id ] = {
      item_link = item.link,
      item_tooltip_link = IU.get_tooltip_link( item.link ),
      item_texture = item.texture,
      item_count = item_count,
      hard_ressed = false,
      winners = winners,
      rolls = {},
      strategy_type = RS.SoftResRoll,
      buttons = buttons,
      type = "Preview"
    }

    rolling_popup:show()
    rolling_popup:refresh( rolling_popup_data[ item.id ] )
  end

  ---@param soft_ressers RollingPlayer[]
  ---@param item Item
  ---@param item_count number
  ---@param dropped_item MasterLootDistributableItem?
  ---@param buttons RollingPopupButtonWithCallback[]
  ---@param candidate_count number
  ---@param candidates ItemCandidate[]
  local function preview_sr_items_not_equal_to_item_count( soft_ressers, item, item_count, dropped_item, buttons, candidate_count, candidates )
    table.insert( buttons, button( "Roll", function() start( RS.SoftResRoll, item, item_count, config.default_rolling_time_seconds() ) end ) )

    if candidate_count > 0 then add_award_other_button( dropped_item, buttons, candidates ) end

    add_close_button( buttons, S.Preview )

    rolling_popup_data[ item.id ] = {
      item_link = item.link,
      item_tooltip_link = IU.get_tooltip_link( item.link ),
      item_texture = item.texture,
      item_count = item_count,
      hard_ressed = false,
      winners = {},
      rolls = roll_tracker.create_roll_data( soft_ressers ),
      strategy_type = RS.SoftResRoll,
      buttons = buttons,
      type = "Preview"
    }

    rolling_popup:show()
    rolling_popup:refresh( rolling_popup_data[ item.id ] )
  end

  ---@param item Item
  ---@param item_count number
  local function preview( item, item_count )
    M.debug.add( "preview" )
    if not item_count or item_count == 0 then
      m.trace( string.format( "item_count: %s", item_count or "nil" ) )
      return
    end

    if rolling_popup_data[ item.id ] then
      rolling_popup_item = item
      rolling_popup:show()
      rolling_popup:refresh( rolling_popup_data[ item.id ] )
      return
    end

    local candidates = ml_candidates.get()
    local soft_ressers = softres.get( item.id )
    local hard_ressed = softres.is_item_hardressed( item.id )
    roll_tracker.preview( item, item_count, candidates, soft_ressers, hard_ressed )

    local color = get_color( item.quality )
    rolling_popup:border_color( color )

    local sr_count = getn( soft_ressers )
    local buttons = {} ---@type RollingPopupButtonWithCallback[]
    local dropped_item = loot_list.get_by_id( item.id )
    local candidate_count = getn( candidates )

    rolling_popup_item = item

    if hard_ressed then
      preview_hard_ressed_item( buttons, item, item_count, dropped_item, candidate_count, candidates )
      return
    end

    if sr_count == 0 then
      preview_non_soft_ressed_items( buttons, item, item_count, dropped_item, candidate_count, candidates )
      return
    end

    if item_count == sr_count then
      preview_sr_items_equal_to_item_count( soft_ressers, item, item_count, dropped_item, buttons, candidate_count, candidates )
      return
    end

    preview_sr_items_not_equal_to_item_count( soft_ressers, item, item_count, dropped_item, buttons, candidate_count, candidates )
  end

  local function tie_content()
    M.debug.add( "tie_content" )
    local data = roll_tracker.get()
    local item = data.item
    local first_iteration = data.iterations[ 1 ]
    local waiting = data.status.type == "Waiting" or false

    local buttons = waiting and roll_in_progress_buttons() or {}

    if data.status.type == "Finished" then
      local dropped_item = loot_list.get_by_id( item.id )
      local candidates = ml_candidates.get()

      ---@type WinnerWithAwardCallback[]
      local winners = m.map( data.winners,
        ---@param player Winner
        function( player )
          if type( player ) ~= "table" then return end -- Fucking lua50 and its n.

          local candidate = ml_candidates.find( player.name )
          local fuck_lua50 = dropped_item
          local strategy = first_iteration.rolling_strategy
          local award_callback = candidate and fuck_lua50 and function()
            show_master_loot_confirmation( candidate, fuck_lua50, strategy )
          end

          ---@type WinnerWithAwardCallback
          return { name = player.name, class = player.class, roll_type = player.roll_type, roll = player.winning_roll, award_callback = award_callback }
        end
      )

      if getn( winners ) == 1 and winners[ 1 ].award_callback then
        table.insert( buttons, button( "AwardWinner", winners[ 1 ].award_callback, should_display_callback ) )
        winners[ 1 ].award_callback = nil
      end

      table.insert( buttons, button( "RaidRoll", function() start( RS.RaidRoll, item, data.item_count ) end ) )
      add_award_other_button( dropped_item, buttons, candidates )
      add_close_button( buttons, "Finished" )
    end

    local tie_iterations = {}

    for i, iteration in ipairs( data.iterations ) do
      if i > 1 then
        table.insert( tie_iterations,
          ---@type TieIteration
          {
            tied_roll = iteration.tied_roll,
            rolls = iteration.rolls
          }
        )
      end
    end

    ---@type RollingPopupTieData
    rolling_popup_data[ item.id ] = {
      ---@type RollingPopupRollData
      roll_data = {
        item_link = item.link,
        item_tooltip_link = IU.get_tooltip_link( item.link ),
        item_texture = item.texture,
        item_count = data.item_count,
        rolls = first_iteration.rolls,
        winners = data.winners,
        strategy_type = first_iteration.rolling_strategy,
        buttons = buttons,
        waiting_for_rolls = waiting or false,
        type = "Roll"
      },
      tie_iterations = tie_iterations,
      type = "Tie"
    }

    rolling_popup:show()
    rolling_popup:refresh( rolling_popup_data[ item.id ] )
  end

  local function on_roll( player_name, player_class, roll_type, roll )
    M.debug.add( string.format( "on_roll( %s, %s, %s, %s )", player_name, player_class, roll_type, roll ) )
    roll_tracker.add( player_name, player_class, roll_type, roll )

    local data, current_iteration = roll_tracker.get()
    local strategy_type = current_iteration and current_iteration.rolling_strategy

    if strategy_type == "NormalRoll" or strategy_type == "SoftResRoll" then
      local waiting_for_rolls = data.status.type == "Waiting" or false

      roll_content(
        data.item,
        data.item_count,
        not waiting_for_rolls and data.status.seconds_left or nil,
        roll_in_progress_buttons(),
        current_iteration.rolls,
        {},
        strategy_type,
        waiting_for_rolls
      )

      return
    end

    if strategy_type == "TieRoll" then
      tie_content()
    end
  end

  local function add_ignored( player_name, player_class, roll_type, roll, reason )
    roll_tracker.add_ignored( player_name, roll_type, roll, reason )
    notify_subscribers( "ignored_roll", {
      player_name = player_name,
      player_class = player_class,
      roll_type = roll_type,
      roll = roll,
      reason = reason
    } )
  end

  ---@param seconds_left number
  local function tick( seconds_left )
    roll_tracker.tick( seconds_left )
    notify_subscribers( "tick", { seconds_left = seconds_left } )

    local data, current_iteration = roll_tracker.get()
    local strategy_type = current_iteration and current_iteration.rolling_strategy

    if strategy_type == "NormalRoll" or strategy_type == "SoftResRoll" then
      roll_content( data.item, data.item_count, seconds_left, roll_in_progress_buttons(), current_iteration.rolls, {}, strategy_type )
    end
  end

  ---@class WinnersFoundData
  ---@field item Item
  ---@field item_count number
  ---@field winners Winner[]
  ---@field rolling_strategy RollingStrategyType

  ---@param item Item
  ---@param item_count number
  ---@param winners Winner[]
  ---@param strategy RollingStrategyType
  local function winners_found( item, item_count, winners, strategy )
    roll_tracker.add_winners( winners )
    notify_subscribers( "winners_found", { item = item, item_count = item_count, winners = winners, rolling_strategy = strategy } )
  end


  ---@param buttons RollingPopupButtonWithCallback[]
  ---@param item Item
  ---@param item_count number
  ---@param strategy_type RollingStrategyType
  local function add_raid_roll_again_button( buttons, item, item_count, strategy_type ) ---@diagnostic disable-line: unused-local -- TODO: leaving for now. Maybe we'll need it.
    table.insert( buttons, button( "RaidRollAgain", function()
      start( strategy_type, item, item_count )
    end ) )
  end

  ---@param data RollTrackerData
  ---@param candidates ItemCandidate[]
  ---@param strategy_type RollingStrategyType
  local function raid_roll_winners( data, candidates, strategy_type )
    local item = data.item
    local buttons = {} ---@type RollingPopupButtonWithCallback[]
    local dropped_item = loot_list.get_by_id( item.id )
    local candidate_count = getn( candidates )

    ---@type WinnerWithAwardCallback[]
    local winners = m.map( data.winners,
      ---@param player Winner
      function( player )
        if type( player ) ~= "table" then return end -- Fucking lua50 and its n.

        local candidate = ml_candidates.find( player.name )
        local award_callback = candidate and dropped_item and function()
          show_master_loot_confirmation( candidate, dropped_item, strategy_type )
        end

        ---@type WinnerWithAwardCallback
        return { name = player.name, class = player.class, roll_type = "MainSpec", award_callback = award_callback }
      end
    )

    if getn( winners ) == 1 and winners[ 1 ].award_callback then
      table.insert( buttons, button( "AwardWinner", winners[ 1 ].award_callback, should_display_callback ) )
      winners[ 1 ].award_callback = nil
    end

    add_raid_roll_again_button( buttons, item, data.item_count, strategy_type )

    if candidate_count > 0 then add_award_other_button( dropped_item, buttons, candidates ) end

    add_close_button( buttons, S.Finish )

    rolling_popup_item = item

    ---@type RollingPopupRaidRollData
    rolling_popup_data[ item.id ] = {
      item_link = item.link,
      item_tooltip_link = IU.get_tooltip_link( item.link ),
      item_texture = item.texture,
      item_count = data.item_count,
      buttons = buttons,
      winners = winners,
      type = "RaidRoll"
    }

    rolling_popup.show()
    rolling_popup:refresh( rolling_popup_data[ item.id ] )
  end

  ---@param data RollTrackerData
  ---@param current_iteration RollIteration
  ---@param candidates ItemCandidate[]
  local function normal_roll_winners( data, current_iteration, candidates )
    local item = data.item
    local buttons = {} ---@type RollingPopupButtonWithCallback[]
    local dropped_item = loot_list.get_by_id( item.id )
    local candidate_count = getn( candidates )

    ---@type WinnerWithAwardCallback[]
    local winners = m.map( data.winners,
      ---@param player Winner
      function( player )
        if type( player ) ~= "table" then return end -- Fucking lua50 and its n.

        local candidate = ml_candidates.find( player.name )
        local award_callback = candidate and dropped_item and function()
          show_master_loot_confirmation( candidate, dropped_item, current_iteration.rolling_strategy )
        end

        ---@type WinnerWithAwardCallback
        return { name = player.name, class = player.class, roll_type = player.roll_type, roll = player.winning_roll, award_callback = award_callback }
      end
    )

    if getn( winners ) == 1 and winners[ 1 ].award_callback then
      table.insert( buttons, button( "AwardWinner", winners[ 1 ].award_callback, should_display_callback ) )
      winners[ 1 ].award_callback = nil
    end

    table.insert( buttons, button( "RaidRoll", function() start( RS.RaidRoll, item, data.item_count ) end ) )

    if candidate_count > 0 then add_award_other_button( dropped_item, buttons, candidates ) end

    add_close_button( buttons, S.Finish )

    rolling_popup_item = item
    ---@type RollingPopupRollData
    rolling_popup_data[ item.id ] = {
      item_link = item.link,
      item_tooltip_link = IU.get_tooltip_link( item.link ),
      item_texture = item.texture,
      item_count = data.item_count,
      buttons = buttons,
      rolls = current_iteration.rolls,
      winners = winners,
      strategy_type = current_iteration.rolling_strategy,
      type = "Roll"
    }

    rolling_popup.show()
    rolling_popup:refresh( rolling_popup_data[ item.id ] )
  end

  ---@param candidates ItemCandidate[]
  local function refresh_finish_popup_content( candidates )
    local data, current_iteration = roll_tracker.get()

    if not current_iteration then return end
    local strategy_type = current_iteration.rolling_strategy

    rolling_popup.ping()

    if strategy_type == "InstaRaidRoll" or strategy_type == "RaidRoll" then
      raid_roll_winners( data, candidates, strategy_type )
      return
    end

    if strategy_type == "NormalRoll" or strategy_type == "SoftResRoll" then
      normal_roll_winners( data, current_iteration, candidates )
      return
    end

    if strategy_type == "TieRoll" then
      tie_content()
    end
  end

  local function finish()
    local candidates = ml_candidates.get()
    roll_tracker.finish( candidates )
    notify_subscribers( "finish" )

    refresh_finish_popup_content( candidates )
  end

  ---@param strategy_type RollingStrategyType
  ---@param item Item
  ---@param item_count number
  ---@param seconds number?
  ---@param message string?
  ---@param rolling_players RollingPlayer[]?
  local function rolling_started( strategy_type, item, item_count, seconds, message, rolling_players )
    roll_tracker.start( strategy_type, item, item_count, seconds, message, rolling_players )

    local _, _, quality = m.api.GetItemInfo( string.format( "item:%s:0:0:0", item.id ) )
    local color = get_color( quality )

    rolling_popup:border_color( color )

    local _, current_iteration = roll_tracker.get()
    local rolls = current_iteration and current_iteration.rolls or {}

    if strategy_type == "NormalRoll" or strategy_type == "SoftResRoll" then
      roll_content( item, item_count, seconds, roll_in_progress_buttons(), rolls, {}, strategy_type )
      return
    end

    notify_subscribers( "rolling_started" )
  end

  local function there_was_a_tie( players, item, item_count, roll_type, roll, rerolling, top_roll )
    roll_tracker.tie( players, roll_type, roll )
    notify_subscribers( "there_was_a_tie", {
      players = players,
      item = item,
      item_count = item_count,
      roll_type = roll_type,
      roll = roll,
      rerolling = rerolling,
      top_roll = top_roll
    } )

    tie_content()
  end

  local function tie_start()
    roll_tracker.tie_start()
    notify_subscribers( "tie_start" )

    tie_content()
  end

  local function rolling_canceled()
    roll_tracker.rolling_canceled()

    local data = roll_tracker.get()
    local item = data.item
    local buttons = {}
    add_close_button( buttons, "InProgress" )

    rolling_popup_data[ item.id ] = {
      item_link = item.link,
      item_tooltip_link = IU.get_tooltip_link( item.link ),
      item_texture = item.texture,
      item_count = data.item_count,
      buttons = buttons,
      type = "RollingCanceled"
    }

    rolling_popup:show()
    rolling_popup:refresh( rolling_popup_data[ item.id ] )
  end

  local function subscribe( event_type, callback )
    callbacks[ event_type ] = callbacks[ event_type ] or {}
    table.insert( callbacks[ event_type ], callback )
  end

  local function waiting_for_rolls()
    roll_tracker.waiting_for_rolls()

    local data, current_iteration = roll_tracker.get()
    local strategy_type = current_iteration and current_iteration.rolling_strategy

    if strategy_type == "NormalRoll" or strategy_type == "SoftResRoll" then
      roll_content( data.item, data.item_count, nil, roll_in_progress_buttons(), current_iteration.rolls, {}, strategy_type, true )
    end
  end

  ---@class MasterLootCandidate
  ---@field name string
  ---@field class PlayerClass
  ---@field is_winner boolean
  ---@field confirm_fn fun()

  ---@class LootAwardedData
  ---@field item_id number
  ---@field item_link string
  ---@field player_name string
  ---@field player_class string?

  ---@param item_id number
  ---@param item_link string
  ---@param player_name string
  ---@param player_class PlayerClass?
  local function loot_awarded( item_id, item_link, player_name, player_class )
    roll_tracker.loot_awarded( player_name, item_id )

    if ml_confirmation_data then
      ml_confirmation_data = nil
      loot_award_popup.hide()
    end

    ---@type LootAwardedData
    local event_data = {
      player_name = player_name,
      player_class = player_class,
      item_id = item_id,
      item_link = item_link
    }

    notify_subscribers( "loot_awarded", event_data )

    local data, current_iteration = roll_tracker.get()

    if data.status and data.status.type == S.Preview and data.item_count > 0 then
      rolling_popup_data[ item_id ] = nil
      preview( data.item, data.item_count )
      notify_subscribers( "LootFrameUpdate" )
      return
    end

    if data.item_count == 0 then
      notify_subscribers( "LootFrameDeselect", { item_id = item_id } )

      if rolling_popup_item then
        rolling_popup_data[ rolling_popup_item.id ] = nil
        rolling_popup_item = nil
      end

      rolling_popup.hide()
      notify_subscribers( "LootFrameClearSelectionCache", item_id )
      return
    end

    local strategy_type = current_iteration and current_iteration.rolling_strategy

    if strategy_type == "InstaRaidRoll" or strategy_type == "RaidRoll" then
      local candidates = ml_candidates.get()
      raid_roll_winners( data, candidates, strategy_type )
    elseif strategy_type == "NormalRoll" or strategy_type == "SoftResRoll" then
      local candidates = ml_candidates.get()
      normal_roll_winners( data, current_iteration, candidates )
    end

    notify_subscribers( "not_all_items_awarded" )
  end

  local function popup_refresh()
    if rolling_popup_item and rolling_popup_data[ rolling_popup_item.id ] then
      M.debug.add( "popup_refresh" )

      local data = roll_tracker.get()

      if data.status.type == "Finished" then
        refresh_finish_popup_content( ml_candidates.get() )
        return
      end

      rolling_popup.show()
      rolling_popup:refresh( rolling_popup_data[ rolling_popup_item.id ] )
    end
  end

  local function loot_opened()
    M.debug.add( "loot_opened" )
    popup_refresh()
  end

  local function loot_closed()
    M.debug.add( "loot_closed" )

    if ml_confirmation_data then
      award_aborted( ml_confirmation_data.item )
      ml_confirmation_data = nil
      loot_award_popup.hide()
      return
    end

    local status = roll_tracker.get().status

    if status and status.type == S.Preview then
      local item_id = rolling_popup_item and rolling_popup_item.id

      if rolling_popup_item then
        rolling_popup_data[ rolling_popup_item.id ] = nil
        rolling_popup_item = nil
      end

      roll_tracker.clear()
      rolling_popup.hide()
      notify_subscribers( "LootFrameDeselect", { item_id = item_id } )

      return
    end

    popup_refresh()
  end

  ---@param error LootAwardError
  local function update_loot_confirmation_with_error( error )
    if not ml_confirmation_data then return end
    ml_confirmation_data.error = error
    loot_award_popup.show( ml_confirmation_data )
  end

  local function player_already_has_unique_item()
    update_loot_confirmation_with_error( LAE.AlreadyOwnsUniqueItem )
  end

  local function player_has_full_bags()
    update_loot_confirmation_with_error( LAE.FullBags )
  end

  local function player_not_found()
    update_loot_confirmation_with_error( LAE.PlayerNotFound )
  end

  local function cant_assign_item_to_that_player()
    update_loot_confirmation_with_error( LAE.CantAssignItemToThatPlayer )
  end

  local function rolling_popup_closed()
    notify_subscribers( "rolling_popup_closed" )

    -- local data = roll_tracker.get()
    --
    -- if data and data.status and data.status.type == S.Preview then
    --   roll_tracker.clear()
    -- end
  end

  local function loot_award_popup_closed()
    notify_subscribers( "loot_award_popup_closed" )
  end

  local function loot_list_item_selected()
    notify_subscribers( "loot_list_item_selected" )
  end

  local function loot_list_item_deselected()
    notify_subscribers( "loot_list_item_deselected" )
  end

  ---@type RollController
  return {
    preview = preview,
    start = start,
    winners_found = winners_found,
    finish = finish,
    tick = tick,
    add = on_roll,
    add_ignored = add_ignored,
    rolling_canceled = rolling_canceled,
    subscribe = subscribe,
    waiting_for_rolls = waiting_for_rolls,
    there_was_a_tie = there_was_a_tie,
    tie_start = tie_start,
    award_aborted = award_aborted,
    loot_awarded = loot_awarded,
    loot_closed = loot_closed,
    loot_opened = loot_opened,
    player_already_has_unique_item = player_already_has_unique_item,
    player_has_full_bags = player_has_full_bags,
    player_not_found = player_not_found,
    cant_assign_item_to_that_player = cant_assign_item_to_that_player,
    rolling_popup_closed = rolling_popup_closed,
    loot_award_popup_closed = loot_award_popup_closed,
    loot_list_item_selected = loot_list_item_selected,
    loot_list_item_deselected = loot_list_item_deselected,
    finish_rolling_early = finish_rolling_early,
    cancel_rolling = cancel_rolling,
    rolling_started = rolling_started,
    award_confirmed = award_confirmed
  }
end

m.RollController = M
return M
