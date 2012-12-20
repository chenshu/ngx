local SMALL_FILE_SIZE = 1024 * 105

local file_length = 0
ngx.req.read_body()
local args = ngx.req.get_post_args()
local post_args = ngx.encode_args(args)
for key, val in pairs(args) do
    if key == "nsp_fsize" then
        file_length = val
    end
end

--[[
-- TODO for test
local resty_md5 = require "resty.md5"
local resty_str = require "resty.string"
local common = require "lua.common"
local md5 = resty_md5:new()
local app_secret = ""
local s = ""
local params = {}

for key, val in common.pairsByKeys(args) do
    if key == "nsp_fsize" then
        file_length = val
    end
    local secret = ""
    if key == "nsp_tstr" then
        md5:reset()
        md5:update(secret)
        md5:update(val)
        app_secret = resty_str.to_hex(md5:final())
    end
    if key == "nsp_filename" then
        s = s .. key .. ngx.escape_uri(val)
        params[key] = ngx.escape_uri(val)
    elseif string.find(key, "nsp_") == 1 and key ~= "nsp_key" then
        s = s .. key .. val
        params[key] = val
    end
end
md5:reset()
md5:update(app_secret)
md5:update(s)
local nsp_key = resty_str.to_hex(md5:final())
params["nsp_key"] = nsp_key
local post_args = ngx.encode_args(params)
--]]

if tonumber(file_length) > SMALL_FILE_SIZE then
    res = ngx.location.capture("/up_retcon/upload_big_file", {method = ngx.HTTP_POST, body = post_args})
    if res.status ~= ngx.HTTP_OK then
        ngx.status = res.status
    end
    ngx.say(res.body)
    ngx.exit(ngx.HTTP_OK)
else
    res = ngx.location.capture("/up_retcon/upload_small_file", {method = ngx.HTTP_POST, body = post_args})
    if res.status ~= ngx.HTTP_OK then
        ngx.status = res.status
    end
    ngx.say(res.body)
    ngx.exit(ngx.HTTP_OK)
end
