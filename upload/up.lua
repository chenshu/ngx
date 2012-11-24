local SMALL_FILE_SIZE = 1024 * 105

local content_type = ""
local content_length = 0
local headers = ngx.req.get_headers()
for k, v in pairs(headers) do
    if k == "content-length" then
        content_length = v
    elseif k == "content-type" then
        content_type = v
    end
end

if tonumber(content_length) > SMALL_FILE_SIZE then
    ngx.exec("/up/upload_big_file")
    return
else
    ngx.var.c_type = content_type
    ngx.exec("/up/upload_small_file")
    return
end
