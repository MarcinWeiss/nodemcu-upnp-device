return function(connection, args)
    local function setDecimalPlaces(number, digits)
        local shift = 10 ^ digits
        return math.floor(number * shift + 0.5) / shift
    end

    local remaining, used, total = file.fsinfo()
    used = setDecimalPlaces(used / 1000, 2)
    total = setDecimalPlaces(total / 1000, 2)
    remaining = setDecimalPlaces(remaining / 1000, 2)

    local buf = dofile("httpserver-header.lc")(200, "html")
    buf = buf.."<!DOCTYPE html>\r\n<html>\r\n<head>\r\n<title>Files</title>\r\n</head>\r\n<body>\r\n"
    buf = buf.."<h1>Local storage</h1>\r\n"
    buf = buf.."<p>Storage usage: <meter min=\"0\" value=" .. used .. " max=" .. total .. ">" .. used .. " out of " .. remaining .. "kb</meter></p>\r\n"
    buf = buf.."<p>free " .. remaining .. " out of " .. total .. "KB</p>\r\n"
    buf = buf.."<table>\r\n<thead>\r\n<tr>\r\n<th align=\"left\">Name</th>\r\n<th>Size</th>\r\n</tr>\r\n</thead>\r\n<tbody>\r\n"
    connection:send(buf)
    coroutine.yield()
    local filesList = file.list()
    for name, size in pairs(filesList) do
        buf = "<td align=\"left\">\r\n<a href=\"" .. name .. "\">" .. name .. "</a>\r\n</td>\r\n"
        buf = buf.."<td align=\"right\">" .. setDecimalPlaces(size / 1000, 2) .. " KB</td>\r\n</tr>\r\n"
        connection:send(buf)
        coroutine.yield()
    end
    buf = "</tbody>\r\n</table>\r\n</body>\r\n</html>"
    connection:send(buf)
end
