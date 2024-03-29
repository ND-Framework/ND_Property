-- For support join my discord: https://discord.gg/Z9Mxu72zZ6

author "Andyyy"
description "Property system for ND_Core"
version "1.0.0"

fx_version "cerulean"
game "gta5"
lua54 "yes"

files {
    "data/**"
}

dependencies {
    "ox_lib",
    "ox_doorlock",
    "ox_inventory",
    "ND_Core"
}

shared_scripts {
    "@ox_lib/init.lua",
    "@ND_Core/init.lua"
}

server_scripts {
    "@oxmysql/lib/MySQL.lua",
    "server/**"
}

client_scripts {
    "client/**"
}
