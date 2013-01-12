page = require("webpage").create()
server = require("webserver").create()
system = require "system"

if system.args.length isnt 2
  console.log "Usage: phantomjs --load-images=no server.js <port>"
  phantom.exit 1
else
  port = system.args[1]

  listening = server.listen port, (request, response) ->
    console.log JSON.stringify request, null, 4

    response.statusCode = 200
    response.headers =
        "Cache": "no-cache"
        "Content-Type": "text/html"

    response.close()

    # url = "http://localhost:#{port}/foo/bar.php?asdf=true"
    # console.log "SENDING REQUEST TO: #{url}"

    # page.open url, (status) ->
    #     if status isnt "success"
    #       console.log "FAIL to load the address: #{url}"
    #     else
    #       console.log "GOT REPLY FROM SERVER:"
    #       console.log page.content

  unless listening
    console.log "could not create web server listening on port #{port}"
    phantom.exit()