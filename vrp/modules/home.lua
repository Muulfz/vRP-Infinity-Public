
-- this module describe the home system (experimental, a lot can happen and not being handled)

local lang = vRP.lang
local cfg = module("cfg/homes")



vRP.prepare("vRP/get_address","SELECT home, number FROM vrp_user_homes WHERE user_id = @user_id")
vRP.prepare("vRP/get_home_owner","SELECT user_id FROM vrp_user_homes WHERE home = @home AND number = @number")
vRP.prepare("vRP/rm_address","DELETE FROM vrp_user_homes WHERE user_id = @user_id")
vRP.prepare("vRP/set_address","REPLACE INTO vrp_user_homes(user_id,home,number) VALUES(@user_id,@home,@number)")


-- api

local components = {}

-- return user address (home and number) or nil
function vRP.getUserAddress(user_id, cbr)
  local rows = vRP.query("vRP/get_address", {user_id = user_id})
  return rows[1]
end

-- set user address
function vRP.setUserAddress(user_id,home,number)
  vRP.execute("vRP/set_address", {user_id = user_id, home = home, number = number})
end

-- remove user address
function vRP.removeUserAddress(user_id)
  vRP.execute("vRP/rm_address", {user_id = user_id})
end

-- return user_id or nil
function vRP.getUserByAddress(home,number,cbr)
  local rows = vRP.query("vRP/get_home_owner", {home = home, number = number})
  if #rows > 0 then
    return rows[1].user_id
  end
end

-- find a free address number to buy
-- return number or nil if no numbers availables
function vRP.findFreeNumber(home,max,cbr)
  local i = 1
  while i <= max do
    if not vRP.getUserByAddress(home,i) then
      return i
    end
    i = i+1
  end
end

-- define home component (oncreate and ondestroy are called for each player entering/leaving a slot)
-- name: unique component id
-- oncreate(owner_id, slot_type, slot_id, cid, config, data, x, y, z, player)
-- ondestroy(owner_id, slot_type, slot_id, cid, config, data, x, y, z, player)
--- owner_id: user_id of house owner
--- slot_type: slot type name
--- slot_id: slot id for a specific type
--- cid: component id (for this slot)
--- config: component config
--- data: component datatable
--- x,y,z: component position
--- player: player joining/leaving the slot
function vRP.defHomeComponent(name, oncreate, ondestroy)
  components[name] = {oncreate,ondestroy}
end

function vRP.getHomeSlotPlayers(stype, sid)
end

-- SLOTS

-- used (or not) slots
local uslots = {}
for k,v in pairs(cfg.slot_types) do
  uslots[k] = {}
  for l,w in pairs(v) do
    uslots[k][l] = {used=false}
  end
end

-- get players in the specified home slot
-- return map of user_id -> player source or nil if the slot is unavailable
function vRP.getHomeSlotPlayers(stype, sid)
  local slot = uslots[stype][sid]
  if slot and slot.used then
    return slot.players
  end
end

-- return slot id or nil if no slot available
local function allocateSlot(stype)
  local slots = cfg.slot_types[stype]
  if slots then
    local _uslots = uslots[stype]
    -- search the first unused slot
    for k,v in pairs(slots) do
      if _uslots[k] and not _uslots[k].used then
        _uslots[k].used = true -- set as used
        return k  -- return slot id
      end
    end
  end

  return nil
end

-- free a slot
local function freeSlot(stype, id)
  local slots = cfg.slot_types[stype]
  if slots then
    uslots[stype][id] = {used = false} -- reset as unused
  end
end

-- get in use address slot (not very optimized yet)
-- return slot_type, slot_id or nil,nil
local function getAddressSlot(home_name,number)
  for k,v in pairs(uslots) do
    for l,w in pairs(v) do
      if w.home_name == home_name and tostring(w.home_number) == tostring(number) then
        return k,l
      end
    end
  end

  return nil,nil
end

-- builds

local function is_empty(table)
  for k,v in pairs(table) do
    return false
  end

  return true
end

-- access a home by address
-- return true on success
function vRP.accessHome(user_id, home, number)
  local _home = cfg.homes[home]
  local stype,slotid = getAddressSlot(home,number) -- get current address slot
  local player = vRP.getUserSource(user_id)

  local owner_id = vRP.getUserByAddress(home,number)
  if _home ~= nil and player ~= nil then
    if stype == nil then -- allocate a new slot
      stype = _home.slot
      slotid = allocateSlot(_home.slot)

      if slotid ~= nil then -- allocated, set slot home infos
        local slot = uslots[stype][slotid]
        slot.home_name = home
        slot.home_number = number
        slot.owner_id = owner_id
        slot.players = {} -- map user_id => player
        slot.components = {} -- components data
      end
    end

    if slotid ~= nil then -- slot available
      enter_slot(user_id,player,stype,slotid)
      return true
    end
  end
end
