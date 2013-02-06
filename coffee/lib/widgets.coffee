pack = require '../package.json'
request = require 'superagent'
dialog = require 'commander'
path = require 'path'
log = require './logger'
async = require 'async'
tar = require 'tar'

fs = require 'fs'
ncp = require('ncp').ncp
fstream = require 'fstream'


###
Returns the montent of maxmertkit.json file
###
exports.maxmertkit = ->
	
	rawjson = fs.readFileSync path.join( '.', pack.maxmertkit )
	
	if not rawjson?
		log.error("couldn\'t read #{pack.maxmertkit} file.")
		process.stdin.destroy()

	else
		json = JSON.parse rawjson




###
Initializing new widget or theme in current directory
###
exports.init = ( options ) ->

	types = ['widget', 'theme']

	async.series
		
		type: ( callback ) ->
			dialog.choose types, (i) ->
				callback null, types[i]

		name: ( callback ) ->
			defaultPkgName = 'test'
			dialog.prompt "name: (test) ", ( pkgName ) ->
				if pkgName is '' then pkgName = defaultPkgName
				callback null, pkgName

		version: ( callback ) ->
			defaultVersion = '0.0.0'
			dialog.prompt "version: (0.0.0) ", ( version ) ->
				if version is '' then version = defaultVersion
				callback null, version

		description: ( callback ) ->
			dialog.prompt "description: ", ( description ) ->
				callback null, description

		repository: ( callback ) ->
			dialog.prompt "repository: ", ( repository ) ->
				callback null, repository

		author: ( callback ) ->
			dialog.prompt "author: ", ( author ) ->
				callback null, author

		license: ( callback ) ->
			defaultLicense = 'BSD'
			dialog.prompt "license: (BSD) ", ( license ) ->
				if license is '' then license = defaultLicense
				callback null, license

	, ( err, maxmertkitjson ) =>
		
		@.writeConfirm maxmertkitjson, options





###
Confirm writing json to the maxmertkit.json file
###
exports.writeConfirm = ( json, options ) ->

	dialog.confirm "Is everything correct? \n\n #{JSON.stringify(json, null, 4)}\n-> ", ( ok ) =>

			console.log ""

			if not ok
				log.error("Initializing canceled")
				process.stdin.destroy()

			else
				fs.exists pack.maxmertkit, ( exists ) =>

					if not exists
						@.write json, options
						process.stdin.destroy()

					else #if exists
						log.error("File #{pack.maxmertkit} already exists.")

						dialog.confirm "Do you want to overwrite it? -> ", ( ok ) =>

							if not ok
								log.error("initialization canceled.")
								process.stdin.destroy()

							else
								@.write json, options
								process.stdin.destroy()




###
Writing json to the maxmertkit.json file
###
exports.write = ( json, options ) ->

	fs.writeFile pack.maxmertkit, JSON.stringify(json, null, 4), ( err ) ->

		if err then log.error "initializing – #{err}."
		log.success "file #{pack.maxmertkit} successfully created."




###
Packing widget or theme in current folder. The folders name should be the same as your package name in maxmertkit.json
###
exports.pack = ( options, callback ) ->

	maxmertkitjson = @.maxmertkit()

	# Check if package name is the same as folder name
	if path.basename( path.resolve('.') ) is "#{maxmertkitjson.name}"

		directoryName = "/tmp/#{maxmertkitjson.name}"
		fileName = "#{maxmertkitjson.name}@#{maxmertkitjson.version}.tar"

		async.series

			dir: ( callback ) =>
				fs.mkdir directoryName, 0o0777, () ->
					callback( null, directoryName )

			store: ( callback ) =>				
				@.store callback

			pack: ( callback ) =>
				fstream.Reader
					path: directoryName
					type: 'Directory'
				.pipe( tar.Pack({}) )
				.pipe fstream.Writer( "/tmp/#{fileName}" ).on 'close', ( err ) ->
					if err?
						log.error 'Failed to create package.'
						if not callback? then process.stdin.destroy() else callback err, directoryName
					else
						callback(null, directoryName)

			restore: ( callback ) =>
				@.restore( fileName, callback )


		, ( err, res ) ->
			log.success "Finished to create package"

# 		zip = new admZip()

# 		fs.readdir '.', ( err, files ) =>
# 			if err
# 				log.error 'Failed to create package.'
# 				if not callback? then process.stdin.destroy() else callback err, fileName

# 			else
# 				async.forEachSeries files, ( file, callback ) =>

# 					if file.charAt(0) isnt '.' and file isnt 'dependences'

# 						if fs.lstatSync( file ).isDirectory()
# 							zip.addLocalFolder( file )
						
# 						else
# 							zip.addLocalFile( file )

# 					callback()
# 				, ( err ) =>

# 					if err
# 						log.error 'Failed to create package.'
# 						if not callback? then process.stdin.destroy() else callback err, fileName
# 					else
# 						zip.writeZip path.join( '/tmp/', fileName )
# 						log.success "Finished to create package"
# 						if not callback? then @.restore( fileName, callback ) else callback null, fileName

	else

		log.error "The folders name (#{path.basename( path.resolve('.') )}) should be the same as your package name in maxmertkit.json (#{maxmertkitjson.name})."




###
Store current folder in /tmp/ folder.
###
exports.store = ( callback ) ->

	maxmertkitjson = @.maxmertkit()

	directoryName = "/tmp/#{maxmertkitjson.name}"

	ncp '.', directoryName,
		filter: (name) ->
			currentName =  path.relative('.',name).split( path.sep )[0]
			
			if currentName.charAt(0) is '.' or path.relative('.',name).indexOf('dependences') isnt -1
				no
			else
				yes
	, ( err ) ->
		if err
			log.error "Failed to store current directory to #{directoryName} folder. Do you have permissions?"
			if not callback? then process.stdin.destroy() else callback err, directoryName
		else
			if not callback? then process.stdin.destroy() else callback null, directoryName



###
Restore package from /tmp folder to the current folder
###
exports.restore = ( fileName, callback ) ->
	
	fs.readFile path.join( '/tmp/', fileName ), ( err, data ) ->
		if err?
			log.error "Failed to restore #{fileName} from /tmp folder. Maybe there is no such file or folder."
			if not callback? then process.stdin.destroy() else callback err, fileName
		
		else

			fs.writeFile path.join( '.', fileName ), data, ( err ) ->

				if err?
					log.error "Failed to restore #{fileName} from /tmp folder. Maybe you do not have permissions to write in current folder."
					if not callback? then process.stdin.destroy() else callback err, fileName

				else
					if not callback? then process.stdin.destroy() else callback null, fileName



###
Unpacking widget or theme in current folder.
###
exports.unpack = ( fileName, callback ) ->

	maxmertkitjson = @.maxmertkit()

	file = fileName or "#{maxmertkitjson.name}@#{maxmertkitjson.version}.zip"

	zip = new admZip file
	zipEntries = zip.getEntries()

	console.log zipEntries






# ==============================
# ============================== SERVER FEATURES
# ==============================



###
Check if widget or theme is exists
###
exports.onServerIsExists = ( options, callback ) ->

	widget = @.maxmertkit()

	request
		.get( "#{pack.homepage}/widgets/#{widget.name}" )
		.set( 'X-Requested-With', 'XMLHttpRequest' )
		.end ( res ) ->
			if res.ok and res.status isnt 500 and res.status isnt 404
				if res.body.done
					log.success "widget with name #{widget.name} exists."
					if not callback? then process.stdin.destroy() else callback null, fileName
				else
					log.error "widget with name #{widget.name} does not exists."
					if not callback? then process.stdin.destroy() else callback yes, fileName












# exports.pack = ->

# 	packFile = "/tmp/#{pack.name}@#{pack.version}.tar"

# 	fstream.Reader
# 		type: "Directory"
# 		path: '.'
	
# 	.pipe(tar.Pack({}))
# 		.on 'error', =>
# 			log.error 'Failed to create package.'

# 	.pipe fstream.Writer( packFile )
# 		.on "close", =>
# 			log.success "Finished to create package"
# 			@.sendPack packFile




# ###
# Check if widget is exists at the server
# ###
# exports.isExist = ( widget, callback ) ->

# 	request
# 		.get( "#{pack.homepage}/widgets/#{widget.name}" )
# 		.set('Accept', 'application/json')
# 		.end (res) ->
			
# 			if res.statusCode is 502 or res.statusCode is 404 or not res.body.done
# 				log.requestError("#{pack.homepage}/widgets/#{widget.name}", widget.name) if widget.options.silent isnt on
# 				callback( false )
				
# 			else
# 				log.requestSuccess("#{pack.homepage}/widgets/#{widget.name}", widget.name) if widget.options.silent isnt on
# 				callback( true )



# ###
# Init new widget/theme
# ###
# exports.init = ( options ) ->

# 	# Writes <pack.maxmertkit> json file
# 	writeJSON = ( json ) ->
# 		fs.writeFile pack.maxmertkit, JSON.stringify(json, null, 4), ( err ) ->
													
# 			if err then log.error("while initializing – #{err}")

# 			log.success("file #{pack.maxmertkit} successfully created.")
# 			process.stdin.destroy()



# 	type = ['widget', 'theme']


# 	console.log 'Choose what you will create'
	
# 	dialog.choose type, (i) ->
# 		# console.log 'You chose %s', type[i]
		
# 		dialog.prompt "#{type[i]} name: (test) ", ( pkgName ) ->
# 			pkgName = 'test' if pkgName is ''
# 			# console.log 'Hello %s', pkgName

# 			dialog.prompt "version: (0.0.0) ", ( version ) ->
# 				version = '0.0.0' if version is ''

# 				dialog.prompt "description: ", ( description ) ->

# 					dialog.prompt "repository: ", ( repository ) ->
				
# 						dialog.prompt "author: ", ( author ) ->

# 							dialog.prompt "license: (BSD) ", ( license ) ->
# 								license = 'BSD' if license is ''

# 								maxmertkitjson = 
# 									type: type[i]
# 									name: pkgName
# 									version: version
# 									description: description
# 									repository: repository
# 									author: author
# 									license: license
# 								console.log ""
							
# 								dialog.confirm "Is everything correct? \n\n #{JSON.stringify(maxmertkitjson, null, 4)}\n-> ", ( ok ) ->
									
# 									console.log ""

# 									if not ok
# 										log.error("Initializing canceled")
# 										process.stdin.destroy()

# 									else
# 										fs.exists pack.maxmertkit, ( exists ) ->
											
# 											if not exists
# 												writeJSON maxmertkitjson

# 											else #if exists
# 												log.error("File #{pack.maxmertkit} already exists.")

# 												dialog.confirm "Do you want to overwrite it? -> ", ( ok ) ->

# 													if not ok
# 														log.error("initialization canceled.")
# 														process.stdin.destroy()

# 													else
# 														writeJSON maxmertkitjson



# exports.install = ( widget, callback ) ->

# 	fileName = "#{widget.name}@#{widget.version}.tar"
# 	stream = fs.createWriteStream( fileName )
# 	req = request.get( "#{pack.homepage}/widgets/#{widget.name}/#{widget.version}/tar" )
# 	req.pipe(stream)
	
# 	stream.on 'close', ->
# 		fs
# 			.createReadStream( fileName )
# 			.pipe( tar.Extract( path: './' ) )
# 			.on 'error', ( err )->
# 				log.error err
# 			.on 'end', ->
# 				fs.unlink fileName
# 				log.success "Installation of #{fileName} complete."

# 	callback()


# exports.sendPack = (file) ->
	
# 	fs.readFile pack.maxmertkit, ( err, data ) ->

# 		if err
# 			log.error("can\'t find #{pack.maxmertkit} file.")
# 			process.stdin.destroy()

# 		if data?
# 			maxmertkitjson = JSON.parse data

# 			request
# 				.post( "#{pack.homepage}/#{maxmertkitjson.author}/publish" )
# 				.attach( path.basename( file ), file )
# 				.end ( res ) ->
# 					console.log res


# exports.checkPack = ->

# 	fs.readFile pack.maxmertkit, ( err, data ) =>

# 		if err
# 			log.error("can\'t find #{pack.maxmertkit} file.")
# 			process.stdin.destroy()

# 		if data?
# 			maxmertkitjson = JSON.parse data

# 			request
# 				.get( "#{pack.homepage}/widgets/#{maxmertkitjson.name}/#{maxmertkitjson.version}" )
# 				.set('Accept', 'application/json')
# 				.end (res) => 
# 					if not res.ok
# 						log.requestError("Getting information about #{pack.name} if failed.")
# 						process.stdin.destroy()
# 					else
# 						@.pack()


# exports.publish = ( author ) ->

# 	dialog.password 'Password: ', ( pass ) =>
# 		request
# 			.post( "#{pack.homepage}/loginAJAX" )
# 			.send
# 				username: author
# 				password: pass
# 			.set('Accept', 'application/json')
# 			.end (res) =>
				
# 				if not res.ok
# 					log.error("Authorization Failed. Check the author name in maxmert.json or your password. Or maybe you need to register at #{pack.homepage}?")
# 					process.stdin.destroy()
# 				else
# 					log.success("Authorization succeed.")
# 					@.checkPack()

					# @.pack ->
					# 	@.sendPack()
					# process.stdin.destroy()





# exports.installJSON = () ->

# 	fs.readFile pack.maxmertkit, ( err, data ) ->

# 		if err
# 			log.error("can\'t find #{pack.maxmertkit} file.")
# 			process.stdin.destroy()

# 		if data?
# 			maxmertkitjson = JSON.parse data

# 			if not maxmertkitjson.dependences?
# 				console.log "There is no dependences in #{pack.maxmertkit} file."
# 				process.stdin.destroy()

# 			else
# 				for widget, version of maxmertkitjson.dependences
# 					exports.install 
# 						name: widget
# 						version: version
# 					, ->

				# console.log exports.install

	# fs.exists pack.maxmertkit, ( exists ) ->

	# 	if exists
	# 		fs.readFile
	# 		console.log maxmertkitjson

	
