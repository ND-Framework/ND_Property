local properties = {}
local function getListPropertyIdList()
    local list = {}
    for i=1, #properties do
        local info = properties[i]
        list[#list+1] = { value = info.id, label = info.id }
    end
    return list
end

local function getGroupsFromProperty(propertyId)
    for i=1, #properties do
        local info = properties[i]
        if info.id == propertyId then
            return info.groups and table.concat(info.groups, ", ")
        end
    end
end

local function stringToArray(str)
    if str == "" then return end

    local array = {}
    for item in str:gmatch("%s*([^,]+)%s*,?") do
        table.insert(array, item:match("^%s*(.-)%s*$"))
    end

    return array
end

RegisterCommand("property", function(source, args, rawCommand)
    local player = NDCore.getPlayer()
    if not player or not player.groups["admin"] then return end
    
    properties = lib.callback.await("ND_Property:getProperties")

    local input = lib.inputDialog("Select property", {
        {
            type = "select",
            label = "Property Id",
            required = true,
            options = getListPropertyIdList()
        }
    })

    if not input or input[1] == "" then return end

    local input2 = lib.inputDialog("Select property", {
        {
            type = "input",
            label = "Groups allowed",
            description = "If multiple separate each group by a comma",
            placeholder = "lspd, lsfd, bennys",
            default = getGroupsFromProperty(input[1])
        },
        {
            type = "checkbox",
            label = "Remove groups after date?"
        },
        {
            type = "date",
            label = "Date input",
            icon = {"far", "calendar"},
            default = true,
            format = "DD/MM/YYYY",
            description = "If above is selected, groups wont have access after date."
        }
    })

    if not input2 then return end

    TriggerServerEvent("ND_Property:updatePropertySettings", input[1], stringToArray(input2[1]), input2[2] and input2[3] or nil)
end, false)

TriggerEvent("chat:addSuggestion", "/property", "Admin command, manage property")
