local HRLib <const>, MySQL <const>, Translation <const> = HRLib --[[@as HRLibServerFunctions]], MySQL, Translation --[[@as HRComservTranslation]] ---@diagnostic disable-line: undefined-global

-- OnEvents

HRLib.OnStart(nil, function()
    MySQL.rawExecute.await('CREATE TABLE IF NOT EXISTS `community_services` (\n    `identifier` varchar(48) NOT NULL PRIMARY KEY,\n    `tasksCount` tinyint(4) NOT NULL DEFAULT 1,\n    `normalClothes` json NOT NULL DEFAULT \'[]\',\n    `pedItems` json NOT NULL DEFAULT \'[]\'\n) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;')

    local punishedPlayers <const> = MySQL.query.await('SELECT * FROM `community_services`;')
    if punishedPlayers[1] then
        local players <const> = GetPlayers()
        for i=1, #players do
            HRLib.table.focusedArray(punishedPlayers, { identifier = HRLib.PlayerIdentifier(tonumber(players[i]) --[[@as integer]], 'license') }, function(_, curr)
                Player(players[i]).state.hasComservTasks = { tasksCount = curr.tasksCount, skin = curr.normalClothes, pedItems = json.decode(curr.pedItems), alreadyHave = true }

                TriggerClientEvent('HRComserv:comservPlayer', tonumber(players[i]) --[[@as integer]], curr.tasksCount)
            end)
        end
    end
end)

HRLib.OnPlJoining(function(source)
    local playerComservs <const> = MySQL.single.await('SELECT * FROM `community_services` WHERE `identifier` = ?;', { HRLib.PlayerIdentifier(source, 'license') })
    if playerComservs then
        Player(source).state.hasComservTasks = { tasksCount = playerComservs.tasksCount, skin = playerComservs.normalClothes, pedItems = json.decode(playerComservs.pedItems), alreadyHave = true }
    end
end)

HRLib.OnPlDisc(function(source)
    local playerState <const>, playerIdentifier <const> = Player(source).state?.hasComservTasks, HRLib.PlayerIdentifier(source, 'license')
    if playerState then
        if not playerState.alreadyHave then
            MySQL.insert('INSERT INTO `community_services` (`identifier`, `tasksCount`, `normalClothes`, `playerItems`) VALUES (?, ?, ?, ?);', { playerIdentifier, playerState.tasksCount, playerState.skin, json.encode(playerState.playerItems) })
        else
            MySQL.update('UPDATE `community_services` SET `tasksCount` = ? WHERE `identifier` = ?;', { playerState.tasksCount, playerIdentifier })
        end
    end
end)

-- Events

RegisterNetEvent('HRComserv:finishedServices', function()
    if Player(source).state.hasComservTasks then
        local source <const>, playerIdentifier <const> = source, HRLib.PlayerIdentifier(source, 'license')

        if MySQL.single.await('SELECT * FROM `community_services` WHERE `identifier` = ?;', { playerIdentifier }) then
            MySQL.rawExecute('DELETE FROM `community_services` WHERE `identifier` = ?;', { playerIdentifier })
        end

        if GetResourceState('ox_inventory') == 'started' or GetResourceState('qb-inventory') == 'started' then
            local playerItems <const>, inventoryFunctions <const> = Player(source).state.hasComservTasks.playerItems, exports[GetResourceState('ox_inventory') == 'started' and 'ox_inventory' or 'qb-inventory']
            if playerItems then
                for i=1, #playerItems do
                    inventoryFunctions:AddItem(source, playerItems[i].name, playerItems[i].count)
                end
            end
        end

        Player(source).state.hasComservTasks = nil
    end
end)

RegisterNetEvent('HRComserv:removeAllPlayerItems', function(invType)
    if Player(source).state.hasComservTasks then
        local inventoryFunctions <const>, playerItems <const> = exports[invType == 'ox' and 'ox_inventory' or 'qb-inventory'], invType == 'ox' and exports.ox_inventory:GetInventoryItems(source) or exports['qb-core']:GetCoreObject().GetPlayer(source).PlayerData.items

        for _,v in pairs(playerItems) do
            inventoryFunctions:RemoveItem(source, v.name, v.count)
        end

        local hasComservTasks = Player(source).state.hasComservTasks
        hasComservTasks.playerItems = playerItems
        Player(source).state.hasComservTasks = hasComservTasks
    end
end)

-- Commands

HRLib.RegCommand('comserv', true, true, function(args, _, _, FPlayer)
    local playerId <const>, tasksCount <const> = tonumber(args[1]), tonumber(args[2])
    if HRLib.DoesIdExist(playerId) then
        if tasksCount then
            Player(playerId --[[@as integer]]).state.hasComservTasks = { tasksCount = tasksCount, skin = HRLib.ClientCallback('getSkin', playerId) }
            TriggerClientEvent('HRComserv:comservPlayer', playerId --[[@as integer]])
            FPlayer:Notify(Translation.comserv_successful, 'success')
        else
            FPlayer:Notify(Translation.comserv_failed_invalidTasksCount, 'error')
        end
    else
        FPlayer:Notify(Translation.id_notFound, 'error')
    end
end, true, { help = Translation.suggestions.comserv_help, restricted = true, args = { { name = 'playerId', help = Translation.suggestions.comserv_arg1_help }, { name = 'tasksCount', help = Translation.suggestions.comserv_arg2_help } } })

HRLib.RegCommand('stopComserv', true, true, function(args, _, _, FPlayer)
    local playerId <const> = tonumber(args[1])
    if HRLib.DoesIdExist(playerId) then
        if Player(playerId --[[@as integer]]).state.hasComservTasks then
            TriggerClientEvent('HRComserv:stopComserv', playerId --[[@as integer]])
            FPlayer:Notify(Translation.stopComserv_successful:format(GetPlayerName(playerId --[[@as integer]])), 'success')
        else
            FPlayer:Notify(Translation.stopComserv_failed_hasNoComserv)
        end

        local playerIdentifier <const> = HRLib.PlayerIdentifier(playerId --[[@as integer]], 'license')
        if MySQL.single.await('SELECT * FROM `community_services` WHERE `identifier` = ?;', { playerIdentifier }) then
            MySQL.rawExecute('DELETE FROM `community_services` WHERE `identifier` = ?;', { playerIdentifier })
        end
    else
        FPlayer:Notify(Translation.id_notFound, 'error')
    end
end, true, { help = Translation.suggestions.stopComserv_help, restricted = true, args = { { name = 'playerId', help = Translation.suggestions.stopComserv_arg1_help } } })