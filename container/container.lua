local base_path = package.path

local error = error
local redis = require "resty.redis"
local insert = table.insert
local remove = table.remove
local sub = string.sub
local format = string.format

local function f(queue, body)
    local service = sub(queue, 8)
    package.path = format("./container/services/%s/svc.lua;", service) .. base_path
    local svc = require(service)
    local ret = svc[body]("xxx")
    ngx.log(ngx.DEBUG, "call: " .. service .. " " .. ret)
end

local handler = function(premature, service)
    ngx.log(ngx.DEBUG, "start service...", service)
    local mem = ngx.shared.mem
    local success, err = mem:add(service, 0)
    if success == false and err == 'exists' then
        return
    else
        ngx.log(ngx.DEBUG, "start service success...", service, " ", success)
        if premature then
            return
        end

        local redis_host = "127.0.0.1"
        local redis_port = 6379
        local redis_pass = "foobared"
        local redis_timeout = 0
        local redis_brpop_timeout = 10

        local red = redis:new()

        red:set_timeout(redis_timeout)

        local ok, err = red:connect(redis_host, redis_port)
        if not ok then
            ngx.log(ngx.ERR, "failed to connect: ", err)
            return
        end

        local ok, err = red:auth(redis_pass)
        if not ok then
            ngx.log(ngx.ERR, "failed to auth: ", err)
            return
        end

        while true do
            local ans, err = red:brpop(service, redis_brpop_timeout)
            if not ans and err then
                ngx.log(ngx.ERR, "failed to brpop: ", err)
            elseif ans and ans ~= ngx.null then
                ngx.log(ngx.DEBUG, "get res from redis: " .. ans[1] .. " " .. ans[2])
                co = ngx.thread.spawn(f, ans[1], ans[2])
            elseif ans == ngx.null then
                ngx.log(ngx.DEBUG, "get null from redis: " .. service)
            else
                ngx.log(ngx.WARN, "should not here")
            end
        end

    end
end

local ok, err = ngx.timer.at(0, handler, ngx.var.uri)
if not ok then
    ngx.log(ngx.ERR, "failed to create timer: ", err)
    return
end
