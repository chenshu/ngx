local method_name = ngx.req.get_method()
if method_name ~= "POST" then
    ngx.log(ngx.WARN, "invalid http method of request: ", method_name)
    ngx.exit(ngx.HTTP_METHOD_NOT_IMPLEMENTED)
end

local lower = string.lower

local nsp_ts = nil
local nsp_sig = nil
local nsp_callback = nil
local nsp_callback_status = nil

local header_proc = {
    ["nsp-ts"] = function(header)
        nsp_ts = header
    end,
    ["nsp-sig"] = function(header)
        nsp_sig = header
    end,
    ["nsp-callback"] = function(header)
        nsp_callback = header
    end,
    ["nsp-callback_status"] = function(header)
        nsp_callback_status = header
    end,
}

local h = ngx.req.get_headers()
for k, v in pairs(h) do
    k = lower(k)
    local proc = header_proc[k]
    if proc then
        proc(v)
    end
end

if not nsp_sig then
    ngx.log(ngx.WARN, "invlid request: ", "nsp_sig not exists")
    ngx.exit(ngx.HTTP_UNAUTHORIZED)
end
