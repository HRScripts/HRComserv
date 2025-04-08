local HRLib <const> = HRLib
local config <const>, functions <const> = HRLib.require('@HRComserv/config.lua') --[[@as HRComservConfig]], {}

functions.setClothes = function(targetPed, oldClothes)
    local resourceName = GetResourceState('illenium-appearance') == 'started' and 1 or GetResourceState('skinchanger') == 'started' and 2
    if resourceName == 1 then
        exports['illenium-appearance']:setPedComponents(targetPed, oldClothes or functions.convertComponents(config.comservClothes, exports['illenium-appearance']:getPedComponents(targetPed)))
    elseif resourceName == 2 then
        config.comservClothes.sex = IsPedMale(targetPed) and 0 or 1
        TriggerEvent('skinchanger:loadSkin', oldClothes or config.comservClothes)
    end
end

functions.getClothes = function(targetPed)
    local resourceName = GetResourceState('illenium-appearance') == 'started' and 1 or GetResourceState('skinchanger') == 'started' and 2
    if resourceName == 1 then
        return json.encode(exports['illenium-appearance']:getPedComponents(targetPed))
    elseif resourceName == 2 then
        local playerSkin

        TriggerEvent('skinchanger:getSkin', function(skin)
            playerSkin = skin
        end)

        return json.encode(playerSkin)
    end
end

functions.convertComponents = function(oldSkin, components) -- Function taked by illenium-appearance
    return {
        {
            component_id = 0,
            drawable = (components and components[1].drawable) or 0,
            texture = (components and components[1].texture) or 0
        },
        {
            component_id = 1,
            drawable = oldSkin.mask_1 or (components and components[2].drawable) or 0,
            texture = oldSkin.mask_2 or (components and components[2].texture) or 0
        },
        {
            component_id = 2,
            drawable = (components and components[3].drawable) or 0,
            texture = (components and components[3].texture) or 0
        },
        {
            component_id = 3,
            drawable = oldSkin.arms or (components and components[4].drawable) or 0,
            texture = oldSkin.arms_2 or (components and components[4].texture) or 0,
        },
        {
            component_id = 4,
            drawable = oldSkin.pants_1 or (components and components[5].drawable) or 0,
            texture = oldSkin.pants_2 or (components and components[5].texture) or 0
        },
        {
            component_id = 5,
            drawable = oldSkin.bags_1 or (components and components[6].drawable) or 0,
            texture = oldSkin.bags_2 or (components and components[6].texture) or 0
        },
        {
            component_id = 6,
            drawable = oldSkin.shoes_1 or (components and components[7].drawable) or 0,
            texture = oldSkin.shoes_2 or (components and components[7].texture) or 0
        },
        {
            component_id = 7,
            drawable = oldSkin.chain_1 or (components and components[8].drawable) or 0,
            texture = oldSkin.chain_2 or (components and components[8].texture) or 0
        },
        {
            component_id = 8,
            drawable = oldSkin.tshirt_1 or (components and components[9].drawable) or 0,
            texture = oldSkin.tshirt_2 or (components and components[9].texture) or 0
        },
        {
            component_id = 9,
            drawable = oldSkin.bproof_1 or (components and components[10].drawable) or 0,
            texture = oldSkin.bproof_2 or (components and components[10].texture) or 0
        },
        {
            component_id = 10,
            drawable = oldSkin.decals_1 or (components and components[11].drawable) or 0,
            texture = oldSkin.decals_2 or (components and components[11].texture) or 0
        },
        {
            component_id = 11,
            drawable = oldSkin.torso_1 or (components and components[12].drawable) or 0,
            texture = oldSkin.torso_2 or (components and components[12].texture) or 0
        }
    }
end

---@param markerPosition vector4
functions.createMarker = function(markerPosition)
    DrawMarker(config.tasksMarker.type, markerPosition.x, markerPosition.y, markerPosition.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, config.tasksMarker.colour.red, config.tasksMarker.colour.green, config.tasksMarker.colour.blue, config.tasksMarker.alpha, true, false, 2, false, nil, nil, false) ---@diagnostic disable-line: param-type-mismatch
end

---@param taskType 'hammerFix'|'digging'|'sweeping'
---@param playerPosition vector4
functions.startTask = function(taskType, playerPosition)
    local playerPed <const>, anim <const>, dict <const> = PlayerPedId(), table.unpack(taskType == 'hammerFix' and {'base', 'amb@world_human_hammering@male@base'} or taskType == 'digging' and { 'world_human_gardener_plant' } or taskType == 'sweeping' and { 'idle_a', 'amb@world_human_janitor@male@idle_a' } or {})
    local tool

    SetEntityCoords(playerPed, playerPosition.x, playerPosition.y, GetEntityCoords(playerPed).z - 1) ---@diagnostic disable-line: missing-parameter
    SetEntityHeading(playerPed, playerPosition.w)

    if dict then
        HRLib.RequestAnimDict(dict)
    end

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

---@return string[]|{ name: string, count: integer }?
functions.removeAllPlayerItems = function()
    if not config.removePlayerItems then return end

    local inventory <const> = GetResourceState('ox_inventory') and 'ox' or GetResourceState('qb-inventory') and 'qb' or 'standalone'
    if inventory == 'ox' or inventory == 'qb' then
        TriggerServerEvent('HRComserv:removeAllPlayerItems', inventory)
    elseif inventory == 'standalone' then
        local pedWeapons <const>, playerPed <const> = HRLib.GetPedWeapons(), PlayerPedId()

        for i=1, #pedWeapons do
            RemoveWeaponFromPed(PlayerPedId(), joaat(pedWeapons[i]))

            pedWeapons[i] = { name = pedWeapons[i], count = GetAmmoInPedWeapon(playerPed, joaat(pedWeapons[i])) } ---@diagnostic disable-line: assign-type-mismatch
        end

        local hasComservTasks <const> = LocalPlayer.state.hasComservTasks
        hasComservTasks.playerItems = pedWeapons
        LocalPlayer.state:set('hasComservTasks', hasComservTasks, true)
    end ---@diagnostic disable-line: missing-return
end

functions.restoreAllPlayerItems = function()
    if config.restorePlayerItems then
        local inventory <const> = GetResourceState('ox_inventory') and 'ox' or GetResourceState('qb-inventory') and 'qb' or 'standalone'
        if inventory == 'standalone' then
            local playerWeapons <const>, playerPed <const> = LocalPlayer.state.hasComservTasks.playerItems, PlayerPedId()
            for i=1, #playerWeapons do
                GiveWeaponToPed(playerPed, joaat(playerWeapons[i].name), playerWeapons[i].count, true, false)
            end
        end
    end
end

return functions
