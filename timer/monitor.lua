local threads = ngx.shared.threads
local keys = threads:get_keys()
for _, key in ipairs(keys) do
    local value, flags = threads:get(key)
    ngx.say("key: " .. key .. ", " .. "value: " .. value)
end
