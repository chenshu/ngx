package.path = './container/?.lua;' .. package.path

local setmetatable = setmetatable
local require = require
local error = error
 
module(...)
 
function sayHello(name)
    return "hello " .. name
end
 
local mt = { __index = _M }
 
local class_mt = {
    -- to prevent use of casual module global variables
    __newindex = function (table, key, val)
        error('attempt to write to undeclared variable "' .. key .. '"')
    end
}
 
setmetatable(_M, class_mt)
