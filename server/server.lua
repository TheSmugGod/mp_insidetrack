ESX = exports["es_extended"]:getSharedObject()
-- Don't edit this file
local neededGameBuild = 2060
local currentGameBuild = GetConvarInt('sv_enforceGameBuild', 1604)

Citizen.CreateThread(function()
    if (currentGameBuild < neededGameBuild) then
        print('^3['..GetCurrentResourceName()..']^0: You need to use ^3' .. neededGameBuild .. '^0 game build (or above) to use this resource.')
    end
end)

RegisterServerEvent('mp_insidetrack:joint', function (value)
    local source = source -- Change Source from a global to a local to ensure it does not change
    local xPlayer = ESX.GetPlayerFromId(source) -- Get the Player Object
    xPlayer.addMoney(value)
end)

--[[
RegisterServerEvent('mp_insidetrack:checkbal')
AddEventHandler('mp_insidetrack:checkbal', function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local PlayerMoney = xPlayer.getMoney()
    if PlayerMoney > 0 then
    TriggerClientEvent('mp_insidetrack:updatebal', source, PlayerMoney)
    end
end)
]]

RegisterCommand('load_track', function(source, args)
    local amount = tonumber(args[1])
   local source = source
   local xPlayer = ESX.GetPlayerFromId(source)
   local PlayerMoney = xPlayer.getMoney()
   if PlayerMoney > amount then 
    TriggerClientEvent('mp_insidetrack:updatebal', source, amount)
    xPlayer.removeMoney(amount)
   end
end, false)
