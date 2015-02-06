package.path = './container/?.lua;' .. package.path

local setmetatable = setmetatable
local require = require
local error = error

local ngx = ngx

local _M = {
    _VERSION = '0.0.1'
}
 
local mt = { __index = _M }
 
function _M.sayHello(name, time)
    --[[
    local nsp = require "nsp"
    local access_token = "yyyyy"
    local client = nsp:new(access_token)
    local svc = client:service("nsp.bar")
    local ret = svc:sayHello(name)
    return "foo sayHello " .. name .. " " .. ret
    --]]
    ngx.sleep(time)
    return "foo sayHello " .. name .. " " .. time
end

return _M
