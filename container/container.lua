local base_path = package.path
package.path = './container/?.lua;' .. package.path

local error = error
local redis = require "resty.redis"
local insert = table.insert
local remove = table.remove
local sub = string.sub
local format = string.format
local find = string.find
local php = require 'serialize'

local requests = {}

local function f(interface, params)
    local start, over = find(interface, ".[^.]*$")
    local service = sub(interface, 1, start - 1)
    local method = sub(interface, start + 1, over)
    package.path = format("./container/services/%s/svc.lua;", service) .. base_path
    local svc = require(service)
    local ret = svc[method](unpack(params))
    ngx.log(ngx.DEBUG, "call: " .. interface .. " " .. ret)
    return ret
end

local function receive(queue)
    local redis_host = "127.0.0.1"
    local redis_port = 6379
    local redis_pass = "foobared"
    local redis_timeout = 0
    local redis_brpop_timeout = 10

    while true do
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

        local ps = php:new()

        while true do
            local ans, err = red:brpop(queue, redis_brpop_timeout)
            if not ans and err then
                ngx.log(ngx.ERR, "failed to brpop: ", err)
                if err ~= "closed" then
                    local ok, err = red:close()
                    if not ok then
                        ngx.log(ngx.ERR, "failed to close: ", err)
                    end
                end
                break
            elseif ans and ans ~= ngx.null then
                ngx.log(ngx.DEBUG, "get res from redis: " .. ans[1] .. " " .. ans[2])
                local req = ps:unserialize(ans[2])
                if req['properties'] then
                    local svc = req['properties']['svc']
                    local params = req['params'] or nil
                    local co = ngx.thread.spawn(f, svc, params)
                    req['coroutine'] = co
                    insert(requests, req)
                end
            elseif ans == ngx.null then
                ngx.log(ngx.DEBUG, "get null from redis: " .. queue)
            else
                ngx.log(ngx.WARN, "should not here")
                if err ~= "closed" then
                    local ok, err = red:close()
                    if not ok then
                        ngx.log(ngx.ERR, "failed to close: ", err)
                    end
                end
                break
            end

        end
    end
end

local function start_receive(queue)
    for i = 1, 1 do
        ngx.thread.spawn(receive, queue)
    end
end

local handler = function(premature, queue)
    ngx.log(ngx.DEBUG, "start listener...", queue)

    local mem = ngx.shared.mem
    local success, err = mem:safe_add(queue, 0)

    if success == true and err == nil then
        ngx.log(ngx.DEBUG, "start listener success...", queue, " ", success)
        if premature then
            return
        end

        start_receive(queue)

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

        local ps = php:new()

        local i = 1

        while true do
            while i <=  #requests do
                local request = requests[i]
                local co = request['coroutine']
                local status = coroutine.status(co)
                ngx.log(ngx.DEBUG, "thread status: ", status)
                if status ~= "dead" then
                    local ok, res = ngx.thread.wait(co)
                    if not ok then
                        ngx.log(ngx.ERR, "failed to wait: ", res)
                        remove(threads, i)
                    else
                        ngx.log(ngx.DEBUG, "wait thread status: ", res)
                        local replyto = request['properties']['replyto']
                        -- TODO
                        request['results'] = res
                        remove(request, 'coroutine')
                        local ok, err = red:lpush(replayto, ps:serialize(request))
                        if not ok then
                            ngx.log(ngx.ERR, "failed to lpush: ", err)
                        end
                        i = i + 1
                    end
                else
                    remove(threads, i)
                end
            end
            ngx.sleep(0.5)
        end
    elseif success == false and err == 'exists' then
        ngx.log(ngx.WARN, "failed to start listener: ", queue, " ", err)
        return
    else
        ngx.log(ngx.ERR, "failed to start listener: ", queue, " ", err)
        return
    end
end

local ok, err = ngx.timer.at(0, handler, ngx.var.uri)
if not ok then
    ngx.log(ngx.ERR, "failed to create timer: ", err)
    return
end
