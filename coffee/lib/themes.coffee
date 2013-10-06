pack = require '../package.json'

async = require 'async'
request = require 'superagent'
fs = require 'fs'
path = require 'path'
dialog = require 'commander'
_ = require 'underscore'
wrench = require 'wrench'

log = require './logger'
maxmertkit = require './maxmertkit'


if global.setImmediate?
	immediately = global.setImmediate


# **Initializing**
# theme.json file with main info about project

exports.init = ( options ) ->

	fileName = 'theme.json'

	async.series

		modifier: ( callback ) =>

			request
				.get( "#{pack.homepage}/api/0.1/defaults/theme" )
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
			log.error "An error while initialized modifier."
			process.stdin.destroy()

		else
			process.stdin.destroy()





# **Publish**
# current version of theme.

exports.publish = ( options ) ->

	mjson = maxmertkit.json()

	fileName = 'theme.json'

	async.series

		theme: ( callback ) =>
			
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
				.post( "#{pack.homepage}/api/0.1/themes/#{mjson.name}/#{mjson.version}" )
				.set( 'X-Requested-With', 'XMLHttpRequest' )
				.send
					theme: res.theme
					password: res.password
					name: mjson.name
					version: mjson.version
					username: mjson.author
				
				.end ( res ) ->
					
					if res.ok
						log.requestSuccess "theme #{mjson.name}@#{mjson.version} successfully published."
						process.stdin.destroy()

					else
						log.requestError res.body.msg, 'ERRR', res.status
						process.stdin.destroy()






# **Unpublish**
# current version of theme.

exports.unpublish = ( options ) ->

	mjson = maxmertkit.json()

	async.series

		password: ( callback ) =>
			
			dialog.password '\nEnter your password: ', ( password ) ->
				callback null, password

	, ( err, res ) =>

		if err?
			log.error "Unpublishing canceled."
			process.stdin.destroy()

		else
			
			request
				.del( "#{pack.homepage}/api/0.1/themes/#{mjson.name}/#{mjson.version}" )
				.set( 'X-Requested-With', 'XMLHttpRequest' )
				.send
					password: res.password
					name: mjson.name
					version: mjson.version
					username: mjson.author
				
				.end ( res ) ->
					
					if res.ok
						log.requestSuccess "theme #{mjson.name}@#{mjson.version} successfully unpublished."
						process.stdin.destroy()

					else
						log.requestError res.body.msg, 'ERRR', res.status
						process.stdin.destroy()








objectLength = ( obj ) ->
    length = 0
    for key of obj
        if obj.hasOwnProperty key then length++
    
    length








# **Install**
# theme dependences.

exports.install = ( pth, list, depent = null ) ->
	
	wrench.mkdirSyncRecursive pth, 0o0777

	fileName = path.join(pth,"_index.sass")

	fs.writeFileSync fileName, ''


	result = null
	ok = objectLength(list) - 1

	arr = []
	_.each list, ( version, name ) ->
		arr.push
			name: name
			version: version

	# console.log arr
	result = ''

	async.reduce arr, null, ( result, theme, callback ) ->
		
		((result, theme, callback) ->
			
			request
				.get( "#{pack.homepage}/api/0.1/themes/#{theme.name}/#{theme.version}" )
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
		)( result, theme, callback )

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
					if nme is 'theme'
						str += "$#{nme}s: #{value}\n"
					else
						str += "$#{nme}: #{value}\n"


				sass fileName, str, ( err, res ) ->

					if err?
						log.error "Couldn\'t write file #{fileName}"

					else

						if depent?

							fs.appendFile path.join(pth,'../../_imports.sass'), "@import 'dependences/themes/_index.sass'\n", ( err ) ->
								
								if err?
									log.error "Couldn\'t append import of #{fileName} to the file _imports.sass"

								else
									log.success "all themes successfully installed."

						else
							log.success "all themes successfully installed."






















# Function with json write.

write = ( file, data, callback ) ->

	fs.writeFile file, data, ( err ) ->

		if err
			log.error "initializing – #{err}."
			callback err, null

		else
		
			log.success "file #{file} successfully created."
			callback null, data



# Write sass file

sass = ( fileName, data, callback ) ->

	fs.writeFile fileName, data, ( err ) ->

		if err?
			callback err, null

		else
			callback null, fileName