local handler = function(premature, uri, args, status)
    ngx.log(ngx.WARN, "here ...", uri, " ", args, " ", status)
    local mem = ngx.shared.mem
    local success, err = mem:add("timer", true)
    if success == false and err == 'exists' then
        return
    else
        ngx.log(ngx.WARN, "here...", success, " ", err)
        if premature then
            return
        end
    end
end

local ok, err = ngx.timer.at(0, handler)
if not ok then
    ngx.log(ngx.ERR, "failed to create timer: ", err)
    return
end
