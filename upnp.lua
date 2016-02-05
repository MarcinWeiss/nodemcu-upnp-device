local subscriptions = {}
local services = {}
local notifications = {}
local noNotifications = true
local notificationHeader = "CONTENT-TYPE: text/xml; charset=\"utf-8\"\r\nNT: upnp:event\r\nNTS: upnp:propchange\r\nSID: uuid:" .. wifi.ap.getmac() .. "\r\nSEQ: 0\r\n"

function notifications.getNextNotification(self)
    local first = table.remove(self, 1)
    return first
end

function notifications.addNotification(self, notificationCallback, notificationBody)
    table.insert(self, { callback = notificationCallback, body = notificationBody })
end

function subscribe(timeLength, service, callback, ip)
    local ends = (tmr.now() / 1000) + timeLength
    local Subscription = { ends = ends, callback = callback }
    function Subscription.isOutdated(self)
        return (tmr.now() / 1000) >= self.ends
    end

    if subscriptions[service] then
        subscriptions[service][ip] = Subscription
        addNotificationToQueue(service)
        return true
    end
    return false
end

function unsubscribe(service, ip)
    if subscriptions[service] then
        for currIp, value in ipairs(subscriptions[service]) do
            if value.isOutdated(value) or currIp == ip then
                table.remove(subscriptions[service], index)
            end
        end
    end
end

function initUpnpService(service, body)
    subscriptions[service] = {}
    services[service] = {}
    services[service].lastNotification = body
end

local function getServiceSubscriptions(service)
    if subscriptions[service] then
        for currCallback, value in ipairs(subscriptions[service]) do
            if value.isOutdated(value) then
                table.remove(subscriptions[service], currCallback)
            end
        end
        return subscriptions[service]
    else
        return {}
    end
end

local function sendNextNotification()
    local function getNextNotificationCallback(code, data)
        print(code, data)
        sendNextNotification()
    end
    local notification = notifications.getNextNotification(notifications)
    if notification then
        print(notification.callback, "\r\n" .. notification.body)
        http.request(notification.callback, "NOTIFY", notificationHeader, notification.body, sendNextNotification())
    else
        noNotifications = true
    end
end

function addNotificationToQueue(service, notificationBody)
    if notificationBody == nil then
        notificationBody = services[service].lastNotification
    else
        services[service].lastNotification = notificationBody
    end

    local subscribents = getServiceSubscriptions(service)
    for _, v in pairs(subscribents) do
        notifications.addNotification(notifications, v.callback, notificationBody)
    end
    if noNotifications then
        noNotifications = false
        sendNextNotification()
    end
end

net.multicastJoin(wifi.sta.getip(), "239.255.255.250")

local mac = wifi.ap.getmac()
mac = mac:gsub(":", "-")

local ssdp_notify = "NOTIFY * HTTP/1.1\r\n" ..
        "HOST: 239.255.255.250:1900\r\n" ..
        "CACHE-CONTROL: max-age=100\r\n" ..
        "NT: upnp:rootdevice\r\n" ..
        "USN: uuid:" .. mac .. string.format("%x", node.chipid()) .. "::upnp:rootdevice\r\n" ..
        "NTS: ssdp:alive\r\n" ..
        "SERVER: NodeMCU/20150415 UPnP/1.1 ovoi/0.1\r\n" ..
        "Location: http://" .. wifi.sta.getip() .. "/ColorLight.xml\r\n\r\n"


local ssdp_response = "HTTP/1.1 200 OK\r\n" ..
        "Cache-Control: max-age=100\r\n" ..
        "EXT:\r\n" ..
        "SERVER: NodeMCU/20150415 UPnP/1.1 ovoi/0.1\r\n" ..
        "ST: upnp:rootdevice\r\n" ..
        "USN: uuid:" .. mac .. string.format("%x", node.chipid()) .. "\r\n" ..
        "Location: http://" .. wifi.sta.getip() .. "/ColorLight.xml\r\n\r\n"

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
        UPnP:connect(1900, "239.255.255.250")
        UPnP:send(ssdp_notify)
        print("Sending notify: " .. notifyCount)
        UPnP:close()
        UPnP = nil
        notify = nil
        collectgarbage()
    end
end

local function response(connection, payload)
    --debug(payload)
    if string.match(payload, "M-SEARCH") then
        connection:send(ssdp_response)
        print("sent " .. node.heap())
    end
end


tmr.alarm(3, 10000, 1, notify)

UPnPd = net.createServer(net.UDP)

UPnPd:on("receive", response)

UPnPd:listen(1900, "239.255.255.250")


