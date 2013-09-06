pack = require '../package.json'

async = require 'async'
request = require 'superagent'
fs = require 'fs'
path = require 'path'
dialog = require 'commander'
wrench = require 'wrench'

log = require './logger'
maxmertkit = require './maxmertkit'



# **Initializing**
# modifyer.json file with main info about project

exports.init = ( options ) ->

	fileName = 'modifyer.json'

	async.series

		modifyer: ( callback ) =>

			request
				.get( "#{pack.homepage}/api/0.1/defaults/modifyer" )
				.set( 'X-Requested-With', 'XMLHttpRequest' )
				.set('Accept', 'application/json')
				.end ( res ) =>

					if res.ok
						write fileName, res.body, callback

					else
						log.requestError res.body.msg, 'ERRR', res.status
						callback res.error, null


	, ( err, res ) =>

		if err?
			log.error "An error while initialized modifyer."
			process.stdin.destroy()

		else
			process.stdin.destroy()





# **Publish**
# current version of modifyer.

exports.publish = ( options ) ->

	mjson = maxmertkit.json()

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
				.post( "#{pack.homepage}/api/0.1/modifyers/#{mjson.name}/#{mjson.version}" )
				.set( 'X-Requested-With', 'XMLHttpRequest' )
				.send
					modifyer: res.modifyer
					password: res.password
					name: mjson.name
					version: mjson.version
					username: mjson.author
				
				.end ( res ) ->
					
					if res.ok
						log.requestSuccess "modifyer #{mjson.name}@#{mjson.version} successfully published."
						process.stdin.destroy()

					else
						log.requestError res.body.msg, 'ERRR', res.status
						process.stdin.destroy()






# **Unpublish**
# current version of modifyer.

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
				.del( "#{pack.homepage}/api/0.1/modifyers/#{mjson.name}/#{mjson.version}" )
				.set( 'X-Requested-With', 'XMLHttpRequest' )
				.send
					password: res.password
					name: mjson.name
					version: mjson.version
					username: mjson.author
				
				.end ( res ) ->
					
					if res.ok
						log.requestSuccess "modifyer #{mjson.name}@#{mjson.version} successfully unpublished."
						process.stdin.destroy()

					else
						log.requestError res.body.msg, 'ERRR', res.status
						process.stdin.destroy()







# **Install**
# modifyer dependences.

exports.install = ( pth, list ) ->

	wrench.mkdirSyncRecursive pth, 0o0777

	for name, version of list

		# Need a closure for correct info view
		do (name, version, pth) ->
			
			request
				.get( "#{pack.homepage}/api/0.1/modifyers/#{name}/#{version}" )
				.set( 'X-Requested-With', 'XMLHttpRequest' )
				
				.end ( res ) =>
					
					if res.ok

						str = "$mod-#{name}: #{res.body.class}"
						fileName = path.join(pth,"_#{name}.sass")
						
						sass fileName, str, ( err, res ) ->

							if err?
								log.error "Couldn\'t write file #{fileName}"

							else

								fs.appendFile path.join(pth,'../../_imports.sass'), "@import 'dependences/modifyers/_#{name}.sass'\n", ( err ) ->
									if err?
										log.error "Couldn\'t append import of #{fileName} to the file _imports.sass"

									else
										log.requestSuccess "modifyer #{name}@#{version} successfully installed."

					else
						log.requestError res.body.msg, 'ERRR', res.status
						process.stdin.destroy()



























# Function with json write.

write = ( file, json, callback ) ->

	fs.writeFile file, JSON.stringify(json, null, 4), ( err ) ->

		if err
			log.error "initializing – #{err}."
			callback err, null

		else
		
			log.success "file #{file} successfully created."
			callback null, json



# Write sass file

sass = ( fileName, data, callback ) ->

	fs.writeFile fileName, data, ( err ) ->

		if err?
			callback err, null

		else
			callback null, fileName

