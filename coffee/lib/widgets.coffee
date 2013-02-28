pack = require '../package.json'
templates = require '../templates.json'

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
modifyers = require './modifyers'



# **Initializing**
# widget

exports.init = ( options ) ->

	fileName = '_index.sass'
	paramsFileName = '_params.sass'
	mjson = maxmertkit.json()

	async.series

		imports: ( callback ) =>
			write '_imports.sass', "// Generated with mwm – maxmertkit widget manager\n", callback

		index: ( callback ) =>
			write fileName, mustache.render( templates.widget, mjson ), callback

		params: ( callback ) =>
			write paramsFileName, mustache.render( templates.params, mjson ), callback


	, ( err, res ) =>

		if err?
			log.error "An error while initialized widget."
			process.stdin.destroy()

		else
			process.stdin.destroy()






# **Publish**
# current version of the widget.

exports.publish = ( options ) ->

	mjson = maxmertkit.json()

	async.series

		widget: ( callback ) =>
			
			archives.pack '.', callback


		password: ( callback ) =>
			
			dialog.password '\nEnter your password: ', ( password ) ->
				callback null, password

	, ( err, res ) =>

		if err?
			log.error "Publishing canceled."
			process.stdin.destroy()

		else
			
			packFile = path.join '.', "#{mjson.name}@#{mjson.version}.tar"

			request
				.post( "#{pack.homepage}/widgets/#{mjson.name}/#{mjson.version}" )
				.set( 'X-Requested-With', 'XMLHttpRequest' )
				
				.attach( 'pack', packFile )
				.field( 'packName', path.basename( packFile ) )
				.field( 'password', res.password )
				.field( 'name', mjson.name )
				.field( 'version', mjson.version )
				.field( 'username', mjson.author )
				
				.end ( res ) ->
					
					if res.ok
						log.requestSuccess "widget #{mjson.name}@#{mjson.version} successfully published."
						process.stdin.destroy()

					else
						log.requestError res.body.msg, 'ERRR', res.status
						process.stdin.destroy()

					fs.unlink packFile




# **Unpublish**
# current version of the widget.

exports.unpublish = ( options ) ->

	mjson = maxmertkit.json()

	fileName = "#{mjson.name}@#{mjson.version}.tar"

	async.series

		password: ( callback ) =>
			dialog.password '\nEnter your password: ', ( password ) ->
				callback null, password

	, ( err, res ) =>

		if err
			log.error "Could not unpublish widget."
			if not callback? or typeof callback is 'object' then process.stdin.destroy() else callback err, mjson.name

		else
			request
				.del( "#{pack.homepage}/widgets/#{mjson.name}/#{mjson.version}" )
				.set( 'X-Requested-With', 'XMLHttpRequest' )
				.field( 'packName', fileName)
				.field( 'name', mjson.name)
				.field( 'version', mjson.version)
				.field( 'password', res.password)
				.field( 'username', mjson.author )
				.end ( res ) ->
					if res.ok
						log.requestSuccess "widget #{mjson.name}@#{mjson.version} successfully unpublished."
						if not callback? or typeof callback is 'object' then process.stdin.destroy() else callback null, mjson.name

					else
						log.requestError res.body.msg, 'ERRR', res.status						
						if not callback? or typeof callback is 'object' then process.stdin.destroy() else callback yes, mjson.name






# **Install**
# widget dependences.

exports.install = ( pth, list, calll, depent ) ->

	arr = []
	_.each list, ( info, name ) ->
		arr.push
			name: name
			version: info.version
			themes: info.themes
			modifyers: info.modifyers

	async.every arr, ( widget, callback ) ->
		
		@calll = calll
		@depent = depent

		process.nextTick ( callback, calll, dependent ) =>
			
			fileName = "#{widget.name}@#{widget.version}.tar"
			
			req = request
				.get( "#{pack.homepage}/widgets/#{widget.name}/#{widget.version}" )
				.set( 'X-Requested-With', 'XMLHttpRequest' )
				.end ( res ) =>

					if res.ok

						req = request
							.get( "#{pack.homepage}/widgets/#{widget.name}/#{widget.version}" )
							.set( 'X-Requested-With', 'XMLHttpRequest' )

						stream = fs.createWriteStream( path.join(pth, fileName) )

						req.pipe stream

						stream.on 'close', ->
							
							archives.unpack path.join(pth, fileName), ( err ) ->
								
								if err?
									log.error "Couldn\'t unpack #{widget.name}@#{widget.version}.tar"
									callback yes, null
								
								else
									fs.unlink path.join(pth, fileName)

									fs.readFile path.join(pth,'../../_imports.sass'), ( err, data ) ->
										if err?
											log.error "Coluld not read #{path.join(pth,'../../_imports.sass')}."
											process.stdin.destroy()

										else
											data = "@import 'dependences/widgets/#{widget.name}/_index.sass'\n" + data
											
											fs.writeFile path.join(pth,'../../_imports.sass'), data, ( err ) ->

												if err?
													callback yes, null

												else
													
													if @depent
														depent = yes
													
													if widget.themes?
														depent = yes

													fs.writeFileSync path.join(pth, widget.name, '_params.sass'), "$dependent: #{depent}\n"

													@calll path.join(pth, widget.name), depent
														
													if widget.themes?
														themes.install path.join( pth, widget.name, 'dependences/themes' ), widget.themes, depent

													if widget.modifyers?
														modifyers.install path.join( pth, widget.name, 'dependences/modifyers' ), widget.modifyers

						

					else
						log.requestError res.body.msg, 'ERRR', res.status						
						if not callback? or typeof callback is 'object' then process.stdin.destroy() else callback yes, widget.name


	, ( res ) ->
		# console.log err
		if not res?
			log.error "An error while installing widgets."
			process.stdin.destroy()

		else
			log.success "Done."

























# Function with json write.

write = ( file, data, callback ) ->

	fs.writeFile file, data, ( err ) ->

		if err
			log.error "initializing – #{err}."
			callback err, null

		else
		
			log.success "file #{file} successfully created."
			callback null, data




















# pack = require '../package.json'
# templates = require '../templates.json'
# request = require 'superagent'
# dialog = require 'commander'
# path = require 'path'
# log = require './logger'
# async = require 'async'
# tar = require 'tar'
# mustache = require 'mustache'
# _ = require 'underscore'
# wrench = require 'wrench'

# fs = require 'fs'
# ncp = require('ncp').ncp
# fstream = require 'fstream'



# # Returns the сontent of maxmertkit.json file

# exports.maxmertkit = ->
	
# 	rawjson = fs.readFileSync path.join( '.', pack.maxmertkit )
	
# 	if not rawjson?
# 		log.error("couldn\'t read #{pack.maxmertkit} file.")
# 		process.stdin.destroy()

# 	else
# 		json = JSON.parse rawjson




# foldersExist = ( pth, callback ) ->

# 	paths = pth.split path.sep
# 	current = ''
	
# 	for index, pt of paths
		
# 		current = path.join current, pt
# 		if not fs.existsSync(current) then callback true, current

# 	callback null, pth








# # **Initializing**
# # maxmertkit.json file with main info about project

# exports.initCommonSubapp = ( options, callback ) ->

# 	async.series

# 		type: ( callback ) ->

# 			if not options.theme and not options.modifyer

# 				callback null, 'widget'

# 			else if options.theme

# 				callback null, 'theme'

# 			else if options.modifyer

# 				callback null, 'modifyer'

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

# 		@.initWriteConfirm  pack.maxmertkit, maxmertkitjson, callback




# # Function with json write confirmation.
# # Uses with maxmertkit.json, theme.json and modifyer.json

# exports.initWriteConfirm = ( file, json, callback ) ->

# 	console.log "\n\nWriting file #{file}\n"
# 	dialog.confirm "Is everything correct? \n\n #{JSON.stringify(json, null, 4)}\n-> ", ( ok ) =>

# 			console.log ""

# 			if not ok
# 				log.error("Initializing canceled")
# 				callback ok, null
# 				process.stdin.destroy()

# 			else
# 				fs.exists file, ( exists ) =>

# 					if not exists
# 						@.initWrite file, json, callback
# 						process.stdin.destroy()

# 					else #if exists
# 						log.error("File #{file} already exists.")

# 						dialog.confirm "Do you want to overwrite it and all other files in that folder? -> ", ( ok ) =>

# 							if not ok
# 								log.error("initialization canceled.")
# 								callback ok, null
# 								process.stdin.destroy()

# 							else
# 								@.initWrite file, json, callback
# 								process.stdin.destroy()




# # Function with json write.
# # Uses with maxmertkit.json, theme.json and modifyer.json

# exports.initWrite = ( file, json, callback ) ->

# 	fs.writeFile file, JSON.stringify(json, null, 4), ( err ) ->

# 		if err
# 			log.error "initializing – #{err}."
# 			callback err, null

# 		else
# 			# TODO: Add some info about maxmertkit.json ??

# 			log.success "file #{file} successfully created."
# 			callback null, json






# exports.initWidgetSubapp = ( options ) ->

# 	async.series

# 		common: ( callback ) =>

# 			@initCommonSubapp options, callback


# 	, ( err, res ) =>

# 		console.log 'ok'



# # **Initialization**
# # of the theme

# exports.initThemeSubapp = ( options ) ->

# 	fileName = 'theme.json'

# 	async.series

# 		common: ( callback ) =>

# 			@initCommonSubapp options, callback


# 		theme: ( callback ) =>

# 			request
# 				.get( "#{pack.homepage}/defaults/theme" )
# 				.set( 'X-Requested-With', 'XMLHttpRequest' )
# 				.set('Accept', 'application/json')
# 				.end ( res ) =>

# 					if res.ok
# 						@initWrite fileName, res.body, callback

# 					else
# 						log.requestError res.body.msg, 'ERRR', res.status
# 						callback res.error, null


# 	, ( err, res ) =>

# 		if err?
# 			log.error "An error while initialized theme."
# 			process.stdin.destroy()

# 		else
# 			process.stdin.destroy()


# # **Initialization**
# # of the modifyer

# exports.initModifyerSubapp = ( options ) ->

# 	fileName = 'modifyer.json'

# 	async.series

# 		common: ( callback ) =>

# 			@initCommonSubapp options, callback


# 		theme: ( callback ) =>

# 			request
# 				.get( "#{pack.homepage}/defaults/modifyer" )
# 				.set( 'X-Requested-With', 'XMLHttpRequest' )
# 				.set('Accept', 'application/json')
# 				.end ( res ) =>

# 					if res.ok
# 						@initWrite fileName, res.body, callback

# 					else
# 						log.requestError res.body.msg, 'ERRR', res.status
# 						callback res.error, null


# 	, ( err, res ) =>

# 		if err?
# 			log.error "An error while initialized modifyer."
# 			process.stdin.destroy()

# 		else
# 			process.stdin.destroy()







# #### Server side



# # **Publish**
# # current version of widget/theme/modifyer.
# # First get type, then call publishing function.
# exports.Publish = ( options ) ->

# 	maxmertkit = @maxmertkit()

# 	switch maxmertkit.type

# 		when 'widget'
# 			@PublishWidget options

# 		when 'theme'
# 			@PublishTheme options

# 		when 'modifyer'
# 			@PublishModifyer options


# # **Publish**
# # current version of modifyer.
# exports.PublishModifyer = ( options ) ->

# 	maxmertkit = @maxmertkit()

# 	fileName = 'modifyer.json'

# 	async.series

# 		modifyer: ( callback ) =>
			
# 			rawjson = fs.readFileSync path.join( '.', fileName )
	
# 			if not rawjson?
# 				log.error("couldn\'t read #{fileName} file.")
# 				callback true, null

# 			else
# 				json = JSON.parse rawjson
# 				callback null, json


# 		password: ( callback ) =>
			
# 			dialog.password '\nEnter your password: ', ( password ) ->
# 				callback null, password

# 	, ( err, res ) =>

# 		if err?
# 			log.error "Publishing canceled."
# 			process.stdin.destroy()

# 		else
			
# 			request
# 				.post( "#{pack.homepage}/modifyers/#{maxmertkit.name}/#{maxmertkit.version}" )
# 				.set( 'X-Requested-With', 'XMLHttpRequest' )
# 				.send
# 					modifyer: res.modifyer
# 					password: res.password
# 					name: maxmertkit.name
# 					version: maxmertkit.version
# 					username: maxmertkit.author
				
# 				.end ( res ) ->
					
# 					if res.ok
# 						log.requestSuccess "modifyer #{maxmertkit.name}@#{maxmertkit.version} successfully published."
# 						process.stdin.destroy()

# 					else
# 						log.requestError res.body.msg, 'ERRR', res.status
# 						process.stdin.destroy()




							






# # **Install**
# # all dependences
# exports.Install = ( options ) ->

	

		




# install = ( json, pth ) ->

# 	async.series

# 		modifyers: ( callback ) ->

# 			if json.modifyers?

# 				foldersExist path.join( pth, 'dependences/modifyers' ), ( err, pth ) ->
# 					if err?
# 						fs.mkdirSync pth

# 				modifyers = []
				
# 				_.each json.modifyers, ( version, name ) ->
# 					modifyers.push
# 						name: name
# 						version: version

				

# 				async.every modifyers, exports.installModifyer, ( err ) ->

# 					if err? then process.stdin.destroy()


# 	, ( err, res ) ->
# 		process.stdin.destroy()



# # **Install**
# # modifyers dependences

# exports.installModifyer = ( modifyer ) ->

# 	request
# 		.get( "#{pack.homepage}/modifyers/#{modifyer.name}/#{modifyer.version}" )
# 		.set( 'X-Requested-With', 'XMLHttpRequest' )
# 		.end ( res ) ->

# 			if res.ok
# 				log.requestSuccess "modifyer #{modifyer.name}@#{modifyer.version} successfully installed."



# 			else
# 				log.requestError res.body.msg, 'ERRR', res.status
# 				res.error







































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



	
