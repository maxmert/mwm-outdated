`#!/usr/bin/env node`


# Dependences
pack = require './package.json'
path = require 'path'
common = require './lib/common'
program = require('nomnom').colors()
log = require './lib/logger'
fs = require 'fs'



program
	.command('init')

	.option 'theme'
		abbr: 't'
		help: 'Initialize a new theme in the current directory.'
		flag: yes

	.option 'modifyer'
		abbr: 'm'
		help: 'Initialize a new modifyer in the current directory.'
		flag: yes

	.callback (options) ->

		common.init options


	.help 'Initializing new widget/modifyer/theme in the current directory.'




program
	.command('publish')

	.callback (options) ->

		common.publish options

	.help 'Publishing current version of widget/modifyer/theme.'




program
	.command('install')

	.callback (options) ->

		common.install options

	.help 'Installing all dependences, themes and modifyers.'






program.parse()