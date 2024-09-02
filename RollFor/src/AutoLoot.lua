local modules = LibStub( "RollFor-Modules" )
if modules.AutoLoot then return end

local M = {}
local pretty_print = modules.pretty_print
local item_utils = modules.ItemUtils
local contains = modules.table_contains_value
---@diagnostic disable-next-line: deprecated
local getn = table.getn

local items = {
  [ "Ragefire Chasm" ] = {
    14149,
    14113, -- Aboriginal Sash of the Whale
  },
  [ "Karazhan" ] = {
    -- Trash mobs
    30642, -- Drape of the Righteous
    30668, -- Grasp of the Dead
    30673, -- Inferno Waist Cord
    30644, -- Grips of Deftness
    30643, -- Belt of the Tracker
    30641, -- Boots of Elusion
    30666, -- Ritssyn's Lost Pendant
    30667, -- Ring of Unrelenting Storms
    21903, -- Pattern: Soulcloth Shoulders
    21904, -- Pattern: Soulcloth Vest

    -- Hyakiss the Lurker
    30675, -- Lurker's Cord
    30676, -- Lurker's Grasp
    30676, -- Lurker's Grasp
    30677, -- Lurker's Belt
    30678, -- Lurker's Girdle

    -- Shadikith the Glider
    30680, -- Glider's Foot-Wraps
    30681, -- Glider's Boots
    30682, -- Glider's Sabatons
    30683, -- Glider's Greaves

    -- Rokad the Ravager
    30684, -- Ravager's Cuffs
    30685, -- Ravager's Wrist-Wraps
    30686, -- Ravager's Bands
    30687, -- Ravager's Bracers

    -- Attumen the Huntsman
    28477, -- Harbinger Bands
    28507, -- Handwraps of Flowing Thought
    28508, -- Gloves of Saintly Blessings
    28453, -- Bracers of the White Stag
    28506, -- Gloves of Dexterous Manipulation
    28503, -- Whirlwind Bracers
    28454, -- Stalker's War Bands
    28502, -- Vambraces of Courage
    28505, -- Gauntlets of Renewed Hope
    28509, -- Worgen Claw Necklace
    28510, -- Spectral Band of Innervation
    28504, -- Steelhawk Crossbow
    --30480, -- Fiery Warhorse's Reigns
    --23809, -- Schematic: Stabilized Eternium Scope

    -- Moroes
    28529, -- Royal Cloak of Arathi Kings
    28570, -- Shadow-Cloak of Dalaran
    28565, -- Nethershard Girdle
    28545, -- Edgewalker Longboots
    28567, -- Belt of Gale Force
    28566, -- Crimson Girdle of the Indomitable
    28569, -- Boots of Valiance
    28530, -- Brooch of Unquenchable Fury
    28528, -- Moroes' Lucky Pocket Watch
    28525, -- Signed of Unshakable Faith
    28568, -- Idol of the Avian Heart
    28524, -- Emerald Ripper
    --22559, -- Formula: Enchant Weapon - Mongoose

    -- Maiden of Virtue
    28511, -- Bands of Indwelling
    28515, -- Bands of Nefarious Deeds
    28517, -- Boots of Foretelling
    28514, -- Bracers of Maliciousness
    28521, -- Mitts of the Treemender
    28520, -- Gloves of Centering
    28519, -- Gloves of Quickening
    28512, -- Bracers of Justice
    28518, -- Iron Gauntlets of the Maiden
    28516, -- Barbed Choker of Discipline
    28523, -- Totem of Healing Rains
    28522, -- Shard of the Virtuous

    -- The Opera Event (shared)
    28594, -- Trial-Fire Trousers
    28591, -- Earthsoul Leggings
    28589, -- Beastmaw Pauldrons
    28593, -- Eternium Greathelm
    28590, -- Ribbon of Sacrifice
    28592, -- Libram of Souls Redeemed

    -- The Opera Event (Romulo & Julianne)
    28578, -- Masquerade Gown
    28579, -- Romulo's Poison Vial
    28572, -- Blade of the Unrequited
    28573, -- Despair

    -- The Opera Event (The Crone)
    28586, -- Wicked Witch's Hat
    28585, -- Ruby Slippers
    28587, -- Legacy
    28588, -- Blue Diamond Witchwand

    -- The Opera Event (The Big Bad Wolf)
    28582, -- Red Riding Hood's Cloak
    28583, -- Big Bad Wolf's Head
    28584, -- Big Bad Wolf's Paw
    28581, -- Wolfslayer Sniper Rifle

    -- Nightbane
    28602, -- Robe of the Elder Scribes
    28600, -- Stonebough Jerkin
    28601, -- Chestguard of the Conniver
    28599, -- Scaled Breastplate of Carnage
    28610, -- Ferocious Swift-Kickers
    28597, -- Panzar'Thar Breastplate
    28608, -- Ironstriders of Urgency
    28609, -- Emberspur Talisman
    28603, -- Talisman of Nightbane
    28604, -- Nightstaff of the Everliving
    28611, -- Dragonheart Flameshield
    28606, -- Shield of Impenetrable Darkness

    -- The Curator
    28612, -- Pauldrons of the Solace-Giver
    28647, -- Forest Wind Shoulderpads
    28631, -- Dragon-Quake Shoulderguards
    28621, -- Wrynn Dynasty Greaves
    28649, -- Garona's Signet Ring
    28633, -- Staff of Infinite Mysteries
    29757, -- Glovers of the Fallen Champion
    29758, -- Glovers of the Fallen Defender
    29756, -- Glovers of the Fallen Hero

    -- Terestian Illhoof
    28660, -- Gilded Thorium Cloak
    28653, -- Shadowvine Cloak of Infusion
    28652, -- Cincture of Will
    28654, -- Malefic Girdle
    28655, -- Cord of Nature's Sustenance
    28656, -- Girdle of the Prowler
    28662, -- Breatplate of the Lightbringer
    28661, -- Mender's Heart-Ring
    28785, -- The Lightning Capacitor
    28657, -- Fool's Bane
    28658, -- Terestian's Stanglestaff
    28659, -- Xavian Stiletto
    --22561, -- Formula: Enchant Weapon - Soulfrost

    -- Shade of Aran
    28672, -- Drape of the Dark Reavers
    28726, -- Mantle of the Mind Flayer
    28670, -- Boots of the Infernal Coven
    28663, -- Boots of the Incorrupt
    28669, -- Rapscallion Boots
    28671, -- Steelspine Faceguard
    28666, -- Pauldrons of the Justice-Seeker
    28674, -- Saberclaw Talisman
    28675, -- Shermanar Great-Ring
    28727, -- Pendant of the Violet Eye
    28728, -- Aran's Soothing Sapphire
    28673, -- Tirisfal Wand of Ascendancy
    --22560, -- Formula: Enchant Weapon - Sunfire

    -- Netherspite
    28744, -- Uni-Mind Headdress
    28742, -- Pantaloons of Repentance
    28732, -- Cowl of Defiance
    28741, -- Skulker's Greaves
    28735, -- Earthblood Chestguard
    28740, -- Rip-Flayer Leggings
    28743, -- Mantle of Abrahmis
    28733, -- Girle of Truth
    28731, -- Shining Chain of the Afterworld
    28730, -- Mithril Band of the Unscarred
    28734, -- Jewel of Infinite Possibilities
    28729, -- Spiteblade

    -- Chess Event
    28756, -- Headdress of the High Potentate
    28755, -- Bladed Shoulderpads of the Merciless
    28750, -- Girdle of Treachery
    28752, -- Forestlord Striders
    28751, -- Heart-Flame Leggings
    28746, -- Fiend Slayer Boots
    28748, -- Legplates of the Innocent
    28747, -- Battlescar Boots
    28745, -- Mithril Chain of Heroism
    28753, -- Ring of Recurrence
    28749, -- King's Defender
    28754, -- Triptych Shield of the Ancients

    -- Prince Malchezaar
    28765, -- Stainless Cloak of the Pure Hearted
    28766, -- Ruby Drape of the Mysticant
    28764, -- Farstrider Wildercloak
    28762, -- Adornment of Stolen Souls
    28763, -- Jade Ring of the Eveliving
    28757, -- Ring of a Thousand Marks
    28770, -- Nathrezim Mindblade
    28768, -- Malchazeen
    28767, -- The Decapitator
    28773, -- Gorehowl
    28771, -- Light's Justice
    28772, -- Sunfury Bow of the Phoenix
    29760, -- Helm of the Fallen Champion
    29761, -- Helm of the Fallen Defender
    29759, -- Helm of the Fallen Hero
  },
  [ "Gruul's Lair" ] = {
    -- High King Maulgar
    28797, -- Brute Cloak of the Ogre-Magi
    28799, -- Belt of Divine Inspiration
    28796, -- Malefic Mask of the Shadows
    28801, -- Maulgar's Warhelm
    28795, -- Bladespire Warbands
    28800, -- Hammer of the Naaru
    29763, -- Pauldrons of the Fallen Champion
    29764, -- Pauldrons of the Fallen Defender
    29762, -- Pauldrons of the Fallen Hero

    -- Gruul the Dragonkiller
    28804, -- Collar of Cho'gall
    28803, -- Cowl of Nature's Breath
    28828, -- Gronn-Stitched Girdle
    28827, -- Gauntlets of the Dragonslayer
    28810, -- Windshear Boots
    28824, -- Gauntlets of Martial Perfection
    28822, -- Teeth of Gruul
    28823, -- Eye of Gruul
    28830, -- Dragonspine Trophy
    28802, -- Bloodmaw Magus-Blade
    28794, -- Axe of the Gronn Lords
    28825, -- Aldori Legacy Defender
    28826, -- Shuriken of Negation
    29766, -- Leggings of the Fallen Champion
    29767, -- Leggings of the Fallen Defender
    29765, -- Leggings of the Fallen Hero
  },
  [ "Magtheridon's Lair" ] = {
    28777, -- Cloak of the Pit Stalker
    28780, -- Soul-Eater's Handwraps
    28776, -- Liar's Tongue Gloves
    28778, -- Terror Pit Girdle
    28775, -- Thundering Greathelm
    28779, -- Girdle of the Endless Pit
    28789, -- Eye of Magtheridon
    28781, -- Karaborian Talisman
    28774, -- Glaive of the Pit
    28782, -- Crystalheart Pulse-Staff
    29458, -- Aegis of the Vindicator
    28783, -- Eredar Wand of Obliteration
    32385, -- Magtheridon's Head
    29754, -- Chestguard of the Fallen Champion
    29753, -- Chestguard of the Fallen Defender
    29755, -- Chestguard of the Fallen Hero
  },
  [ "Tempest Keep" ] = {
    -- Trash mobs
    30024, -- Mantle of the Elven Kings
    30020, -- Fire-Cord of the Magus
    30029, -- Bark-Gloves of Ancient Wisdom
    30026, -- Bands of the Celestial Archer
    30030, -- Girdle of Fallen Stars
    30028, -- Seventh Ring of the Tirisfalen
    30324, -- Plans: Red Havoc Boots
    30322, -- Plans: Red Belt of Battle
    30323, -- Plans: Boots of the Protector
    30321, -- Plans Beot of the Guardian
    30280, -- Pattern: Belt of Blasting
    30282, -- Pattern: Boots of Blasting
    30283, -- Pattern: Boots of the Long Road
    30281, -- Pattern: Belt of the Long Road
    30308, -- Pattern: Hurricane Boots
    30304, -- Pattern: Monsoon Belt
    30305, -- Pattern: Boots of Natural Grace
    30307, -- Pattern: Boots of the Crimson Hawk
    30306, -- Pattern: Boots of Utter Darkness
    30301, -- Pattern: Belt of Natural Power
    30303, -- Pattern: Belt of the Black Eagle
    30302, -- Pattern: Belt of Deep Shadow

    -- Void Reaver
    29986, -- Cowl of ther Grand Engineer
    29984, -- Girdle of Zaetar
    29985, -- Void Reaver Greaves
    29983, -- Fel-Steel Warhelm
    32515, -- Wristguards of Detemination
    30619, -- Fel Reaver's Piston
    30450, -- Warp-Spring Coil
    30248, -- Pauldrons of the Vanquished Champion
    30249, -- Pauldrons of the Vanquished Defender
    30250, -- Pauldrons of the Vanquished Hero
  },
  [ "Hyjal Summit" ] = {
    -- Trash mobs
    32590, -- Nethervoid Cloak
    34010, -- Pepe's Shroud of Pacification
    32609, -- Boots of the Divine Light
    32592, -- Chestguard of Relentless Storms
    32591, -- Choker of Serrated Blades
    32589, -- Hellfire-Encased Pendant
    34009, -- Hammer of Judgement
    32946, -- Claw of Molten Fury
    32945, -- Fist of Molten Fury

    -- Dunno why, but these don't seem to be dropping.
    32285, -- Design: Flashing Crimson Spinel
    32296, -- Design: Great Lionseye
    32303, -- Design: Inscribed Pyrestone
    32295, -- Design: Mystic Lionseye
    32298, -- Design: Shifting Shadowsong Amethyst
    32297, -- Design: Soverign Shadowsong Amethyst
    32289, -- Design: Stormy Empyrean Sapphire
    32307, -- Design: Veiled Pyrestone
    23627, -- Plans: Bracers of the Green Fortress

    -- However, the BT ones are:
    32738, -- Plans: Dawnsteel Bracers
    32739, -- Plans: Dawnsteel Shoulders
    32736, -- Plans: Swiftsteel Bracers
    32737, -- Plans: Swiftsteel Shoulders
    32748, -- Pattern: Bindings of Lightning Reflexes
    32744, -- Pattern: Bracers of Renewed Life
    32750, -- Pattern: Living Earth Bindings
    32751, -- Pattern: Living Earth Shoulders
    32749, -- Pattern: Shoulders of Lightning Reflexes
    32745, -- Pattern: Shoulderpads of Renewed Life
    32746, -- Pattern: Swiftstrike Bracers
    32747, -- Pattern: Swiftstrike Shoulders
    32754, -- Pattern: Bracers of Nimble Thought
    32755, -- Pattern: Mantle of Nimble Thought
    32753, -- Pattern: Swiftheal Mantle
    32752, -- Pattern: Swiftheal Wraps
  }
}

function M.new( api, db )
  local frame

  local function find_player_candidate_index()
    for i = 1, 40 do
      local name = modules.api.GetMasterLootCandidate( i )
      if name == api().UnitName( "player" ) then
        return i
      end
    end
  end

  local function on_auto_loot()
    local item_count = api().GetNumLootItems()
    local zone_name = api().GetRealZoneText()
    local item_ids = items[ zone_name ]

    if not item_ids or getn( item_ids ) == 0 then
      return
    end

    local threshold = modules.api.GetLootThreshold()

    for slot = 1, item_count do
      local link = modules.api.GetLootSlotLink( slot )
      local _, _, _, quality = modules.api.GetLootSlotInfo( slot )
      if not quality then quality = 0 end

      if link then
        local item_id = item_utils.get_item_id( link )

        if quality < threshold or db.char.auto_loot and contains( item_ids, item_id ) then
          local index = find_player_candidate_index()

          if index then
            api().GiveMasterLoot( slot, index )
          else
            pretty_print( string.format( "%s cannot be looted.", link ) )
          end
        else
          pretty_print( string.format( "%s (%s) is not on the auto-loot list.", link, item_id ) )
        end
      end
    end
  end

  local function create_frame()
    frame = api().CreateFrame( "BUTTON", nil, api().LootFrame, "UIPanelButtonTemplate" )
    frame:SetWidth( 90 )
    frame:SetHeight( 23 )
    frame:SetText( "Auto Loot" )
    frame:SetPoint( "TOPRIGHT", api().LootFrame, "TOPRIGHT", -75, -44 )
    frame:SetScript( "OnClick", on_auto_loot )
    frame:Show()
  end

  local function on_loot_opened()
    if not frame then create_frame() end

    local zone_name = api().GetRealZoneText()
    local item_ids = items[ zone_name ]

    if not item_ids or getn( item_ids ) == 0 then
      frame:Hide()
    else
      frame:Show()
    end

    on_auto_loot()
    -- end
  end

  return {
    on_loot_opened = on_loot_opened
  }
end

modules.AutoLoot = M
return M
