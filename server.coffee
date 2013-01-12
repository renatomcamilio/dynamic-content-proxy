page    = require("webpage").create()
server  = require("webserver").create()
system  = require "system"
url     = require "url"
fs      = require 'fs'

if system.args.length isnt 2
  console.log "Usage: phantomjs --load-images=no server.js <port>"
  phantom.exit 1
else
  port = system.args[1]

  listening = server.listen port, (request, response) ->
    # Browser sends request asking for favicon
    unless request.url.match /favicon/
      queryString = url.parse(request.url, true).query
      address = queryString.url
      filename = queryString.filename if queryString.filename?

      response.statusCode = 200
      response.setEncoding 'utf8'
      response.headers =
        "Cache": "no-cache"
        "Content-Type": "text/html"


      console.log "SENDING REQUEST TO: #{address}"

      page.open address, (status) ->
        if status isnt "success"
          response.write "FAILED to load the address: #{address}"
        else
          console.log "GOT REPLY FROM SERVER!"
          response.write page.content
          if filename then fs.write filename, page.content, "w"
        
        response.close()

  unless listening
    console.log "could not create web server listening on port #{port}"
    phantom.exit()