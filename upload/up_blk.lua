local SMALL_FILE_SIZE = 1024 * 105
local SMALL_FILE_HOST = "10.6.2.143"
local SMALL_FILE_PORT = 80
local BIG_FILE_HOST = "10.6.2.50"
local BIG_FILE_PORT = 80

local req = "POST /up/up_blk HTTP/1.1\r\n"

local content_type = ""
local content_length = 0
local headers = ngx.req.get_headers()
for k, v in pairs(headers) do
    if k == "content-length" then
        content_length = v
    elseif k == "content-type" then
        content_type = v
    end
    req = req .. k .. ": " .. v .. "\r\n"
end
req = req .. "\r\n"

local resty_md5 = require "resty.md5"
local resty_str = require "resty.string"
local resty_upload = require "resty.upload"
local common = require "lua.common"
local match = string.match
local gmatch = string.gmatch
local find = string.find

local boundary = "--" .. match(content_type, "boundary=([-%w]+)")

local md5 = resty_md5:new()

local chunk_size = 4096
local form = resty_upload:new(chunk_size)
form:set_timeout(0)

local is_file = false
local is_fsize = false
local file_length = 0

local sock = ngx.socket.tcp()
sock:settimeout(0)

while true do
    local typ, res, err = form:read()
    if not typ then
        ngx.log(ngx.ERR, "read data fail: ", err)
        ngx.exit(ngx.HTTP_BAD_REQUEST)
        return
    end
    if typ == "header" and #res == 3 then
        if res[1] ~= "Content-Type" then
            for k, v in gmatch(res[2], "(%S+)=\"([^\"]+)\"") do
                if k == "name" and v == "nsp_fsize" then
                    is_fsize = true
                end
            end
            req = req .. boundary .. "\r\n" .. res[3] .. "\r\n"
        else
            is_file = true
            req = req .. res[3] .. "\r\n\r\n"
            local bytes, err = sock:send(req)
            if not bytes then
                ngx.log(ngx.ERR, "send header fail: ", err)
                ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
            end
            req = ""
        end
    elseif typ == "body" then
        if is_file then
            local bytes, err = sock:send(res)
            if not bytes then
                ngx.log(ngx.ERR, "send body fail: ", err)
                ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
            end
        else
            if is_fsize then
                file_length = res
                local ok, err
                if tonumber(file_length) > SMALL_FILE_SIZE then
                    ok, err = sock:connect(BIG_FILE_HOST, BIG_FILE_PORT)
                else
                    ok, err = sock:connect(SMALL_FILE_HOST, SMALL_FILE_PORT)
                end
                if not ok then
                    ngx.log(ngx.ERR, "create tcp socket fail: ", err)
                    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
                    return
                end
                is_fsize = false
            end
            req = req .. "\r\n" .. res
        end
    elseif typ == "part_end" then
        req = req .. "\r\n"
        is_file = false
    elseif typ == "eof" then
        local bytes, err = sock:send(req .. boundary .. "--\r\n")
        if not bytes then
            ngx.log(ngx.ERR, "send over fail: ", err)
            ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
        end
        break
    end
end

function parseStatusLineOfResponse(line)
    local match = string.match
    return match(line, "HTTP/%d.%d (%d%d%d)")
end

function parseHeaderOfResponse(line)
    local match = string.match
    local gsub = string.gsub
    local k, v = match(line, "([^:%s]+):(.*)")
    return gsub(k, "^%s*(.-)%s*$", "%1"), gsub(v, "^%s*(.+)%s*$", "%1")
end

function parseResponseHeader(sock)
    local lower = string.lower
    local ln = 1
    local status
    local header = {}

    while true do
        local data, err, partial = sock:receive()
        data = data or partial
        if ln == 1 then
            status = parseStatusLineOfResponse(data)
        elseif data == "" then
            break
        else
            local h_k, h_v = parseHeaderOfResponse(data)
            header[lower(h_k)] = h_v
        end
        ln = ln + 1
    end

    return status, header
end

function parseResponseBody(sock, content_length, chunked)
    if content_length and not chunked then
        local data, err, partial = sock:receive(content_length)
        if not data then
            return nil, err
        else
            return data, nil
        end
    elseif not content_length and chunked then
        local body = ""
        local size = "*l"
        local is_body_size = true
        local is_ready_over = false
        while true do
            local data, err, partial = sock:receive(size)
            if data == "0" then
                is_ready_over = true
                content_length = "*l"
            elseif is_ready_over then
                break
            elseif is_body_size then
                size = tonumber(data, "16")
                is_body_size = false
            else
                body = body .. (data or partial)
                size = "*l"
            end
        end
        return body, nil
    else
        return nil, "can't parse response body"
    end
end

local status, header = parseResponseHeader(sock)
local content_length = header["content-length"] or nil
local chunked = header["transfer-encoding"] or nil
local body, err = parseResponseBody(sock, content_length, chunked)
if not body then
    ngx.log(ngx.ERR, "parse response fail: ", err)
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    return
end

local ok, err = sock:setkeepalive(300000, 100)
if not ok then
    --ngx.log(ngx.ERR, "failed to set keepalive: ".. err)
    --ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    --return
end

ngx.status = status
ngx.say(body)
ngx.exit(ngx.HTTP_OK)
