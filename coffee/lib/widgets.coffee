pack = require '../package.json'
request = require 'superagent'
dialog = require 'commander'
path = require 'path'
log = require './logger'
targz = require 'tar.gz'
fs = require 'fs'

###
Check if widget is exists at the server
###
exports.isExist = ( widget, callback ) ->

	request
		.get( "#{pack.homepage}/widgets/#{widget.name}" )
		.set('Accept', 'application/json')
		.end (res) ->
			
			if res.statusCode is 502 or res.statusCode is 404 or not res.body.done
				log.requestError("#{pack.homepage}/widgets/#{widget.name}", widget.name) if widget.options.silent isnt on
				callback( false )
				
			else
				log.requestSuccess("#{pack.homepage}/widgets/#{widget.name}", widget.name) if widget.options.silent isnt on
				callback( true )



###
Init new widget/theme
###
exports.init = ( options ) ->

	# Writes <pack.maxmertkit> json file
	writeJSON = ( json ) ->
		fs.writeFile pack.maxmertkit, JSON.stringify(json, null, 4), ( err ) ->
													
			if err then log.error("while initializing – #{err}")

			log.success("file #{pack.maxmertkit} successfully created.")
			process.stdin.destroy()



	type = ['widget', 'theme']


	console.log 'Choose what you will create'
	
	dialog.choose type, (i) ->
		# console.log 'You chose %s', type[i]
		
		dialog.prompt "#{type[i]} name: (test) ", ( pkgName ) ->
			pkgName = 'test' if pkgName is ''
			# console.log 'Hello %s', pkgName

			dialog.prompt "version: (0.0.0) ", ( version ) ->
				version = '0.0.0' if version is ''

				dialog.prompt "description: ", ( description ) ->

					dialog.prompt "repository: ", ( repository ) ->
				
						dialog.prompt "author: ", ( author ) ->

							dialog.prompt "license: (BSD) ", ( license ) ->
								license = 'BSD' if license is ''

								maxmertkitjson = 
									type: type[i]
									name: pkgName
									version: version
									description: description
									repository: repository
									author: author
									license: license
								console.log ""
							
								dialog.confirm "Is everything correct? \n\n #{JSON.stringify(maxmertkitjson, null, 4)}\n-> ", ( ok ) ->
									
									console.log ""

									if not ok
										log.error("Initializing canceled")
										process.stdin.destroy()

									else
										fs.exists pack.maxmertkit, ( exists ) ->
											
											if not exists
												writeJSON maxmertkitjson

											else #if exists
												log.error("File #{pack.maxmertkit} already exists.")

												dialog.confirm "Do you want to overwrite it? -> ", ( ok ) ->

													if not ok
														log.error("initialization canceled.")
														process.stdin.destroy()

													else
														writeJSON maxmertkitjson



exports.install = ( widget, callback ) ->

	request
		.get( "#{pack.homepage}/widgets/#{widget.name}/#{widget.version}/tar" )
		.set('Accept', 'application/json')
		.end (res) ->
			
			if res.statusCode is 502 or res.statusCode is 404
				log.requestError("#{pack.homepage}/widgets/#{widget.name}", widget.name)
				callback( false )

			else
				console.log res

	callback()



exports.installJSON = () ->

	fs.readFile pack.maxmertkit, ( err, data ) ->

		if err
			log.error("can\'t find #{pack.maxmertkit} file.")
			process.stdin.destroy()

		if data?
			maxmertkitjson = JSON.parse data

			if not maxmertkitjson.dependences?
				console.log "There is no dependences in #{pack.maxmertkit} file."
				process.stdin.destroy()

			else
				for widget, version of maxmertkitjson.dependences
					exports.install 
						name: widget
						version: version
					, ->

				# console.log exports.install

	# fs.exists pack.maxmertkit, ( exists ) ->

	# 	if exists
	# 		fs.readFile
	# 		console.log maxmertkitjson

	
