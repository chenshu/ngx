module("lua.util", package.seeall)

function prepare(client_body_temp_file)
    -- TODO Clear client_body_temp Directory
    client_body_temp_file:add("id", 1)
end
