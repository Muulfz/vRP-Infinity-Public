
-- module describing business system (company, money laundering)

local cfg = module("cfg/business")


vRP.prepare("vRP/create_business","INSERT IGNORE INTO vrp_user_business(user_id,name,description,capital,laundered,reset_timestamp) VALUES(@user_id,@name,'',@capital,0,@time)")
vRP.prepare("vRP/delete_business","DELETE FROM vrp_user_business WHERE user_id = @user_id")
vRP.prepare("vRP/get_business","SELECT name,description,capital,laundered,reset_timestamp FROM vrp_user_business WHERE user_id = @user_id")
vRP.prepare("vRP/add_capital","UPDATE vrp_user_business SET capital = capital + @capital WHERE user_id = @user_id")
vRP.prepare("vRP/add_laundered","UPDATE vrp_user_business SET laundered = laundered + @laundered WHERE user_id = @user_id")
vRP.prepare("vRP/get_business_page","SELECT user_id,name,description,capital FROM vrp_user_business ORDER BY capital DESC LIMIT @b,@n")
vRP.prepare("vRP/reset_transfer","UPDATE vrp_user_business SET laundered = 0, reset_timestamp = @time WHERE user_id = @user_id")


-- api

-- return user business data or nil
function vRP.getUserBusiness(user_id, cbr)
  if user_id then
    local rows = vRP.query("vRP/get_business", {user_id = user_id})
    local business = rows[1]

    -- when a business is fetched from the database, check for update of the laundered capital transfer capacity
    if business and os.time() >= business.reset_timestamp+cfg.transfer_reset_interval*60 then
      vRP.execute("vRP/reset_transfer", {user_id = user_id, time = os.time()})
      business.laundered = 0
    end

    return business
  end
end

-- close the business of an user
function vRP.closeBusiness(user_id)
  vRP.execute("vRP/delete_business", {user_id = user_id})
end
