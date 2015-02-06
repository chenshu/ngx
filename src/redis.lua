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

local data = new_tab(0, 3)

local strong_random = resty_random.bytes(32, true)
while strong_random == nil do
    strong_random = resty_random.bytes(32, true)
end
local ticket = str.to_hex(strong_random)

local strong_random2 = resty_random.bytes(128, true)
while strong_random2 == nil do
    strong_random2 = resty_random.bytes(128, true)
end
local service = str.to_hex(strong_random2)

--data['url'] = 'http://192.168.201.81:8080/t?ticket=' .. ticket .. '&service=' .. service
data['url'] = 'http://192.168.192.11:8092/casserver/validate?ticket=1ST-107-WbfV1bojeIjEBgA6ZXwK-cas&service=http%3A%2F%2Flogindev.vmall.com%2Foauth2%2Flogin%3Fclient_id%3D59395%26response_type%3Dtoken%26redirect_uri%3Dhttp%253A%252F%252Fwww.example.com%252Foauth_redirect%26state%3Dxyz%26h%3D1403601558.3696%26v%3D98111caa3ecc3c0b'

data['ts'] = ngx.time()

local strong_random3 = resty_random.bytes(64, true)
while strong_random3 == nil do
    strong_random3 = resty_random.bytes(64, true)
end
--data['access_token'] = str.to_hex(strong_random3)
data['access_token'] = 'BlQf6/Bwq/QstKiquiD/D/Su+wnJ991ipX3iJffWAV8ePMhCA72T9Yr9mXM='

local ok, err = red:lpush('/queue/tobeverified', cjson.encode(data))
if not ok then
    ngx.log(ngx.ERR, "failed to lpush: ", err)
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

local ans, err = red:blpop(data['access_token'], 5)
if not ans then
    ngx.log(ngx.ERR, "service not found or service to slow: ", err)
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
elseif ans == null then
    ngx.log(ngx.ERR, "service not found or service to slow: ", err)
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

local ok, err = red:set_keepalive(10000, 100)
if not ok then
    ngx.log(ngx.ERR, "failed to set keepalive: ", err)
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

if type(ans) ~= "table" then
    ngx.log(ngx.ERR, "failed to ans type: ", type(ans))
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

ngx.say(ans[2])
ngx.exit(ngx.HTTP_OK)
