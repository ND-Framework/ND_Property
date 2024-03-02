local properties = lib.load("data.property")
local inventory = exports.ox_inventory
local doorList = {}

local function getPropertyById(propertyId)
    for i=1, #properties do
        local info = properties[i]
        if info.id == propertyId then
            return info
        end
    end
end

SetTimeout(500, function()
    NDCore.loadSQL("database/nd_property.sql")

    Wait(500)

    MySQL.query("SELECT * FROM `nd_property`", {}, function(result)
        if not result then return end
    
        for i=1, #result do
            local item = result[i]
            local property = getPropertyById(item.property_id)
            if not property then goto skip end
    
            property.groups = json.decode(item.property_groups)
            property.resetGroupsTime = item.reset_groups_time

            -- if it's been more than one day in seconds, remove group access.
            if property.resetGroupsTime and os.time()-property.resetGroupsTime > 86400 then
                property.groups = nil
                property.resetGroupsTime = nil
            end
            
            ::skip::
        end
    end)

    MySQL.query("SELECT `id`, `name` FROM `ox_doorlock`", {}, function(result)
        if not result then return end

        for i=1, #result do
            local door = result[i]
            if door.name:find("property_") then
                doorList[door.name] = door.id
            end
        end
    end)
end)

-- update or insert property info to db.
local function updatePropertyDatabase(propertyId, groups, resetGroupsTime)
    local property_id = MySQL.scalar.await("SELECT `property_id` FROM `nd_property` WHERE `property_id` = ? LIMIT 1", {propertyId})

    if property_id then
        return MySQL.update("UPDATE `nd_property` SET `property_groups` = ?, `reset_groups_time` = ? WHERE `property_id` = ?", {
            groups and json.encode(groups) or nil, resetGroupsTime, propertyId
        })
    end

    MySQL.insert("INSERT INTO `nd_property` (`property_id`, `property_groups`, `reset_groups_time`) VALUES (?, ?, ?)", {
        propertyId, json.encode(groups), resetGroupsTime
    })
end

-- register stash for inventory, if stash already exists it will be updated.
local function updateStash(property)
    local lockerCoords = property.locker?.coords?.xyz
    if not lockerCoords then return end

    inventory:RegisterStash(
        "property_" .. property.id,
        property.label,
        50, -- slots.
        100000, -- max weight.
        nil, -- nil makes shared, true makes unique.
        nil, -- anyone allowed.
        lockerCoords
    )
end

-- get poperty id from doorname.
local function doorNameToPropertyId(str)
    local firstUnderscore = str:find("_")
    local lastUnderscore = str:find("_[^_]*$")

    if firstUnderscore and lastUnderscore then
        return str:sub(firstUnderscore+1, lastUnderscore-1)
    elseif firstUnderscore then
        return str:sub(firstUnderscore+1)
    else
        return str
    end
end

-- reorder groups array to {[group] = rank}.
local function reorderGroups(groups)
    if not groups then return {} end

    local newGroups = {}
    for i=1, #groups do
        newGroups[groups[i]] = 0
    end

    return newGroups
end

-- update ox_doorlock groups.
local function updateDoors(property)
    local doorlock = exports.ox_doorlock

    for doorName, doorId in pairs(doorList) do
        if doorNameToPropertyId(doorName) == property.id then
            local door = doorlock:getDoor(doorId)
            door.groups = reorderGroups(property.groups)
            doorlock:editDoor(doorId, door)
        end
    end
end

-- update property data, will also update db.
local function updateProperty(propertyId, groups, resetGroupsTime)
    local property = getPropertyById(propertyId)
    if not property then return end

    property.groups = groups
    property.resetGroupsTime = resetGroupsTime

    updatePropertyDatabase(propertyId, groups, resetGroupsTime)
    updateStash(property)
    updateDoors(property)
end

-- check stash permission by property groups when opening.
inventory:registerHook("openInventory", function(payload)
    if payload.inventoryType ~= "stash" or not payload.inventoryId:find("property_") then return end

    local property = getPropertyById(payload.inventoryId:gsub("property_", ""))
    if not property or not property.groups then return true end

    local player = NDCore.getPlayer(payload.source)
    for group, _ in pairs(player.groups) do
        if lib.table.contains(property.groups, group) then
            return true
        end
    end
    
    return false
end)

-- admin can get all property data from server for the property management tool.
lib.callback.register("ND_Property:getProperties", function(src)
    local player = NDCore.getPlayer(src)
    if not player or not player.groups["admin"] then return end
    return properties
end)

-- update property trough the property management admin tool.
RegisterNetEvent("ND_Property:updatePropertySettings", function(propertyId, groups, resetGroupsTime)
    local src = source
    local player = NDCore.getPlayer(src)
    if not player or not player.groups["admin"] then return end
    updateProperty(propertyId, groups, resetGroupsTime and math.floor(resetGroupsTime / 1000) or nil)
end)

-- register a stash if there isn't one for that property (first time open).
RegisterNetEvent("ND_Property:registerStash", function(propertyId)
    local property = getPropertyById(propertyId)
    if not property or not property.locker then return end
    updateStash(property)
end)

exports("updateProperty", updateProperty)
exports("getPropertyById", getPropertyById)
