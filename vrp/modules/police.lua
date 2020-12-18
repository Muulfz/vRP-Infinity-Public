
-- this module define some police tools and functions
local lang = vRP.lang
local cfg = module("cfg/police")

-- police records

-- insert a police record for a specific user
--- line: text for one line (can be html)
function vRP.insertPoliceRecord(user_id, line)
  if user_id then
    local data = vRP.getUData(user_id, "vRP:police_records")
    local records = data..line.."<br />"
    vRP.setUData(user_id, "vRP:police_records", records)
  end
end

-- search identity by registration
function vRP.police_search_reg(player)
  local reg = vRP.prompt(player,lang.police.pc.searchreg.prompt(),"")
  local user_id = vRP.getUserByRegistration(reg)
  if user_id then
    local identity = vRP.getUserIdentity(user_id)
    if identity then
      -- display identity and business
      local name = identity.name
      local firstname = identity.firstname
      local age = identity.age
      local phone = identity.phone
      local registration = identity.registration
      local bname = ""
      local bcapital = 0
      local home = ""
      local number = ""

      local business = vRP.getUserBusiness(user_id)
      if business then
        bname = business.name
        bcapital = business.capital
      end

      local address = vRP.getUserAddress(user_id)
      if address then
        home = address.home
        number = address.number
      end

      local content = lang.police.identity.info({name,firstname,age,registration,phone,bname,bcapital,home,number})
      vRPclient._setDiv(player,"police_pc",".div_police_pc{ background-color: rgba(0,0,0,0.75); color: white; font-weight: bold; width: 500px; padding: 10px; margin: auto; margin-top: 150px; }",content)
    else
      vRPclient._notify(player,lang.common.not_found())
    end
  else
    vRPclient._notify(player,lang.common.not_found())
  end
end

-- show police records by registration
function vRP.show_police_records(player)
  local reg = vRP.prompt(player,lang.police.pc.searchreg.prompt(),"")
  local user_id = vRP.getUserByRegistration(reg)
  if user_id then
    local content = vRP.getUData(user_id, "vRP:police_records")
    vRPclient._setDiv(player,"police_pc",".div_police_pc{ background-color: rgba(0,0,0,0.75); color: white; font-weight: bold; width: 500px; padding: 10px; margin: auto; margin-top: 150px; }",content)
  else
    vRPclient._notify(player,lang.common.not_found())
  end
end

-- delete police records by registration
function vRP.delete_police_records(player)
  local reg = vRP.prompt(player,lang.police.pc.searchreg.prompt(),"")
  local user_id = vRP.getUserByRegistration(reg)
  if user_id then
    vRP.setUData(user_id, "vRP:police_records", "")
    vRPclient._notify(player,lang.police.pc.records.delete.deleted())
  else
    vRPclient._notify(player,lang.common.not_found())
  end
end

-- close business of an arrested owner
function vRP.police_close_business(player)
  local nplayer = vRPclient.getNearestPlayer(player,5)
  local nuser_id = vRP.getUserId(nplayer)
  if nuser_id then
    local identity = vRP.getUserIdentity(nuser_id)
    local business = vRP.getUserBusiness(nuser_id)
    if identity and business then
      if vRP.request(player,lang.police.pc.closebusiness.request({identity.name,identity.firstname,business.name}),15) then
        vRP.closeBusiness(nuser_id)
        vRPclient._notify(player,lang.police.pc.closebusiness.closed())
      end
    else
      vRPclient._notify(player,lang.common.no_player_near())
    end
  else
    vRPclient._notify(player,lang.common.no_player_near())
  end
end

-- track vehicle
function vRP.police_track_vehicle(player)
  local reg = vRP.prompt(player,lang.police.pc.trackveh.prompt_reg(),"")
  local user_id = vRP.getUserByRegistration(reg)
  if user_id then
    local note = vRP.prompt(player,lang.police.pc.trackveh.prompt_note(),"")
    -- begin veh tracking
    vRPclient._notify(player,lang.police.pc.trackveh.tracking())
    local seconds = math.random(cfg.trackveh.min_time,cfg.trackveh.max_time)
    SetTimeout(seconds*1000,function()
      local tplayer = vRP.getUserSource(user_id)
      if tplayer then
        local ok,x,y,z = vRPclient.getAnyOwnedVehiclePosition(tplayer)
        if ok then -- track success
          vRP.sendServiceAlert(nil, cfg.trackveh.service,x,y,z,lang.police.pc.trackveh.tracked({reg,note}))
        else
          vRPclient._notify(player,lang.police.pc.trackveh.track_failed({reg,note})) -- failed
        end
      else
        vRPclient._notify(player,lang.police.pc.trackveh.track_failed({reg,note})) -- failed
      end
    end)
  else
    vRPclient._notify(player,lang.common.not_found())
  end
end

--TODO: add commands
---- handcuff
function vRP.police_handcuff(player,choice)
  local nplayer = vRPclient.getNearestPlayer(player,10)
  if nplayer then
    local nuser_id = vRP.getUserId(nplayer)
    if nuser_id then
      vRPclient._toggleHandcuff(nplayer)
    else
      vRPclient._notify(player,lang.common.no_player_near())
    end
  end
end

---- drag
function vRP.police_drag(player)
  local nplayer = vRPclient.getNearestPlayer(player,10)
  if nplayer then
    local nuser_id = vRP.getUserId(nplayer)
    if nuser_id then
      local followed = vRPclient.getFollowedPlayer(nplayer)
      if followed ~= player then -- drag
        vRPclient._followPlayer(nplayer, player)
      else -- stop follow
        vRPclient._followPlayer(nplayer)
      end
    else
      vRPclient._notify(player,lang.common.no_player_near())
    end
  end
end

function vRP.police_put_in_vehicle(player)
  local nplayer = vRPclient.getNearestPlayer(player,10)
  local nuser_id = vRP.getUserId(nplayer)
  if nuser_id then
    if vRPclient.isHandcuffed(nplayer) then  -- check handcuffed
      vRPclient._putInNearestVehicleAsPassenger(nplayer, 5)
    else
      vRPclient._notify(player,lang.police.not_handcuffed())
    end
  else
    vRPclient._notify(player,lang.common.no_player_near())
  end
end

function vRP.police_get_out_veh(player)
  local nplayer = vRPclient.getNearestPlayer(player,10)
  local nuser_id = vRP.getUserId(nplayer)
  if nuser_id then
    if vRPclient.isHandcuffed(nplayer) then  -- check handcuffed
      vRPclient._ejectVehicle(nplayer)
    else
      vRPclient._notify(player,lang.police.not_handcuffed())
    end
  else
    vRPclient._notify(player,lang.common.no_player_near())
  end
end

---- askid
function vRP.police_askid(player,choice)
  local nplayer = vRPclient.getNearestPlayer(player,10)
  local nuser_id = vRP.getUserId(nplayer)
  if nuser_id then
    vRPclient._notify(player,lang.police.menu.askid.asked())
    if vRP.request(nplayer,lang.police.menu.askid.request(),15) then
      local identity = vRP.getUserIdentity(nuser_id)
      if identity then
        -- display identity and business
        local name = identity.name
        local firstname = identity.firstname
        local age = identity.age
        local phone = identity.phone
        local registration = identity.registration
        local bname = ""
        local bcapital = 0
        local home = ""
        local number = ""

        local business = vRP.getUserBusiness(nuser_id)
        if business then
          bname = business.name
          bcapital = business.capital
        end

        local address = vRP.getUserAddress(nuser_id)
        if address then
          home = address.home
          number = address.number
        end

        local content = lang.police.identity.info({name,firstname,age,registration,phone,bname,bcapital,home,number})
        vRPclient._setDiv(player,"police_identity",".div_police_identity{ background-color: rgba(0,0,0,0.75); color: white; font-weight: bold; width: 500px; padding: 10px; margin: auto; margin-top: 150px; }",content)
        -- request to hide div
        vRP.request(player, lang.police.menu.askid.request_hide(), 1000)
        vRPclient._removeDiv(player,"police_identity")
      end
    else
      vRPclient._notify(player,lang.common.request_refused())
    end
  else
    vRPclient._notify(player,lang.common.no_player_near())
  end
end

---- police check
function vRP.police_check(player,choice)
  local nplayer = vRPclient.getNearestPlayer(player,5)
  local nuser_id = vRP.getUserId(nplayer)
  if nuser_id then
    vRPclient._notify(nplayer,lang.police.menu.check.checked())
    local weapons = vRPclient.getWeapons(nplayer)
    -- prepare display data (money, items, weapons)
    local money = vRP.getMoney(nuser_id)
    local items = ""
    local data = vRP.getUserDataTable(nuser_id)
    if data and data.inventory then
      for k,v in pairs(data.inventory) do
        local item_name, item_desc, item_weight = vRP.getItemDefinition(k)
        if item_name then
          items = items.."<br />"..item_name.." ("..v.amount..")"
        end
      end
    end

    local weapons_info = ""
    for k,v in pairs(weapons) do
      weapons_info = weapons_info.."<br />"..k.." ("..v.ammo..")"
    end

    vRPclient._setDiv(player,"police_check",".div_police_check{ background-color: rgba(0,0,0,0.75); color: white; font-weight: bold; width: 500px; padding: 10px; margin: auto; margin-top: 150px; }",lang.police.menu.check.info({money,items,weapons_info}))
    -- request to hide div
    vRP.request(player, lang.police.menu.check.request_hide(), 1000)
    vRPclient._removeDiv(player,"police_check")
  else
    vRPclient._notify(player,lang.common.no_player_near())
  end
end

function vRP.police_seize_weapons(player, choice)
  local user_id = vRP.getUserId(player)
  if user_id then
    local nplayer = vRPclient.getNearestPlayer(player, 5)
    local nuser_id = vRP.getUserId(nplayer)
    if nuser_id and vRP.hasPermission(nuser_id, "police.seizable") then
      if vRPclient.isHandcuffed(nplayer) then  -- check handcuffed
        local weapons = vRPclient.replaceWeapons(nplayer, {})
        for k,v in pairs(weapons) do -- display seized weapons
          -- vRPclient._notify(player,lang.police.menu.seize.seized({k,v.ammo}))
          -- convert weapons to parametric weapon items
          vRP.giveInventoryItem(user_id, "wbody|"..k, 1, true)
          if v.ammo > 0 then
            vRP.giveInventoryItem(user_id, "wammo|"..k, v.ammo, true)
          end
        end

        vRPclient._notify(nplayer,lang.police.menu.seize.weapons.seized())
      else
        vRPclient._notify(player,lang.police.not_handcuffed())
      end
    else
      vRPclient._notify(player,lang.common.no_player_near())
    end
  end
end

function vRP.police_seize_items(player, choice)
  local user_id = vRP.getUserId(player)
  if user_id then
    local nplayer = vRPclient.getNearestPlayer(player, 5)
    local nuser_id = vRP.getUserId(nplayer)
    if nuser_id and vRP.hasPermission(nuser_id, "police.seizable") then
      if vRPclient.isHandcuffed(nplayer) then  -- check handcuffed
        local inv = vRP.getInventory(user_id)

        for k,v in pairs(cfg.seizable_items) do -- transfer seizable items
          local sub_items = {v} -- single item

          if string.sub(v,1,1) == "*" then -- seize all parametric items of this idname
            local idname = string.sub(v,2)
            sub_items = {}
            for fidname,_ in pairs(inv) do
              if splitString(fidname, "|")[1] == idname then -- same parametric item
                table.insert(sub_items, fidname) -- add full idname
              end
            end
          end

          for _,idname in pairs(sub_items) do
            local amount = vRP.getInventoryItemAmount(nuser_id,idname)
            if amount > 0 then
              local item_name, item_desc, item_weight = vRP.getItemDefinition(idname)
              if item_name then -- do transfer
                if vRP.tryGetInventoryItem(nuser_id,idname,amount,true) then
                  vRP.giveInventoryItem(user_id,idname,amount,false)
                  vRPclient._notify(player,lang.police.menu.seize.seized({item_name,amount}))
                end
              end
            end
          end
        end

        vRPclient._notify(nplayer,lang.police.menu.seize.items.seized())
      else
        vRPclient._notify(player,lang.police.not_handcuffed())
      end
    else
      vRPclient._notify(player,lang.common.no_player_near())
    end
  end
end

-- toggle jail nearest player
function vRP.police_jail(player, choice)
  local user_id = vRP.getUserId(player)
  if user_id then
    local nplayer = vRPclient.getNearestPlayer(player, 5)
    local nuser_id = vRP.getUserId(nplayer)
    if nuser_id then
      if vRPclient.isJailed(nplayer) then
        vRPclient._unjail(nplayer)
        vRPclient._notify(nplayer,lang.police.menu.jail.notify_unjailed())
        vRPclient._notify(player,lang.police.menu.jail.unjailed())
      else -- find the nearest jail
        local x,y,z = vRPclient.getPosition(nplayer)
        local d_min = 1000
        local v_min = nil
        for k,v in pairs(cfg.jails) do
          local dx,dy,dz = x-v[1],y-v[2],z-v[3]
          local dist = math.sqrt(dx*dx+dy*dy+dz*dz)

          if dist <= d_min and dist <= 15 then -- limit the research to 15 meters
            d_min = dist
            v_min = v
          end

          -- jail
          if v_min then
            vRPclient._jail(nplayer,v_min[1],v_min[2],v_min[3],v_min[4])
            vRPclient._notify(nplayer,lang.police.menu.jail.notify_jailed())
            vRPclient._notify(player,lang.police.menu.jail.jailed())
          else
            vRPclient._notify(player,lang.police.menu.jail.not_found())
          end
        end
      end
    else
      vRPclient._notify(player,lang.common.no_player_near())
    end
  end
end

function vRP.police_fine(player, choice)
  local user_id = vRP.getUserId(player)
  if user_id then
    local nplayer = vRPclient.getNearestPlayer(player, 5)
    local nuser_id = vRP.getUserId(nplayer)
    if nuser_id then
      local money = vRP.getMoney(nuser_id)+vRP.getBankMoney(nuser_id)

      -- build fine menu
      local menu = {name=lang.police.menu.fine.title(),css={top="75px",header_color="rgba(0,125,255,0.75)"}}

      local choose = function(player,choice) -- fine action
        local amount = cfg.fines[choice]
        if amount ~= nil then
          if vRP.tryFullPayment(nuser_id, amount) then
            vRP.insertPoliceRecord(nuser_id, lang.police.menu.fine.record({choice,amount}))
            vRPclient._notify(player,lang.police.menu.fine.fined({choice,amount}))
            vRPclient._notify(nplayer,lang.police.menu.fine.notify_fined({choice,amount}))
            vRP.closeMenu(player)
          else
            vRPclient._notify(player,lang.money.not_enough())
          end
        end
      end

      for k,v in pairs(cfg.fines) do -- add fines in function of money available
        if v <= money then
          menu[k] = {choose,v}
        end
      end

      -- open menu
      vRP.openMenu(player, menu)
    else
      vRPclient._notify(player,lang.common.no_player_near())
    end
  end
end

function vRP.police_store_weapons(player, choice)
  local user_id = vRP.getUserId(player)
  if user_id then
    local weapons = vRPclient.replaceWeapons(player, {})
    for k,v in pairs(weapons) do
      -- convert weapons to parametric weapon items
      vRP.giveInventoryItem(user_id, "wbody|"..k, 1, true)
      if v.ammo > 0 then
        vRP.giveInventoryItem(user_id, "wammo|"..k, v.ammo, true)
      end
    end
  end
end

-- WANTED SYNC

local wantedlvl_players = {}

function vRP.getUserWantedLevel(user_id)
  return wantedlvl_players[user_id] or 0
end

-- receive wanted level
function tvRP.updateWantedLevel(level)
  local player = source
  local user_id = vRP.getUserId(player)
  if user_id then
    local was_wanted = (vRP.getUserWantedLevel(user_id) > 0)
    wantedlvl_players[user_id] = level
    local is_wanted = (level > 0)

    -- send wanted to listening service
    if not was_wanted and is_wanted then
      local x,y,z = vRPclient.getPosition(player)
      vRP.sendServiceAlert(nil, cfg.wanted.service,x,y,z,lang.police.wanted({level}))
    end

    if was_wanted and not is_wanted then
      vRPclient._removeNamedBlip(-1, "vRP:wanted:"..user_id) -- remove wanted blip (all to prevent phantom blip)
    end
  end
end

-- delete wanted entry on leave
AddEventHandler("vRP:playerLeave", function(user_id, player)
  wantedlvl_players[user_id] = nil
  vRPclient._removeNamedBlip(-1, "vRP:wanted:"..user_id)  -- remove wanted blip (all to prevent phantom blip)
end)

-- display wanted positions
local function task_wanted_positions()
  local listeners = vRP.getUsersByPermission("police.wanted")
  for k,v in pairs(wantedlvl_players) do -- each wanted player
    local player = vRP.getUserSource(tonumber(k))
    if player and v and v > 0 then
      local x,y,z = vRPclient.getPosition(player)
      for l,w in pairs(listeners) do -- each listening player
        local lplayer = vRP.getUserSource(w)
        if lplayer then
          vRPclient._setNamedBlip(lplayer, "vRP:wanted:"..k,x,y,z,cfg.wanted.blipid,cfg.wanted.blipcolor,lang.police.wanted({v}))
        end
      end
    end
  end
  SetTimeout(5000, task_wanted_positions)
end

async(function()
  task_wanted_positions()
end)
