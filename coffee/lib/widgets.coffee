pack = require '../package.json'
request = require 'superagent'
dialog = require 'commander'
path = require 'path'
log = require './logger'
targz = require 'tar.gz'
fs = require 'fs'



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


exports.init = ( options ) ->

	

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

exports.install = ( name, callback ) ->

	

	callback()

	
