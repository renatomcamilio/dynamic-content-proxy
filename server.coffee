page    = require("webpage").create()
server  = require("webserver").create()
system  = require "system"

if not Date::toISOString
  Date::toISOString = ->
    pad = (n) ->
      if n < 10 then '0' + n else n
    ms = (n) ->
      if n < 10 then '00' + n else (if n < 100 then '0' + n else n)
    @getFullYear() + '-' +
    pad(@getMonth() + 1) + '-' +
    pad(@getDate()) + 'T' +
    pad(@getHours()) + ':' +
    pad(@getMinutes()) + ':' +
    pad(@getSeconds()) + '.' +
    ms(@getMilliseconds()) + 'Z'

createHAR = (address, title, startTime, resources, content) ->
  entries = []

  resources.forEach (resource) ->
    request = resource.request
    startReply = resource.startReply
    endReply = resource.endReply

    if not request or not startReply or not endReply
      return

    entries.push
      startedDateTime: request.time.toISOString()
      time: endReply.time - request.time
      request:
        method: request.method
        url: request.url
        httpVersion: 'HTTP/1.1'
        cookies: []
        headers: request.headers
        queryString: []
        headersSize: -1
        bodySize: -1

      response:
        status: endReply.status
        statusText: endReply.statusText
        httpVersion: 'HTTP/1.1'
        cookies: []
        headers: endReply.headers
        redirectURL: ''
        headersSize: -1
        bodySize: startReply.bodySize
        content:
          size: startReply.bodySize
          mimeType: endReply.contentType

      cache: {}
      timings:
        blocked: 0
        dns: -1
        connect: -1
        send: 0
        wait: startReply.time - request.time
        receive: endReply.time - startReply.time
        ssl: -1
      pageref: address

  log:
    version: '1.2'
    creator:
      name: 'PhantomJS'
      version: phantom.version.major + '.' + phantom.version.minor + '.' + phantom.version.patch

    pages: [
      startedDateTime: startTime.toISOString()
      id: address
      title: title
      pageTimings:
        onLoad: page.endTime - page.startTime
      comment: content
    ]
    entries: entries

if system.args.length isnt 2
  console.log "Usage: phantomjs --load-images=no server.js <port>"
  phantom.exit 1
else
  port = system.args[1]

  listening = server.listen port, (request, response) ->
    regex = new RegExp("[\\?&]url=([^&#]*)")
    results = regex.exec(request.url)
    if (results == null)
      page.address = 'http://ifconfig.me/'
    else
      page.address = decodeURIComponent(results[1].replace(/\+/g, " "))

    page.resources = []

    page.onLoadStarted = ->
      page.startTime = new Date()

    page.onResourceRequested = (req) ->
      page.resources[req.id] =
        request: req
        startReply: null
        endReply: null

    page.onResourceReceived = (res) ->
      if res.stage is 'start'
        page.resources[res.id].startReply = res
      if res.stage is 'end'
        page.resources[res.id].endReply = res

    response.statusCode = 200
    response.setEncoding 'utf8'
    response.headers =
      "Cache": "no-cache"
      "Content-Type": "application/json; charset=utf-8"

    console.log "SENDING REQUEST TO: #{page.address}"

    page.open page.address, (status) ->
      if status isnt 'success'
        console.log "FAIL to load the address: #{page.ddress}"
        response.write '{ "error" : 1, "success" : 0, "status" : "fail" }'
      else
        console.log "GOT REPLY FROM SERVER!"

        page.endTime = new Date()
        page.title = page.evaluate ->
          document.title

        har = createHAR page.address, page.title, page.startTime, page.resources, page.content
        response.write JSON.stringify har, undefined, 4
        response.close()

  unless listening
    console.log "could not create web server listening on port #{port}"
    phantom.exit()
