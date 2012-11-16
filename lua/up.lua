local resty_md5 = require "resty.md5"
local resty_str = require "resty.string"
local resty_random = require "resty.random"
local resty_upload = require "resty.upload"
local common = require "lua.common"
local util = require "lua.util"

local nsp_key = ""
local nsp_tstr = "1352890147"

local md5 = resty_md5:new()

local chunk_size = 4096
local form = resty_upload:new(chunk_size)
form:set_timeout(0)

local client_body_temp_path = "client_body_temp"
local client_body_temp_file = ngx.shared.client_body_temp_file
if client_body_temp_file:get("id") == nil then
    util.prepare(client_body_temp_file)
end
local params = {}
local key
local value
local file
local file_path
local file_hash
local file_size = 0
local files = {}

while true do
    local typ, res, err = form:read()
    if not typ then
        ngx.say("failed to read: ", err)
        return
    end
    if typ == "header" and #res == 3 then
        for k, v in string.gmatch(res[2], "(%S+)=\"([^\"]+)\"") do
            if k == "name" and string.find(v, "nsp_") == 1 then
                key = v
            elseif k == "filename" then
                file_path = string.format("%s/%s", client_body_temp_path, client_body_temp_file:incr("id", 1))
                file = io.open(file_path, "w+")
                if not file then
                    ngx.say("failed to open file ", file_name)
                    return
                end
            else
            end
        end
    elseif typ == "body" then
        if key then
            value = res
        elseif file then
            file:write(res)
            md5:update(res)
            file_size = file_size + string.len(res)
        else
        end
    elseif typ == "part_end" then
        if key then
            params[key] = value
            key = nil
        elseif file then
            file:close()
            file = nil
            local md5_sum = md5:final()
            file_hash = resty_str.to_hex(md5_sum)
            files[file_path] = {hash = file_hash, size = file_size, fid = file_hash .. string.format("%x", file_size)}
            file_size = 0
            md5:reset()
        else
        end
    elseif typ == "eof" then
        break
    else
    end
end

local s = ""
for k, v in common.pairsByKeys(params) do
    if k ~= "nsp_key" then
        s = s .. k .. v
    else
        ngx.say("nsp_key=", v)
    end
end

md5:reset()
md5:update(nsp_key)
md5:update(nsp_tstr)
local app_secret = resty_str.to_hex(md5:final())
md5:reset()
md5:update(app_secret)
md5:update(s)
ngx.say("cal_key=", resty_str.to_hex(md5:final()))
md5:reset()
md5:update(nsp_key)
md5:update(s)
ngx.say("cal_key=", resty_str.to_hex(md5:final()))

local cnt = 0

for k, v in pairs(files) do
    ngx.say(k)
    for field, value in pairs(v) do
        ngx.say(field, "===", value)
        if field == "size" then
            cnt = cnt + value
        end
    end
end

local headers = ngx.req.get_headers()
for k, v in pairs(headers) do
    ngx.say(k, "===", v)
    if k == "content-length" then
        ngx.say(tonumber(v) - cnt)
    end
end


--return ngx.exec("/up.lua")
