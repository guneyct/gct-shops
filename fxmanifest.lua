fx_version 'cerulean'
game 'gta5'

version '1.0.0'

escrow_ignore = {
    "config.lua"
}

shared_scripts {
    '@PolyZone/client.lua',
    '@PolyZone/BoxZone.lua',
    '@PolyZone/EntityZone.lua',
    '@PolyZone/CircleZone.lua',
    '@PolyZone/ComboZone.lua',
    '@qb-core/shared/locale.lua',
    'locale/tr.lua',
    'config.lua'
}

client_script 'client/main.lua'
server_script {'@oxmysql/lib/MySQL.lua', 'server/main.lua' }

lua54 'yes'