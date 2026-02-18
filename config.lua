local config <const> = {}

config.language = 'en'

config.discordLogs = {
    enable = true,
    webHookURL = 'https://discord.com/webhooks/......',
    settings = {
        botName = 'Logs',
        title = 'Community Services',
        color = 999999,
        messages = {
            comserv_message = {
                enable = true,
                description = 'Player %s was sent to community services.\n\n\nLicense: %s\nSteam Hex: %s\nFiveM Id: %s\nDiscord: %s\nStaff Name: %s',
                showedIdentifiers = {
                    'name',
                    'license',
                    'steam',
                    'fivem',
                    'discord',
                    'staffName'
                }
            },
            finishComserv_message = {
                enable = true,
                description = 'Player %s finished its community services.\n\n\nLicense: %s\nSteam Hex: %s\nFiveM Id: %s\nDiscord: %s',
                showedIdentifiers = {
                    'name',
                    'license',
                    'steam',
                    'fivem',
                    'discord'
                }
            },
            stopComserv_message = {
                enable = true,
                description = 'Community services of player %s were stopped.\n\n\nLicense: %s\nSteam Hex: %s\nFiveM Id: %s\nDiscord: %s\nStaff Name: %s',
                showedIdentifiers = {
                    'name',
                    'license',
                    'steam',
                    'fivem',
                    'discord',
                    'staffName'
                }
            }
        }
    }
}

--[[
    The count of the showed identifiers for each message must be same as the `%s` symbols count in the description (the arrangement of the showed identifiers here is important!)
    Possible Identifiers:
    'name',
    'steam',
    'licese',
    'license2',
    'fivem',
    'discord',
    'ip',
    'xbl',
    'live',
    'staffName' -- This identifier is not available for the finishComserv_message!
]]

config.tasksDuration = {
    hammerFix = 5000,
    sweeping = 5000,
    digging = 5000
}

config.taskButton = 'E'

config.comservLocations = {
    {
        spawnCoords = vector3(1772.3788, 3797.0134, 33.9043),
        allowedDistance = 15.0,
        tasks = {
            {
                coords = vector4(1777.6198, 3795.4888, 33.9795, 600.0),
                type = 'hammerFix'
            },
            {
                coords = vector4(1777.0300, 3799.5671, 34.5231, 298.9253),
                type = 'sweeping'
            },
            {
                coords = vector4(1768.1304, 3805.5369, 34.1334, 48.5324),
                type = 'digging'
            }
        }
    },
    {
        spawnCoords = vector3(165.4393, -989.9612, 30.0857),
        allowedDistance = 25.0,
        tasks = {
            {
                coords = vector4(156.7134, -1007.0770, 29.5411, 160.8827),
                type = 'hammerFix'
            },
            {
                coords = vector4(163.5233, -1006.0145, 29.3967, 249.2508),
                type = 'sweeping'
            },
            {
                coords = vector4(178.7770, -997.6605, 29.2918, 251.4863),
                type = 'digging'
            }
        }
    }
}

config.comservClothes = { -- Each field's value is the cloth number
	tshirt_1 = 0,
	tshirt_2 = 0,
	torso_1 = 0,
	torso_2 = 0,
	decals_1 = 0,
	decals_2 = 0,
	arms = 0,
	pants_1 = 0,
	pants_2 = 0,
	shoes_1 = 0,
	shoes_2 = 0
}

config.disableInventory = true

config.restorePlayerItems = true -- Choose to restore the player's items/weapons after finishing its tasks

config.removePlayerItems = true

config.finishComservPosition = vector3(422.9242, -979.4069, 30.7094)

config.tasksMarker = {
    type = 21,
    colour = {
        red = 255,
        green = 255,
        blue = 255
    },
    alpha = 255
}

config.disablePlacesChangeAfterRejoin = false -- Sets whether or not the cleaning place should change each time the player rejoins (a player that has community services)

return config