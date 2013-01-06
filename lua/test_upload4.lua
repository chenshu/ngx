local sock, err = ngx.req.socket()

if sock then
    ngx.say("got the request socket")
else
    ngx.say("failed to get the request socket: ", err)
    return
end

for i = 1, 6 do
    --local reader = sock:receiveuntil("\r\n")
    --local data, err, partial = reader()
    local data, err, partial = sock:receive()
    if not data then
        ngx.say("failed to read the data stream: ", err)
    end
    ngx.say("read the data stream: ", data)
end
