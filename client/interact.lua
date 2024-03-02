local properties = lib.load("data.property")
local target = exports.ox_target
local inventory = exports.ox_inventory

local function createTarget(prop, propertyId)
    target:addLocalEntity(prop, {
        {
            name = "ND_Property:wardrobe",
            icon = "fa-solid fa-shirt",
            label = "Open wardrobe",
            distance = 1.5,
            onSelect = function()
                exports["ND_AppearanceShops"]:openWardrobe()
            end
        },
        {
            name = "ND_Property:stash",
            icon = "fa-solid fa-box",
            label = "Open stash",
            distance = 1.5,
            onSelect = function()
                local stash = "property_" .. propertyId
                if inventory:openInventory("stash", stash) ~= false then return end

                TriggerServerEvent("ND_Property:registerStash", propertyId)
                inventory:openInventory("stash", stash)
            end
        },
    })
end

for i=1, #properties do
    local info = properties[i]
    local locker = info.locker

    if not locker then goto skip end

    local point = lib.points.new({
        coords = locker.coords,
        distance = 25
    })

    function point:onEnter()
        lib.requestModel(locker.model)
        local coords = locker.coords
        local prop = CreateObject(locker.model, coords.x, coords.y, coords.z, false, false, false)
        self.prop = prop

        if not locker.noGroundSnap then
            PlaceObjectOnGroundProperly_2(prop)
        end

        SetEntityHeading(prop, coords.w)
        SetModelAsNoLongerNeeded(locker.model)
        createTarget(prop, info.id)
    end

    function point:onExit()
        local prop = self.prop
        if not prop or not DoesEntityExist(prop) then return end
        DeleteEntity(prop)
        target:removeLocalEntity(prop, {"ND_Property:wardrobe", "ND_Property:stash"})
    end

    ::skip::
end

RegisterCommand("prop", function(source, args, rawCommand)
    local coords = GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, 1.0, 0.0)
    lib.requestModel(`p_cs_locker_01_s`)
    local prop = CreateObject(`p_cs_locker_01_s`, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(prop, coords.w)
    PlaceObjectOnGroundProperly_2(prop)
    SetModelAsNoLongerNeeded(`p_cs_locker_01_s`)
end, false)
