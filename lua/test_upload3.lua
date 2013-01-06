local h = ngx.req.get_headers()
for k, v in pairs(h) do
    --ngx.say("received: ", k, "=", v)
end

--[[
local sock, err = ngx.req.socket()

if sock then
    ngx.log(ngx.ERR, "got the request socket", nil)
else
    ngx.log(ngx.ERR, "failed to get the request socket: ", err)
    ngx.exit(500)
end

for i = 1, 6 do
    --local reader = sock:receiveuntil("\r\n")
    --local data, err, partial = reader()
    local data, err, partial = sock:receive()
    if not data then
        ngx.log(ngx.ERR, "failed to read the data stream: ", err)
    end
    ngx.log(ngx.ERR, "read the data stream: ", data)
end
--]]

ngx.exit(ngx.HTTP_UNAUTHORIZED)

