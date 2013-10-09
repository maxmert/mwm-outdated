pack = require '../package.json'

fs = require 'fs'
path = require 'path'

log = require './logger'


exports.directory = () ->
	
	if fs.existsSync(".mwmc")
		conf = JSON.parse( fs.readFileSync ".mwmc", encoding: 'utf8' )
		if conf.directory? then conf.directory else '.'
	else
		'.'