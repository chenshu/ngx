module("lua.common", package.seeall)

function pairsByKeys(t, f)
    local arr = {}
    for k in pairs(t) do arr[#arr + 1] = k end
    table.sort(arr, f)
    local i = 0
    return function ()
        i = i + 1
        return arr[i], t[arr[i]]
    end
end

function keyExists(t, key)
    for k, v in pairs(t) do
        if key == k then
            return true
        end
    end

    return false
end

function valueExists(t, value)
    for k, v in pairs(t) do
        if value == v then
            return true
        end
    end

    return false
end
