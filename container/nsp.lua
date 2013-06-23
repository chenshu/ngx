local setmetatable = setmetatable
local require = require
local error = error

local ngx = ngx
local redis = require "resty.redis"

module(...)

local mt = { __index = _M }

local redis_host = "127.0.0.1"
local redis_port = 6699
local redis_pass = "foobared"
local redis_timeout = 0
local redis_brpop_timeout = 10
local service_queue_prefix = "/queue/"

function new(self, access_token)

    local red = redis:new()

    red:set_timeout(redis_timeout)

    local ok, err = red:connect(redis_host, redis_port)
    if not ok then
        ngx.log(ngx.ERR, "failed to connect: ", err)
        return nil, err
    end

    local ok, err = red:auth(redis_pass)
    if not ok then
        ngx.log(ngx.ERR, "failed to auth: ", err)
        return nil, err
    end

    return setmetatable({
        access_token = access_token,
        red = red
    }, mt)
end

function service(self, service)
    local o = {
        client = self,
        svc = service,
        call = function(self, ...)
            local ok, err = self.client.red:lpush(service_queue_prefix .. self.svc, self.method)
            if not ok then
                ngx.log(ngx.ERR, "failed to lpush: ", err)
                return
            end

            local ok, err = self.client.red:set_keepalive(0, 10)
            if not ok then
                ngx.log(ngx.ERR, "failed to set keepalive: ", err)
                return
            end

            return ok
        end
    }
    return setmetatable(o, {
        __index = function(table, key)
            o.method = key
            return o.call
        end
    })
end

local class_mt = {
    -- to prevent use of casual module global variables
    __newindex = function (table, key, val)
        error('attempt to write to undeclared variable "' .. key .. '"')
    end
}

setmetatable(_M, class_mt)
