page = require("webpage").create()
system = require "system"
fs = require "fs"
 
if system.args.length < 3 or system.args.length > 5
    console.log "Usage: phantomjs --load-images=no html.js URL filename"
    phantom.exit 1
else
    [file, address, output] = system.args

    page.open address, (status) ->
        if status isnt "success"
            console.log "Unable to load the address! (#{address})"
        else
            fs.write output, page.content, "w"

        phantom.exit()