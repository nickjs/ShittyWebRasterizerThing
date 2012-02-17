http = require 'http'
url = require 'url'
process = require 'child_process'
fs = require 'fs'
path = require 'path'

http.createServer (request, response) ->
  requestURL = url.parse request.url
  params = {}
  for param in requestURL.query.split('&')
    param = param.split('=')
    params[param[0]] = param[1]

  params.url = decodeURIComponent params.url

  components = requestURL.pathname.split('.')
  params.format = components.pop()
  pathname = components.join('.').substr(1)

  size = if params.size then params.size.split('x') else []
  params.size = width: size[0] || 0, height: size[1] || 0

  (routes[pathname] || routes['404'])(params, response)

.listen 8080, 'localhost'

outputURL = (params) ->
  "images/#{params.url.replace(/[\/|\|\.|\?|\&\=:]/g,'_')}.#{params.size.width}x#{params.size.height}.#{params.format}"

renderImage = (params, response) ->
  console.log "RENDER #{params.url}"
  file = outputURL params

  fs.stat outputURL(params), (error, stat) ->
    response.writeHead 200, 'Content-Type': "image/#{params.format}", 'Content-Length': stat.size
    fs.readFile file, (error, data) ->
      response.end data

routes =
  invalidate: (params, response) ->
    console.log "INVALIDATE #{params.url}"
    fs.unlink outputURL params
    # routes.image params, response
    response.writeHead 200
    response.end 'ok'

  render: (params, response) ->
      console.log "GENERATE #{params.url}"
      output = outputURL params
      path.exists output, (exists) ->
        if exists
          return renderImage params, response

        console.log "RASTERIZE #{params.url} -> #{output}"
        process.exec "bin/phantomjs ./rasterizer.coffee '#{params.url}' '#{output}' #{params.size.width} #{params.size.height}", (error) ->
          if error
            response.writeHead 500, 'Content-Type': 'text/plain'
            response.end "Could not rasterize #{error}"
          else
            renderImage params, response

  '404': (params, response) ->
    response.writeHead 404
    response.end "Action not found"
