`#!/usr/bin/env node`


# Dependences
pack = require './package.json'
path = require 'path'
widgets = require './lib/widgets'
program = require('nomnom').colors()
log = require './lib/logger'
fs = require 'fs'


program
	.command('init')

	.callback (options) ->

		widgets.init options


	.help 'Initializing new widget or theme in the current directory.'



program
	.command('pack')

	.callback (options) ->

		widgets.pack options


	.help 'Create .zip file in current folder.'



program
	.command('unpack')

	.callback (options) ->

		widgets.unpack null, options


	.help 'Unpack .zip file in current folder.'



program
	.command('check')

	.callback (options) ->

		widgets.onServerIsExists options


	.help 'Check if package with that name already exists.'



# ==============================
# ============================== SERVER FEATURES
# ==============================


program
	.command('exist')

	.callback (options) ->

		widgets.onServerIsExistsVersion null, options


	.help 'Check if widget or theme with name specified in maxmertkit.json is exist on the server.'






program
	.command('publish')

	.callback (options) ->

		widgets.onServerPublish null, options


	.help 'Publish current version of widget or theme.'
	








# program
# 	.command('install')

# 	.option 'widgets'
# 		position: 1
# 		help: 'names of widgets to install'
# 		list: on
# 	.option 'silent'
# 		abbr: 's'
# 		default: off
# 		flag: yes
# 		help: 'no log output during installation'
	
# 	.callback (options) ->
		
# 		if options.widgets? and options.widgets.length > 0
# 		# if we have widget names DONT USE maxmertkit.json

# 			widgetList = []
# 			for widget in options.widgets
# 				widgetList.push
# 					name: widget
# 					options: options


# 			async.every widgetList, widgets.isExist, (res) ->
# 				if res is true
# 					async.forEachSeries widgetList, widgets.install, (res) ->

# 				else
# 					console.log "Some of the widgets do not exist at #{pack.homepage}. Installation aborted!"


		
# 		else
# 		# if we dont have widget names, use maxmertkit.json for dependences

# 			widgets.installJSON()

	
# 	.help 'Installing widgets to maxmertkit css framework.'





# program
# 	.command('init')

# 	.callback (options) ->

# 		widgets.init options


# 	.help 'Initializing new widget or theme in current directory'



# program
# 	.command('pack')

# 	.callback (options) ->

# 		widgets.pack options


# 	.help 'Create .tar file'



# program
# 	.command('publish')

# 	.callback (options) ->
# 		fs.readFile 'maxmertkit.json', (err, data) ->
# 			maxmertkitjson = JSON.parse(data)
			
# 			if err
# 				log.error("You don\'t have maxmertkit.json file.")
# 			else
# 				widgets.publish maxmertkitjson.author


# 	.help 'Publish your widget to mwm-site'
	





program.parse()