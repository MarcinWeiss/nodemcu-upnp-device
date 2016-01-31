return function(connection, args)
    local function setDecimalPlaces(number, digits)
        local shift = 10 ^ digits
        return math.floor(number * shift + 0.5) / shift
    end

    dofile("httpserver-header.lc")(connection, 200, "html")
    connection:send('<!DOCTYPE html>\r\n<html>\r\n<head>\r\n<title>Files</title>\r\n</head>\r\n<body>\r\n')
    coroutine.yield()

    local remaining, used, total = file.fsinfo()
    used = setDecimalPlaces(used / 1000, 2)
    total = setDecimalPlaces(total / 1000, 2)
    remaining = setDecimalPlaces(remaining / 1000, 2)


    connection:send("<h1>Local storage</h1>\r\n")
    coroutine.yield()
    connection:send("<p>Storage usage: <meter min=\"0\" value=" .. used .. " max=" .. total .. ">" .. used .. " out of " .. remaining .. "kb</meter></p>\r\n")
    coroutine.yield()
    connection:send("<p>free " .. remaining .. " out of " .. total .. "KB</p>\r\n")
    coroutine.yield()
    connection:send("<table>\r\n<thead>\r\n<tr>\r\n<th align=\"left\">Name</th>\r\n<th>Size</th>\r\n</tr>\r\n</thead>\r\n<tbody>\r\n")
    coroutine.yield()
    l = file.list()
    for name, size in pairs(l) do
        connection:send("<td align=\"left\">\r\n<a href=\"" .. name .. "\">" .. name .. "</a>\r\n</td>\r\n")
        coroutine.yield()
        connection:send("<td align=\"right\">" .. setDecimalPlaces(size / 1000, 2) .. " KB</td>\r\n</tr>\r\n")
        coroutine.yield()
    end
    connection:send("</tbody>\r\n</table>\r\n</body>\r\n</html>")
end
