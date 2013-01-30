`#!/usr/bin/env node`


# Dependences
pack = require './package.json'
widgets = require './lib/widgets'
program = require('nomnom').colors()
async = require 'async'
log = require './lib/logger'



program
	.command('install')

	.option 'widgets'
		position: 1
		help: 'names of widgets to install'
		list: on
	.option 'silent'
		abbr: 's'
		default: off
		flag: yes
		help: 'no log output during installation'
	
	.callback (options) ->
		
		widgetList = []
		for widget in options.widgets
			widgetList.push
				name: widget
				options: options


		async.every widgetList, widgets.isExist, (res) ->
			if res is true
				async.forEachSeries widgetList, widgets.install, (res) ->

			else
				console.log "Some of the widgets do not exist at #{pack.homepage}. Installation aborted!"
	
	.help 'Installing widgets to maxmertkit css framework.'





program
	.command('init')

	# .option 'theme'
	# 	abbr: 't'
	# 	flag: yes
	# 	default: off
	# 	help: 'init new theme if flag is active'

	.callback (options) ->

		widgets.init options


	.help 'Initializing new widget or theme in current directory'





program.parse()