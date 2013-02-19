pack = require '../package.json'

fs = require 'fs'
path = require 'path'

log = require './logger'


exports.json = ( pth ) ->
	
	if not pth?
		pth = path.join( '.', pack.maxmertkit )

	rawjson = fs.readFileSync pth
	
	if not rawjson?
		log.error("couldn\'t read #{pack.maxmertkit} file.")
		process.stdin.destroy()

	else
		json = JSON.parse rawjson