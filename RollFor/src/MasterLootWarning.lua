local modules = LibStub( "RollFor-Modules" )
if modules.MasterLootWarning then return end

local M                    = {}
local red                  = modules.colors.red
local table_contains_value = modules.table_contains_value

---@diagnostic disable-next-line: undefined-global
local UIParent             = UIParent

local zones                = {
  "Terokkar Forest",
  "Karazhan",
  "Gruul's Lair",
  "Magtheridon's Lair",
  "Serpentshrine Cavern",
  "Tempest Keep",
  "Black Temple",
  "Sunwell Plateau"
}

local function create_frame( api )
  local frame = api().CreateFrame( "FRAME", "RollForMasterLootWarning", UIParent )
  frame:Hide()

  local label = frame:CreateFontString( nil, "OVERLAY" )
  label:SetFont( "FONTS\\FRIZQT__.TTF", 24, "OUTLINE" )
  label:SetPoint( "TOPLEFT", 0, 0 )
  label:SetText( string.format( "No %s!", red( "Master Loot" ) ) )

  frame:SetWidth( label:GetWidth() )
  frame:SetHeight( label:GetHeight() )
  frame:SetPoint( "TOPLEFT", UIParent, "TOPLEFT", (UIParent:GetWidth() / 2) - (frame:GetWidth() / 2), -270 )

  return frame
end

function M.new( api, db )
  local frame

  local function show()
    if not frame or (frame.fadeInfo and frame.fadeInfo.finishedFunc) or db.char.disable_ml_warning then return end

    frame:SetAlpha( 1 )
    frame:Show()
  end

  local function on_player_regen_disabled()
    local zone_name = api().GetRealZoneText()
    if not table_contains_value( zones, zone_name ) or not api().IsInRaid() or api().GetLootMethod() == "master" then return end

    if not frame then frame = create_frame( api ) end
    show()
  end

  local function hide()
    if not frame or frame.fading_out or not frame:IsVisible() then return end

    frame.fading_out = true
    api().UIFrameFadeOut( frame, 2, 1, 0 )
    frame.fadeInfo.finishedFunc = function()
      frame.fading_out = nil
      frame:Hide()
    end
  end

  local function on_party_loot_method_changed()
    local is_master_loot = api().GetLootMethod() == "master"

    if api().IsInRaid() and api().InCombatLockdown() and not is_master_loot then
      show()
      return
    end

    if frame and frame:IsVisible() and frame:GetAlpha() == 1 and is_master_loot then
      hide()
      return
    end
  end

  local function on_zone_changed()
    local zone_name = api().GetRealZoneText()

    if not table_contains_value( zones, zone_name ) or not api().IsInRaid() and frame and frame:IsVisible() and api().InCombatLockdown() then
      hide()
    end
  end

  return {
    on_player_regen_disabled = on_player_regen_disabled,
    on_party_loot_method_changed = on_party_loot_method_changed,
    on_zone_changed = on_zone_changed,
    hide = hide
  }
end

modules.MasterLootWarning = M
return M
