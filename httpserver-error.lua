-- httpserver-error.lua
-- Part of nodemcu-httpserver, handles sending error pages to client.
-- Author: Marcos Kirsch

return function(connection, args)

    local function getHeader(code, errorString, extraHeaders, mimeType)
        local headerBuf = "HTTP/1.0 " .. code .. " " .. errorString .. "\r\nServer: nodemcu-httpserver\r\nContent-Type: " .. mimeType .. "\r\n"
        for i, header in ipairs(extraHeaders) do
            headerBuf = headerBuf .. header .. "\r\n"
        end
        headerBuf = headerBuf .. "connection: close\r\n\r\n"
        return headerBuf
    end

    print("Error " .. args.code .. ": " .. args.errorString)
    args.headers = args.headers or {}
    local buf = getHeader(args.code, args.errorString, args.headers, "text/html")
    buf = buf.."<html><head><title>" .. args.code .. " - " .. args.errorString .. "</title></head><body><h1>" .. args.code .. " - " .. args.errorString .. "</h1></body></html>\r\n"
    connection:send(buf)
end
