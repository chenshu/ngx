local resty_md5 = require "resty.md5"
local resty_str = require "resty.string"
local resty_upload = require "resty.upload"
local common = require "lua.common"

local md5 = resty_md5:new()

local app_secret = "84846872146146823164821648216482"

local chunk_size = 4096
local form = resty_upload:new(chunk_size)
form:set_timeout(0)

local key
local value
local params = {}
local is_file = false
local body = ""

while true do
    local typ, res, err = form:read()
    if not typ then
        ngx.exit(ngx.HTTP_BAD_REQUEST)
        return
    end
    if typ == "header" and #res == 3 then
        for k, v in string.gmatch(res[2], "(%S+)=\"([^\"]+)\"") do
            if k == "name" and string.find(v, "nsp_") == 1 then
                key = v
            elseif k == "filename" then
                is_file = true
            end
        end
    elseif typ == "body" then
        if key then
            value = res
        elseif is_file then
            body = body .. res
        end
    elseif typ == "part_end" then
        if key then
            params[key] = value
            key = nil
            value = nil
        elseif is_file then
            is_file = false
        end
    elseif typ == "eof" then
        break
    end
end

local nsp_key
local nsp_tstr
local s = ""
for k, v in common.pairsByKeys(params) do
    if k == "nsp_key" then
        nsp_key = v
    elseif k == "nsp_tstr" then
        nsp_tstr = v
        s = s .. k .. v
    else
        s = s .. k .. v
    end
end

if not nsp_key then
    ngx.exit(ngx.HTTP_BAD_REQUEST)
    return
end

local secret = app_secret

if nsp_tstr then
    md5:reset()
    md5:update(app_secret)
    md5:update(nsp_tstr)
    secret = resty_str.to_hex(md5:final())
end

md5:reset()
md5:update(secret)
md5:update(s)
local post_key = resty_str.to_hex(md5:final())
if string.lower(nsp_key) ~= post_key then
    ngx.exit(ngx.HTTP_BAD_REQUEST)
    return
end

ngx.var.c_type = content_type
local data = ""
local boundary = "--" .. string.match(content_type, "boundary=([-%w]+)") .. "\r\n"
local prefix = "Content-Disposition: form-data; name="
for k, v in pairs(params) do
    data = data .. boundary .. prefix .. "\"" .. k .. "\"" .. "\r\n"
    data = data .. "\r\n"
    data = data .. v .. "\r\n"
end
data = data .. boundary .. prefix .. "\"userfile\"; filename=\"tmpfile\"\r\n"
data = data .. "Content-Type: application/octet-stream\r\n\r\n" .. body .. "\r\n"
data = data .. boundary .. "--\r\n"
res = ngx.location.capture("/up/upload_small_file", {method = ngx.HTTP_POST, body = data, copy_all_vars = true})
ngx.status = res.status
ngx.say(res.body)
ngx.exit(ngx.HTTP_OK)
