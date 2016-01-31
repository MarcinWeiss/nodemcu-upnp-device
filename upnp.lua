local subscriptions = {}

function subscribe(timeLength, event, callback)
    local ends = (tmr.now()/1000) +timeLength
    local Subscription = {ends = ends, callback=callback }
    function Subscription.isOutdated(self)
        return (tmr.now()/1000)>=self.ends
    end
    if not subscriptions[event] then
        subscriptions[event] = {}
    end
    subscriptions[event][callback] = Subscription
end

function unsubscribe(event, callback)
    if subscriptions[event] then
        for currCallback,value in ipairs(subscriptions[event]) do
            if value.isOutdated(value) or value.callback == callback then
                table.remove(subscriptions[event], index)
            end
        end
    end
end

function getServiceSubscriptions(event)
    if subscriptions[event] then
        for currCallback,value in ipairs(subscriptions[event]) do
            if value.isOutdated(value) then
                table.remove(subscriptions[event], currCallback)
            end
        end
        return subscriptions[event]
    else
        return {}
    end
end

net.multicastJoin(wifi.sta.getip(), "239.255.255.250")

local ssdp_notify = "NOTIFY * HTTP/1.1\r\n"..
"HOST: 239.255.255.250:1900\r\n"..
"CACHE-CONTROL: max-age=100\r\n"..
"NT: upnp:rootdevice\r\n"..
"USN: uuid:49c893b4-2fe9-11e5-9751-0024e820e50e"..string.format("%x",node.chipid()).."::upnp:rootdevice\r\n"..
"NTS: ssdp:alive\r\n"..
"SERVER: NodeMCU/20150415 UPnP/1.1 ovoi/0.1\r\n"..
"Location: http://"..wifi.sta.getip().."/ColorLight.xml\r\n\r\n"


local ssdp_response = "HTTP/1.1 200 OK\r\n"..
"Cache-Control: max-age=100\r\n"..
"EXT:\r\n"..
"SERVER: NodeMCU/20150415 UPnP/1.1 ovoi/0.1\r\n"..
"ST: upnp:rootdevice\r\n"..
"USN: uuid:49c893b4-2fe9-11e5-9751-0024e820e50e"..string.format("%x",node.chipid()).."\r\n"..
"Location: http://"..wifi.sta.getip().."/ColorLight.xml\r\n\r\n"

notifyCount = 0

local function notify()
    notifyCount = notifyCount + 1
    if notifyCount == 3 then
        tmr.stop(3)
        notifyCount = nil
        ssdp_notify = nil
        collectgarbage()
    else
        UPnP = net.createConnection(net.UDP)
        UPnP:connect(1900,"239.255.255.250")
        UPnP:send(ssdp_notify)
        print("Sending notify: "..notifyCount)
        UPnP:close()
        UPnP = nil
        notify = nil
        collectgarbage()
    end
end

local function response(connection, payload)
    --debug(payload)
    if string.match(payload,"M-SEARCH") then
        connection:send(ssdp_response)
        print("sent "..node.heap())
    end
end


tmr.alarm(3, 10000, 1, notify)

UPnPd=net.createServer(net.UDP) 

UPnPd:on("receive", response )

UPnPd:listen(1900,"239.255.255.250")


