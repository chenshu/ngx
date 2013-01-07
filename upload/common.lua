module("upload.common", package.seeall)

local resty_str = require "resty.string"
local resty_random = require "resty.random"

function random(length)
    local strong_random = resty_random.bytes(length, true)
    while strong_random == nil do
        strong_random = resty_random.bytes(length, true)
    end
    return resty_str.to_hex(strong_random)
end
