pack = require '../package.json'

async = require 'async'
request = require 'superagent'
fs = require 'fs'
path = require 'path'
dialog = require 'commander'

log = require './logger'
maxmertkit = require './maxmertkit'



# **Initializing**
# maxmertkit.json file with main info about project

exports.init = ( options ) ->

	fileName = 'modifyer.json'

	async.series

		modifyer: ( callback ) =>

			request
				.get( "#{pack.homepage}/defaults/modifyer" )
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
				.post( "#{pack.homepage}/modifyers/#{mjson.name}/#{mjson.version}" )
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





exports.install = ( pth, list ) ->

	for name, version of list

		# Need a closure for correct info view
		do (name, version, pth) ->
			
			request
				.get( "#{pack.homepage}/modifyers/#{name}/#{version}" )
				.set( 'X-Requested-With', 'XMLHttpRequest' )
				
				.end ( res ) =>
					
					if res.ok

						str = "$mod-#{name}: #{res.body.class}"
						fileName = path.join(pth,"_#{name}.sass")
						
						sass fileName, str, ( err, res ) ->

							if err?
								log.error "Couldn\'t write file #{fileName}"

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



sass = ( fileName, data, callback ) ->

	fs.writeFile fileName, data, ( err ) ->

		if err?
			callback err, null

		else
			callback null, fileName

