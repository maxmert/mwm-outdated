`#!/usr/bin/env node`


# Dependences
pack = require './package.json'
request = require 'superagent'
async = require 'async'
path = require 'path'
log = require './lib/logger'
widgets = require './lib/widgets'
program = require('nomnom').colors()

#URL
URL = 'http://localhost:3000'


program
	.command('install')

	.option 'widgets'
		position: 1
		help: 'names to install'
		list: on
	.option 'silent'
		abbr: 's'
		default: off
		flag: yes
		help: 'tell nothing while installing'
	
	.callback (options) ->
		
		# Check if widget exists and install it if it does
		isExist = ( name ) ->
			request
				.get( "#{URL}/widgets/#{name}" )
				.set('Accept', 'application/json')
				.end (res) ->
					if res.statusCode is 502 or res.statusCode is 404
						log.error("#{URL}/widgets/#{name}", name) if not options.silent
						
					else
						log.success("#{URL}/widgets/#{name}", name) if not options.silent
						console.log path.dirname __dirname
						

		
		async.every options.widgets, isExist, (res) ->
			console.log 123
	
	.help 'Installing widgets to maxmertkit css framework.'


program.parse()


# program
# 	.version( pack.version )
# 	.option('-T, --no-tests', 'ignore test hook')

# program
# 	.command( 'install [widgets]' )
# 	.option("-s, --silent", "Do not tell anything while installing")
# 	.description( 'Install widgets' )
# 	.action (widgets, options) ->
# 		console.log widgets, options
		# Get all widget names
		# list = widgets.getList name, program.args

		
		# Check if widget exists and install it if it does
		# isExist = ( name ) ->
		# 	request
		# 		.get( "#{URL}/widgets/#{name}" )
		# 		.set('Accept', 'application/json')
		# 		.end (res) ->
		# 			if res.statusCode is 502 or res.statusCode is 404
		# 				log.error "#{URL}/widgets/#{name}", name
		# 				# console.log "#{logName('mwm')} #{logTypeError('ERRR')} #{logStatusError(res.statusCode)} #{logWidgetName(name)} – #{URL}/widgets/#{name}"
						
		# 			else
		# 				log.success "#{URL}/widgets/#{name}", name
		# 				# console.log "#{logName('mwm')} #{logTypeSuccess('http')} #{logStatusSuccess(res.statusCode)} #{logWidgetName(name)} – #{URL}/widgets/#{name}"
						

		
		# async.every list, isExist, (res) ->
		# 	console.log 123


# program.parse process.argv