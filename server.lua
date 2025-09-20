-- Wait for shared data to load
CreateThread(function()
    Wait(2000)
end)

local activeLocationIndex = 1
local lastLocationIndex = nil
local nextSwitchTime = nil
local lastObjectType = nil

-- Initialize timer
CreateThread(function()
    Wait(3000)
    if Shared and Shared.Config then
        local intervalMs = Shared.Config.LocationSwitchInterval * 60 * 1000
        nextSwitchTime = GetGameTimer() + intervalMs
    end
end)

ESX.RegisterServerCallback('55-drugsfarm:server:cb:get:Shared', function(src, cb)
    cb(Shared)
end)

RegisterNetEvent('55-drugsfarm:server:pickubOject')
AddEventHandler('55-drugsfarm:server:pickubOject', function(entity, objectType)
    if not Shared or not Shared.Settings[objectType] then 
        return 
    end

    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then 
        return 
    end

    local itemConfig = Shared.Settings[objectType]['Items']['Add']
    local amount = itemConfig['Amount']
    
    if itemConfig['IsRandomized'] then 
        amount = math.random(itemConfig['Amount'][1], itemConfig['Amount'][2])
    end

    local itemName = itemConfig['Item'][1]
    
    local canCarry = exports.ox_inventory:CanCarryItem(source, itemName, amount)
    
    if not canCarry then 
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Je kan dit niet meer dragen..',
            duration = 4000
        })
        return 
    end

    local success = exports.ox_inventory:AddItem(source, itemName, amount)
    
    if success then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'success',
            description = 'Je hebt ' .. amount .. 'x ' .. itemName .. ' gekregen!',
            duration = 3000
        })
    end
end)

local function getAlternatingLocation()
    if not Shared or not Shared.Config or not Shared.Config.Locations then
        return 1
    end
    
    -- Get current location's object type
    local currentObjectType = nil
    if activeLocationIndex > 0 and Shared.Config.Locations[activeLocationIndex] then
        currentObjectType = Shared.Config.Locations[activeLocationIndex].objectType
    end
    
    -- Determine what object type we want next (alternate)
    local targetObjectType = nil
    if currentObjectType == "Benzo" then
        targetObjectType = "Methanol"
    elseif currentObjectType == "Methanol" then
        targetObjectType = "Benzo"
    else
        -- First run, start with Benzo
        targetObjectType = "Benzo"
    end
    
    -- Find all locations with the target object type
    local availableLocations = {}
    for i = 1, #Shared.Config.Locations do
        if Shared.Config.Locations[i].objectType == targetObjectType and i ~= activeLocationIndex then
            table.insert(availableLocations, i)
        end
    end
    
    -- If no locations found for target type, get any location of the other type
    if #availableLocations == 0 then
        local otherType = (targetObjectType == "Benzo") and "Methanol" or "Benzo"
        for i = 1, #Shared.Config.Locations do
            if Shared.Config.Locations[i].objectType == otherType and i ~= activeLocationIndex then
                table.insert(availableLocations, i)
            end
        end
    end
    
    -- Select random location from available ones
    if #availableLocations > 0 then
        math.randomseed(os.time())
        local randomIndex = math.random(1, #availableLocations)
        return availableLocations[randomIndex]
    else
        return 1
    end
end

local function sendDiscordWebhook(oldLocation, newLocation)
    if not Shared or not Shared.Config or not Shared.Config.Discord or not Shared.Config.Discord.Enabled then
        return
    end
    
    if not Shared.Config.Discord.WebhookURL or Shared.Config.Discord.WebhookURL == "" then
        return
    end
    
    local oldLocationName = oldLocation and Shared.Config.Locations[oldLocation] and Shared.Config.Locations[oldLocation].label or "None"
    local newLocationName = Shared.Config.Locations[newLocation] and Shared.Config.Locations[newLocation].label or "Unknown"
    local newObjectType = Shared.Config.Locations[newLocation] and Shared.Config.Locations[newLocation].objectType or "Unknown"
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    
    -- Replace placeholder in description
    local description = Shared.Config.Discord.Description:gsub("{DRUG_TYPE}", newObjectType)
    
    local webhookData = {
        ["username"] = Shared.Config.Discord.Username,
        ["avatar_url"] = Shared.Config.Discord.AvatarURL,
        ["embeds"] = {
            {
                ["title"] = Shared.Config.Discord.Title,
                ["description"] = description,
                ["color"] = Shared.Config.Discord.Color,
                ["thumbnail"] = { ["url"] = Shared.Config.Discord.ThumbnailURL },
                ["fields"] = {
                    {
                        ["name"] = Shared.Config.Discord.Fields.PreviousLocation,
                        ["value"] = oldLocationName,
                        ["inline"] = true
                    },
                    {
                        ["name"] = Shared.Config.Discord.Fields.NewLocation, 
                        ["value"] = newLocationName,
                        ["inline"] = true
                    },
                    {
                        ["name"] = Shared.Config.Discord.Fields.DrugType,
                        ["value"] = newObjectType,
                        ["inline"] = true
                    },
                    {
                        ["name"] = Shared.Config.Discord.Fields.NextSwitch,
                        ["value"] = "In " .. Shared.Config.LocationSwitchInterval .. " minuten",
                        ["inline"] = false
                    }
                },
                ["footer"] = {
                    ["text"] = Shared.Config.Discord.FooterText .. " • " .. timestamp,
                    ["icon_url"] = Shared.Config.Discord.FooterIconURL
                }
            }
        }
    }
    
    PerformHttpRequest(Shared.Config.Discord.WebhookURL, function(err, text, headers)
        -- Silent execution, no console logs
    end, 'POST', json.encode(webhookData), { 
        ['Content-Type'] = 'application/json' 
    })
end

local function notifyClientsLocationChange(newIndex)
    if not Shared or not Shared.Config or not Shared.Config.Locations[newIndex] then
        return
    end
    
    -- Send Discord notification
    sendDiscordWebhook(lastLocationIndex, newIndex)
    
    -- Send location change to all clients
    TriggerClientEvent('exios-drugsfarm:client:setActiveLocation', -1, newIndex)
end

-- Main location switching loop
CreateThread(function()
    while true do
        if Shared and Shared.Config and nextSwitchTime then
            local currentTime = GetGameTimer()
            
            if currentTime >= nextSwitchTime then
                local newLocation = getAlternatingLocation()
                
                lastLocationIndex = activeLocationIndex
                activeLocationIndex = newLocation
                
                -- Reset timer
                local intervalMs = Shared.Config.LocationSwitchInterval * 60 * 1000
                nextSwitchTime = currentTime + intervalMs
                
                -- Notify clients
                notifyClientsLocationChange(activeLocationIndex)
            end
        end
        
        Wait(5000)
    end
end)

ESX.RegisterServerCallback('exios-drugsfarm:server:getActiveLocation', function(src, cb)
    cb(activeLocationIndex)
end)
