local HRLib <const>, MySQL <const>, Translation <const> = HRLib, MySQL, Translation --[[@as HRComservTranslation]] ---@diagnostic disable-line: undefined-global
local config <const> = HRLib.require('@HRComserv/config.lua') --[[@as HRComservConfig]]

-- Functions

---@param staffName string
---@param targetPlayerId integer
---@param currMessage table
local getIdentifiersForDesc = function(staffName, targetPlayerId, currMessage)
    local identifiers <const> = {}

    for i=1, #currMessage.showedIdentifiers do
        local curr <const> = currMessage.showedIdentifiers[i]
        if curr == 'name' or curr == 'staffName' then
            identifiers[i] = curr == 'name' and GetPlayerName(targetPlayerId) or staffName
        else
            if curr == 'discord' then
                identifiers[#identifiers+1] = ('<@%s>'):format(HRLib.PlayerIdentifier(targetPlayerId, curr, true) or 'undefined')
            else
                identifiers[#identifiers+1] = HRLib.PlayerIdentifier(targetPlayerId, curr) or 'undefined'
            end
        end
    end

    return table.unpack(identifiers)
end

-- OnEvents

HRLib.OnStart(nil, function()
    MySQL.rawExecute.await('CREATE TABLE `community_services` (\n    `identifier` varchar(48) NOT NULL PRIMARY KEY,\n    `tasksCount` tinyint(4) NOT NULL DEFAULT 1,\n    `normalClothes` json NOT NULL,\n    `playerItems` json NOT NULL,\n    `firstPlace` json NOT NULL\n) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;')

    local punishedPlayers <const> = MySQL.query.await('SELECT * FROM `community_services`;')
    if #punishedPlayers > 0 then
        local players <const> = GetPlayers()
        for i=1, #players do
            HRLib.table.focusedArray(punishedPlayers, { identifier = HRLib.PlayerIdentifier(tonumber(players[i]) --[[@as integer]], 'license') }, function(_, curr)
                Player(tonumber(players[i]) --[[@as integer]]).state.hasComservTasks = { tasksCount = curr.tasksCount, skin = curr.normalClothes, playerItems = json.decode(curr.playerItems), firstPlace = vector3(table.unpack(HRLib.table.deepclone(json.decode(curr.firstPlace), true))), alreadyHave = true }

                TriggerClientEvent('HRComserv:comservPlayer', tonumber(players[i]) --[[@as integer]])
            end)
        end
    end
end)

HRLib.OnStop(nil, function()
    local players <const> = GetPlayers()
    for i=1, #players do
        local curr <const> = tonumber(players[i]) --[[@as integer]]
        local currState <const>, currIdentifier <const> = Player(curr).state.hasComservTasks, HRLib.PlayerIdentifier(curr, 'license')
        if currState then
            if not currState.alreadyHave then
                MySQL.insert('INSERT INTO `community_services` (`identifier`, `tasksCount`, `normalClothes`, `playerItems`, `firstPlace`) VALUES (?, ?, ?, ?, ?);', { currIdentifier, currState.tasksCount, currState.skin, json.encode(currState.playerItems), json.encode(currState.firstPlace) })
            else
                MySQL.update('UPDATE `community_services` SET `tasksCount` = ? WHERE `identifier` = ?;', { currState.tasksCount, currIdentifier })
            end
        end
    end
end)

HRLib.OnPlJoining(function(source)
    local playerComservs <const> = MySQL.single.await('SELECT * FROM `community_services` WHERE `identifier` = ?;', { HRLib.PlayerIdentifier(source, 'license') })
    if playerComservs then
        Player(source).state.hasComservTasks = { tasksCount = playerComservs.tasksCount, skin = playerComservs.normalClothes, playerItems = json.decode(playerComservs.playerItems), firstPlace = vector3(table.unpack(HRLib.table.deepclone(json.decode(playerComservs.firstPlace), true))), alreadyHave = true }
    end
end)

---@param source integer
HRLib.OnPlDisc(function(source)
    local playerState <const>, playerIdentifier <const> = Player(source).state?.hasComservTasks, HRLib.PlayerIdentifier(source, 'license')
    if playerState then
        if not playerState.alreadyHave then
            MySQL.insert('INSERT INTO `community_services` (`identifier`, `tasksCount`, `normalClothes`, `playerItems`, `firstPlace`) VALUES (?, ?, ?, ?, ?);', { playerIdentifier, playerState.tasksCount, playerState.skin, json.encode(playerState.playerItems), json.encode(playerState.firstPlace) })
        else
            MySQL.update('UPDATE `community_services` SET `tasksCount` = ? WHERE `identifier` = ?;', { playerState.tasksCount, playerIdentifier })
        end
    end
end)

-- Events

RegisterNetEvent('HRComserv:finishedServices', function(isFromCommand)
    if Player(source).state.hasComservTasks then
        local source <const>, playerIdentifier <const> = source, HRLib.PlayerIdentifier(source, 'license')

        if MySQL.single.await('SELECT * FROM `community_services` WHERE `identifier` = ?;', { playerIdentifier }) then
            MySQL.rawExecute('DELETE FROM `community_services` WHERE `identifier` = ?;', { playerIdentifier })
        end

        if not isFromCommand then
            local currConfig <const> = config.discordLogs
            local currMessage <const> = currConfig.settings.messages.finishComserv_message
            if currConfig.enable and currMessage.enable then
                HRLib.DiscordMsg(currConfig.webHookURL, currConfig.settings.botName, currConfig.settings.title, currMessage.description:format(getIdentifiersForDesc('undefined', source, currMessage)), nil, currConfig.settings.color, '', 'System')
            end
        end

        Player(source).state.hasComservTasks = nil
    end
end)

AddStateBagChangeHandler('HRComserv:removeAllPlayerItems', '', function(bagName, key, value)
    if value and HRLib.string.find(bagName, 'player:') then
        local playerId <const> = GetPlayerFromStateBagName(bagName)
        if Player(playerId).state.hasComservTasks then
            local playerItems

            if value ~= 'standalone' then
                local inventoryFunctions <const> = value == 'ox' and exports.ox_inventory or exports['qb-core']:GetCoreObject().GetPlayer(playerId)
                playerItems = value == 'ox' and inventoryFunctions:GetInventoryItems(playerId) or value == 'qb' and inventoryFunctions.PlayerData.items

                if playerItems then
                    local removeItem <const> = value == 'ox' and function(name, count) inventoryFunctions:RemoveItem(playerId, name, count) end or inventoryFunctions.Functions.RemoveItem --[[@as function]]
                    for _,v in pairs(playerItems) do
                        removeItem(v.name, v.count)
                    end
                end
            else
                playerItems = HRLib.GetPedWeapons(playerId)

                local ped <const> = GetPlayerPed(playerId)
                for i=1, #playerItems do
                    RemoveWeaponFromPed(ped, joaat(playerItems[i]))
                end
            end

            local hasComservTasks <const> = Player(playerId).state.hasComservTasks
            hasComservTasks.playerItems = playerItems or {}
            Player(playerId).state.hasComservTasks = hasComservTasks
        end

        if Player(playerId).state[key] == value then
            Player(playerId).state[key] = nil
        else
            Citizen.CreateThreadNow(function()
                repeat Wait(10) until Player(playerId).state[key] == value

                Player(playerId).state[key] = nil
            end)
        end
    end
end)

do
    AddStateBagChangeHandler('HRComserv:restorePlayerItems', '', function(bagName, key, value)
        if value and HRLib.string.find(bagName, 'player:') then
            local playerId <const> = GetPlayerFromStateBagName(bagName)

            local playerItems <const> = Player(playerId).state.hasComservTasks.playerItems
            if value == 'ox' then
                local ox_inventory <const> = exports.ox_inventory
                for i=1, #playerItems do
                    local item <const> = playerItems[i]
                    ox_inventory:AddItem(playerId, item.name, item.count, item.metadata, item.slot)
                end
            elseif value == 'qb' then
                local addItem <const> = exports['qb-core']:GetPlayer(playerId).Functions.AddItem
                for i=1, #playerItems do
                    local item <const> = playerItems[i]
                    addItem(item.name, item.amount, item.slot, item.info)
                end
            end

            if Player(playerId).state[key] == value then
                Player(playerId).state[key] = nil
            else
                Citizen.CreateThreadNow(function()
                    repeat Wait(10) until Player(playerId).state[key] == value

                    Player(playerId).state[key] = nil
                end)
            end
        end
    end)
end

-- Exports

exports('comservPlayer', function(playerId, tasksCount)
    if not Player(playerId).state.hasComservTasks and type(playerId) == 'number' and type(tasksCount) == 'number' then
        Player(playerId).state.hasComservTasks = { tasksCount = tasksCount, skin = HRLib.ClientCallback('getSkin', source) }

        TriggerClientEvent('HRComserv:comservPlayer', playerId)

        local currConfig <const> = config.discordLogs
        local currMessage <const> = currConfig.settings.messages.comserv_message
        if currConfig.enable and currMessage.enable then
            HRLib.DiscordMsg(currConfig.webHookURL, currConfig.settings.botName, currConfig.settings.title, currMessage.description:format(getIdentifiersForDesc(('(called by %s resource)'):format(GetInvokingResource()), playerId, currMessage)), nil, currConfig.settings.color, '', 'System')
        end
    end
end)

exports('stopPlayerComserv', function(playerId)
    if Player(playerId).state.hasComservTasks then
        TriggerClientEvent('HRComserv:stopComserv', playerId)

        local playerIdentifier <const> = HRLib.PlayerIdentifier(playerId --[[@as integer]], 'license')
        if MySQL.single.await('SELECT * FROM `community_services` WHERE `identifier` = ?;', { playerIdentifier }) then
            MySQL.rawExecute('DELETE FROM `community_services` WHERE `identifier` = ?;', { playerIdentifier })
        end
    end
end)

-- Commands

HRLib.RegCommand('comserv', true, true, function(args, _, IPlayer, FPlayer)
    local playerId <const>, tasksCount <const> = tonumber(args[1]) --[[@as integer]], tonumber(args[2]) --[[@as integer]]
    if HRLib.DoesIdExist(playerId, true) then
        if tasksCount then
            if not Player(playerId).state.hasComservTasks then
                Player(playerId).state.hasComservTasks = { tasksCount = tasksCount, skin = HRLib.ClientCallback('getSkin', playerId) }

                TriggerClientEvent('HRComserv:comservPlayer', playerId)
            else
                local hasComservTasks <const> = HRLib.table.deepclone(Player(playerId).state.hasComservTasks, true)
                hasComservTasks.tasksCount = tasksCount
                Player(playerId).state.hasComservTasks = hasComservTasks
            end

            FPlayer:Notify(Translation.comserv_successful, 'success')

            local currConfig <const> = config.discordLogs
            local currMessage <const> = currConfig.settings.messages.comserv_message
            if currConfig.enable and currMessage.enable then
                HRLib.DiscordMsg(currConfig.webHookURL, currConfig.settings.botName, currConfig.settings.title, currMessage.description:format(getIdentifiersForDesc(IPlayer.name, playerId, currMessage)), nil, currConfig.settings.color, '', 'System')
            end
        else
            FPlayer:Notify(Translation.comserv_failed_invalidTasksCount, 'error')
        end
    else
        FPlayer:Notify(Translation.id_notFound, 'error')
    end
end, { help = Translation.suggestions.comserv_help, restricted = true, args = { { name = 'playerId', help = Translation.suggestions.comserv_arg1_help }, { name = 'tasksCount', help = Translation.suggestions.comserv_arg2_help } } })

HRLib.RegCommand('stopComserv', true, true, function(args, _, IPlayer, FPlayer)
    local playerId <const> = tonumber(args[1]) --[[@as integer]]
    if HRLib.DoesIdExist(playerId) then
        if Player(playerId).state.hasComservTasks then
            TriggerClientEvent('HRComserv:stopComserv', playerId, true)
            FPlayer:Notify(Translation.stopComserv_successful:format(GetPlayerName(playerId)), 'success')

            local currConfig <const> = config.discordLogs
            local currMessage <const> = currConfig.settings.messages.stopComserv_message
            if currConfig.enable and currMessage.enable then
                HRLib.DiscordMsg(currConfig.webHookURL, currConfig.settings.botName, currConfig.settings.title, currMessage.description:format(getIdentifiersForDesc(IPlayer.name, playerId, currMessage)), nil, currConfig.settings.color, '', 'System')
            end
        else
            FPlayer:Notify(Translation.stopComserv_failed_hasNoComserv)
        end
    else
        FPlayer:Notify(Translation.id_notFound, 'error')
    end
end, { help = Translation.suggestions.stopComserv_help, restricted = true, args = { { name = 'playerId', help = Translation.suggestions.stopComserv_arg1_help } } })