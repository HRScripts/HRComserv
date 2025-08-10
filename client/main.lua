local HRLib <const>, Translation <const> = HRLib, Translation --[[@as HRComservTranslation]]
local config <const>, functions <const> = HRLib.require(('@%s/config.lua'):format(GetCurrentResourceName())) --[[@as HRComservConfig]], HRLib.require('@HRComserv/client/modules/functions.lua') --[[@as HRComservClientFunctions]]
local textUIMessages <const> = { Translation.prefix_textUI, Translation.startTaskButtonPrefix:format(HRLib.Keys[config.taskButton]) }
local firstSpawned, stopped, threadsStopped, hasChange = true, nil, { false, false }, false

-- Functions

local stopComserv = function(isFromCommand)
    stopped = true

    if not threadsStopped[1] or not threadsStopped[2] then
        repeat Wait(20) until threadsStopped[1] and threadsStopped[2]
    end

    HRLib.hideTextUI()
    functions.restoreAllPlayerItems()
    SetEntityCoordsNoOffset(PlayerPedId(), config.finishComservPosition) ---@diagnostic disable-line: missing-parameter, param-type-mismatch
    functions.setClothes(PlayerPedId(), json.decode(LocalPlayer.state.hasComservTasks.skin))

    if config.disableInventory then
        LocalPlayer.state:set('invBusy', false, true)
    end

    TriggerServerEvent('HRComserv:finishedServices', isFromCommand)
end

local comservPlayer = function()
    if not LocalPlayer.state.hasComservTasks then
        repeat Wait(10) until LocalPlayer.state.hasComservTasks ~= nil
    end

    if stopped then stopped = nil end
    if threadsStopped[1] or threadsStopped[2] then threadsStopped = { false, false } end
    if hasChange then hasChange = false end

    local hasComservTasks = LocalPlayer.state.hasComservTasks
    local randomLocation <const>, playerPed <const> = hasComservTasks.alreadyHave and not config.disablePlacesChangeAfterRejoin and config.comservLocations[math.random(1, #config.comservLocations)] or hasComservTasks.alreadyHave and config.comservLocations[select(2, HRLib.table.find(config.comservLocations, { spawnLocation = vector3(hasComservTasks.firstPlace[1], hasComservTasks.firstPlace[2], hasComservTasks.firstPlace[3]) }, true))] or config.comservLocations[math.random(1, #config.comservLocations)], PlayerPedId()
    local currentTask = randomLocation.tasks[math.random(#randomLocation.tasks)]

    if not hasComservTasks.firstPlace then
        local hasComservTasksCopy <const> = HRLib.table.deepclone(hasComservTasks, true)
        hasComservTasksCopy.firstPlace = { randomLocation.spawnCoords.x, randomLocation.spawnCoords.y, randomLocation.spawnCoords.z }
        LocalPlayer.state:set('hasComservTasks', hasComservTasksCopy, true)
    end

    functions.removeAllPlayerItems()
    functions.setClothes(playerPed)
    SetEntityCoordsNoOffset(playerPed, randomLocation.spawnCoords) ---@diagnostic disable-line: missing-parameter, param-type-mismatch
    HRLib.showTextUI(textUIMessages[1]:format(hasComservTasks.tasksCount))

    if config.disableInventory then
        LocalPlayer.state:set('invBusy', true, true)
    end

    CreateThread(function()
        while not stopped do
            Wait(4)

            functions.createMarker(currentTask.coords)

            hasComservTasks = LocalPlayer.state.hasComservTasks
            local taskDistance <const>, isPressed <const> = #(GetEntityCoords(playerPed) - vector3(currentTask.coords.x, currentTask.coords.y, currentTask.coords.z)), IsControlJustPressed(0, HRLib.Keys[config.taskButton])
            if taskDistance <= 1.5 and not isPressed then
                HRLib.showTextUI(textUIMessages[2])
            elseif isPressed and taskDistance <= 1.5 then
                local hasComservTasksCopy <const> = HRLib.table.deepclone(hasComservTasks, true)
                hasComservTasksCopy.tasksCount = hasComservTasksCopy.tasksCount - 1
                LocalPlayer.state:set('hasComservTasks', hasComservTasksCopy, true)

                hasComservTasks = LocalPlayer.state.hasComservTasks

                HRLib.hideTextUI()
                functions.startTask(currentTask.type, currentTask.coords)

                if hasComservTasks.tasksCount == 0 then
                    stopComserv(false)

                    break
                else
                    HRLib.showTextUI(textUIMessages[1]:format(hasComservTasks.tasksCount))
                end

                currentTask = randomLocation.tasks[math.random(#randomLocation.tasks)]
            else
                local isOpen <const>, text <const> = HRLib.isTextUIOpen(true)
                if (isOpen and text == textUIMessages[2] and taskDistance > 1.5) or hasChange then
                    HRLib.showTextUI(textUIMessages[1]:format(hasComservTasks.tasksCount))
                end
            end
        end

        threadsStopped[1] = true
    end)

    CreateThread(function()
        while not stopped do
            Wait(1000)

            SetEntityInvincible(PlayerPedId(), true)
            functions.healPlayer()

            if #(GetEntityCoords(playerPed) - randomLocation.spawnCoords) > randomLocation.allowedDistance and not stopped then
                SetEntityCoordsNoOffset(playerPed, randomLocation.spawnCoords.x, randomLocation.spawnCoords.y, randomLocation.spawnCoords.z) ---@diagnostic disable-line: missing-parameter
                HRLib.Notify(Translation.tooFar, 'error')
            end
        end

        SetEntityInvincible(PlayerPedId(), false)

        threadsStopped[2] = true
    end)
end

-- OnEvents

if LocalPlayer.state.hasComservTasks and IsEntityOnScreen(PlayerPedId()) then
    comservPlayer()
end

HRLib.OnPlSpawn(function()
    if firstSpawned then
        while not IsEntityOnScreen(PlayerPedId()) do
            Wait(10)
        end

        if LocalPlayer.state.hasComservTasks and not stopped then
            comservPlayer()
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
    if stopped and (not threadsStopped[1] or not threadsStopped[2]) then
        repeat Wait(10) until threadsStopped[1] and threadsStopped[2]
    end

    comservPlayer()
end)

RegisterNetEvent('HRComserv:stopComserv', stopComserv)

-- State Bag Change Handlers

AddStateBagChangeHandler('hasComservTasks', '', function(_, _, value)
    if value and not stopped then
        hasChange = true
    end
end)