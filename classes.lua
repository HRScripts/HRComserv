---@class HRComservConfig
---@field language string
---@field discordLogs { enable: boolean, webHookURL: string, settings: { botName: string, title: string, color: integer<6>, messages: { enable: boolean, description: string, showedIdentifiers: string[] }[] } }
---@field tasksDuration { hammerFix: integer, sweeping: integer, digging: integer }
---@field taskButton integer<360>
---@field comservLocations { spawnCoords: vector3, allowedDistance: number, tasks: { coords: vector4, type: 'hammerFix'|'digging'|'sweeping' }[] }[]
---@field comservClothes table
---@field disableInventory boolean
---@field tasksMarker { type: integer<43>, colour: { red: integer<255>, green: integer<255>, blue: integer<255> }, alpha: integer<255> }
---@field finishComservPosition vector3
---@field restorePlayerItems boolean
---@field removePlayerItems boolean

---@class HRComservClientFunctions
---@field setClothes fun(targetPed: integer)
---@field getClothes fun(targetPed: integer): string
---@field convertComponents fun(oldSkin: table, components: table): { component_id: integer<11>, drawable: number, texture: number }[]<11>
---@field createMarker fun(markerPosition: vector4)
---@field startTask fun(taskType: 'hammerFix'|'digging'|'sweeping', playerPosition: vector4)
---@field removeAllPlayerItems fun(): string[]
---@field restoreAllPlayerItems function

---@class HRComservTranslation
---@field tooFar string
---@field id_notFound string
---@field prefix_textUI string
---@field comserv_successful string
---@field comserv_failed_invalidTasksCount string
---@field stopComserv_successful string
---@field stopComserv_failed_hasNoComserv string
---@field suggestions { comserv_help: string, comserv_arg1_help: string, comserv_arg2_help: string, stopComserv_help: string, stopComserv_arg1_help: string }