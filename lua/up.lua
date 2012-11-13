local upload = require "resty.upload"
local cjson = require "cjson"

local chunk_size = 4096
local form = upload:new(chunk_size)
form:set_timeout(0)

while true do
    local typ, res, err = form:read()
    if not typ then
        ngx.say("failed to read: ", err)
        return
    end
    ngx.say("read: ", cjson.encode({typ, res}))
    if typ == "eof" then
        break
    end
end

local typ, res, err = form:read()
ngx.say("read: ", cjson.encode({typ, res}))

--[[
local headers = ngx.req.get_headers()
for k, v in pairs(headers) do
    ngx.say(k, "    ", v)
end
ngx.say(ngx.var.remote_addr)
--]]

--return ngx.exec("/up.lua")
