local uuid = require "uuid"
--print("here's a new uuid: ", uuid("1234567890abcdef"))
uuid.seed()
print("here's a new uuid: ", uuid())
print("here's a new uuid: ", uuid())

local socket = require("socket")
local uuid = require("uuid")
--uuid.randomseed(socket.gettime()*10000)
uuid.randomseed(os.time())
print("here's a new uuid: ",uuid())
print("here's a new uuid: ",uuid())
