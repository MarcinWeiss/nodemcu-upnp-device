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

local serverFiles = {
    'httpserver.lua', 'httpserver-basicauth.lua', 'httpserver-b64decode.lua',
    'httpserver-request.lua', 'httpserver-static.lua', 'httpserver-header.lua',
    'httpserver-error.lua', 'upnp.lua', 'core.lua',
    'wifi.lua', 'xml.lua', 'http-node_info.lua',
    'http-file_list.lua', 'urls.lua'
}

for _, f in ipairs(serverFiles) do compileAndRemoveIfNeeded(f) end

local setUuidInXml = function(filename)
    file.rename(filename, filename .. "-temp")
    file.close()

    file.open(filename .. "-temp", "r")
    local inData = {}
    local instr = file.readline()
    while instr do
        table.insert(inData, instr)
        instr = file.readline()
    end
    file.close()


    local mac = wifi.ap.getmac()
    mac = mac:gsub(":", "-")
    file.open(filename, "w")
    for _, line in ipairs(inData) do
        file.write(string.gsub(line, "<UDN>uuid:.-</UDN>", "<UDN>uuid:" .. mac .. "</UDN>"))
    end
    file.close()

    file.remove(filename .. "-temp")
end
local xmlFiles = { 'ColorLight.xml' }
for _, f in ipairs(xmlFiles) do setUuidInXml(f) end

compileAndRemoveIfNeeded = nil
serverFiles = nil
setUuidInXml = nil
xmlFiles = nil
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
