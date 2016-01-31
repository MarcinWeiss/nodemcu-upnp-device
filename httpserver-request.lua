local function getContentLength(isHeadless, request)
    if isHeadless then
        return string.len(request)
    else
        return string.len(request:match(".-\r?\n\r?\n(.*)"))
    end
end

return function(request)
    print("parsing request")
    print(request)
    local method, path, varsRaw = request:match("([A-Z]+) /([^%?]*)%??(.*) HTTP")

    local isHeadless = (method ==nil and path == nil and varsRaw == nil);

    local vars = {}
    if not isHeadless then
        if #(varsRaw) > 0 then
            for k, v in varsRaw:gmatch("(%w+)=(%w+)&*") do
                vars[k] = v
            end
        end
        for k , v in request:gmatch("\n(.-): (.-)\r") do
            vars[k] = v
        end
    end
    local headerContentLength = vars["Content-Length"] and  tonumber(vars["Content-Length"]) or 0
    local contentLength = getContentLength(isHeadless, request)
    local isComplete = not isHeadless and headerContentLength==contentLength
    print(headerContentLength)
    print(contentLength)
    print(isComplete)
    print(isHeadless)

    return method, path, vars, isComplete, isHeadless, contentLength
end
