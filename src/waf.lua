local bit = require "bit"
local resty_md5 = require "resty.md5"
local str = require "resty.string"

local function printx(data)
    ngx.say(data)
    ngx.say("<br/>")
end

local crc8_table = {
      0,   7,  14,   9,  28,  27,  18,  21,  56,  63,  54,  49,  36,  35,  42,  45,
    112, 119, 126, 121, 108, 107,  98, 101,  72,  79,  70,  65,  84,  83,  90,  93,
    224, 231, 238, 233, 252, 251, 242, 245, 216, 223, 214, 209, 196, 195, 202, 205,
    144, 151, 158, 153, 140, 139, 130, 133, 168, 175, 166, 161, 180, 179, 186, 189,
    199, 192, 201, 206, 219, 220, 213, 210, 255, 248, 241, 246, 227, 228, 237, 234,
    183, 176, 185, 190, 171, 172, 165, 162, 143, 136, 129, 134, 147, 148, 157, 154,
     39,  32,  41,  46,  59,  60,  53,  50,  31,  24,  17,  22,   3,   4,  13,  10,
     87,  80,  89,  94,  75,  76,  69,  66, 111, 104,  97, 102, 115, 116, 125, 122,
    137, 142, 135, 128, 149, 146, 155, 156, 177, 182, 191, 184, 173, 170, 163, 164,
    249, 254, 247, 240, 229, 226, 235, 236, 193, 198, 207, 200, 221, 218, 211, 212,
    105, 110, 103,  96, 117, 114, 123, 124,  81,  86,  95,  88,  77,  74,  67,  68,
     25,  30,  23,  16,   5,   2,  11,  12,  33,  38,  47,  40,  61,  58,  51,  52,
     78,  73,  64,  71,  82,  85,  92,  91, 118, 113, 120, 127, 106, 109, 100,  99,
     62,  57,  48,  55,  34,  37,  44,  43,   6,   1,   8,  15,  26,  29,  20,  19,
    174, 169, 160, 167, 178, 181, 188, 187, 150, 145, 152, 159, 138, 141, 132, 131,
    222, 217, 208, 215, 194, 197, 204, 203, 230, 225, 232, 239, 250, 253, 244, 243
}

local function crc8(data)
    local code = 0
    for c in string.gmatch(data, ".") do
        -- table first index is 1, so add 1
        code = crc8_table[bit.bxor(code, string.byte(c)) + 1]
    end
    return code
end

local function rc4(key, data)
    local s = {}
    for i = 0, 255 do
        s[i] = i
    end
    local i = 0
    local table = {}
    for c in string.gmatch(key, ".") do
        table[i] = c
        i = i + 1
    end
    local j = 0
    for i = 0, 255 do
        j = (j + s[i] + string.byte(table[i % string.len(key)])) % 256;
        local x = s[i]
        s[i] = s[j]
        s[j] = x
    end
    i = 0
    j = 0
    local out = ''
    for x in string.gmatch(data, ".") do
        i = (i + 1) % 256
        j = (j + s[i]) % 256
        local y = s[i]
        s[i] = s[j]
        s[j] = y
        out = out .. string.char(bit.bxor(string.byte(x), s[(s[i] + s[j]) % 256]))
    end
    return out
end

local secret = ""
local access_token = ""
printx(access_token)
local token = ngx.decode_base64(access_token)
printx(token)
printx(token:len())
printx(ngx.encode_base64(token))
local version = string.byte(string.sub(token, 1))
printx(version)
local version_master = bit.arshift(version, 2)
printx(version_master)
--printx(bit.tohex(bit.lshift(1, 2) + bit.band(2, 0x3f)))
local prefix = string.sub(token, 1, 5)
local digest_hex = ngx.md5(prefix .. secret)
printx(digest_hex)
local digest = ngx.md5_bin(prefix .. secret)
printx(digest)
local data = string.sub(token, 6)
printx(data)
data = rc4(digest, data)
printx(ngx.md5(prefix .. string.sub(data, 1, string.len(data) - 1)))
local checkcode = crc8(prefix .. string.sub(data, 1, string.len(data) - 1))
printx(checkcode)

local expire = string.sub(token, 2, 5)
printx(string.len(expire))
printx(tonumber(expire))
