local lower = string.lower
local len = string.len
local format = string.format
local rename = os.rename
local resty_md5 = require "resty.md5"
local resty_str = require "resty.string"
local common = require "upload.common"
local random = common.random

local content_type = nil
local content_length = nil
local nsp_ts = nil
local nsp_sig = nil
local nsp_callback = nil
local nsp_callback_status = nil

local header_proc = {
    ["content-type"] = function(header)
        content_type = header
    end,
    ["content-length"] = function(header)
        content_length = tonumber(header)
    end,
    ["nsp-ts"] = function(header)
        nsp_ts = header
    end,
    ["nsp-sig"] = function(header)
        nsp_sig = header
    end,
    ["nsp-callback"] = function(header)
        nsp_callback = header
    end,
    ["nsp-callback_status"] = function(header)
        nsp_callback_status = header
    end,
}

local h = ngx.req.get_headers()
for k, v in pairs(h) do
    k = lower(k)
    local proc = header_proc[k]
    if proc then
        proc(v)
    end
end

local sock, err = ngx.req.socket()
if not sock then
    ngx.log(ngx.ERR, "failed to get the request socket: ", err)
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end
sock:settimeout(0)

local md5 = resty_md5:new()
if not md5 then
    ngx.log(ngx.ERR, "failed to create md5 object")
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

local local_file_name = format("/tmp/%s.%s", random(16), content_length)
local file = io.open(local_file_name, "w+")

local seg_size = 1024 * 1024 * 64
local chunk_size = 4096
if content_length < chunk_size then
    chunk_size = content_length
end
local size = 0
while size < content_length do
    local data, err, partial = sock:receive(chunk_size)
    data = data or partial
    if not data then
        ngx.log(ngx.ERR, "failed to read the data stream: ", err)
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end
    file:write(data)
    size = size + len(data)
    local ok = md5:update(data)
    if not ok then
        ngx.log(ngx.ERR, "failed to add data")
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end
    local less = content_length - size
    if less < chunk_size then
        chunk_size = less
    end
end

file:close()

local digest = md5:final()
local hash = resty_str.to_hex(digest)
local fid = format("%s%s", hash, format("%x", size))
ngx.say("fid: ", fid)
local ok, err = rename(local_file_name, "/tmp/" .. fid)
if not ok then
    ngx.log(ngx.ERR, "failed to rename file: ", err)
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

ngx.exit(ngx.HTTP_OK)
