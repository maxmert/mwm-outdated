maxmertkit = require './maxmertkit'

request = require 'superagent'
path = require 'path'
log = require './logger'
async = require 'async'
tar = require 'tar'
mustache = require 'mustache'
_ = require 'underscore'
wrench = require 'wrench'

fs = require 'fs'
ncp = require('ncp').ncp
fstream = require 'fstream'






exports.pack = ( folder, callback ) ->

	mjson = maxmertkit.json()

	# Check if package name is the same as folder name
	if path.basename( path.resolve(folder) ) is "#{mjson.name}"

		if mjson.type is 'widget'

			directoryName = "/tmp/#{mjson.name}"
			fileName = "#{mjson.name}@#{mjson.version}.tar"

			# Need to do a lot of things one after another
			async.series

				# Remove directory in /tmp folder is it exists
				rmdir: ( callback ) =>
					fs.exists directoryName, ( exists ) ->
						if exists
							rmdirSyncForce directoryName, callback
						
						callback null, 'yes'

				# Create directory in /tmp folder
				dir: ( callback ) =>
					fs.mkdir directoryName, 0o0777, () ->
						callback null, directoryName

				# Copy current widget or theme to /tmp without dependencies
				store: ( callback ) =>				
					@.store callback

				# # Do code precompilation
				# precompile: ( callback ) =>
				# 	@.precompile directoryName, callback

				# Pack current widget
				pack: ( callback ) =>
					fstream.Reader
						path: directoryName
						type: 'Directory'
					.pipe( tar.Pack({}) )
					.pipe fstream.Writer( "/tmp/#{fileName}" ).on 'close', ( err ) ->
						if err?
							log.error 'Failed to create package.'
							if not callback? then process.stdin.destroy() else callback err, fileName
						else
							callback(null, fileName)

				# Restore .tar file to the current directory
				restore: ( callback ) =>
					@.restore( fileName, callback )


			, ( err, res ) ->
				log.success "Finished to create package"
				if not callback? then process.stdin.destroy() else callback null, fileName

		else
			log.error "You need to pack only widgets."
			if not callback? then process.stdin.destroy() else callback no, fileName		

	else

		log.error "The folders name (#{path.basename( path.resolve('.') )}) should be the same as your package name in maxmertkit.json (#{mjson.name})."
		if not callback? then process.stdin.destroy() else callback no, fileName






# Store current folder in /tmp/ folder.

exports.store = ( callback ) ->

	mjson = maxmertkit.json()

	directoryName = "/tmp/#{mjson.name}"

	ncp '.', directoryName,
		filter: (name) ->
			currentName =  path.relative('.',name).split( path.sep )[0]
			
			if currentName.charAt(0) is '.' or path.relative('.',name).indexOf('dependences') isnt -1 or path.relative('.',name).indexOf('.tar') isnt -1
				no
			else
				yes
	, ( err ) ->
		if err
			log.error "Failed to store current directory to #{directoryName} folder. Do you have permissions?"
			if not callback? then process.stdin.destroy() else callback err, directoryName
		else
			if not callback? then process.stdin.destroy() else callback null, directoryName



# Restore package from /tmp folder to the current folder

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




# Unpacking widget in current folder.

exports.unpack = ( fileName, callback ) ->

	mjson = maxmertkit.json()
	fileName = "#{mjson.name}@#{mjson.version}.tar"
	fs
		.createReadStream( path.join '.', fileName )
		.pipe tar.Extract
			path: '.'
		.on 'error', ( err ) ->
			log.error "Failed to unpack #{fileName} width error:\n#{err}"
			if not callback? or typeof callback is 'object' then process.stdin.destroy() else callback err, fileName
		.on 'end', () ->
			log.success "File #{fileName} unpacked."
			if not callback? or typeof callback is 'object' then process.stdin.destroy() else callback null, fileName







rmdirSyncForce = ( path ) ->
	if path[path.length - 1] isnt '/'
		path = path + '/'

	files = fs.readdirSync path
	filesLength = files.length

	if filesLength
		for file in files
			fileStats = fs.statSync path+file
			if fileStats.isFile()
				fs.unlinkSync(path + file)
			if fileStats.isDirectory()
				rmdirSyncForce(path + file)

	fs.rmdirSync path











# Prepare main file of widget for publishing

# exports.precompile = ( directoryName, callback ) ->

# 	mjson = maxmertkit.json()
# 	fileName = path.join( directoryName, '_index.sass' )

# 	async.series

# 		widget: ( callback ) ->

# 			fs.readFile fileName, ( err, data ) ->

# 				if err? then callback( err, null )

# 				callback null, data

# 	, ( err, data ) ->

# 		if err?
# 			log.error "Failed to precompile #{fileName}."
# 			if not callback? then process.stdin.destroy() else callback err, fileName

# 		else
# 			mjson.data = data.widget

# 			result = mustache.render templates.widgetFinal, mjson

# 			fs.writeFile fileName, result, ( err ) ->

# 					if err?
# 						log.error "Failed to precompile #{fileName}."
# 						if not callback? then process.stdin.destroy() else callback err, fileName

# 					else
# 						if not callback? then process.stdin.destroy() else callback null, fileName















































# ###
# Packing widget or theme in current folder. The folders name should be the same as your package name in maxmertkit.json
# ###
# exports.pack = ( options, callback ) ->

# 	maxmertkitjson = @.maxmertkit()

# 	# Check if package name is the same as folder name
# 	if path.basename( path.resolve('.') ) is "#{maxmertkitjson.name}"

# 		directoryName = "/tmp/#{maxmertkitjson.name}"
# 		fileName = "#{maxmertkitjson.name}@#{maxmertkitjson.version}.tar"

# 		# Need to do a lot of things one after another
# 		async.series

# 			# Remove directory in /tmp folder is it exists
# 			rmdir: ( callback ) =>
# 				fs.exists directoryName, ( exists ) ->
# 					if exists
# 						rmdirSyncForce directoryName, callback
					
# 					callback null, 'yes'

# 			# Create directory in /tmp folder
# 			dir: ( callback ) =>
# 				fs.mkdir directoryName, 0o0777, () ->
# 					callback( null, directoryName )

# 			# Copy current widget or theme to /tmp without dependencies
# 			store: ( callback ) =>				
# 				@.store callback

# 			# Do code precompilation
# 			precompile: ( callback ) =>
# 				@.precompile directoryName, callback

# 			# Pack current widget
# 			pack: ( callback ) =>
# 				fstream.Reader
# 					path: directoryName
# 					type: 'Directory'
# 				.pipe( tar.Pack({}) )
# 				.pipe fstream.Writer( "/tmp/#{fileName}" ).on 'close', ( err ) ->
# 					if err?
# 						log.error 'Failed to create package.'
# 						if not callback? then process.stdin.destroy() else callback err, fileName
# 					else
# 						callback(null, fileName)

# 			# Restore .tar file to the current directory
# 			restore: ( callback ) =>
# 				@.restore( fileName, callback )


# 		, ( err, res ) ->
# 			log.success "Finished to create package"
# 			if not callback? then process.stdin.destroy() else callback null, fileName

# 	else

# 		log.error "The folders name (#{path.basename( path.resolve('.') )}) should be the same as your package name in maxmertkit.json (#{maxmertkitjson.name})."
# 		if not callback? then process.stdin.destroy() else callback no, fileName




# ###
# Store current folder in /tmp/ folder.
# ###
# exports.store = ( callback ) ->

# 	maxmertkitjson = @.maxmertkit()

# 	directoryName = "/tmp/#{maxmertkitjson.name}"

# 	ncp '.', directoryName,
# 		filter: (name) ->
# 			currentName =  path.relative('.',name).split( path.sep )[0]
			
# 			if currentName.charAt(0) is '.' or path.relative('.',name).indexOf('dependences') isnt -1 or path.relative('.',name).indexOf('.tar') isnt -1
# 				no
# 			else
# 				yes
# 	, ( err ) ->
# 		if err
# 			log.error "Failed to store current directory to #{directoryName} folder. Do you have permissions?"
# 			if not callback? then process.stdin.destroy() else callback err, directoryName
# 		else
# 			if not callback? then process.stdin.destroy() else callback null, directoryName



# ###
# Restore package from /tmp folder to the current folder
# ###
# exports.restore = ( fileName, callback ) ->
	
# 	fs.readFile path.join( '/tmp/', fileName ), ( err, data ) ->
# 		if err?
# 			log.error "Failed to restore #{fileName} from /tmp folder. Maybe there is no such file or folder."
# 			if not callback? then process.stdin.destroy() else callback err, fileName
		
# 		else

# 			fs.writeFile path.join( '.', fileName ), data, ( err ) ->

# 				if err?
# 					log.error "Failed to restore #{fileName} from /tmp folder. Maybe you do not have permissions to write in current folder."
# 					if not callback? then process.stdin.destroy() else callback err, fileName

# 				else
# 					if not callback? then process.stdin.destroy() else callback null, fileName



# ###
# Unpacking widget or theme in current folder.
# ###
# exports.unpack = ( fileName, callback ) ->

# 	maxmertkitjson = @.maxmertkit()
# 	fileName = "#{maxmertkitjson.name}@#{maxmertkitjson.version}.tar"
# 	fs
# 		.createReadStream( path.join '.', fileName )
# 		.pipe tar.Extract
# 			path: '.'
# 		.on 'error', ( err ) ->
# 			log.error "Failed to unpack #{fileName} width error:\n#{err}"
# 			if not callback? or typeof callback is 'object' then process.stdin.destroy() else callback err, fileName
# 		.on 'end', () ->
# 			log.success "File #{fileName} unpacked."
# 			if not callback? or typeof callback is 'object' then process.stdin.destroy() else callback null, fileName



# ###
# Prepare main file of widget for publishing
# ###
# exports.precompile = ( directoryName, callback ) ->

# 	maxmertkitjson = @.maxmertkit()
# 	fileName = path.join( directoryName, '_index.sass' )

# 	async.series

# 		widget: ( callback ) ->

# 			fs.readFile fileName, ( err, data ) ->

# 				if err? then callback( err, null )

# 				callback null, data

# 	, ( err, data ) ->

# 		if err?
# 			log.error "Failed to precompile #{fileName}."
# 			if not callback? then process.stdin.destroy() else callback err, fileName

# 		else
# 			maxmertkitjson.data = data.widget

# 			result = mustache.render templates.widgetFinal, maxmertkitjson

# 			fs.writeFile fileName, result, ( err ) ->

# 					if err?
# 						log.error "Failed to precompile #{fileName}."
# 						if not callback? then process.stdin.destroy() else callback err, fileName

# 					else
# 						if not callback? then process.stdin.destroy() else callback null, fileName




# ###
# Install all dependences
# ###
# exports.install = ->

# 	maxmertkitjson = @.maxmertkit()

# 	if not maxmertkitjson.dependences? or maxmertkitjson.dependences.length <= 0
# 		log.error "Couldn\'t install your dependences because you don\'t have any."
# 		process.stdin.destroy()

# 	else

# 		deps = maxmertkitjson.dependences
# 		dependences = []

# 		for name, version of deps
# 			dependences.push name: name, version: version

# 		async.series

# 			exists: ( callback ) =>
		
# 				async.every dependences, @onServerIsExistsVersion, (err, results) =>
# 					if err
# 						callback err, null

# 					else
# 						callback null, yes

# 			get: ( callback ) =>

# 				async.every dependences, @onServerGetDependencyWidget, ( err, results ) =>

# 					if err
# 						callback err, null

# 					else
# 						callback null, yes


# 		, ( err, data ) ->

# 			if err?
# 				console.log '\n'
# 				log.error "Installation aborted because some widgets or their versions don\'t exists on server."
# 				process.stdin.destroy()


# # ==============================
# # ============================== SERVER FEATURES
# # ==============================



# ###
# Get dependency from server
# ###
# exports.onServerGetDependencyWidget = ( widget, callback ) ->


# 	writer = fs.createWriteStream("/tmp/#{widget.name}@#{widget.version}.tar")

# 	req = request
# 		.get( "#{pack.homepage}/widgets/#{widget.name}/#{widget.version}/tar" )
# 		.set( 'X-Requested-With', 'XMLHttpRequest' )
# 		.set('Accept', 'application/tar')
	
# 	req.pipe writer
# 		# .end ( res ) ->
# 		# 	if res.ok
# 		# 		console.log res
# 		# 		# log.requestSuccess res.body.msg, 'OK', res.status
# 		# 		if not callback? or typeof callback is 'object' then process.stdin.destroy() else callback null, widget.name
			
# 		# 	else
# 		# 		log.requestError res.body.msg, 'ERRR', res.status
# 		# 		if not callback? or typeof callback is 'object' then process.stdin.destroy() else callback yes, widget.name





# ###
# Check if widget or theme is exists
# ###
# exports.onServerIsExistsApp = ( options, callback ) ->

# 	widget = @.maxmertkit()
# 	if options.version? and options.version is yes
# 		@onServerIsExistsVersion widget, callback
# 	else
# 		@onServerIsExists widget, callback


# exports.onServerIsExists = ( widget, callback ) ->

# 	request
# 		.get( "#{pack.homepage}/widgets/#{widget.name}" )
# 		.set( 'X-Requested-With', 'XMLHttpRequest' )
# 		.end ( res ) ->
# 			if res.ok
# 				log.requestSuccess res.body.msg, 'OK', res.status
# 				if not callback? or typeof callback is 'object' then process.stdin.destroy() else callback null, widget.name
			
# 			else
# 				log.requestError res.body.msg, 'ERRR', res.status
# 				if not callback? or typeof callback is 'object' then process.stdin.destroy() else callback yes, widget.name






# ###
# Check if widget or theme with current version is exists
# ###
# exports.onServerIsExistsVersionApp = ( options, callback ) ->

# 	widget = @.maxmertkit()

# 	@onServerIsExistsVersion widget, callback


# exports.onServerIsExistsVersion = ( widget, callback ) ->

# 	async.series

# 		exists: ( callback ) =>
# 			exports.onServerIsExists( widget, callback )
		
# 	, ( err, res ) =>
		
# 		if err
# 			if not callback? or typeof callback is 'object' then process.stdin.destroy() else callback err, widget.name
# 		else
			
# 			request
# 				.get( "#{pack.homepage}/widgets/#{widget.name}/#{widget.version}" )
# 				.set( 'X-Requested-With', 'XMLHttpRequest' )
# 				.end ( res ) ->
					
# 					if res.ok
# 						log.requestSuccess res.body.msg, 'OK', res.status
# 						if not callback? or typeof callback is 'object' then process.stdin.destroy() else callback null, widget.name
# 					else
# 						log.requestError res.body.msg, 'ERRR', res.status
# 						if not callback? or typeof callback is 'object' then process.stdin.destroy() else callback yes, widget.name





# ###
# Publish current version of widget or theme
# ###
# exports.onServerPublish = ( options, callback ) ->

# 	widget = @.maxmertkit()
# 	widget.dependencies = [] if not widget.dependencies?

	
# 	fileName = "#{widget.name}@#{widget.version}.tar"

# 	async.series

# 		# exists: ( callback ) =>
# 		# 	@.onServerIsExistsVersion( options, callback )

# 		pack: ( callback ) =>
# 			@.pack( options, callback )

# 		password: ( callback ) =>
# 			dialog.password '\nEnter your password: ', ( password ) ->
# 				callback null, password

# 	, ( err, res ) =>
		
# 		if err
# 			log.error "Could not publish widget."
# 			if not callback? or typeof callback is 'object' then process.stdin.destroy() else callback err, widget.name

# 		else
# 			request
# 				.post( "#{pack.homepage}/widgets/#{widget.name}/#{widget.version}/publish" )
# 				.set( 'X-Requested-With', 'XMLHttpRequest' )
# 				.attach( 'pack', fileName )
# 				.field( 'packName', res.pack)
# 				.field( 'name', widget.name)
# 				.field( 'version', widget.version)
# 				.field( 'password', res.password)
# 				.field( 'username', widget.author )
# 				# .field( 'dependencies', widget.dependencies )
# 				.end ( res ) ->
# 					if res.ok
# 						log.requestSuccess "widget #{widget.name}@#{widget.version} successfully published."
# 						fs.unlink "#{widget.name}@#{widget.version}.tar", (err) ->
# 							if not callback? or typeof callback is 'object' then process.stdin.destroy() else callback null, widget.name

# 					else
# 						log.requestError res.body.msg, 'ERRR', res.status
# 						fs.unlink "#{widget.name}@#{widget.version}.tar", (err) ->				
# 							if not callback? or typeof callback is 'object' then process.stdin.destroy() else callback yes, widget.name






# ###
# Unpublish current version of widget or theme
# ###
# exports.onServerUnpublish = ( options, callback ) ->

# 	widget = @.maxmertkit()

# 	fileName = "#{widget.name}@#{widget.version}.tar"

# 	async.series

# 		password: ( callback ) =>
# 			dialog.password '\nEnter your password: ', ( password ) ->
# 				callback null, password

# 	, ( err, res ) =>

# 		if err
# 			log.error "Could not unpublish widget."
# 			if not callback? or typeof callback is 'object' then process.stdin.destroy() else callback err, widget.name

# 		else
# 			request
# 				.del( "#{pack.homepage}/widgets/#{widget.name}/#{widget.version}" )
# 				.set( 'X-Requested-With', 'XMLHttpRequest' )
# 				.field( 'packName', fileName)
# 				.field( 'name', widget.name)
# 				.field( 'version', widget.version)
# 				.field( 'password', res.password)
# 				.field( 'username', widget.author )
# 				.end ( res ) ->
# 					if res.ok
# 						log.requestSuccess "widget #{widget.name}@#{widget.version} successfully unpublished."
# 						if not callback? or typeof callback is 'object' then process.stdin.destroy() else callback null, widget.name

# 					else
# 						log.requestError res.body.msg, 'ERRR', res.status						
# 						if not callback? or typeof callback is 'object' then process.stdin.destroy() else callback yes, widget.name




# # exports.pack = ->

# # 	packFile = "/tmp/#{pack.name}@#{pack.version}.tar"

# # 	fstream.Reader
# # 		type: "Directory"
# # 		path: '.'
	
# # 	.pipe(tar.Pack({}))
# # 		.on 'error', =>
# # 			log.error 'Failed to create package.'

# # 	.pipe fstream.Writer( packFile )
# # 		.on "close", =>
# # 			log.success "Finished to create package"
# # 			@.sendPack packFile




# # ###
# # Check if widget is exists at the server
# # ###
# # exports.isExist = ( widget, callback ) ->

# # 	request
# # 		.get( "#{pack.homepage}/widgets/#{widget.name}" )
# # 		.set('Accept', 'application/json')
# # 		.end (res) ->
			
# # 			if res.statusCode is 502 or res.statusCode is 404 or not res.body.done
# # 				log.requestError("#{pack.homepage}/widgets/#{widget.name}", widget.name) if widget.options.silent isnt on
# # 				callback( false )
				
# # 			else
# # 				log.requestSuccess("#{pack.homepage}/widgets/#{widget.name}", widget.name) if widget.options.silent isnt on
# # 				callback( true )



# # ###
# # Init new widget/theme
# # ###
# # exports.init = ( options ) ->

# # 	# Writes <pack.maxmertkit> json file
# # 	writeJSON = ( json ) ->
# # 		fs.writeFile pack.maxmertkit, JSON.stringify(json, null, 4), ( err ) ->
													
# # 			if err then log.error("while initializing – #{err}")

# # 			log.success("file #{pack.maxmertkit} successfully created.")
# # 			process.stdin.destroy()



# # 	type = ['widget', 'theme']


# # 	console.log 'Choose what you will create'
	
# # 	dialog.choose type, (i) ->
# # 		# console.log 'You chose %s', type[i]
		
# # 		dialog.prompt "#{type[i]} name: (test) ", ( pkgName ) ->
# # 			pkgName = 'test' if pkgName is ''
# # 			# console.log 'Hello %s', pkgName

# # 			dialog.prompt "version: (0.0.0) ", ( version ) ->
# # 				version = '0.0.0' if version is ''

# # 				dialog.prompt "description: ", ( description ) ->

# # 					dialog.prompt "repository: ", ( repository ) ->
				
# # 						dialog.prompt "author: ", ( author ) ->

# # 							dialog.prompt "license: (BSD) ", ( license ) ->
# # 								license = 'BSD' if license is ''

# # 								maxmertkitjson = 
# # 									type: type[i]
# # 									name: pkgName
# # 									version: version
# # 									description: description
# # 									repository: repository
# # 									author: author
# # 									license: license
# # 								console.log ""
							
# # 								dialog.confirm "Is everything correct? \n\n #{JSON.stringify(maxmertkitjson, null, 4)}\n-> ", ( ok ) ->
									
# # 									console.log ""

# # 									if not ok
# # 										log.error("Initializing canceled")
# # 										process.stdin.destroy()

# # 									else
# # 										fs.exists pack.maxmertkit, ( exists ) ->
											
# # 											if not exists
# # 												writeJSON maxmertkitjson

# # 											else #if exists
# # 												log.error("File #{pack.maxmertkit} already exists.")

# # 												dialog.confirm "Do you want to overwrite it? -> ", ( ok ) ->

# # 													if not ok
# # 														log.error("initialization canceled.")
# # 														process.stdin.destroy()

# # 													else
# # 														writeJSON maxmertkitjson



# # exports.install = ( widget, callback ) ->

# # 	fileName = "#{widget.name}@#{widget.version}.tar"
# # 	stream = fs.createWriteStream( fileName )
# # 	req = request.get( "#{pack.homepage}/widgets/#{widget.name}/#{widget.version}/tar" )
# # 	req.pipe(stream)
	
# # 	stream.on 'close', ->
# # 		fs
# # 			.createReadStream( fileName )
# # 			.pipe( tar.Extract( path: './' ) )
# # 			.on 'error', ( err )->
# # 				log.error err
# # 			.on 'end', ->
# # 				fs.unlink fileName
# # 				log.success "Installation of #{fileName} complete."

# # 	callback()


# # exports.sendPack = (file) ->
	
# # 	fs.readFile pack.maxmertkit, ( err, data ) ->

# # 		if err
# # 			log.error("can\'t find #{pack.maxmertkit} file.")
# # 			process.stdin.destroy()

# # 		if data?
# # 			maxmertkitjson = JSON.parse data

# # 			request
# # 				.post( "#{pack.homepage}/#{maxmertkitjson.author}/publish" )
# # 				.attach( path.basename( file ), file )
# # 				.end ( res ) ->
# # 					console.log res


# # exports.checkPack = ->

# # 	fs.readFile pack.maxmertkit, ( err, data ) =>

# # 		if err
# # 			log.error("can\'t find #{pack.maxmertkit} file.")
# # 			process.stdin.destroy()

# # 		if data?
# # 			maxmertkitjson = JSON.parse data

# # 			request
# # 				.get( "#{pack.homepage}/widgets/#{maxmertkitjson.name}/#{maxmertkitjson.version}" )
# # 				.set('Accept', 'application/json')
# # 				.end (res) => 
# # 					if not res.ok
# # 						log.requestError("Getting information about #{pack.name} if failed.")
# # 						process.stdin.destroy()
# # 					else
# # 						@.pack()


# # exports.publish = ( author ) ->

# # 	dialog.password 'Password: ', ( pass ) =>
# # 		request
# # 			.post( "#{pack.homepage}/loginAJAX" )
# # 			.send
# # 				username: author
# # 				password: pass
# # 			.set('Accept', 'application/json')
# # 			.end (res) =>
				
# # 				if not res.ok
# # 					log.error("Authorization Failed. Check the author name in maxmert.json or your password. Or maybe you need to register at #{pack.homepage}?")
# # 					process.stdin.destroy()
# # 				else
# # 					log.success("Authorization succeed.")
# # 					@.checkPack()

# 					# @.pack ->
# 					# 	@.sendPack()
# 					# process.stdin.destroy()





# # exports.installJSON = () ->

# # 	fs.readFile pack.maxmertkit, ( err, data ) ->

# # 		if err
# # 			log.error("can\'t find #{pack.maxmertkit} file.")
# # 			process.stdin.destroy()

# # 		if data?
# # 			maxmertkitjson = JSON.parse data

# # 			if not maxmertkitjson.dependences?
# # 				console.log "There is no dependences in #{pack.maxmertkit} file."
# # 				process.stdin.destroy()

# # 			else
# # 				for widget, version of maxmertkitjson.dependences
# # 					exports.install 
# # 						name: widget
# # 						version: version
# # 					, ->

# 				# console.log exports.install

# 	# fs.exists pack.maxmertkit, ( exists ) ->

# 	# 	if exists
# 	# 		fs.readFile
# 	# 		console.log maxmertkitjson