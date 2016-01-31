return function(connection, args)
    dofile("httpserver-header.lc")(connection, 200, nil)
end
