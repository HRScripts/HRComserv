RemoveMarkers = true
local HRLib <const>, Translation <const> = HRLib, Translation --[[@as HRComservTranslation]]
local config <const>, functions <const> = HRLib.require(('@%s/config.lua'):format(GetCurrentResourceName())) --[[@as HRComservConfig]], HRLib.require('@HRComserv/client/modules/functions.lua') --[[@as HRComservClientFunctions]]
local textUIMessages <const> = { Translation.prefix_textUI, Translation.startTaskButtonPrefix:format(HRLib.Keys[config.taskButton]) }
local firstSpawned, hasChange = true, false

-- Functions

local comservPlayer = function()
    if not LocalPlayer.state.hasComservTasks then
        repeat Wait(10) until LocalPlayer.state.hasComservTasks ~= nil
    end

    RemoveMarkers = nil
    local hasComservTasks = LocalPlayer.state.hasComservTasks
    local randomLocation <const>, playerPed <const> = hasComservTasks.alreadyHave and not config.disablePlacesChangeAfterRejoin and config.comservLocations[math.random(1, #config.comservLocations)] or hasComservTasks.alreadyHave and vector3(hasComservTasks.firstPlace[1], hasComservTasks.firstPlace[2], hasComservTasks.firstPlace[3]) or config.comservLocations[math.random(1, #config.comservLocations)], PlayerPedId()
    local currentTask = randomLocation.tasks[math.random(#randomLocation.tasks)]

    if not hasComservTasks.firstPlace then
        local hasComservTasksCopy <const> = HRLib.table.deepclone(hasComservTasks, true)
        local spawnCoords <const> = randomLocation.spawnCoords
        hasComservTasksCopy.firstPlace = { spawnCoords.x, spawnCoords.y, spawnCoords.z }
        LocalPlayer.state:set('hasComservTasks', hasComservTasksCopy, true)
    end

    hasComservTasks = setmetatable(hasComservTasks, {
        __call = function(self, removeTasksCountRemoval)
            local hasComservTasksCopy <const> = HRLib.table.deepclone(LocalPlayer.state.hasComservTasks, true)
            for k,v in pairs(hasComservTasksCopy) do
                rawset(self, k, v)
            end

            if not removeTasksCountRemoval then
                rawset(self, 'tasksCount', tonumber(rawget(self, 'tasksCount')) - 1)
                rawset(self, 'playerItems', LocalPlayer.state.hasComservTasks.playerItems)
                LocalPlayer.state:set('hasComservTasks', self, true)
            end
        end
    })

    functions.removeAllPlayerItems()
    functions.setClothes(playerPed)
    SetEntityCoordsNoOffset(playerPed, randomLocation.spawnCoords) ---@diagnostic disable-line: missing-parameter, param-type-mismatch
    HRLib.showTextUI(textUIMessages[1]:format(hasComservTasks.tasksCount))

    if config.disableInventory then
        LocalPlayer.state:set('invBusy', true, true)
    end

    CreateThread(function()
        while not RemoveMarkers do
            Wait(4)

            functions.createMarker(currentTask.coords)

            local taskDistance <const>, isPressed <const> = #(GetEntityCoords(playerPed) - vector3(currentTask.coords.x, currentTask.coords.y, currentTask.coords.z)), IsControlJustPressed(0, HRLib.Keys[config.taskButton])
            if taskDistance <= 1.5 and not isPressed then
                HRLib.showTextUI(textUIMessages[2])
            elseif isPressed and taskDistance <= 1.5 then
                HRLib.hideTextUI()
                functions.startTask(currentTask.type, currentTask.coords)
                hasComservTasks()

                if hasComservTasks.tasksCount == 0 then
                    return TriggerEvent('HRComserv:stopComserv')
                else
                    HRLib.showTextUI(textUIMessages[1]:format(hasComservTasks.tasksCount))
                end

                currentTask = randomLocation.tasks[math.random(#randomLocation.tasks)]
            elseif hasChange then
                hasComservTasks(true)
                HRLib.showTextUI(textUIMessages[1]:format(hasComservTasks.tasksCount))

                hasChange = false
            else
                local isOpen <const>, text <const> = HRLib.isTextUIOpen(true)
                if isOpen and text == textUIMessages[2] and taskDistance > 1.5 then
                    HRLib.showTextUI(textUIMessages[1]:format(hasComservTasks.tasksCount))
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

        if LocalPlayer.state.hasComservTasks and RemoveMarkers then
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

RegisterNetEvent('HRComserv:comservPlayer', comservPlayer)

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

-- State Bag Change Handlers

AddStateBagChangeHandler('hasComservTasks', '', function(_, _, value)
    if not RemoveMarkers and value then
        hasChange = true
    elseif RemoveMarkers and value then
        comservPlayer()
    end
end)