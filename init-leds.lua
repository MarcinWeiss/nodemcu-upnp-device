values = { r = 0, g = 0, b = 0 }
local notificationBody = "<e:propertyset xmlns:e=\"urn:schemas-upnp-org:event-1-0\">\r\n" ..
        "<e:property>\r\n" ..
        "<r>0</r>\r\n" ..
        "</e:property>\r\n" ..
        "<e:property>\r\n" ..
        "<g>0</g>\r\n" ..
        "</e:property>\r\n" ..
        "<e:property>\r\n" ..
        "<b>0</b>\r\n" ..
        "</e:property>\r\n" ..
        "</e:propertyset>"
initUpnpService("ChangeColor", notificationBody)
