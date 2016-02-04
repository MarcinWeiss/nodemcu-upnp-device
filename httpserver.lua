-- httpserver
-- Author: Marcos Kirsch

-- Starts web server in the specified port.
return function(port)

    local s = net.createServer(net.TCP, 10)
    s:listen(port,
        function(connection)
            local urls = dofile("urls.lc")

            local bodylessRequests = {}

            -- This variable holds the thread used for sending data back to the user.
            -- We do it in a separate thread because we need to yield when sending lots
            -- of data in order to avoid overflowing the mcu's buffer.
            local connectionThread

            local function fileExists(filename)
                local fileExists = file.open(filename, "r")
                file.close()
                if fileExists then
                    return true
                else
                    return false
                end
            end

            local function onSubscribe(connection, uri, args, reqIp)
                local callback = args["Callback"]:match("<(.*)>")
                local timeoutUnit, timeout = args["Timeout"]:match("%s?(.*)%-(.*)$")

                if timeoutUnit == "Minute" then
                    timeout = timeout * 60
                elseif timeout == "Hour" then
                    timeout = timeout * 360
                end
                subscribe(timeout, uri, callback, reqIp)

                local fileServeFunction = function(connection, args)
                    connection:send("HTTP/1.0 200 OK\r\nServer: nodemcu-httpserver\r\nCONTENT-LENGTH: 0\r\nTIMEOUT: " ..
                            timeoutUnit .. "-" .. timeout .. "\r\nSID: uuid:" .. wifi.ap.getmac() .. "\r\nConnection: close\r\n\r\n")
                end
                connectionThread = coroutine.create(fileServeFunction)
                coroutine.resume(connectionThread, connection, args)
            end

            local function onUnsubscribe(connection, uri, args, reqIp)

                unsubscribe(uri, reqIp)

                local fileServeFunction = function(connection, args)
                    connection:send("HTTP/1.0 200 OK\r\nServer: nodemcu-httpserver\r\nCONTENT-LENGTH: 0\r\nConnection: close\r\n\r\n")
                end
                connectionThread = coroutine.create(fileServeFunction)
                coroutine.resume(connectionThread, connection, args)
            end

            local function onPost(connection, uri, args, body)
                local fileServeFunction = nil
                local ServiceId, xmlargs = dofile("xml.lc")(body)
                for k, v in pairs(xmlargs) do
                    args[k] = v
                end

                args["resultType"] = "xml"
                args["serviceId"] = ServiceId

                if #(uri) > 32 then
                    -- nodemcu-firmware cannot handle long filenames.
                    args = { code = 414, errorString = "Request-URI Too Long" }
                    fileServeFunction = dofile("httpserver-error.lc")
                else
                    local altUri = urls[(#(uri) > 0) and uri or ServiceId]
                    if altUri then
                        uri = altUri
                    end
                    local extension = uri:match(".+%.(.+)")
                    print(uri)
                    if not fileExists(uri) then
                        args = { code = 404, errorString = "Not Found" }
                        fileServeFunction = dofile("httpserver-error.lc")
                    elseif (extension == "lc" or extension == "lua") and uri:match("^(http)%-.+") then
                        fileServeFunction = dofile(uri)
                    else
                        args = { code = 404, errorString = "Not Found" }
                        fileServeFunction = dofile("httpserver-error.lc")
                    end
                end
                connectionThread = coroutine.create(fileServeFunction)
                coroutine.resume(connectionThread, connection, args)
            end

            local function onGet(connection, uri, args)
                local fileServeFunction = nil
                if #(uri) > 32 then
                    -- nodemcu-firmware cannot handle long filenames.
                    args = { code = 414, errorString = "Request-URI Too Long" }
                    fileServeFunction = dofile("httpserver-error.lc")
                else
                    local altUri = urls[uri]
                    if altUri then
                        uri = altUri
                    end
                    local extension = uri:match(".+%.(.+)")
                    if not fileExists(uri) then
                        args = { code = 404, errorString = "Not Found" }
                        fileServeFunction = dofile("httpserver-error.lc")
                    elseif (extension == "lc" or extension == "lua") and uri:match("^(http)%-.+") then
                        fileServeFunction = dofile(uri)
                    else
                        args = { file = uri, ext = extension }
                        fileServeFunction = dofile("httpserver-static.lc")
                    end
                end
                connectionThread = coroutine.create(fileServeFunction)
                coroutine.resume(connectionThread, connection, args)
            end

            local function onReceive(connection, payload)
                print(node.heap())
                local reqIp = connection:getpeer()
                local method, path, args, isComplete, isHeadless, contentLength = dofile("httpserver-request.lc")(payload)
                if isHeadless and bodylessRequests[reqIp] then
                    local newMethod, newPath, newArgs, newIsComplete, newIsHeadless, newContentLength = dofile("httpserver-request.lc")(bodylessRequests[reqIp] .. payload)
                    if newIsComplete then
                        method, path, args, isComplete, isHeadless, contentLength = newMethod, newPath, newArgs, newIsComplete, newIsHeadless, newContentLength
                        payload = bodylessRequests[reqIp] .. payload
                        bodylessRequests[reqIp] = nil
                    end
                end

                debug(method)
                debug(path)
                debug(reqIp)
                debug("-------")

                if not isComplete then
                    if not isHeadless then
                        bodylessRequests[reqIp] = payload
                    else
                        if bodylessRequests[reqIp].find("\r\n\r\n") == 1 then
                            bodylessRequests[reqIp] = bodylessRequests[reqIp] .. "\r\n\r\n"
                        end
                        bodylessRequests[reqIp] = bodylessRequests[reqIp] .. payload
                    end
                elseif method == "GET" then
                    onGet(connection, path, args)
                elseif method == "POST" then
                    onPost(connection, path, args, payload:match("\r\n\r\n(.*)"))
                elseif method == "SUBSCRIBE" then
                    onSubscribe(connection, path, args, reqIp)
                elseif method == "UNSUBSCRIBE" then
                    onUnsubscribe(connection, path, args, reqIp)
                else
                    local args = { code = 400, errorString = "Bad Request" }
                    local fileServeFunction = dofile("httpserver-error.lc")
                    connectionThread = coroutine.create(fileServeFunction)
                    coroutine.resume(connectionThread, connection, args)
                end
            end

            local function onSent(connection, payload)
                collectgarbage()
                if connectionThread then
                    local connectionThreadStatus = coroutine.status(connectionThread)
                    if connectionThreadStatus == "suspended" then
                        -- Not finished sending file, resume.
                        coroutine.resume(connectionThread)
                    elseif connectionThreadStatus == "dead" then
                        -- We're done sending file.
                        connection:close()
                        connectionThread = nil
                    end
                end
            end

            connection:on("receive", onReceive)
            connection:on("sent", onSent)
        end)
    -- false and nil evaluate as false
    local ip = wifi.sta.getip()
    if not ip then ip = wifi.ap.getip() end
    print("nodemcu-httpserver running at http://" .. ip .. ":" .. port)
    return s
end
