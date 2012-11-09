local resty_md5 = require "resty.md5"
local upload = require "resty.upload"
local resty_str = require "resty.string"

local chunk_size = 4096
local form = upload:new(chunk_size)
local md5 = resty_md5:new()
local file
while true do
    local typ, res, err = form:read()
    if not typ then
        ngx.say("failed to read: ", err)
        return
    end

    if typ == "header" then
        local file_name = "abcdef"
        if file_name then
            file = io.open(file_name, "w+")
            if not file then
                ngx.say("failed to open file ", file_name)
                return
            end
        end
    elseif typ == "body" then
        if file then
            file:write(res)
            md5:update(res)
        end
    elseif typ == "part_end" then
        file:close()
        file = nil
        local md5_sum = md5:final()
        md5:reset()
        ngx.say(resty_str.to_hex(md5_sum))
    elseif typ == 'eof' then
        break
    else
    end
end
