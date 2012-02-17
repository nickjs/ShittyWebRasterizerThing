page = require('webpage').create()

[address, output, width, height] = phantom.args
if not address or not output
  phantom.exit(1)

page.viewportSize = { width: 600, height: 600 }
page.clipRect = { width: width, height: height }
page.open address, (status) ->
  if status isnt 'success'
    phantom.exit(2)
  else
    page.render output
    phantom.exit()
