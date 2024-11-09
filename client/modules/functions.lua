local HRLib <const> = HRLib --[[@as HRLibClientFunctions]]
local config <const>, functions <const> = HRLib.require('@HRComserv/config.lua') --[[@as HRComservConfig]], {}

functions.setClothes = function(targetPed)
    local resourceName = GetResourceState('illenium-appearance') == 'started' and 1 or GetResourceState('skinchanger') == 'started' and 2
    print(resourceName)
    if resourceName == 1 then
        exports['illenium-appearance']:setPedAppearance(targetPed, config.comservClothes)
    elseif resourceName == 2 then
        TriggerEvent('skinchanger:loadSkin', config.comservClothes)
    end
end

functions.getClothes = function()
    local resourceName = GetResourceState('illenium-appearance') == 'started' and 1 or GetResourceState('skinchanger') == 'started' and 2
    if resourceName == 1 then
        return json.encode(exports['illenium-appearance']:getPedAppearance(PlayerPedId()))
    elseif resourceName == 2 then
        local playerSkin

        TriggerEvent('skinchanger:getSkin', function(skin)
            playerSkin = skin
        end)

        return json.encode(playerSkin)
    end
end

---@param markerPosition vector4
functions.createMarker = function(markerPosition)
    CreateThread(function()
        while not RemoveMarkers do
            Wait(10)

            DrawMarker(config.tasksMarker.type, markerPosition.x, markerPosition.y, markerPosition.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, config.tasksMarker.colour.red, config.tasksMarker.colour.green, config.tasksMarker.colour.blue, config.tasksMarker.alpha, true, false, 2, false, nil, nil, false) ---@diagnostic disable-line: param-type-mismatch
        end
    end)
end

---@param taskType 'hammerFix'|'digging'|'sweeping'
---@param playerPosition vector4
functions.startTask = function(taskType, playerPosition)
    local playerPed <const>, anim <const>, dict <const> = PlayerPedId(), table.unpack(taskType == 'hammerFix' and {'base', 'amb@world_human_hammering@male@base'} or taskType == 'digging' and { 'world_human_gardener_plant' } or taskType == 'sweeping' and { 'idle_a', 'amb@world_human_janitor@male@idle_a' } or {})
    local tool

    SetEntityCoords(playerPed, playerPosition.x, playerPosition.y, playerPosition.z) ---@diagnostic disable-line: missing-parameter
    SetEntityHeading(playerPed, playerPosition.w)
    HRLib.RequestAnimDict(dict)

    if taskType == 'hammerFix' then
        TaskPlayAnim(playerPed, dict, anim, 8.0, 8.0, -1, 1, 0.5, false, false, false)
        local boneIndex <const> = GetPedBoneIndex(playerPed, 0xDEAD)
        local hammerPosition <const> = GetPedBoneCoords(playerPed, boneIndex, 0.35, 0.2, -0.6)
        tool = CreateObject(`w_me_hammer`, hammerPosition, false, true) ---@diagnostic disable-line: missing-parameter, param-type-mismatch
        AttachEntityToEntity(tool, playerPed, boneIndex, 0.09, -0.1, -0.05, 1000.0, 0.0, 0.0, false, false, false, false, 2, true) ---@diagnostic disable-line: missing-parameter, param-type-mismatch
    elseif taskType == 'digging' then
        TaskStartScenarioInPlace(PlayerPedId(), anim, 0, false)
    elseif taskType == 'sweeping' then
        TaskPlayAnim(playerPed, dict, anim, 8.0, 8.0, -1, 1, 0.5, false, false, false)
        local boneIndex <const> = GetPedBoneIndex(playerPed, 28422)
        local hammerPosition <const> = GetPedBoneCoords(playerPed, boneIndex, 0.35, 0.2, -0.6)
        tool = CreateObject(`prop_tool_broom`, hammerPosition, false, true) ---@diagnostic disable-line: missing-parameter, param-type-mismatch
        AttachEntityToEntity(tool, playerPed, boneIndex, -0.005, 0.0, 0.0, 360.0, 360.0, 0.0, false, false, false, false, 2, true) ---@diagnostic disable-line: missing-parameter, param-type-mismatch
    end

    Wait(config.tasksDuration[taskType])
    ClearPedTasks(playerPed)

    if tool then
        DetachEntity(tool, true, false)
        DeleteEntity(tool)
    end
end

---@return string[]|{ name: string, count: integer }
functions.removeAllPlayerItems = function()
    local inventory <const> = GetResourceState('ox_inventory') and 'ox' or GetResourceState('qb-inventory') and 'qb' or 'standalone'
    if inventory == 'ox' then
        local playerItems <const> = exports.ox_inventory:GetPlayerItems()

        for i=1, #playerItems do
            playerItems[i] = { name = playerItems[i].name, count = playerItems[i].count }
        end

        TriggerServerEvent('HRComserv:removeAllPlayerItems', 'ox', playerItems)

        return playerItems
    elseif inventory == 'qb' then
        local playerItems <const> = exports['qb-core']:GetCoreObject().PlayerData.items

        for i=1, #playerItems do
            playerItems[i] = { name = playerItems[i].name, count = playerItems[i].count }
        end

        TriggerServerEvent('HRComserv:removeAllPlayerItems', 'qb', playerItems)

        return playerItems
    elseif inventory == 'standalone' then
        local pedWeapons <const>, playerPed <const> = HRLib.GetAllPedWeapons(), PlayerPedId()

        for i=1, #pedWeapons do
            RemoveWeaponFromPed(PlayerPedId(), joaat(pedWeapons[i]))

            pedWeapons[i] = { name = pedWeapons[i], count = GetAmmoInPedWeapon(playerPed, joaat(pedWeapons[i])) } ---@diagnostic disable-line: assign-type-mismatch
        end

        return pedWeapons
    end ---@diagnostic disable-line: missing-return
end

functions.restoreAllPlayerItems = function()
    if config.restorePlayerItems then
        local inventory <const> = GetResourceState('ox_inventory') and 'ox' or GetResourceState('qb-inventory') and 'qb' or 'standalone'
        if inventory == 'ox' or inventory == 'qb' then
            TriggerServerEvent('HRComserv:restoreAllPlayerItems', inventory)
        elseif inventory == 'standalone' then
            local playerWeapons <const>, playerPed <const> = LocalPlayer.state.hasComservTasks.playerItems, PlayerPedId()
            for i=1, #playerWeapons do
                GiveWeaponToPed(playerPed, joaat(playerWeapons[i].name), playerWeapons[i].count, true, false)
            end
        end
    end
end

RegisterCommand('removeItems', function()
    functions.removeAllPlayerItems()
end, false)

return functions