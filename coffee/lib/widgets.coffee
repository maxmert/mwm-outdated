pack = require '../package.json'

async = require 'async'
request = require 'superagent'
fs = require 'fs'
path = require 'path'
dialog = require 'commander'
_ = require 'underscore'

log = require './logger'
maxmertkit = require './maxmertkit'



# **Initializing**
# widget

exports.init = ( options ) ->

	fileName = 'index.sass'

	async.series

		widget: ( callback ) =>

			request
				.get( "#{pack.homepage}/defaults/widget" )
				.set( 'X-Requested-With', 'XMLHttpRequest' )
				.set('Accept', 'application/json')
				.end ( res ) =>

					if res.ok
						write fileName, JSON.stringify(res.body, null, 4), callback

					else
						log.requestError res.body.msg, 'ERRR', res.status
						callback res.error, null


	, ( err, res ) =>

		if err?
			log.error "An error while initialized widget."
			process.stdin.destroy()

		else
			process.stdin.destroy()







# **Install**
# widget dependences.

exports.install = ( pth, list, callback ) ->

	arr = []
	_.each list, ( version, name ) ->
		arr.push
			name: name
			version: version


	async.every arr, ( result, callback ) ->
		
		process.nextTick ->
			
			request
				.get( "#{pack.homepage}/themes/#{theme.name}/#{theme.version}" )
				.set( 'X-Requested-With', 'XMLHttpRequest' )
				
				.end ( res ) =>
					
					if not res.ok
						log.requestError res.body.msg, 'ERRR', res.status

					else
						
						if not result?
							result = res.body

						else
							for nme, value of res.body
								result[nme] += "\t#{value}"

						log.requestSuccess "theme #{theme.name}@#{theme.version} successfully downloaded."

						callback null, result

	, ( err, res ) ->
		
		if err?
			log.error "An error while installing themes."
			process.stdin.destroy()

		else
			
			if not res?
				log.error "An error while installing themes."
				process.stdin.destroy()

			else

				str = ''

				for nme, value of res
					str += "$#{nme}: #{value}\n"

				sass fileName, str, ( err, res ) ->

					if err?
						log.error "Couldn\'t write file #{fileName}"

					else

						fs.appendFile '_imports.sass', "@import '#{fileName}'\n", ( err ) ->
							
							if err?
								log.error "Couldn\'t append import of #{fileName} to the file _imports.sass"

							else
								console.log '\n'
								log.requestSuccess "all themes successfully installed."




















































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



	
