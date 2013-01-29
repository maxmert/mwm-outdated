`#!/usr/bin/env node`


# Dependences
pack = require '../package.json'
program = require 'commander'
request = require 'superagent'
async = require 'async'

# Colors
colorName = `'\033[37m\033[40m'`
colorTypeHttp = `'\033[32m\033[40m'`
colorTypeError = `'\033[31m\033[40m'`
colorWidgetName = `'\033[34m'`
colorReset = `'\033[0m\033[0m'`

program
	.version( pack.version )



# Install command
program
	.command( 'install [names]' )
	.description( 'Install widgets with names' )
	.option( '-s, --silent', 'Be quite while installing' )
	.action (name) ->
		
		# Set all packages to the program.args
		program.args.unshift name
		
		console.log "#{colorName}mwm#{colorReset} Checking for availability: #{colorWidgetName}%s#{colorReset}", program.args

		isExist = ( name ) ->
			request
				.get( "http://maxmertkit.com/widgets/#{name}" )
				.set('Accept', 'application/json')
				.end (res) ->
					if res.statusCode is 502 or 404
						console.log "#{colorName}mwm#{colorReset} #{colorTypeError}ERR#{colorReset} #{colorWidgetName}%s#{colorReset} widget not found.", name

		
		async.every program.args, isExist, (res) ->
			console.log res
		
			
			



program.parse process.argv
	