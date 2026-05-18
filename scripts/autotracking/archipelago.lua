require("scripts/autotracking/item_mapping")
require("scripts/autotracking/location_mapping")

CUR_INDEX = -1
SLOT_DATA = {}

function dump_table(o, depth)
  if depth == nil then
    depth = 0
  end
  if type(o) == 'table' then
    local tabs = ('\t'):rep(depth)
    local tabs2 = ('\t'):rep(depth + 1)
    local s = '{\n'
    for k, v in pairs(o) do
      if type(k) ~= 'number' then
        k = '"' .. k .. '"'
      end
      s = s .. tabs2 .. '[' .. k .. '] = ' .. dump_table(v, depth + 1) .. ',\n'
    end
    return s .. tabs .. '}'
  else
    return tostring(o)
  end
end

function OnClear(slot_data)
  CUR_INDEX = -1
  SLOT_DATA = slot_data

  if SLOT_DATA["progressive_globes"] == 1 then
    Tracker:FindObjectForCode("setting_prog_globes").CurrentStage = 1
  else
    Tracker:FindObjectForCode("setting_prog_globes").CurrentStage = 0
  end

  Tracker:FindObjectForCode("debt_tenthousand").CurrentStage = math.floor(SLOT_DATA["debt"] / 10000) % 10
  Tracker:FindObjectForCode("debt_thousand").CurrentStage = math.floor(SLOT_DATA["debt"] / 1000) % 10
  Tracker:FindObjectForCode("debt_hundred").CurrentStage = math.floor(SLOT_DATA["debt"] / 100) % 10
  Tracker:FindObjectForCode("debt_ten").CurrentStage = math.floor(SLOT_DATA["debt"] / 10) % 10
  Tracker:FindObjectForCode("debt_one").CurrentStage = SLOT_DATA["debt"] % 10

  local starting_onion_id = 0
  local onions_in_pool = false
  for area, color in pairs(SLOT_DATA["onion_locations"]) do
    if area == "VoR" then
      local pikmin = {
        red = 0,
        yellow = 1,
        blue = 2
      }
      starting_onion_id = pikmin[color]
    end
    if color == "none" then
      onions_in_pool = true
    end
  end

  -- reset locations
  for _, location in pairs(LOCATION_MAPPING) do
    if location[1] then
      local obj = Tracker:FindObjectForCode(location[1])
      if obj then
        if location[1]:sub(1, 1) == "@" then
          obj.AvailableChestCount = obj.ChestCount
        else
          obj.Active = false
        end
      elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
        print(string.format("onClear: could not find location obj for code %s", location[1]))
      end
    end
  end
  -- reset items
  for _, item in pairs(ITEM_MAPPING) do
    if item[1] and item[2] then
      -- don't reset onions if not in pool
      if onions_in_pool or (item[1] ~= "redonion" and item[1] ~= "yellowonion" and item[1] ~= "blueonion") then
        local obj = Tracker:FindObjectForCode(item[1])
        if obj then
          if item[2] == "toggle" then
            obj.Active = false
          elseif item[2] == "progressive" then
            obj.CurrentStage = 0
            obj.Active = false
          elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
            print(string.format("onClear: unknown item type %s for code %s", item[2], item[1]))
          end
        elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
          print(string.format("onClear: could not find item obj for code %s", item[1]))
        end
      end
    end
  end

  -- Purple pikmin always available in VoR
  Tracker:FindObjectForCode("purpleonion").Active = true

  -- White pikmin always available in AW
  if Has("W2") then
    Tracker:FindObjectForCode("whiteonion").Active = true
  end

  if starting_onion_id == 0 then
    Tracker:FindObjectForCode("redonion").Active = true
  elseif starting_onion_id == 1 then
    Tracker:FindObjectForCode("yellowonion").Active = true
  elseif starting_onion_id == 2 then
    Tracker:FindObjectForCode("blueonion").Active = true
  end

  if SLOT_DATA["cave_keys"] == 0 then
    Tracker:FindObjectForCode("ecentrancekey").Active = true
    Tracker:FindObjectForCode("scentrancekey").Active = true
    Tracker:FindObjectForCode("fcentrancekey").Active = true
    Tracker:FindObjectForCode("hobentrancekey").Active = true
    Tracker:FindObjectForCode("wfgentrancekey").Active = true
    Tracker:FindObjectForCode("bkentrancekey").Active = true
    Tracker:FindObjectForCode("shentrancekey").Active = true
    Tracker:FindObjectForCode("cosentrancekey").Active = true
    Tracker:FindObjectForCode("gkentrancekey").Active = true
    Tracker:FindObjectForCode("srentrancekey").Active = true
    Tracker:FindObjectForCode("smgcentrancekey").Active = true
    Tracker:FindObjectForCode("cocentrancekey").Active = true
    Tracker:FindObjectForCode("hohentrancekey").Active = true
    Tracker:FindObjectForCode("ddentrancekey").Active = true
  end

  if SLOT_DATA["weapons_in_pool"] == 1 then
    Tracker:FindObjectForCode("loc_comedybomb").Active = true
    Tracker:FindObjectForCode("loc_flarecannon").Active = true
    Tracker:FindObjectForCode("loc_monsterpump").Active = true
    Tracker:FindObjectForCode("loc_shocktherapist").Active = true
  end

  UpdateCaveAccess()
  UpdatePokos()
  UpdateTreasureCount()
end

function OnItem(index, item_id, item_name, player_number)
  if index <= CUR_INDEX then
    return
  end
  CUR_INDEX = index;
  local item = ITEM_MAPPING[item_id]
  if item == nil then
    print(string.format("onItem: could not find mapping for item %s", item_id))
  else
    local obj = Tracker:FindObjectForCode(item[1])
    if obj then
      if obj.Type == "toggle" then
        obj.Active = true
      end

      if Has("W2") then
        Tracker:FindObjectForCode("whiteonion").Active = true
      end
    else
      print(string.format("onItem: could not find object for code %s", item[1]))
    end
  end

  UpdateCaveAccess()
  UpdatePokos()
  UpdateTreasureCount()
end

function OnLocation(location_id, location_name)
  local location = LOCATION_MAPPING[location_id]
  if not location or not location[1] then
    print(string.format("onLocation: could not find location mapping for id %s", location_id))
    return
  end

  local obj = Tracker:FindObjectForCode(location[1])
  if obj then
    if location[1]:sub(1, 1) == "@" then
      obj.AvailableChestCount = obj.AvailableChestCount - 1
    else
      obj.Active = true
    end
  else
    print(string.format("onLocation: could not find object for code %s", location[1]))
  end
end

function UpdateCaveAccess()
  for cave_in, cave_out in pairs(SLOT_DATA["caves"]) do
    local caves = {
      EC = 1,
      SC = 2,
      FC = 3,
      HoB = 4,
      WFG = 5,
      BK = 6,
      SH = 7,
      CoS = 8,
      GK = 9,
      SR = 10,
      SMGC = 11,
      CoC = 12,
      HoH = 13,
      DD = 14,
    }
    if CanAccess(cave_in) then
      Tracker:FindObjectForCode(cave_in .. "_dst").CurrentStage = caves[cave_out]
    else
      Tracker:FindObjectForCode(cave_in .. "_dst").CurrentStage = 0
    end
  end
end

function UpdatePokos()
  local current_pokos = CountPokos()
  local digits = { 0, 0, 0, 0, 0 }
  local pokos_codes = {
    "pokos_tenthousand",
    "pokos_thousand",
    "pokos_hundred",
    "pokos_ten",
    "pokos_one"
  }

  digits[1] = math.floor(current_pokos / 10000) % 10
  digits[2] = math.floor(current_pokos / 1000) % 10
  digits[3] = math.floor(current_pokos / 100) % 10
  digits[4] = math.floor(current_pokos / 10) % 10
  digits[5] = current_pokos % 10

  for k, v in pairs(pokos_codes) do
    Tracker:FindObjectForCode(v).CurrentStage = digits[k]
  end
end

function UpdateTreasureCount()
  local current_treasures = CountTreasures(SLOT_DATA["onion_locations"], SLOT_DATA["cave_keys"] == 0)
  local digits = { 0, 0, 0 }
  local treasures_codes = {
    "treasures_hundred",
    "treasures_ten",
    "treasures_one"
  }

  digits[1] = math.floor(current_treasures / 100) % 10
  digits[2] = math.floor(current_treasures / 10) % 10
  digits[3] = current_treasures % 10

  for k, v in pairs(treasures_codes) do
    Tracker:FindObjectForCode(v).CurrentStage = digits[k]
  end
end

Archipelago:AddClearHandler("clear handler", OnClear)
Archipelago:AddItemHandler("item handler", OnItem)
Archipelago:AddLocationHandler("location handler", OnLocation)
