fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'HRComserv'
author 'HRScripts Development'
description 'A community services resource available for Ox, ESX & QBCore frameworks'
version '1.0.2'

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