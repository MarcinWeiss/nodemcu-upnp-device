local rPin = 1
local gPin = 2
local bPin = 3
local wPin = 4

local w = 0

local function setpin(value, pin, white)
    print("stop", pin)
    pwm.close(pin)
    local correctedVal = value - white
    print("corrected val", correctedVal)
    if (correctedVal ~= 0) then
        pwm.setup(pin, 1000, correctedVal)
        print("setup pin", pin)
        pwm.start(pin)
        print("pin", pin, "started")
    end
end

local function setColor()
    setpin(r, rPin, w)
    setpin(g, gPin, w)
    setpin(b, bPin, w)
    setpin(w, wPin, 0)
end

local function setWhite()
    if (r <= g and r <= b) then
        print("lowest r")
        w = r;
    elseif (g <= r and g <= b) then
        print("lowest g")
        w = g;
    elseif (b <= r and b <= g) then
        print("lowest b")
        w = b;
    end
end

local function RGB2RGBW(args)
    if (args["r"] ~= nil) then
        r = tonumber(args["r"])
    end
    if (args["g"] ~= nil) then
        g = tonumber(args["g"])
    end
    if (args["b"] ~= nil) then
        b = tonumber(args["b"])
    end

    if (r == nil) then
        r = 0
    end
    if (g == nil) then
        g = 0
    end
    if (b == nil) then
        b = 0
    end
    print(r,g,b)
    setWhite()
end

return function(connection, args)
    RGB2RGBW(args)
    print(r, g, b, w)
    setColor()
    if (args["resultType"] == "xml") then
        dofile("httpserver-header.lc")(connection, 200, "xml")
        coroutine.yield()
        local buf = "<s:Envelope xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\" s:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\"><s:Body>"
        buf = buf .. "<u:" .. args["serviceId"] .. "Response xmlns:u=\"urn:schemas-upnp-org:service:ChangeColor:1\">"
        buf = buf .. "<r>" .. r .. "</r>"
        buf = buf .. "<g>" .. g .. "</g>"
        buf = buf .. "<b>" .. b .. "</b>"
        buf = buf .. "</u:" .. args["serviceId"] .. "Response>"
        buf = buf .. "</s:Body></s:Envelope>"
        connection:send(buf);
    else
        dofile("httpserver-header.lc")(connection, 200, "html")
        coroutine.yield()
        local buf = "<h1> RGB Led light </h1><input id=\"colorPicker\" type=\"color\" name=\"favcolor\" value=\"#000000\" onchange=\"myFunction()\">"
        buf = buf .. "<form method=\"get\">"
        buf = buf .. "<input id=\"rInput\" type=\"hidden\" name=\"r\" min=\"0\" max=\"1023\" value=\"0\">"
        buf = buf .. "<input id=\"gInput\" type=\"hidden\" name=\"g\" min=\"0\" max=\"1023\" value=\"0\">"
        buf = buf .. "<input id=\"bInput\" type=\"hidden\" name=\"b\" min=\"0\" max=\"1023\" value=\"0\">"
        buf = buf .. "<p><input type=\"submit\"></p></form>"
        buf = buf .. "<script>function componentToHex(c){var hex=c.toString(16); return hex.length==1 ? \"0\" + hex : hex;}"
        buf = buf .. "function rgbToHex(r, g, b){return \"#\" + componentToHex(Math.floor(r/4)) + componentToHex(Math.floor(g/4)) + componentToHex(Math.floor(b/4));}"
        buf = buf .. "function hexToRgb(hex){var result = /^#?([a-f\\d]{2})([a-f\\d]{2})([a-f\\d]{2})$/i.exec(hex); return result ?{r: parseInt(result[1], 16)*4, g: parseInt(result[2], 16)*4, b: parseInt(result[3], 16)*4}: null;}"
        buf = buf .. "function myFunction(){var x=document.getElementById(\"colorPicker\").value; var rgb=hexToRgb(x); "
        buf = buf .. "document.getElementById(\"rInput\").value=rgb.r; "
        buf = buf .. "document.getElementById(\"gInput\").value=rgb.g; "
        buf = buf .. "document.getElementById(\"bInput\").value=rgb.b;}"
        buf = buf .. "document.getElementById(\"colorPicker\").value=rgbToHex(" .. r .. "," .. g .. "," .. b .. ");"
        buf = buf .. "myFunction();"
        buf = buf .. "</script>";
        connection:send(buf);
    end
    collectgarbage()
end
