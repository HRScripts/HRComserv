local config <const> = {}

config.language = 'en'

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
                coords = vector4(158.9692, -1003.9127, 29.3883, 159.6395),
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

config.disabledControls = { -- You can add the disabled controls during comserv here
    'F2',
    'TAB',
    'F1'
}

config.tasksMarker = {
    type = 21,
    colour = {
        red = 255,
        green = 255,
        blue = 255
    },
    alpha = 255
}

config.finishComservPosition = vector3(422.9242, -979.4069, 30.7094)

config.restorePlayerWeapons = true -- Choose to restore the player's weapons after finishing it's tasks

return config