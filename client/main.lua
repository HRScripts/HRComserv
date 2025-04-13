RemoveMarkers = true
local HRLib <const>, Translation <const> = HRLib, Translation --[[@as HRComservTranslation]]
local config <const>, functions <const> = HRLib.require(('@%s/config.lua'):format(GetCurrentResourceName())) --[[@as HRComservConfig]], HRLib.require('@HRComserv/client/modules/functions.lua') --[[@as HRComservClientFunctions]]
local firstSpawned = true

-- OnEvents

if LocalPlayer.state.hasComservTasks and IsEntityOnScreen(PlayerPedId()) then
    TriggerEvent('HRComserv:comservPlayer')
end

HRLib.OnPlSpawn(function()
    if firstSpawned then
        while not IsEntityOnScreen(PlayerPedId()) do
            Wait(10)
        end

        if LocalPlayer.state.hasComservTasks and not RemoveMarkers then
            TriggerEvent('HRComserv:comservPlayer')
        end

        firstSpawned = false
    end
end)

-- Callbacks

HRLib.CreateCallback('getSkin', true, function()
    return functions.getClothes(PlayerPedId())
end)

-- Events

RegisterNetEvent('HRComserv:comservPlayer', function()
    RemoveMarkers = nil

    local randomLocation <const>, playerPed <const>, hasComservTasks = config.comservLocations[math.random(1, #config.comservLocations)], PlayerPedId(), LocalPlayer.state.hasComservTasks
    local currentTask = randomLocation.tasks[math.random(#randomLocation.tasks)]

    while not hasComservTasks do
        Wait(10)

        hasComservTasks = LocalPlayer.state.hasComservTasks
    end

    hasComservTasks = setmetatable(hasComservTasks, {
        __call = function(self)
            rawset(self, 'tasksCount', tonumber(rawget(self, 'tasksCount')) - 1)
            rawset(self, 'playerItems', LocalPlayer.state.hasComservTasks.playerItems)
            LocalPlayer.state:set('hasComservTasks', self, true)
        end
    })

    functions.removeAllPlayerItems()
    functions.setClothes(playerPed)
    SetEntityCoordsNoOffset(playerPed, randomLocation.spawnCoords) ---@diagnostic disable-line: missing-parameter, param-type-mismatch
    HRLib.showTextUI(Translation.prefix_textUI:format(hasComservTasks.tasksCount))

    if config.disableInventory then
        LocalPlayer.state:set('invBusy', true, true)
    end

    CreateThread(function()
        while not RemoveMarkers do
            Wait(4)

            functions.createMarker(currentTask.coords)

            if IsControlJustPressed(0, HRLib.Keys[config.taskButton]) and #(GetEntityCoords(playerPed) - vector3(currentTask.coords.x, currentTask.coords.y, currentTask.coords.z)) <= 1.5 then
                functions.startTask(currentTask.type, currentTask.coords)
                hasComservTasks()

                if hasComservTasks.tasksCount == 0 then
                    TriggerEvent('HRComserv:stopComserv')

                    return
                else
                    HRLib.showTextUI(Translation.prefix_textUI:format(hasComservTasks.tasksCount))
                end

                currentTask = randomLocation.tasks[math.random(#randomLocation.tasks)]
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

RegisterNetEvent('HRComserv:stopComserv', function(isFromCommand)
    RemoveMarkers = true

    HRLib.hideTextUI()
    functions.restoreAllPlayerItems()
    SetEntityCoordsNoOffset(PlayerPedId(), config.finishComservPosition) ---@diagnostic disable-line: missing-parameter, param-type-mismatch
    functions.setClothes(PlayerPedId(), json.decode(LocalPlayer.state.hasComservTasks.skin))

    if config.disableInventory then
        LocalPlayer.state:set('invBusy', false, true)
    end

    TriggerServerEvent('HRComserv:finishedServices', isFromCommand)
end)