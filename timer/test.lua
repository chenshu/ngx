local handler = function(premature, uri, args, status)

    local m = ngx.shared.thread
    local ok, err = m:safe_set(uri, coroutine.status(coroutine.running()))
    if ok == true and err == nil then
        ngx.log(ngx.INFO, "success...", uri, ":", ok, "-", err)
    else
        ngx.log(ngx.ERR, "failure...", uri, ":", ok, "-", err)
        return
    end

    ngx.log(ngx.WARN, "here ...", uri, " ", args, " ", status)
    local mem = ngx.shared.mem
    local success, err = mem:safe_add(uri, true)
    if success == true and err == nil then
        ngx.log(ngx.WARN, "success...", success, " ", err)
        if premature then
            return
        end
    else
        ngx.log(ngx.ERR, "failure...", success, " ", err)
        return
    end
end

local ok, err = ngx.timer.at(0, handler, ngx.var.uri, ngx.var.args, ngx.header.status)
if not ok then
    ngx.log(ngx.ERR, "failed to create timer: ", err)
    return
end
