local HRLib <const>, Translation <const> = HRLib, Translation --[[@as HRComservTranslation]]
local config <const>, functions <const> = HRLib.require(('@%s/config.lua'):format(GetCurrentResourceName())) --[[@as HRComservConfig]], HRLib.require('@HRComserv/client/modules/functions.lua') --[[@as HRComservClientFunctions]]
local textUIMessages <const> = { Translation.prefix_textUI, Translation.startTaskButtonPrefix:format(HRLib.Keys[config.taskButton]) }
local stopped, threadsStopped, hasChange = nil, { false, false }, false

-- Functions

local stopComserv = function(isFromCommand)
    Citizen.CreateThreadNow(function()
        stopped = true

        if not threadsStopped[1] or not threadsStopped[2] then
            repeat Wait(20) until threadsStopped[1] and threadsStopped[2]
        end

        HRLib.hideTextUI()
        functions.restoreAllPlayerItems()

        do
            local playerPed <const> = HRLib.IPlayer.ped
            SetEntityCoordsNoOffset(playerPed, table.unpack(config.finishComservPosition))
            functions.setClothes(playerPed, json.decode(LocalPlayer.state.hasComservTasks.skin))
        end

        if config.disableInventory then
            LocalPlayer.state:set('invBusy', false, true)
        end

        TriggerServerEvent('HRComserv:finishedServices', isFromCommand)
    end)
end

local comservPlayer = function()
    if not LocalPlayer.state.hasComservTasks then
        repeat Wait(10) until LocalPlayer.state.hasComservTasks ~= nil
    end

    stopped = nil
    threadsStopped = { false, false }
    hasChange = false

    local hasComservTasks = LocalPlayer.state.hasComservTasks
    local randomLocation <const>, playerPed <const> = hasComservTasks.alreadyHave and not config.disablePlacesChangeAfterRejoin and config.comservLocations[math.random(1, #config.comservLocations)] or hasComservTasks.alreadyHave and config.comservLocations[select(2, HRLib.table.find(config.comservLocations, { spawnLocation = vector3(hasComservTasks.firstPlace[1], hasComservTasks.firstPlace[2], hasComservTasks.firstPlace[3]) }, true))] or config.comservLocations[math.random(1, #config.comservLocations)], HRLib.IPlayer.ped
    local currentTask = randomLocation.tasks[math.random(#randomLocation.tasks)]

    if not hasComservTasks.firstPlace then
        local hasComservTasksCopy <const> = HRLib.table.deepclone(hasComservTasks, true)
        hasComservTasksCopy.firstPlace = { randomLocation.spawnCoords.x, randomLocation.spawnCoords.y, randomLocation.spawnCoords.z }
        LocalPlayer.state:set('hasComservTasks', hasComservTasksCopy, true)
    end

    if not hasComservTasks.alreadyHave then
        functions.removeAllPlayerItems()
    end

    functions.setClothes(playerPed)
    SetEntityCoordsNoOffset(playerPed, randomLocation.spawnCoords) ---@diagnostic disable-line: missing-parameter, param-type-mismatch
    HRLib.showTextUI(textUIMessages[1]:format(hasComservTasks.tasksCount))

    if config.disableInventory then
        LocalPlayer.state:set('invBusy', true, true)
    end

    Citizen.CreateThreadNow(function()
        while not stopped do
            Wait(4)

            functions.createMarker(currentTask.coords)

            hasComservTasks = LocalPlayer.state.hasComservTasks
            if hasComservTasks then
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
            elseif HRLib.isTextUIOpen() then
                HRLib.hideTextUI()
            end
        end

        threadsStopped[1] = true
    end)

    Citizen.CreateThreadNow(function()
        while not stopped do
            Wait(1000)

            SetEntityInvincible(HRLib.IPlayer.ped, true)
            functions.healPlayer()

            if #(GetEntityCoords(playerPed) - randomLocation.spawnCoords) > randomLocation.allowedDistance and not stopped then
                SetEntityCoordsNoOffset(playerPed, randomLocation.spawnCoords.x, randomLocation.spawnCoords.y, randomLocation.spawnCoords.z) ---@diagnostic disable-line: missing-parameter
                HRLib.Notify(Translation.tooFar, 'error')
            end
        end

        SetEntityInvincible(HRLib.IPlayer.ped, false)

        threadsStopped[2] = true
    end)
end

-- OnEvents

if LocalPlayer.state.hasComservTasks and ((HRLib.bridge.type ~= 'unknown_unusedBridge' and HRLib.bridge.isPlayerSpawned) or (HRLib.bridge.type == 'unknown_unusedBridge' and IsEntityOnScreen(HRLib.IPlayer.ped))) then
    comservPlayer()
end

if HRLib.bridge.type ~= 'unknown_unusedBridge' then
    HRLib.bridge.addPlayerSpawnFunction(function()
        if LocalPlayer.state.hasComservTasks and not stopped then
            comservPlayer()
        end
    end)
else
    local spawnedAlready = false
    HRLib.OnPlSpawn(function()
        if not spawnedAlready then
            spawnedAlready = true

            if LocalPlayer.state.hasComservTasks and not stopped then
                comservPlayer()
            end
        end
    end)
end

-- Callbacks

HRLib.CreateCallback('getSkin', true, function()
    return functions.getClothes(HRLib.IPlayer.ped)
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