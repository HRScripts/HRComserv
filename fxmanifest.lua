fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'HRComserv'
author 'HRScripts Development'
description 'A community comserv resource available for QBCore & ESX frameworks'
version '1.0.0'

shared_script '@HRLib/import.lua'

client_script 'client/main.lua'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua'
}

files {
    'config.lua',
    'client/modules/*.lua',
    'translation.lua'
}

dependencies {
    'HRLib',
    'oxmysql'
}