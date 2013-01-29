`#!/usr/bin/env node`


# Dependences
pack = require '../package.json'
program = require 'commander'
request = require 'superagent'
async = require 'async'
log = require 'cli-color'

logName = log.xterm(255).bgXterm(0)
logTypeError = log.xterm(196).bgXterm(0)
logTypeSuccess = log.xterm(34).bgXterm(0)
logStatusError = log.xterm(196)
logStatusSuccess = log.xterm(34)
logWidgetName = log.xterm(61)

#URL
URL = 'http://localhost:3000'

colorName = `'\033[37m\033[40m'`
colorStatus = `'\033[32m'`
colorStatusError = `'\033[31m'`
colorTypeHttp = `'\033[32m\033[40m'`
colorTypeError = `'\033[31m\033[40m'`
colorWidgetName = `'\033[34m'`
colorReset = `'\033[0m\033[0m'`

program
	.version( pack.version )
	.command( 'install [widgets]', 'Install widgets')
	.parse process.argv
	# .action (name) ->
	# 	console.log program.options
	# 	# Set all packages to the program.args
	# 	program.args.unshift name

	# 	# Check if widget exists and install it if it does
	# 	isExist = ( name ) ->
	# 		request
	# 			.get( "#{URL}/widgets/#{name}" )
	# 			.set('Accept', 'application/json')
	# 			.end (res) ->
	# 				if res.statusCode is 502 or res.statusCode is 404
	# 					console.log "#{logName('mwm')} #{logTypeError('ERR')} #{logStatusError(res.statusCode)} #{logWidgetName(name)} not found."
						
	# 				else
	# 					console.log "#{logName('mwm')} #{logTypeSuccess('http')} #{logStatusSuccess(res.statusCode)} #{logWidgetName(name)} – #{URL}/widgets/#{name}"
						

		
	# 	async.every program.args, isExist, (res) ->
	# 		console.log 123