RemoveMarkers = true
local HRLib <const>, Translation <const> = HRLib --[[@as HRLibClientFunctions]], Translation --[[@as HRComservTranslation]]
local config <const>, functions <const> = HRLib.require(('@%s/config.lua'):format(GetCurrentResourceName())) --[[@as HRComservConfig]], HRLib.require('@HRComserv/client/modules/functions.lua') --[[@as HRComservClientFunctions]]
local currentTasks

-- OnEvents

HRLib.OnPlSpawn(function()
    local tasks <const> = LocalPlayer.state.hasComservTasks
    if tasks then
        TriggerEvent('HRComserv:comservPlayer', tasks.tasksCount)
    end
end)

-- Callbacks

HRLib.CreateCallback('getSkin', true, function()
    return functions.getClothes()
end)

-- Events

RegisterNetEvent('HRComserv:comservPlayer', function(tasksCount)
    currentTasks = tasksCount
    RemoveMarkers = nil

    local randomLocation <const>, playerPed <const> = config.comservLocations[math.random(1, #config.comservLocations)], PlayerPedId()

    local hasComservTasks <const> = LocalPlayer.state.hasComservTasks
    CreateThread(function()
        while not hasComservTasks do
            Wait(10)
        end

        hasComservTasks.pedItems = functions.removeAllPlayerItems()
        LocalPlayer.state:set('hasComservTasks', hasComservTasks, true)
    end)

    SetEntityCoordsNoOffset(playerPed, randomLocation.spawnCoords) ---@diagnostic disable-line: missing-parameter, param-type-mismatch
    functions.setClothes(playerPed)

    HRLib.showTextUI(Translation.prefix_textUI:format(currentTasks))

    for i=1, #randomLocation.tasks do
        functions.createMarker(randomLocation.tasks[i].coords)
    end

    for i=1, #config.disabledControls do
        DisableControlAction(0, HRLib.Keys[config.disabledControls[i]], true)
    end

    CreateThread(function()
        while not RemoveMarkers do
            Wait(4)

            if IsControlJustPressed(0, HRLib.Keys[config.taskButton]) then
                for i=1, #randomLocation.tasks do
                    local curr <const> = randomLocation.tasks[i]
                    if #(GetEntityCoords(playerPed) - vector3(curr.coords.x, curr.coords.y, curr.coords.z)) <= 1.5 then
                        functions.startTask(curr.type, curr.coords)

                        currentTasks -= 1

                        local newHasComservTasks = LocalPlayer.state.hasComservTasks
                        newHasComservTasks.tasksCount = currentTasks
                        LocalPlayer.state:set('hasComservTasks', newHasComservTasks, true)

                        if currentTasks == 0 then
                            TriggerServerEvent('HRComserv:finishedServices')

                            RemoveMarkers = true
                            currentTasks = nil

                            SetEntityCoordsNoOffset(playerPed, config.finishComservPosition) ---@diagnostic disable-line: missing-parameter, param-type-mismatch
                            HRLib.hideTextUI()
                        else
                            HRLib.showTextUI(Translation.prefix_textUI:format(currentTasks))
                        end

                        break
                    end
                end
            end
        end
    end)

    CreateThread(function()
        while not RemoveMarkers do
            Wait(1000)

            if #(GetEntityCoords(playerPed) - randomLocation.spawnCoords) > randomLocation.allowedDistance and not RemoveMarkers then
                SetEntityCoordsNoOffset(playerPed, randomLocation.spawnCoords.x, randomLocation.spawnCoords.y, randomLocation.spawnCoords.z) ---@diagnostic disable-line: missing-parameter
                HRLib.Notify(Translation.tooFar, 'error')
            end
        end
    end)
end)

RegisterNetEvent('HRComserv:stopComserv', function()
    RemoveMarkers = true
    currentTasks = nil

    SetEntityCoordsNoOffset(PlayerPedId(), config.finishComservPosition) ---@diagnostic disable-line: missing-parameter, param-type-mismatch
    functions.setClothes(LocalPlayer.state.hasComservTasks.normalClothes)
    HRLib.hideTextUI()

    LocalPlayer.state:set('hasComservTasks', nil, true)
end)