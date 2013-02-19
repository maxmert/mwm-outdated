pack = require '../package.json'
templates = require '../templates.json'
request = require 'superagent'
dialog = require 'commander'
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



# Returns the сontent of maxmertkit.json file

exports.maxmertkit = ->
	
	rawjson = fs.readFileSync path.join( '.', pack.maxmertkit )
	
	if not rawjson?
		log.error("couldn\'t read #{pack.maxmertkit} file.")
		process.stdin.destroy()

	else
		json = JSON.parse rawjson




foldersExist = ( pth, callback ) ->

	paths = pth.split path.sep
	current = ''
	
	for index, pt of paths
		
		current = path.join current, pt
		if not fs.existsSync(current) then callback true, current

	callback null, pth








# **Initializing**
# maxmertkit.json file with main info about project

exports.initCommonSubapp = ( options, callback ) ->

	async.series

		type: ( callback ) ->

			if not options.theme and not options.modifyer

				callback null, 'widget'

			else if options.theme

				callback null, 'theme'

			else if options.modifyer

				callback null, 'modifyer'

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

		@.initWriteConfirm  pack.maxmertkit, maxmertkitjson, callback




# Function with json write confirmation.
# Uses with maxmertkit.json, theme.json and modifyer.json

exports.initWriteConfirm = ( file, json, callback ) ->

	console.log "\n\nWriting file #{file}\n"
	dialog.confirm "Is everything correct? \n\n #{JSON.stringify(json, null, 4)}\n-> ", ( ok ) =>

			console.log ""

			if not ok
				log.error("Initializing canceled")
				callback ok, null
				process.stdin.destroy()

			else
				fs.exists file, ( exists ) =>

					if not exists
						@.initWrite file, json, callback
						process.stdin.destroy()

					else #if exists
						log.error("File #{file} already exists.")

						dialog.confirm "Do you want to overwrite it and all other files in that folder? -> ", ( ok ) =>

							if not ok
								log.error("initialization canceled.")
								callback ok, null
								process.stdin.destroy()

							else
								@.initWrite file, json, callback
								process.stdin.destroy()




# Function with json write.
# Uses with maxmertkit.json, theme.json and modifyer.json

exports.initWrite = ( file, json, callback ) ->

	fs.writeFile file, JSON.stringify(json, null, 4), ( err ) ->

		if err
			log.error "initializing – #{err}."
			callback err, null

		else
			# TODO: Add some info about maxmertkit.json ??

			log.success "file #{file} successfully created."
			callback null, json






exports.initWidgetSubapp = ( options ) ->

	async.series

		common: ( callback ) =>

			@initCommonSubapp options, callback


	, ( err, res ) =>

		console.log 'ok'



# **Initialization**
# of the theme

exports.initThemeSubapp = ( options ) ->

	fileName = 'theme.json'

	async.series

		common: ( callback ) =>

			@initCommonSubapp options, callback


		theme: ( callback ) =>

			request
				.get( "#{pack.homepage}/defaults/theme" )
				.set( 'X-Requested-With', 'XMLHttpRequest' )
				.set('Accept', 'application/json')
				.end ( res ) =>

					if res.ok
						@initWrite fileName, res.body, callback

					else
						log.requestError res.body.msg, 'ERRR', res.status
						callback res.error, null


	, ( err, res ) =>

		if err?
			log.error "An error while initialized theme."
			process.stdin.destroy()

		else
			process.stdin.destroy()


# **Initialization**
# of the modifyer

exports.initModifyerSubapp = ( options ) ->

	fileName = 'modifyer.json'

	async.series

		common: ( callback ) =>

			@initCommonSubapp options, callback


		theme: ( callback ) =>

			request
				.get( "#{pack.homepage}/defaults/modifyer" )
				.set( 'X-Requested-With', 'XMLHttpRequest' )
				.set('Accept', 'application/json')
				.end ( res ) =>

					if res.ok
						@initWrite fileName, res.body, callback

					else
						log.requestError res.body.msg, 'ERRR', res.status
						callback res.error, null


	, ( err, res ) =>

		if err?
			log.error "An error while initialized modifyer."
			process.stdin.destroy()

		else
			process.stdin.destroy()







#### Server side



# **Publish**
# current version of widget/theme/modifyer.
# First get type, then call publishing function.
exports.Publish = ( options ) ->

	maxmertkit = @maxmertkit()

	switch maxmertkit.type

		when 'widget'
			@PublishWidget options

		when 'theme'
			@PublishTheme options

		when 'modifyer'
			@PublishModifyer options


# **Publish**
# current version of modifyer.
exports.PublishModifyer = ( options ) ->

	maxmertkit = @maxmertkit()

	fileName = 'modifyer.json'

	async.series

		modifyer: ( callback ) =>
			
			rawjson = fs.readFileSync path.join( '.', fileName )
	
			if not rawjson?
				log.error("couldn\'t read #{fileName} file.")
				callback true, null

			else
				json = JSON.parse rawjson
				callback null, json


		password: ( callback ) =>
			
			dialog.password '\nEnter your password: ', ( password ) ->
				callback null, password

	, ( err, res ) =>

		if err?
			log.error "Publishing canceled."
			process.stdin.destroy()

		else
			
			request
				.post( "#{pack.homepage}/modifyers/#{maxmertkit.name}/#{maxmertkit.version}" )
				.set( 'X-Requested-With', 'XMLHttpRequest' )
				.send
					modifyer: res.modifyer
					password: res.password
					name: maxmertkit.name
					version: maxmertkit.version
					username: maxmertkit.author
				
				.end ( res ) ->
					
					if res.ok
						log.requestSuccess "modifyer #{maxmertkit.name}@#{maxmertkit.version} successfully published."
						process.stdin.destroy()

					else
						log.requestError res.body.msg, 'ERRR', res.status
						process.stdin.destroy()




							






# **Install**
# all dependences
exports.Install = ( options ) ->

	

		




install = ( json, pth ) ->

	async.series

		modifyers: ( callback ) ->

			if json.modifyers?

				foldersExist path.join( pth, 'dependences/modifyers' ), ( err, pth ) ->
					if err?
						fs.mkdirSync pth

				modifyers = []
				
				_.each json.modifyers, ( version, name ) ->
					modifyers.push
						name: name
						version: version

				

				async.every modifyers, exports.installModifyer, ( err ) ->

					if err? then process.stdin.destroy()


	, ( err, res ) ->
		process.stdin.destroy()



# **Install**
# modifyers dependences

exports.installModifyer = ( modifyer ) ->

	request
		.get( "#{pack.homepage}/modifyers/#{modifyer.name}/#{modifyer.version}" )
		.set( 'X-Requested-With', 'XMLHttpRequest' )
		.end ( res ) ->

			if res.ok
				log.requestSuccess "modifyer #{modifyer.name}@#{modifyer.version} successfully installed."



			else
				log.requestError res.body.msg, 'ERRR', res.status
				res.error







































# ###
# Initializing new widget or theme in current directory
# ###
# exports.init = ( options ) ->

# 	types = ['widget', 'theme']

# 	async.series
		
# 		type: ( callback ) ->
# 			dialog.choose types, (i) ->
# 				callback null, types[i]

# 		name: ( callback ) ->
# 			defaultPkgName = 'test'
# 			dialog.prompt "name: (test) ", ( pkgName ) ->
# 				if pkgName is '' then pkgName = defaultPkgName
# 				callback null, pkgName

# 		version: ( callback ) ->
# 			defaultVersion = '0.0.0'
# 			dialog.prompt "version: (0.0.0) ", ( version ) ->
# 				if version is '' then version = defaultVersion
# 				callback null, version

# 		description: ( callback ) ->
# 			dialog.prompt "description: ", ( description ) ->
# 				callback null, description

# 		repository: ( callback ) ->
# 			dialog.prompt "repository: ", ( repository ) ->
# 				callback null, repository

# 		author: ( callback ) ->
# 			dialog.prompt "author: ", ( author ) ->
# 				callback null, author

# 		license: ( callback ) ->
# 			defaultLicense = 'BSD'
# 			dialog.prompt "license: (BSD) ", ( license ) ->
# 				if license is '' then license = defaultLicense
# 				callback null, license

# 	, ( err, maxmertkitjson ) =>
		
# 		@.writeConfirm maxmertkitjson, options





# ###
# Confirm writing json to the maxmertkit.json file
# ###
# exports.writeConfirm = ( json, options ) ->

# 	dialog.confirm "Is everything correct? \n\n #{JSON.stringify(json, null, 4)}\n-> ", ( ok ) =>

# 			console.log ""

# 			if not ok
# 				log.error("Initializing canceled")
# 				process.stdin.destroy()

# 			else
# 				fs.exists pack.maxmertkit, ( exists ) =>

# 					if not exists
# 						@.write json, options
# 						process.stdin.destroy()

# 					else #if exists
# 						log.error("File #{pack.maxmertkit} already exists.")

# 						dialog.confirm "Do you want to overwrite it and all other files in that folder? -> ", ( ok ) =>

# 							if not ok
# 								log.error("initialization canceled.")
# 								process.stdin.destroy()

# 							else
# 								@.write json, options
# 								process.stdin.destroy()




# ###
# Writing json to the maxmertkit.json file
# Init other files
# ###
# exports.write = ( json, options ) ->

# 	fs.writeFile pack.maxmertkit, JSON.stringify(json, null, 4), ( err ) ->

# 		if err then log.error "initializing – #{err}."
# 		log.success "file #{pack.maxmertkit} successfully created."

	
# 	if json.type is 'widget'

# 		# Initialize _index.sass
# 		fs.writeFile '_index.sass', mustache.render( templates.widget, json ) , ( err ) ->
			
# 			if err?
# 				log.error "Coluldn\'t initialize _index.sass file."
# 				process.stdin.destroy()

# 			else
# 				log.success "file _index.sass successfully created."

# 	else

# 		# If theme
# 		fs.writeFile 'theme.json', mustache.render( templates.theme, json ) , ( err ) ->

# 			if err?
# 				log.error "Coluldn\'t initialize theme.json file."
# 				process.stdin.destroy()

# 			else
# 				log.success "file theme.json successfully created."




# rmdirSyncForce = ( path ) ->
# 	if path[path.length - 1] isnt '/'
# 		path = path + '/'

# 	files = fs.readdirSync path
# 	filesLength = files.length

# 	if filesLength
# 		for file in files
# 			fileStats = fs.statSync path+file
# 			if fileStats.isFile()
# 				fs.unlinkSync(path + file)
# 			if fileStats.isDirectory()
# 				rmdirSyncForce(path + file)

# 	fs.rmdirSync path



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

	
