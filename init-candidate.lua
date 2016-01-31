-- Compile server code and remove original .lua files.
-- This only happens the first time afer the .lua files are uploaded.

local compileAndRemoveIfNeeded = function(f)
    if file.open(f) then
        file.close()
        print('Compiling:', f)
        node.compile(f)
        file.remove(f)
        collectgarbage()
    end
end

local serverFiles = { 'httpserver.lua', 'httpserver-basicauth.lua', 'httpserver-b64decode.lua', 'httpserver-request.lua',
    'httpserver-static.lua', 'httpserver-header.lua', 'httpserver-error.lua', 'upnp.lua', 'core.lua',
    'wifi.lua', 'xml.lua', 'http-node_info.lua', 'http-file_list.lua', 'httpserver-ok.lua'}
for _, f in ipairs(serverFiles) do compileAndRemoveIfNeeded(f) end

compileAndRemoveIfNeeded = nil
serverFiles = nil
collectgarbage()

-- Connect to the WiFi access point.
-- Once the device is connected, start the HTTP server.

dofile("core.lc")
dofile("wifi.lc")
step = 0
tmr.alarm(0, 100, 1, function()
    if wifi.sta.getip() ~= nil then
        tmr.stop(0)
        dofile("httpserver.lc")(80)
        dofile("upnp.lc")
    end
end)
