local nsp = require "http.nsp"
local client = nsp:new("kdfkasdjfasdfadfkadf")
local svc = client:service("nsp.demo.message")
local http_status, nsp_status, response = svc:get{
    foo = "bar",
    i = 100
}

ngx.say(http_status)
ngx.say(nsp_status)
local t = type(response)
if t == "string" then
    ngx.say(response)
elseif t == "table" then
    for i, v in pairs(response) do
        print(i, "=", v)
    end
else
    ngx.say(res)
end
