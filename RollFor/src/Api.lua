local libStub = LibStub
local modules = libStub( "RollFor-Modules" )
if modules.Api then return end

local M = {}

M.RollType = {
  NormalRoll = { slash_command = "/rf" }, -- Includes soft-res rolls.
  NoSoftResRoll = { slash_command = "/arf" },
  RaidRoll = { slash_command = "/rr" }
}

--M.ResultType = {
--NOT_IN_A_GROUP = "NOT_IN_A_GROUP",
--ROLLING_IN_PROGRESS = "ROLLING_IN_PROGRESS",
--INVALID_ITEM = "INVALID_ITEM",
--ROLLING_FINISHED = "ROLLING_FINISHED",
--ROLLING_CANCELLED = "ROLLING_CANCELLED"
--}

--M.RollType = {
--ROLL = "ROLL",
--SOFTRES_ROLL = "SOFTRES_ROLL",
--TIE_ROLL = "TIE_ROLL",
---- This scenario is when players soft-ressed items, but didn't roll for them
---- in time. The system stops and waits for the remaining players to roll
---- (yes, we're nice). However, now it's up to the Master Looter to decide
---- whether to finish the rolling now and announce the current winner or
---- to wait for the remaining soft-ressing players to roll.
---- Maybe they disconnected, maybe they're afk, or maybe they're plain stupid.
--SOFTRES_ROLLS_MISSING = "SOFTRES_ROLLS_MISSING",
---- Item is hard-ressed, there is no rolling.
--ITEM_HARDRESSED = "ITEM_HARDRESSED",
--RAID_ROLL = "RAID_ROLL",
---- Nobody rolled for the item. Or there's an extra item left, for example
---- two identical items dropped and only one person rolled for it.
--NO_WINNER = "NO_WINNER"
--}

--function M.roll_result( item, roll, winner_name )
--return {
--roll_type = M.RollType.ROLL,
--item = item,
--roll = roll,
--winner_name = winner_name,
--}
--end

--function M.tie_roll_result( item, tie_roll, tie_rollers )
--return {
--roll_type = M.RollType.TIE_ROLL,
--item = item,
--roll = tie_roll,
--tie_rollers = tie_rollers
--}
--end

--function M.softres_roll_result( item, winner_name )
--return {
--roll_type = M.RollType.SOFTRES_ROLL,
--item = item,
--winner_name = winner_name
--}
--end

--function M.hardres_result( item, hardres_player_name )
--return {
--roll_type = M.RollType.ITEM_HARDRESSED,
--item = item,
--winner_name = hardres_player_name
--}
--end

--function M.raid_roll_result( item, players, roll, winner_name )
--return {
--roll_type = M.RollType.RAID_ROLL,
--item = item,
--players = players,
--roll = roll,
--winner_name = winner_name
--}
--end

--function M.no_winner( item )
--return {
--roll_type = M.RollType.NO_WINNER,
--item = item
--}
--end

modules.Api = M
return M
