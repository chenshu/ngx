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
