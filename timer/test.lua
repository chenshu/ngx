local redis = require "resty.redis"

local function f()
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

    local ok, err = red:set_keepalive(0, 3)
    if not ok then
        ngx.log(ngx.ERR, "failed to set keepalive: ", err)
        return
    end
end

local handler = function(premature, uri, args, status)
    ngx.log(ngx.WARN, "here ...", uri, " ", args, " ", status)
    local mem = ngx.shared.mem
    local success, err = mem:add(uri, true)
    if success == false and err == 'exists' then
        return
    else
        ngx.log(ngx.WARN, "here...", success, " ", err)
        if premature then
            return
        end
        local threads = ngx.shared.threads
        co = ngx.thread.spawn(f)
        local ok, err = threads:safe_set(uri, coroutine.status(co))
        if err ~= nil then
            ngx.log(ngx.WARN, "set failure...", uri, " ", coroutine.status(co))
        end
    end
end

local ok, err = ngx.timer.at(0, handler, ngx.var.uri)
if not ok then
    ngx.log(ngx.ERR, "failed to create timer: ", err)
    return
end
