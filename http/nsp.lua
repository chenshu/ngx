local http = require "resty.http"
local cjson = require "cjson"
local setmetatable = setmetatable
local pairs = pairs
local format = string.format
local ngx = ngx

module(...)

_VERSION = "0.0.1"

local url = "http://127.0.0.1:8080"
local host = "api.vmall.com"
local timeout = 5 * 1000
local keepalive_timeout = 5 * 60 * 1000
local keepalive_pool_size = 30
local method = "POST"
local content_type = "application/x-www-form-urlencoded"

local nsp_fmt = "JSON"

local mt = { __index = _M }

function new(self, access_token)
    local hc = http:new()
    return setmetatable({
        access_token = access_token,
        http_client = hc,
    }, mt)
end

function service(self, service)
    local svc = {
        client = self,
        svc = service,
        call = function (self, ...)
            local req_body = format("%s=%s&%s=%s&%s=%s", "access_token", self.client.access_token, "nsp_svc", format("%s.%s", self.svc, self.method), "nsp_ts", ngx.time())
            for i, v in pairs(...) do
                req_body = format("%s&%s=%s", req_body, i, v)
            end
            local ok, code, headers, status, body = self.client.http_client:request {
                url = url,
                timeout = timeout,
                keepalive = keepalive_timeout,
                method = method,
                headers = { ["Host"] = host, ["Content-Type"] = content_type },
                body = req_body
            }
            local http_status = code
            local nsp_status = headers["nsp_status"] or 0
            local response = body
            if code == 200 then
                response = cjson.decode(body)
            end
            return http_status, nsp_status, response
        end
    }
    return setmetatable(svc, { __index = function (table, key)
        svc.method = key
        return svc.call
    end})
end

local class_mt = {
    -- to prevent use of casual module global variables
    __newindex = function (table, key, val)
        error('attempt to write to undeclared variable "' .. key .. '"')
    end
}

setmetatable(_M, class_mt)
