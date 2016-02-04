results = {}
debug = true

function debug(message)
    if (debug) then
        print(message)
    end
end

function resultsToJson()
    local buf = "";
    buf = buf .. "{\n";
    buf = buf .. "\t\"results\": [\n"
    local hasResults = false
    for key, value in pairs(results) do
        hasResults = true
        buf = buf .. "\t\t{\"type\": \"" .. key .. "\", "
        local hasReadouts = false
        for subKey, subVal in pairs(results[key]) do
            hasReadouts = true
            buf = buf .. "\"" .. subKey .. "\":" .. subVal .. ", "
        end
        if (hasReadouts) then
            buf = string.sub(buf, 1, -3)
        end
        buf = buf .. "}, "
    end
    if (hasResults) then
        buf = string.sub(buf, 1, -3)
    end
    buf = buf .. "\n\t]\n}";
    return buf;
end
