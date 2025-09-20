-- shared.lua

-- This file contains shared variables and functions that are used by both the client and server.

Shared = {}

lib.locale()

Shared.Settings = {
    ['Benzo'] = {
        ['Max Spawn Limit'] = 15,
        ['Pick-Up'] = {
            ['Animation'] = {
                ['Dict'] = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
                ['Clip'] = 'machinic_loop_mechandplayer'
            }
        },
        ['Items'] = {
            ['Add'] = {
                ['Item'] = { 'benzo' },
                ['IsRandomized'] = true,
                ['Amount'] = { 2, 7 }
            }
        },
        ['ObjectHash'] = `h4_prop_h4_barrel_01a`,
        ['Target Interaction'] = {
            ['Icon'] = 'fa-solid fa-pills',
            ['Label'] = 'Pluk benzo'
        }
    },
    ['Methanol'] = {
        ['Max Spawn Limit'] = 15,
        ['Pick-Up'] = {
            ['Animation'] = {
                ['Dict'] = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
                ['Clip'] = 'machinic_loop_mechandplayer'
            }
        },
        ['Items'] = {
            ['Add'] = {
                ['Item'] = { 'methanol' },
                ['IsRandomized'] = true,
                ['Amount'] = { 2, 7 }
            }
        },
        ['ObjectHash'] = `h4_prop_h4_barrel_01a`,
        ['Target Interaction'] = {
            ['Icon'] = 'fa-solid fa-flask',
            ['Label'] = 'Pluk methanol'
        }
    }
}

Shared.Config = {
    -- Location switch interval in minutes
    LocationSwitchInterval = 15,
    
    -- Discord webhook configuration
    Discord = {
        Enabled = true, -- Set to false to disable Discord notifications
        WebhookURL = "",
        
        -- Webhook appearance settings
        Username = "55 Development",
        AvatarURL = "https://mathisse.nl/logo.png",
        ThumbnailURL = "https://mathisse.nl/logo.png",
        FooterIconURL = "https://mathisse.nl/logo.png",
        
        -- Embed settings
        Title = "🔄 Drugs locatie veranderd.",
        Description = "De actieve drugs locatie is veranderd naar **{DRUG_TYPE}**.",
        Color = 3447003, -- Decimal color (blue)
        
        -- Field names (customize the text)
        Fields = {
            PreviousLocation = "Vorige Locatie",
            NewLocation = "Nieuwe Locatie", 
            DrugType = "Drug soort",
            NextSwitch = "Volgende Locatie"
        },
        
        -- Footer text
        FooterText = "55 Development"
    },
    
    -- Available farming locations for benzo and methanol
    Locations = {
        -- Benzo Locations
        [1] = {
            label = "Benzo Paleto Links",
            objectType = "Benzo",
            coordinates = vec3(-940.3034, 6186.6514, 4.0062),
            rewardItem = "benzo"
        },
        [2] = {
            label = "Benzo Paleto Rechts", 
            objectType = "Benzo",
            coordinates = vec3(56.4722, 7208.5581, 3.8571),
            rewardItem = "benzo"
        },
        [3] = {
            label = "Benzo Sandy Shores Noord",
            objectType = "Benzo",
            coordinates = vec3(1905.2791, 4653.2642, 40.9784),
            rewardItem = "benzo"
        },
        [4] = {
            label = "Benzo Sandy Shores Zuid",
            objectType = "Benzo",
            coordinates = vec3(2557.2791, 3853.2642, 33.9784),
            rewardItem = "benzo"
        },
        [5] = {
            label = "Benzo Grapeseed Oost",
            objectType = "Benzo",
            coordinates = vec3(2905.1234, 4512.5678, 48.1234),
            rewardItem = "benzo"
        },
        
        -- Methanol Locations
        [6] = {
            label = "Methanol Eiland onder vliegveld",
            objectType = "Methanol", 
            coordinates = vec3(4700.1133, -4656.9414, 3.0377),
            rewardItem = "methanol"
        },
        [7] = {
            label = "Methanol Eiland Bij vliegveld",
            objectType = "Methanol",
            coordinates = vec3(4159.0093, -4464.1470, 2.2363),
            rewardItem = "methanol"
        },
        [8] = {
            label = "Methanol Mount Chiliad",
            objectType = "Methanol",
            coordinates = vec3(-1205.6789, 2789.4321, 18.5432),
            rewardItem = "methanol"
        },
        [9] = {
            label = "Methanol sandy",
            objectType = "Methanol",
            coordinates = vec3(1205.9876, 3456.7890, 35.2468),
            rewardItem = "methanol"
        },
        [10] = {
            label = "Methanol Desert Airfield",
            objectType = "Methanol",
            coordinates = vec3(1745.3210, 3287.6543, 41.1357),
            rewardItem = "methanol"
        }
    }
}
