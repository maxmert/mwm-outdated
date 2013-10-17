pack = require '../package.json'
templates = require '../templates.json'

config = require './config'
async = require 'async'
request = require 'superagent'
fs = require 'fs'
path = require 'path'
dialog = require 'commander'
_ = require 'underscore'
mustache = require 'mustache'

log = require './logger'
archives = require './archives'
maxmertkit = require './maxmertkit'
themes = require './themes'
modifiers = require './modifiers'

EventEmitter = require("events").EventEmitter
sys = require("sys")


if global.setImmediate?
	immediately = global.setImmediate



# **Install**
# widget dependences.

exports.install = ( pth, mjson, calll, depent, themesss ) ->
	# TODO: Two requests???
	# console.log mjson
	arr = []
	_.each mjson.dependences, ( ver, name ) ->
		arr.push
			name: name
			version: if ver.version? then ver.version else ver
			themes: if ver.themes? then ver.themes else mjson.themes
	# console.log arr

	async.eachSeries arr, ( widget, callback ) ->
		# console.log widget
		@calll = calll
		@depent = depent

		process.nextTick ( calll, depent, themesss ) =>
			# console.log widget.name, 'begin'
			fileName = "#{widget.name}@#{widget.version}.tar"
			
			req = request
				.get( "#{pack.homepage}/api/0.1/widgets/#{widget.name}/#{widget.version}" )
				.set( 'X-Requested-With', 'XMLHttpRequest' )
				.end ( res ) =>

					if res.ok

						req = request
							.get( "#{pack.homepage}/api/0.1/widgets/#{widget.name}/#{widget.version}" )
							.set( 'X-Requested-With', 'XMLHttpRequest' )

						stream = fs.createWriteStream( path.join(pth, fileName) )

						req.pipe stream

						stream.on 'close', =>
							
							archives.unpack path.join(pth, fileName), ( err ) =>
								
								if err?
									log.error "Couldn\'t unpack #{widget.name}@#{widget.version}.tar"
									callback yes, null
								
								else
									fs.unlink path.join(pth, fileName)

									if path.dirname(path.join(pth, widget.name, '_myvars.sass')) isnt '.'
										fs.readFile path.join(pth, widget.name, '_myvars.sass'),( err, data ) ->
											if not err?
												widgetPath = path.join(pth, widget.name)
												fs.appendFile path.join(config.directory(),'_paths.sass'), "$#{widget.name}-path: '#{widgetPath}'\n", ( err ) ->
												fs.appendFile path.join(config.directory(),'_vars.sass'), "\n#{data}\n", ( err ) ->


									fs.readFile path.join(pth,'../../_imports.sass'), ( err, data ) =>
										if err?
											log.error "Coluld not read #{path.join(pth,'../../_imports.sass')}."
											process.stdin.destroy()

										else
											data = data + "@import 'dependences/widgets/#{widget.name}/_index.sass'\n"
											
											fs.writeFile path.join(pth,'../../_imports.sass'), data, ( err ) =>
												# console.log widget.name, 'inside'
												if err?
													log.error "Coluld not write #{path.join(pth,'../../_imports.sass')}."
													callback yes, null

												else
													# console.log @depent
													# if @depent
													# 	depent = yes
													
													# if widget.themes?
													# 	depent = yes

													fs.writeFileSync path.join(pth, widget.name, '_params.sass'), "$dependent: #{if depent then yes else null}\n"
													if widget.themes?
														if themesss?
															themesss = _.extend(widget.themes, themesss)
															# console.log themesss
														else
															themesss = widget.themes
															# console.log themesss
														# depent = yes

													@calll path.join(pth, widget.name), @depent, themesss
													callback()
														
													# if widget.themes?
													# 	themes.install path.join( pth, widget.name, 'dependences/themes' ), widget.themes, depent

													# if widget.modifiers?
													# 	modifiers.install path.join( pth, widget.name, 'dependences/modifiers' ), widget.modifiers

						

					else
						log.requestError res.body.msg, 'ERRR', res.status						
						if not callback? or typeof callback is 'object' then process.stdin.destroy() else callback yes, widget.name


	, ( err ) ->
		if err?
			log.error "An error while installing widgets: #{err}"
			process.stdin.destroy()




# Function with json write.

write = ( file, data, callback ) ->

	fs.writeFile file, data, ( err ) ->

		if err
			log.error "initializing – #{err}."
			callback err, null

		else
		
			log.success "file #{file} successfully created."
			callback null, data