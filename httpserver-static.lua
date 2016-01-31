-- httpserver-static.lua
-- Part of nodemcu-httpserver, handles sending static files to client.
-- Author: Marcos Kirsch

return function(connection, args)
    local path = args.file
    debug("serving static file: "..path)
    dofile("httpserver-header.lc")(connection, 200, args.ext)
    -- coroutine.yield()
    -- Send file in little chunks
    local continue = true
    local bytesSent = 0
    while continue do
        collectgarbage()
        -- NodeMCU file API lets you open 1 file at a time.
        -- So we need to open, seek, close each time in order
        -- to support multiple simultaneous clients.
        file.open(path)
        file.seek("set", bytesSent)
        local chunk = file.read(256)
        file.close()
        if chunk == nil then
            continue = false
        else
            coroutine.yield()
            connection:send(chunk)
            bytesSent = bytesSent + #chunk
            chunk = nil
        end
    end
end
