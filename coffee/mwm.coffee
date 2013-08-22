`#!/usr/bin/env node`

# Dependences
# ------------------------------------------
pack = require './package.json'
path = require 'path'
common = require './lib/common'
archives = require './lib/archives'
program = require('nomnom').colors()
log = require './lib/logger'
fs = require 'fs'




# Program
# ------------------------------------------
program
	.command('init')

	.option 'widget',
		abbr: 'w'
		help: 'Initialize a new widget in the current directory.'
		flag: yes

	.option 'theme',
		abbr: 't'
		help: 'Initialize a new theme in the current directory.'
		flag: yes

	.option 'modifyer',
		abbr: 'm'
		help: 'Initialize a new modifyer in the current directory.'
		flag: yes

	.option 'animation',
		abbr: 'a'
		help: 'Initialize a new animation in the current directory.'
		flag: yes

	.callback (options) ->

		common.init options


	.help 'Initializing new project/widget/modifyer/theme/animation in the current directory.'




program
	.command('publish')

	.callback (options) ->

		common.publish options

	.help 'Publishing current version of widget/modifyer/theme/animation.'




program
	.command('unpublish')

	.callback (options) ->

		common.unpublish options

	.help 'Unpublishing current version of widget/modifyer/theme/animation.'




program
	.command('install')

	.callback (options) ->

		common.install options

	.help 'Installing all dependences, themes, modifyers and animations.'




program
	.command('pack')

	.callback (options) ->

		archives.pack '.', null

	.help 'Pack current version of widget/modifyer/theme/animation to a tar file.'






program.parse()