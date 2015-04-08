local thread = ngx.shared.thread
local keys = thread:get_keys()
for _, key in ipairs(keys) do
    local value, flags = thread:get(key)
    ngx.say("worker thread: " .. key .. ", " .. value)
end
