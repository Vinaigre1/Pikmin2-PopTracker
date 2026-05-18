require("scripts/countPokos")

EntranceTable = {
  ["unknown"] = 0,
  ["EC"] = 1,
  ["SC"] = 2,
  ["FC"] = 3,
  ["HoB"] = 4,
  ["WFG"] = 5,
  ["BK"] = 6,
  ["SH"] = 7,
  ["CoS"] = 8,
  ["GK"] = 9,
  ["SR"] = 10,
  ["SMGC"] = 11,
  ["CoC"] = 12,
  ["HoH"] = 13,
  ["DD"] = 14
}

function Has(item)
  local item_map = {
    ["RP"] = "redonion",
    ["YP"] = "yellowonion",
    ["BP"] = "blueonion",
    ["PP"] = "purpleonion",
    ["WP"] = "whiteonion",

    ["W2"] = "sphericalatlas",
    ["W3"] = "geographicprojection",
    ["W4"] = "debt",

    ["NS"] = "five-mannapsack",
    ["RA"] = "repugnantappendage"
  }

  if item == "W4" then
    return DebtPayedOff() and Has("W2") and Has("W3")
  elseif (item == "W2" or item == "W3") and Tracker:FindObjectForCode("setting_prog_globes").CurrentStage == 1 then
    local globe1 = Tracker:FindObjectForCode("sphericalatlas").Active
    local globe2 = Tracker:FindObjectForCode("geographicprojection").Active
    if item == "W2" then
      return globe1 or globe2
    elseif item == "W3" then
      return globe1 and globe2
    end
  elseif item_map[item] ~= nil then
    return Tracker:FindObjectForCode(item_map[item]).Active
  end
end

function HasKey(key)
  local key_map = {
    ["EC"] = "ecentrancekey",
    ["SC"] = "scentrancekey",
    ["FC"] = "fcentrancekey",
    ["HoB"] = "hobentrancekey",
    ["WFG"] = "wfgentrancekey",
    ["BK"] = "bkentrancekey",
    ["SH"] = "shentrancekey",
    ["CoS"] = "cosentrancekey",
    ["GK"] = "gkentrancekey",
    ["SR"] = "srentrancekey",
    ["SMGC"] = "smgcentrancekey",
    ["CoC"] = "cocentrancekey",
    ["HoH"] = "hohentrancekey",
    ["DD"] = "ddentrancekey",
  }

  if key_map[key] ~= nil then
    return Tracker:FindObjectForCode(key_map[key]).Active
  end
end

function NotHasKey(key)
  return not HasKey(key)
end

function SB()
  return AccessibilityLevel.SequenceBreak
end

function DebtPayedOff()
  local pokos = 0
  pokos = pokos + Tracker:FindObjectForCode("pokos_tenthousand").CurrentStage * 10000
  pokos = pokos + Tracker:FindObjectForCode("pokos_thousand").CurrentStage * 1000
  pokos = pokos + Tracker:FindObjectForCode("pokos_hundred").CurrentStage * 100
  pokos = pokos + Tracker:FindObjectForCode("pokos_ten").CurrentStage * 10
  pokos = pokos + Tracker:FindObjectForCode("pokos_one").CurrentStage * 1
  local debt = 0
  debt = debt + Tracker:FindObjectForCode("debt_tenthousand").CurrentStage * 10000
  debt = debt + Tracker:FindObjectForCode("debt_thousand").CurrentStage * 1000
  debt = debt + Tracker:FindObjectForCode("debt_hundred").CurrentStage * 100
  debt = debt + Tracker:FindObjectForCode("debt_ten").CurrentStage * 10
  debt = debt + Tracker:FindObjectForCode("debt_one").CurrentStage * 1
  return pokos >= debt
end

function IsSelectedDestination(entrance, area)
  return Tracker:FindObjectForCode(entrance .. "_dst").CurrentStage == EntranceTable[area]
end

function ResetCaves()
  Tracker:FindObjectForCode("EC_dst").CurrentStage = 1
  Tracker:FindObjectForCode("SC_dst").CurrentStage = 2
  Tracker:FindObjectForCode("FC_dst").CurrentStage = 3
  Tracker:FindObjectForCode("HoB_dst").CurrentStage = 4
  Tracker:FindObjectForCode("WFG_dst").CurrentStage = 5
  Tracker:FindObjectForCode("BK_dst").CurrentStage = 6
  Tracker:FindObjectForCode("SH_dst").CurrentStage = 7
  Tracker:FindObjectForCode("CoS_dst").CurrentStage = 8
  Tracker:FindObjectForCode("GK_dst").CurrentStage = 9
  Tracker:FindObjectForCode("SR_dst").CurrentStage = 10
  Tracker:FindObjectForCode("SMGC_dst").CurrentStage = 11
  Tracker:FindObjectForCode("CoC_dst").CurrentStage = 12
  Tracker:FindObjectForCode("HoH_dst").CurrentStage = 13
  Tracker:FindObjectForCode("DD_dst").CurrentStage = 14
end

function CanAccess(cave)
  local cave_access = {
    EC = "$HasKey|EC",

    SC = {
      "$HasKey|SC,$Has|BP,$Has|WP",
      "$HasKey|SC,$Has|BP,$Has|NS,^$SB",
    },

    FC = "$HasKey|FC,$Has|BP",

    HoB = "$HasKey|HoB,$Has|W2",

    WFG = "$HasKey|WFG,$Has|W2,$Has|PP",

    BK = {
      "$HasKey|BK,$Has|W2,$Has|YP,$Has|PP,$Has|WP",
      "$HasKey|BK,$Has|W2,$Has|NS,^$SB",
    },

    SH = {
      "$HasKey|SH,$Has|W2,$Has|BP,$Has|WP",
      "$HasKey|SH,$Has|W2,$Has|WP,^$SB",
    },

    CoS = "$HasKey|CoS,$Has|W3",

    GK = {
      "$HasKey|GK,$Has|W3,$Has|YP",
      "$HasKey|GK,$Has|W3,$Has|NS,^$SB",
    },

    SR = {
      "$HasKey|SR,$Has|W3,$Has|BP,$Has|YP",
      "$HasKey|SR,$Has|W3,$Has|BP,$Has|RA,^$SB",
    },

    SMGC = "$HasKey|SMGC,$Has|W3,$Has|BP",

    CoC = "$HasKey|CoC,$Has|W4",

    HoH = "$HasKey|HoH,$Has|W4,$Has|BP,$Has|YP",

    DD = {
      "$HasKey|DD,$Has|W4,$Has|WP,$Has|BP",
      "$HasKey|DD,$Has|W4,$Has|WP,^$SB",
    },
  }

  return EvaluateAccessRules(cave_access[cave])
end

function EvaluateAccessRules(rules)
  if rules == nil then
    return false
  end

  if type(rules) == "string" then
    return EvaluateRuleRoute(rules)
  end

  for _, route in ipairs(rules) do
    local result = EvaluateRuleRoute(route)

    if result == true then
      return true
    elseif result == AccessibilityLevel.SequenceBreak then
      return AccessibilityLevel.SequenceBreak
    end
  end

  return false
end

function EvaluateRuleRoute(route)
  local is_sequence_break = false

  for rule in string.gmatch(route, "([^,]+)") do
    if rule == "^$SB" then
      is_sequence_break = true
    elseif string.sub(rule, 1, 8) == "$HasKey|" then
      local key = string.sub(rule, 9)
      if not HasKey(key) then
        return false
      end
    elseif string.sub(rule, 1, 5) == "$Has|" then
      local item = string.sub(rule, 6)
      if not Has(item) then
        return false
      end
    end
  end

  if is_sequence_break then
    return AccessibilityLevel.SequenceBreak
  end

  return true
end

function CheckBuried(location)
  if Has("WP") or SLOT_DATA["buried_treasure_locations"] == nil then
    return true
  end

  for _, treasure in pairs(SLOT_DATA["buried_treasure_locations"]) do
    if location == treasure[2] then
      return false
    end
  end
  return true
end

function IsSublevel(cave, level, result)
  if SLOT_DATA["sublevels"] ~= nil then
    return SLOT_DATA["sublevels"][cave][tonumber(level)] == tonumber(result) - 1
  else
    return level == result
  end
end
