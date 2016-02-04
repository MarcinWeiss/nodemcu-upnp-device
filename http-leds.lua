local rPin = 1
local gPin = 2
local bPin = 3
local wPin = 4

if values == nil then
    print("initializing values")
    values = { r = 0, g = 0, b = 0 }
end

return function(connection, args)

    local function setColor(newR, newG, newB)
        local function setpin(value, pin)
            pwm.close(pin)
            if (value ~= 0) then
                pwm.setup(pin, 1000, value)
                pwm.start(pin)
            end
        end

        local function getWhite()
            if (values.r <= values.g and values.r <= values.b) then
                return values.r;
            elseif (values.g <= values.r and values.g <= values.b) then
                return newG;
            elseif (values.b <= values.r and values.b <= values.g) then
                return newB;
            end
        end

        if values.r ~= newR or values.g ~= newG or values.b ~= newB then
            values.r, values.g, values.b = newR, newG, newB
            local w = getWhite()
            setpin(values.r - w, rPin)
            setpin(values.g - w, gPin)
            setpin(values.b - w, bPin)
            setpin(w, wPin, 0)
            return true;
        else
            return false;
        end
    end

    if args["r"] ~= nil and args["g"] ~= nil and args["b"] ~= nil then
        print("setRequest")
        local wasChanged = setColor(tonumber(args["r"]), tonumber(args["g"]), tonumber(args["b"]))
        local subscribents = getServiceSubscriptions("ChangeColor")
        if wasChanged then
            print("sending subscriptions")
            local subscribentsCallbacks = {}
            local n = 0
            for _, v in pairs(subscribents) do
                n = n + 1
                subscribentsCallbacks[n] = v.callback
            end


            local subscribentsIterator = { subscribentsCallbacks = subscribentsCallbacks, index = 0 }

            function subscribentsIterator.getNextCallback(self)
                self.index = self.index + 1
                if self.index <= table.getn(self.subscribentsCallbacks) then
                    return function(code, data)
                        local subscribentsCallback = self.subscribentsCallbacks[self.index]

                        local notificationBody = "<e:propertyset xmlns:e=\"urn:schemas-upnp-org:event-1-0\">\r\n" ..
                                "<e:property>\r\n" ..
                                "<r>" .. values.r .. "</r>\r\n" ..
                                "</e:property>\r\n" ..
                                "<e:property>\r\n" ..
                                "<g>" .. values.g .. "</g>\r\n" ..
                                "</e:property>\r\n" ..
                                "<e:property>\r\n" ..
                                "<b>" .. values.b .. "</b>\r\n" ..
                                "</e:property>\r\n" ..
                                "</e:propertyset>"

                        local header = "CONTENT-TYPE: text/xml; charset=\"utf-8\"\r\nNT: upnp:event\r\nNTS: upnp:propchange\r\nSID: uuid:" .. wifi.ap.getmac() .. "\r\nSEQ: 0\r\n"
                        http.request(subscribentsCallback, "NOTIFY", header, notificationBody, self.getNextCallback(self))
                    end
                else
                    return function(code, data)
                        print("done sending dotifications:")
                    end
                end
            end

            function subscribentsIterator.notifySubscribents(self)
                self.getNextCallback(self)(nil, nil)
            end

            subscribentsIterator.notifySubscribents(subscribentsIterator)
        end
    else
        print("getRequest")
    end

    if (args["resultType"] == "xml") then
        local buf = dofile("httpserver-header.lc")(200, "xml")
        buf = buf .. "<s:Envelope xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\" s:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\"><s:Body>"
        buf = buf .. "<u:" .. args["serviceId"] .. "Response xmlns:u=\"urn:schemas-upnp-org:service:ChangeColor:1\">"
        buf = buf .. "<r>" .. values.r .. "</r>"
        buf = buf .. "<g>" .. values.g .. "</g>"
        buf = buf .. "<b>" .. values.b .. "</b>"
        buf = buf .. "</u:" .. args["serviceId"] .. "Response>"
        buf = buf .. "</s:Body></s:Envelope>"
        connection:send(buf)
    else
        local buf = dofile("httpserver-header.lc")(200, "html")
        buf = buf .. "<h1> RGB Led light </h1><input id=\"colorPicker\" type=\"color\" name=\"favcolor\" value=\"#000000\" onchange=\"myFunction()\">"
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
        buf = buf .. "document.getElementById(\"colorPicker\").value=rgbToHex(" .. values.r .. "," .. values.g .. "," .. values.b .. ");"
        buf = buf .. "myFunction();"
        buf = buf .. "</script>"
        connection:send(buf)
    end
    collectgarbage()
end
