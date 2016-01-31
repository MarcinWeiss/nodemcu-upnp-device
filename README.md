# nodemcu-upnp-device
Simple UPNP device for home automation and IoT

based on:
 pastukhov/nodemcu-ssdp
 marcoskirsch/nodemcu-httpserver
 

manual
 use latest NodeMCU dev branch firmware
 modify wifi.lua to use your networks SSID and password
 upload all files except *.py, *.bat and *.md manualy or use upload.bat script (modify it to use proper port, default is COM6)
 execute command 'dofile("init-candidate.lua")' on your nodemcu
 after establishing connection device will print its ip
 use browser or UPNP client to connect
 
 http://%nodemcu-ip%//http-file_list.lua will show you list of files on the device, all *.lc and *.lua files with name starting with "http" will will serve you http page
 