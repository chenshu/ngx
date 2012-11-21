local SMALL_FILE_SIZE = 1024 * 105

local resty_md5 = require "resty.md5"
local resty_str = require "resty.string"
local resty_upload = require "resty.upload"
local common = require "lua.common"

local sock = ngx.socket.tcp()
sock:settimeout(0)
local host = "10.6.2.50"
local port = 80
local ok, err = sock:connect(host, port)
if not ok then
    ngx.log(ngx.ERR, "create tcp socket fail: ", err)
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    return
end

local bytes, err = sock:send("POST /up/up_blk HTTP/1.1\r\n")
if not bytes then
    ngx.log(ngx.ERR, "send url fail: ", err)
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    return
end

local content_type = ""
local content_length = 0
local headers = ngx.req.get_headers()
for k, v in pairs(headers) do
    if k == "content-length" then
        content_length = v
    elseif k == "content-type" then
        content_type = v
    end
    bytes, err = sock:send(k .. ": " .. v .. "\r\n")
    if not bytes then
        ngx.log(ngx.ERR, "send header fail: ", err)
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
        return
    end
end

bytes, err = sock:send("\r\n")
if not bytes then
    ngx.log(ngx.ERR, "send new line fail: ", err)
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    return
end

local boundary = "--" .. string.match(content_type, "boundary=([-%w]+)")

local md5 = resty_md5:new()

local chunk_size = 4096
local form = resty_upload:new(chunk_size)
form:set_timeout(0)

local is_file = false

while true do
    local typ, res, err = form:read()
    if not typ then
        ngx.log(ngx.ERR, "read data fail: ", err)
        ngx.exit(ngx.HTTP_BAD_REQUEST)
        return
    end
    if typ == "header" and #res == 3 then
        if res[1] ~= "Content-Type" then
            bytes, err = sock:send(boundary .. "\r\n" .. res[3] .. "\r\n")
            if not bytes then
                ngx.log(ngx.ERR, "send body header fail: ", err)
                ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
            end
        else
            is_file = true
            bytes, err = sock:send(res[3] .. "\r\n\r\n")
            if not bytes then
                ngx.log(ngx.ERR, "send body header fail: ", err)
                ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
            end
        end
    elseif typ == "body" then
        if is_file then
            bytes, err = sock:send(res)
            if not bytes then
                ngx.log(ngx.ERR, "send body data fail: ", err)
                ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
            end
        else
            bytes, err = sock:send("\r\n" .. res)
            if not bytes then
                ngx.log(ngx.ERR, "send body data fail: ", err)
                ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
            end
        end
    elseif typ == "part_end" then
        bytes, err = sock:send("\r\n")
        if not bytes then
            ngx.log(ngx.ERR, "send body new line fail: ", err)
            ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
        end
        is_file = false
    elseif typ == "eof" then
        bytes, err = sock:send(boundary .. "--\r\n")
        if not bytes then
            ngx.log(ngx.ERR, "send over fail: ", err)
            ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
        end
        break
    end
end

function parseHttpResponse(response)
    local status = 500
    local header = {}
    local body = ""
    local h, b = string.match(response, "(.-)\r\n\r\n(.+)")
    local lines = string.gmatch(h .. "\r\n", "(.-)\r\n")
    for line in lines do
        if not string.find(line, ":") then
            status = string.match(line, "HTTP/%d.%d (%d%d%d)")
        else
            local headers = string.gmatch(line, "([^:%s]+):(.*)")
            for k, v in headers do
                header[string.gsub(k, "^%s*(.-)%s*$", "%1")] = string.gsub(v, "^%s*(.+)%s*$", "%1")
            end
        end
    end
    if header["Transfer-Encoding"] == "chunked" then
        body = parseHttpBodyByChunked(b)
    else
        body = b
    end
    return status, header, body
end

function parseHttpBodyByChunked(body)
    local length = 0
    local res = ""
    local data = body
    local chunked_size = tonumber(string.match(data, "([0-9a-f]+)\r\n"), 16)
    while chunked_size > 0 do
        local start = string.find(data, "\r\n") + 2
        res = res .. string.sub(data, start, start + chunked_size)
        data = string.sub(data, start + chunked_size + 2)
        chunked_size = tonumber(string.match(data, "([0-9a-f]+)\r\n"), 16)
    end
    return res
end

local result = ""

while true do
    local data, err, partial = sock:receive(2^10)
    result = result .. (data or partial)
    if err == "closed" then
        break
    end
end

--[[
local ok, err = sock:setkeepalive(0, 1000)
if not ok then
    ngx.log(ngx.ERR, "failed to set keepalive: ".. err)
    return
end
ngx.log(ngx.ERR, result)
--]]

local status, header, body = parseHttpResponse(result)
ngx.status = status
ngx.say(body)
ngx.exit(ngx.HTTP_OK)
