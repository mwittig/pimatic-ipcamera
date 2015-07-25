#Promise = env.require 'bluebird'
#assert = require 'assert'
#events = require 'events'
WriteStream = require('stream').Writable
http = require 'http' 
MjpegCamera = require 'mjpeg-camera'
path = require 'path'
fs = require 'fs'
class Base 
	constructor: (framework,config,plugin) ->
		@framework = framework
		@config = config
		@plugin = plugin
		#@plugin.info "Called "+@config.devices
		@array = []
		@createImgDirectory()
	createImgDirectory: ->
		imgPath = ""
		if process.platform in ['win32', 'win64']
			imgPath = path.dirname(fs.realpathSync(__filename+"\\..\\"))+"\\pimatic-mobile-frontend\\public\\img\\"
		else
			imgPath = path.dirname(fs.realpathSync(__filename+"/../"))+"/pimatic-mobile-frontend/public/img/"			
		@plugin.info "Create directory for the first time 5 "+imgPath
		fs.exists(imgPath,(exists)=>
			if !exists 
				@plugin.info "Create directory for the first time 3"
				fs.mkdir(imgPath,(stat)=>
					@plugin.info "Create directory for the first time 4"
				)
		)
	add : (@id,@name,@cameraUrl) ->
		#@plugin.info "Called Again "+ @id + "," + @name + "," + @cameraUrl
		camera = new MjpegCamera({url: @cameraUrl,name: @name})
		@array.push ({camera,@id})
	start : () ->
		#@plugin.info "masuk sini untuk " + @array
		http.createServer((req,res) =>
			stat = false
			boundary = '--boundandrebound'
			@array.forEach((entry)=>
				if !stat
					#@plugin.info "entry : /stream/" + entry["id"] + " "+req.url
					if (("/stream/"+entry["id"]).toLowerCase()==req.url.toLowerCase()) 
						#@plugin.info "masuk yuks"	
						entry["camera"].start()
						res.writeHead(200, {'Content-Type': 'multipart/x-mixed-replace; boundary=' + boundary});
						ws = new WriteStream({objectMode: true})
						ws._write =(chunk, enc, next) ->
							#@plugin.info "masuk sni"
							jpeg = chunk.data
							res.write(boundary + '\nContent-Type: image/jpeg\nContent-Length: '+ jpeg.length + '\n\n')
							res.write(jpeg)
							next()
							return
						@plugin.info entry["camera"].name
						entry["camera"].pipe(ws)
						res.on 'close', () =>
							#console.log "stop"
							entry["camera"].stop()
							return
						stat=true
					else if (("/page/"+entry["id"]).toLowerCase()==req.url.toLowerCase()) 
						res.writeHead(200, {'Content-Type': 'text/html'})
						res.end('<!doctype html>\
              <html>\
                <head>\
                  <title>'+entry["camera"].name+'</title>\
                </head>\
                <body style="background:#000;">\
                  <img src="/stream" style="width:100%;height:auto;">\
                </body>\
              </html>')
					return
			)
		).listen(10000)
		return
		
		
		
module.exports = Base