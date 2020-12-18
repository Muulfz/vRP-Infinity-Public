-- this module define the emotes menu

local cfg = module("cfg/emotes")
local lang = vRP.lang

local emotes = cfg.emotes

function vRP.play_emote(player, name)
    local emote = emotes[name]
    if emote then
        vRPclient._playAnim(player, emote[1], emote[2], emote[3])
    end
end

function vRP.player_stop_animations(player)
    vRPclient._stopAnim(player, true) -- upper
    vRPclient._stopAnim(player, false) -- full
end

