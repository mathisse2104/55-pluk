DRM.Functions.SpawnObjects = function(objType, coords)
    CreateThread(function()
        local targetCount = Shared.Settings[objType]['Max Spawn Limit']
        local currentCount = #DRM.Data[objType]
        local toSpawn = targetCount - currentCount
     
        
        for i = 1, toSpawn do
            Wait(100) -- Small delay between spawns
            local drugCoords = DRM.Functions.GenerateCoords(coords, objType)
            ESX.Game.SpawnLocalObject(Shared.Settings[objType]['ObjectHash'], drugCoords, function(obj)
                if DoesEntityExist(obj) then
                    PlaceObjectOnGroundProperly(obj)
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
    while attempts < 100 do -- Prevent infinite loops
        Wait(1) 
        local drugsCoordX, drugsCoordY

        math.randomseed(GetGameTimer() + attempts)
        local modX = math.random(-15, 15)  -- Reduced from -20, 20
        Wait(10)
        math.randomseed(GetGameTimer() + attempts + 1000)
        local modY = math.random(-15, 15)  -- Reduced from -20, 20

        drugsCoordX = coords.x + modX
        drugsCoordY = coords.y + modY

        local coordZ = DRM.Functions.GetZCoordinate(drugsCoordX, drugsCoordY)
        local coord = vector3(drugsCoordX, drugsCoordY, coordZ)

        if DRM.Functions.ValidateCoord(objType, coord, coords) then 
            return coord 
        end
        
        attempts = attempts + 1
    end
    
    -- Fallback coordinate if validation fails too many times
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
