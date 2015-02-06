package.path = './container/?.lua;' .. package.path

local setmetatable = setmetatable
local require = require
local error = error

local _M = {
    _VERSION = '0.0.1'
}
 
local mt = { __index = _M }
 
function _M.sayHello(name)
    return "bar sayHello " .. name
end

return _M
