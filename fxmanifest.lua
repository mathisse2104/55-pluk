fx_version "adamant"
game "gta5"
use_fxv2_oal "yes"
lua54 "yes"
version "1.0.0"
author '55 Development'
description '55 Drugspluk'

dependencies { 
    "ox_lib", 
    "ox_target", 
    "ox_inventory",
    "es_extended"
}

client_scripts { 
    "client.lua"
}

server_scripts { 
    "server.lua" 
}

shared_scripts { 
    "@es_extended/imports.lua", 
    "@ox_lib/init.lua", 
    "shared.lua" 
}

escrow_ignore {
    "shared.lua"
}
