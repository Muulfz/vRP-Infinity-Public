function vRP.admin_coords(user_id)
    if user_id and vRP.hasPermission(user_id, permissions.player.coords) then
        return vRPclient.getPosition(user_id)
    end
end

function vRP.admin_kick(user_id, target_id, reason)
    if user_id and vRP.hasPermission(parseInt(user_id), permissions.player.kick) then
        local source_id = vRP.getUserSource(parseInt(target_id))
        if source_id then
            vRP.kick(source_id, reason)
            return true
        end
    end
    return false
end

function vRP.admin_revive(user_id, target_id)
    if user_id and vRP.hasPermission(parseInt(user_id), permissions.player.revive) then
        local playersToRevive = {}
        local allPlayerTag = "-1"

        if target_id then
            if target_id ~= allPlayerTag then
                table.insert(playersToRevive, target_id)
            else
                playersToRevive = vRP.getUsers()
            end
        else
            table.insert(playersToRevive, user_id)
        end

        vRP.admin_revive_bulk(playersToRevive)
        return true
    end
    return false
end

function vRP.admin_revive_bulk(listOfUsers)
    local life = 400
    for k, v in pairs(listOfUsers) do
        local ids = vRP.getUserSource(k)
        if ids then
            vRPclient.setHealth(ids, life)
        end
    end
end

function vRP.admin_no_clip(user_id, target_id)
    if user_id and vRP.hasPermission(parseInt(user_id), permissions.player.noclip) then
        local noClipUser = user_id
        if target_id then
            noClipUser = target_id
        end

        vRPclient._toggleNoclip(vRP.getUserSource(noClipUser))
    end
end

function vRP.admin_whitelist(user_id, target_id)
    if user_id and vRP.hasPermission(user_id, permissions.admin.whitelist) then
        vRP.setWhitelisted(target_id, true)
        return true
    end
    return false
end

function vRP.admin_un_whitelist(user_id, target_id)
    if user_id and vRP.hasPermission(user_id, permissions.admin.unwhitelist) then
        vRP.setWhitelisted(target_id, false)
        return true
    end
    return false
end

function vRP.admin_remove_group(user_id, target_id, group)
    if user_id and vRP.hasPermission(user_id, permissions.admin.group_remove) then
        if group then
            vRP.removeUserGroup(target_id, group)
            return true
        end
    end
    return false
end


