-- httpserver-header.lua
-- Part of nodemcu-httpserver, knows how to send an HTTP header.
-- Author: Marcos Kirsch

return function(code, extension)

    local function getHTTPStatusString(code)
        local codez = {}
        codez[200] = "OK"
        codez[400] = "Bad Request"
        codez[404] = "Not Found"

        if codez[code] then
            return codez[code]
        else
            return "Not Implemented"
        end
    end

    local function getMimeType(ext)
        local gzip = false
        -- A few MIME types. Keep list short. If you need something that is missing, let's add it.
        local mt = { css = "text/css", gif = "image/gif", html = "text/html", ico = "image/x-icon", jpeg = "image/jpeg", jpg = "image/jpeg", js = "application/javascript", json = "application/json", png = "image/png", xml = "text/xml" }
        -- add comressed flag if file ends with gz
        if ext:find("%.gz$") then
            ext = ext:sub(1, -4)
            gzip = true
        end
        local contentType
        if mt[ext] then
            contentType = mt[ext]
        else
            contentType = "text/plain"
        end
        return { contentType = contentType, gzip = gzip }
    end

    local function getHeader(code, mimeType)
        local header = "HTTP/1.0 " .. code .. " " .. getHTTPStatusString(code) .. "\r\n"
        header = header .. "Server: nodemcu-httpserver, UPnP/1.0\r\n"
        header = header .. "Connection: close\r\n"
        if mimeType then
            header = header .. "Content-Type: " .. mimeType["contentType"] .. "\r\n"
        else
            header = header .. "CONTENT-LENGTH: 0\r\n"
        end

        if mimeType["gzip"] then
            header = header .. "Content-Encoding: gzip\r\n"
        end
        header = header .. "\r\n"
        return header
    end

    if extension then
        local mimeType = getMimeType(extension)
        return getHeader(code, mimeType)
    else
        return getHeader(code)
    end
end

