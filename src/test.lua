local redis = require "resty.redis"
local resty_random = require "resty.random"
local str = require "resty.string"
local cjson = require "cjson"

local ok, new_tab = pcall(require, "table.new")
if not ok then
    new_tab = function (narr, nrec) return {} end
end

local redis_host = '127.0.0.1'
local redis_port = 6379
local redis_pass = nil
local redis_timeout = 60000
local redis_blpop_timeout = 10

local red = redis:new()

-- Sets the timeout (in ms) protection for subsequent operations, including the connect method.
red:set_timeout(redis_timeout)

--[[
local ok, err = red:connect("unix:/tmp/redis.sock")
if not ok then
    ngx.log(ngx.ERR, "failed to connect: ", err)
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end
--]]

local ok, err = red:connect(redis_host, redis_port)
if not ok then
    ngx.log(ngx.ERR, "failed to connect: ", err)
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

if redis_pass then
    local ok, err = red:auth(redis_pass)
    if not ok then
        ngx.log(ngx.ERR, "failed to authenticate: ", err)
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end
end

local script_lpush_response = [[
    redis.call('set', KEYS[1], ARGV[1])
    return redis.call('lpush', KEYS[2], KEYS[1])
]]

local res, err = red:eval(script_lpush_response, 2, 'context_id_1', '/temp-queue/reply-xxx', 'response body')
if not res then
    ngx.log(ngx.ERR, "failed to eval: ", err)
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end
ngx.say(res)

local script_lpush_request = [[
    if redis.call('exists', KEYS[1]) == 1 then
        return redis.call('llen', KEYS[2])
    else
        return redis.call('lpush', KEYS[2], ARGV[1])
    end
]]

local res, err = red:eval(script_lpush_request, 2, 'context_id_1', '/queue/ca-request', 'request body')
if not res then
    ngx.log(ngx.ERR, "failed to eval: ", err)
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end
ngx.say(res)

-- brpop command not allow in script
-- two phase

local ans, err = red:blpop('/temp-queue/reply-xxx', 10)
if not ans then
    ngx.log(ngx.ERR, "service not found or service to slow: ", err)
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
elseif ans == null then
    ngx.log(ngx.ERR, "service not found or service to slow: ", err)
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

if type(ans) ~= "table" then
    ngx.log(ngx.ERR, "failed to ans type: ", type(ans))
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

local script_brpop_response = [[
    local result = redis.call('get', KEYS[1])
    redis.call('del', KEYS[1])
    return result
]]

local res, err = red:eval(script_brpop_response, 1, 'context_id_1')
if not res then
    ngx.log(ngx.ERR, "failed to eval: ", err)
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end
ngx.say(res)

local ok, err = red:set_keepalive(10000, 100)
if not ok then
    ngx.log(ngx.ERR, "failed to set keepalive: ", err)
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

ngx.say('=============================')
ngx.say('yes')
ngx.say('c1528200@rmqkr.net')
ngx.say('0')
ngx.say('260086000000567009')
ngx.say('ec74e20ec90118cc5188bf6bfe0b63f9')
ngx.say('0016100011201406240651243631594bd728ba90')
ngx.say('539BDEEB1FA66B4C679CCB707DB3D1E84A7E98A7CB0B7DFD7550AB72CDE400300940B2AA75686D16E0DF821129DED4C505211FE19F10901F25F1FDA95EECA5BC09A216488DFC631B92D37025C3CD2B6311EDA75B1183F9F1BE')
ngx.say('AEFF464D068585E6B4E642208FCEF70BA82BF0FF8FFA8A')
ngx.say('1')
ngx.say('')
ngx.say('%7B%7D')
ngx.exit(ngx.HTTP_OK)
