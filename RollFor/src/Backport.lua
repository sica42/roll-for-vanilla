---@diagnostic disable: undefined-global
function IsInParty() return GetNumRaidMembers() == 0 and GetNumPartyMembers() > 0 end

function IsInRaid() return GetNumRaidMembers() > 0 end

function IsInGroup() return IsInParty() or IsInRaid() end

---@diagnostic disable-next-line: undefined-field
if not string.gmatch then string.gmatch = string.gfind end

---@diagnostic disable-next-line: duplicate-set-field
string.match = string.match or function( str, pattern )
  if not str then return nil end

  local _, _, r1, r2, r3, r4, r5, r6, r7, r8, r9 = string.find( str, pattern )
  return r1, r2, r3, r4, r5, r6, r7, r8, r9
end
