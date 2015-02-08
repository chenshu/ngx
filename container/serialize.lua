local setmetatable = setmetatable
local error = error
local type = type
local tonumber = tonumber
local ipairs = ipairs
local pairs = pairs

local len = string.len
local sub = string.sub
local lower = string.lower
local format = string.format
local abs = math.abs
local floor = math.floor
local ceil = math.ceil

local insert = table.insert
local concat = table.concat

local _M = {
    _VERSION = '0.0.1'
}

local mt = { __index = _M }

local function is_number(self, data)
    if tonumber(data) then
        return true
    else
        return false
    end
end

local function serialize_key(self, data)
    local t = type(data)
    if t == 'number' then
        return 'i:' .. data .. ';'
    elseif t == 'boolean' then
        if data then
            return 'i:1;'
        else
            return 'i:0;'
        end
    elseif t == 'nil' then
        -- table index not is nil
        return 's:0:"";'
    elseif t == 'string' then
        local d = tonumber(data)
        if d then
            if abs(d) > 2147483647 then
                return 'd:' .. data .. ';'
            else
                return 'i:' .. data  .. ';'
            end
        else
            return 's:' .. len(data) .. ':"' .. data .. '";'
        end
    else
        error('unknown key type when serialize: ' .. t)
    end
end

local function serialize_value(self, data)
    local t = type(data)
    if t == 'number' then
        if (floor(data) == data or ceil(data) == data) and abs(data) < 2147483648 then
            return 'i:' .. data .. ';'
        elseif abs(data) > 2147483647 then
            return 'd:' .. format('%d', tonumber(data)) .. ';'
        else
            return 'd:' .. data .. ';'
        end
    elseif t == 'boolean' then
        if data then
            return 'b:1;'
        else
            return 'b:0;'
        end
    elseif t == 'nil' then
        return 'N;'
    elseif t == 'string' then
        if data == "null" then
            return 'N;'
        else
            return 's:' .. len(data) .. ':"' .. data .. '";'
        end
    elseif t == 'table' then
        local out = {}
        local i = 0
        local length = 0
        local DummyClass = data['DummyClass'] or nil
        if #data > 0 then
            for k, v in ipairs(data) do
                if k ~= 'DummyClass' then
                    insert(out, serialize_key(self, i))
                    i = i + 1
                    insert(out, serialize_value(self, v))
                    length = length + 1
                end
            end
        else
            for k, v in pairs(data) do
                if k ~= 'DummyClass' then
                    insert(out, serialize_key(self, k))
                    insert(out, serialize_value(self, v))
                    length = length + 1
                end
            end
        end
        if DummyClass then
            return 'O:' .. len(DummyClass) .. ':"' .. DummyClass .. '":' .. length .. ':{' .. concat(out) .. '}'
        else
            return 'a:' .. length .. ':{' .. concat(out) .. '}'
        end
    else
        error('unknown data type when serialize: ' .. t)
    end
end

local function read_until(self, data, offset, stopchar)
    local limit = len(data)
    local buf = {}
    -- lua index from 1, not 0
    local i = offset + 1
    local char = sub(data, i, i)
    while char ~= stopchar do
        insert(buf, char)
        i = i + 1
        if i > limit then
            error('String index OutOfBounds Exception: ' .. i .. ' ' .. limit)
        end
        char = sub(data, i, i)
    end
    return #buf, concat(buf)
end

local function read_chars(self, data, offset, length)
    -- lua index from 1, not 0
    local i = offset + 1
    local s = sub(data, i, offset + length)
    return len(s), s
end

local function unserialize_value(self, data, offset, nullable)
    offset = offset or 0
    local buf = {}
    local dtype = lower(sub(data, offset + 1, offset + 1))
    local dataoffset = offset + 2
    local charlength, arrlength = 0, 0
    local readdata, stringlength = nil, nil
    local typeconvert = nil
    if dtype == 'i' then
        typeconvert = function(x) return tonumber(x) end
        charlength, readdata = read_until(self, data, dataoffset, ';')
        dataoffset = dataoffset + charlength + 1
    elseif dtype == 'd' then
        typeconvert = function(x) return tonumber(x) end
        charlength, readdata = read_until(self, data, dataoffset, ';')
        dataoffset = dataoffset + charlength + 1
    elseif dtype == 'b' then
        typeconvert = function(x) return tonumber(x) == 1 end
        charlength, readdata = read_until(self, data, dataoffset, ';')
        dataoffset = dataoffset + charlength + 1
    elseif dtype == 'n' then
        typeconvert = function(x) return x end
        if nullable then
            readdata = "null"
        else
            readdata = nil
        end
    elseif dtype == 's' then
        typeconvert = function(x) return x end
        charlength, stringlength = read_until(self, data, dataoffset, ':')
        dataoffset = dataoffset + charlength + 2
        charlength, readdata = read_chars(self, data, dataoffset, tonumber(stringlength))
        dataoffset = dataoffset + charlength + 2
    elseif dtype == 'a' then
        typeconvert = function(x) return x end
        readdata = {}
        charlength, arrlength = read_until(self, data, dataoffset, ':')
        dataoffset = dataoffset + charlength + 2
        for i = 0, tonumber(arrlength) - 1 do
            local ktype, kcharlength, key = unserialize_value(self, data, dataoffset)
            dataoffset = dataoffset + kcharlength
            local vtype, vcharlength, value = unserialize_value(self, data, dataoffset, true)
            dataoffset = dataoffset + vcharlength
            local k = tonumber(key)
            if k then
                readdata[k + 1] = value
            else
                readdata[key] = value
            end
        end
        dataoffset = dataoffset + 1
    elseif dtype == 'o' then
        typeconvert = function(x) return x end
        local class_name, class_length = nil
        charlength, stringlength = read_until(self, data, dataoffset, ':')
        dataoffset = dataoffset + charlength + 2
        charlength, class_name = read_chars(self, data, dataoffset, tonumber(stringlength))
        dataoffset = dataoffset + charlength + 2
        readdata = {['DummyClass'] = class_name}
        charlength, class_length = read_until(self, data, dataoffset, ':')
        dataoffset = dataoffset + charlength + 2
        for i = 0, tonumber(class_length) - 1 do
            local ktype, kcharlength, key = unserialize_value(self, data, dataoffset)
            dataoffset = dataoffset + kcharlength
            local vtype, vcharlength, value = unserialize_value(self, data, dataoffset, true)
            dataoffset = dataoffset + vcharlength
            readdata[key] = value
        end
        dataoffset = dataoffset + 1
    else
        error('unknown data type when unserialize: ' .. dtype)
    end
    return dtype, dataoffset - offset, typeconvert(readdata)
end

function _M.new(self)
    return setmetatable({}, mt)
end

function _M.serialize(self, data)
    return serialize_value(self, data)
end

function _M.unserialize(self, data)
    local t, o, s = unserialize_value(self, data)
    return s
end

return _M
