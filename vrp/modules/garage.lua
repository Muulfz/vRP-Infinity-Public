-- a basic garage implementation

vRP.prepare("vRP/add_vehicle","INSERT IGNORE INTO vrp_user_vehicles(user_id,vehicle) VALUES(@user_id,@vehicle)")
vRP.prepare("vRP/remove_vehicle","DELETE FROM vrp_user_vehicles WHERE user_id = @user_id AND vehicle = @vehicle")
vRP.prepare("vRP/get_vehicles","SELECT vehicle FROM vrp_user_vehicles WHERE user_id = @user_id")
vRP.prepare("vRP/get_vehicle","SELECT vehicle FROM vrp_user_vehicles WHERE user_id = @user_id AND vehicle = @vehicle")


-- load config

local Tools = module("vrp","lib/Tools")
local cfg = module("cfg/garages")


-- repair nearest vehicle
function vRP.vehicle_repair_nearest(player,choice)
  local user_id = vRP.getUserId(player)
  if user_id then
    -- anim and repair
    if vRP.tryGetInventoryItem(user_id,"repairkit",1,true) then
      vRPclient._playAnim(player,false,{task="WORLD_HUMAN_WELDING"},false)
      SetTimeout(15000, function()
        vRPclient._fixeNearestVehicle(player,7)
        vRPclient._stopAnim(player,false)
      end)
    end
  end
end

-- replace nearest vehicle
function vRP.vehicle_replace_nearest(player,choice)
  vRPclient._replaceNearestVehicle(player,7)
end
