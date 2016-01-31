
return function(xml)
    local args = {}
    local path, argsRaw = xml:match("<s:Body>.*<u:(.*) xmlns.*\">(.*)</u")
    if not path then
        path = xml:match("<s:Body>.*<u:(.*) xmlns.*\"/>")
    else
        if (argsRaw ~= nil) then
            for k, v in argsRaw:gmatch("<(.-)>(.-)<.->") do
                args[k] = v
            end
        end
    end

    return path, args
end
