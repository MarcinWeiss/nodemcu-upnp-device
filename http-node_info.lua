local function toAttribute(connection, attr, val)
    return "<li><b>" .. attr .. ":</b> " .. val .. "<br></li>\n"
end

return function(connection, args)
    collectgarbage()
    local buf = "HTTP/1.0 200 OK\r\nContent-Type: text/html\r\nCache-Control: private, no-store\r\n\r\n"
    buf = buf .. '<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><title>A Lua script sample</title></head><body><h1>Node info</h1><ul>'
    local majorVer, minorVer, devVer, chipid, flashid, flashsize, flashmode, flashspeed = node.info();
    buf = buf .. toAttribute(connection, "NodeMCU version", majorVer .. "." .. minorVer .. "." .. devVer)
    buf = buf .. toAttribute(connection, "chipid", chipid)
    buf = buf .. toAttribute(connection, "flashid", flashid)
    buf = buf .. toAttribute(connection, "flashsize", flashsize)
    buf = buf .. toAttribute(connection, "flashmode", flashmode)
    buf = buf .. toAttribute(connection, "flashspeed", flashspeed)
    buf = buf .. toAttribute(connection, "node.heap()", node.heap())
    buf = buf .. toAttribute(connection, 'Memory in use (KB)', collectgarbage("count"))
    buf = buf .. toAttribute(connection, 'IP address', wifi.sta.getip())
    buf = buf .. toAttribute(connection, 'MAC address', wifi.sta.getmac())
    buf = buf .. '</ul></body></html>'
    connection:send(buf)
end
