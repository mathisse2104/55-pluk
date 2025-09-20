-- exios-drugsfarm client.lua - Fixed version

DRM = { ['Functions'] = {}, ['Data'] = {} }

local SharedMessageSent, activeEntity, isInteracting = false, nil, false
local activeLocationIndex = 1
local lastLocationIndex = nil
local locationJustChanged = false
local currentActiveObjectType = nil

lib.locale()

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(PlayerData)
    ESX.PlayerData = PlayerData
    ESX.PlayerLoaded = true
end)

RegisterNetEvent('esx:onPlayerLogout')
AddEventHandler('esx:onPlayerLogout', function()
    ESX.PlayerLoaded = false
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(Job)
    ESX.PlayerData.job = Job
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for k, v in pairs(DRM.Data) do 
        for _, v in pairs(v) do 
            ESX.Game.DeleteObject(v) 
        end 
    end
end)

local function setupOxTargetForCurrentLocation()
    if not Shared or not Shared.Config or not Shared.Config.Locations[activeLocationIndex] then
        return
    end
    
    local currentLoc = Shared.Config.Locations[activeLocationIndex]
    local objectType = currentLoc.objectType
    currentActiveObjectType = objectType
    
    if Shared.Settings[objectType] then
        -- Remove all existing targets first
        exports.ox_target:removeModel(Shared.Settings[objectType]['ObjectHash'])
        
        -- Add target only for current active object type
        exports.ox_target:addModel(Shared.Settings[objectType]['ObjectHash'], {
            {
                icon = Shared.Settings[objectType]['Target Interaction']['Icon'],
                label = Shared.Settings[objectType]['Target Interaction']['Label'],
                distance = 2.0,
                canInteract = function(entity, distance, coords, name, bone)
                    if not isInteracting then
                        activeEntity = entity
                        return true
                    else
                        return false
                    end
                end,
                onSelect = function(data)
                    TriggerEvent('exios-drugsfarm:client:pickupObject', data, objectType)
                end
            },
        })
    end
end

RegisterNetEvent('exios-drugsfarm:client:setActiveLocation')
AddEventHandler('exios-drugsfarm:client:setActiveLocation', function(index)
    
    if not Shared or not Shared.Config or not Shared.Config.Locations then
        return
    end
    
    -- Delete all existing barrels from ALL object types
    for objType, objects in pairs(DRM.Data) do
        for _, obj in pairs(objects) do
            if DoesEntityExist(obj) then
                ESX.Game.DeleteObject(obj)
            end
        end
        DRM.Data[objType] = {} -- Clear the array
    end
    
    -- Update location
    lastLocationIndex = activeLocationIndex
    activeLocationIndex = index
    locationJustChanged = true
    
    -- Setup ox_target for new location
    setupOxTargetForCurrentLocation()
    
    -- Spawn at new location
    local newLoc = Shared.Config.Locations[activeLocationIndex]
    if newLoc then
        if not DRM.Data[newLoc.objectType] then 
            DRM.Data[newLoc.objectType] = {} 
        end
        DRM.Functions.SpawnObjects(newLoc.objectType, newLoc.coordinates)
    end
end)

CreateThread(function()
    ESX.TriggerServerCallback('exios-drugsfarm:server:cb:get:Shared', function(sharedData)
        if sharedData and type(sharedData) == "table" and (sharedData.Settings or sharedData.Config) then
            Shared = sharedData
        else
            return
        end
    end)

    local timeout = 0
    while not Shared and timeout < 100 do 
        Wait(100)
        timeout = timeout + 1
    end
    
    if not Shared then
        return
    end

    while not ESX.PlayerLoaded do Wait(100) end
    
    ESX.TriggerServerCallback('exios-drugsfarm:server:getActiveLocation', function(index)
        TriggerEvent('exios-drugsfarm:client:setActiveLocation', index)
    end)

    -- Main loop
    while true do 
        local sleep = 2000
        local ped = cache.ped
        local loc = Shared.Config and Shared.Config.Locations and Shared.Config.Locations[activeLocationIndex]

        if loc then
            -- Initialize data for current object type if needed
            if not DRM.Data[loc.objectType] then 
                DRM.Data[loc.objectType] = {} 
            end
            
            local distance = #(GetEntityCoords(ped) - loc.coordinates)

            if distance < 50.0 or locationJustChanged then
                -- Only spawn for the current active location's object type
                if Shared.Settings and Shared.Settings[loc.objectType] and #DRM.Data[loc.objectType] < Shared.Settings[loc.objectType]['Max Spawn Limit'] then
                    DRM.Functions.SpawnObjects(loc.objectType, loc.coordinates)
                end
                if locationJustChanged then
                    locationJustChanged = false
                end
            elseif distance >= 50.0 then
                -- Clean up barrels when far away, but only for current location type
                if DRM.Data[loc.objectType] and next(DRM.Data[loc.objectType]) and not locationJustChanged then
                    for _, obj in pairs(DRM.Data[loc.objectType]) do
                        if DoesEntityExist(obj) then
                            ESX.Game.DeleteObject(obj)
                        end
                    end
                    DRM.Data[loc.objectType] = {}
                end
            end
        end

        Wait(sleep)
    end
end)

RegisterNetEvent('exios-drugsfarm:client:pickupObject')
AddEventHandler('exios-drugsfarm:client:pickupObject', function(data, objectType)
    if isInteracting then return end
    
    -- Double check that we're picking up the correct object type
    if objectType ~= currentActiveObjectType then
        return
    end

    isInteracting = true
    TaskTurnPedToFaceEntity(cache.ped, data.entity, 1.0)
    Wait(1500)

    LocalPlayer.state.invBusy = true
    FreezeEntityPosition(cache.ped, true)

    if Shared.Settings[objectType]['Pick-Up']['Animation'] then 
        ESX.Streaming.RequestAnimDict(Shared.Settings[objectType]['Pick-Up']['Animation']['Dict'], function()
            TaskPlayAnim(cache.ped, Shared.Settings[objectType]['Pick-Up']['Animation']['Dict'], Shared.Settings[objectType]['Pick-Up']['Animation']['Clip'], 1.0, 1.0, 3000, 33, 1, false, false, false)
        end)
    end

    Wait(1500)

    local success = lib.skillCheck({'easy', 'easy', 'easy'}, {'a', 'f', 'e'})

    FreezeEntityPosition(cache.ped, false)
    ClearPedTasks(cache.ped)
    Wait(750)

    if success then
        ESX.Game.DeleteObject(activeEntity)

        for i, obj in ipairs(DRM.Data[objectType]) do
            if obj == activeEntity then
                table.remove(DRM.Data[objectType], i)
                break
            end
        end

        TriggerServerEvent('exios-drugsfarm:server:pickubOject', activeEntity, objectType)

        -- Spawn replacement
        if Shared.Config and Shared.Config.Locations then
            local loc = Shared.Config.Locations[activeLocationIndex]
            if loc and loc.objectType == objectType then
                CreateThread(function()
                    Wait(2000)
                    local drugCoords = DRM.Functions.GenerateCoords(loc.coordinates, objectType)
                    ESX.Game.SpawnLocalObject(Shared.Settings[objectType]['ObjectHash'], drugCoords, function(obj)
                        if DoesEntityExist(obj) then
                            SetEntityCoords(obj, drugCoords.x, drugCoords.y, drugCoords.z, false, false, false, true)
                            Wait(100)
                            PlaceObjectOnGroundProperly(obj)
                            Wait(100)
                            FreezeEntityPosition(obj, true)
                            DRM.Data[objectType][#DRM.Data[objectType]+1] = obj
                        end
                    end)
                end)
            end
        end
    else
        lib.notify({type = 'error', description = 'Plukken mislukt, probeer het opnieuw!'})
    end

    isInteracting = false
    LocalPlayer.state.invBusy = false
    activeEntity = nil
end)

-- DRM Functions
DRM.Functions.SpawnObjects = function(objType, coords)
    if not Shared or not Shared.Settings or not Shared.Settings[objType] then
        return
    end
    
    CreateThread(function()
        local targetCount = Shared.Settings[objType]['Max Spawn Limit']
        local currentCount = #DRM.Data[objType]
        local toSpawn = targetCount - currentCount
       
        for i = 1, toSpawn do
            Wait(200)
            local drugCoords = DRM.Functions.GenerateCoords(coords, objType)
            
            ESX.Game.SpawnLocalObject(Shared.Settings[objType]['ObjectHash'], drugCoords, function(obj)
                if DoesEntityExist(obj) then
                    SetEntityCoords(obj, drugCoords.x, drugCoords.y, drugCoords.z, false, false, false, true)
                    Wait(100)
                    PlaceObjectOnGroundProperly(obj)
                    Wait(100)
                    FreezeEntityPosition(obj, true)
                    DRM.Data[objType][#DRM.Data[objType]+1] = obj
                end
            end)
        end
    end)
end

DRM.Functions.ValidateCoord = function(objType, plantCoord, coords)
    if #DRM.Data[objType] > 0 then
        local validate = true
        for k, v in pairs(DRM.Data[objType]) do
            if DoesEntityExist(v) and #(plantCoord - GetEntityCoords(v)) < 3 then
                validate = false
                break
            end
        end
        if #(plantCoord - coords) > 50 then
            validate = false
        end
        return validate
    else
        return true
    end
end

DRM.Functions.GenerateCoords = function(coords, objType)
    local attempts = 0
    while attempts < 100 do
        Wait(1) 
        local drugsCoordX, drugsCoordY

        math.randomseed(GetGameTimer() + attempts)
        local modX = math.random(-15, 15)
        Wait(10)
        math.randomseed(GetGameTimer() + attempts + 1000)
        local modY = math.random(-15, 15)

        drugsCoordX = coords.x + modX
        drugsCoordY = coords.y + modY

        local coordZ = DRM.Functions.GetZCoordinate(drugsCoordX, drugsCoordY)
        
        if not coordZ or coordZ < coords.z - 10 or coordZ > coords.z + 10 then
            coordZ = coords.z
        end
        
        local coord = vector3(drugsCoordX, drugsCoordY, coordZ)

        if DRM.Functions.ValidateCoord(objType, coord, coords) then 
            return coord 
        end
        
        attempts = attempts + 1
    end
    
    return vector3(coords.x + math.random(-5, 5), coords.y + math.random(-5, 5), coords.z)
end

DRM.Functions.GetZCoordinate = function(x, y)
    local groundCheckHeights = { 50, 51.0, 52.0, 53.0, 54.0, 55.0, 56.0, 57.0, 58.0, 59.0, 60.0 }

    for i, height in ipairs(groundCheckHeights) do
        local foundGround, z = GetGroundZFor_3dCoord(x, y, height)
        if foundGround then return z end
    end

    return 53.85
end
