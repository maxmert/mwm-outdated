pack = require '../package.json'
templates = require '../templates.json'

async = require 'async'
request = require 'superagent'
fs = require 'fs'
path = require 'path'
dialog = require 'commander'
_ = require 'underscore'
mustache = require 'mustache'
md = require('markdown').markdown
jsdom = require 'jsdom'

log = require './logger'
archives = require './archives'
maxmertkit = require './maxmertkit'
themes = require './themes'
modifyers = require './modifyers'


if global.setImmediate?
	immediately = global.setImmediate


# **Initializing**
# widget

exports.init = ( options ) ->

	fileName = '_index.sass'
	paramsFileName = '_params.sass'
	varsFileName = '_vars.sass'
	myvarsFileName = '_myvars.sass'
	mjson = maxmertkit.json()

	async.series

		imports: ( callback ) =>
			write '_imports.sass', "// Generated with mwm – maxmertkit widget manager\n", callback

		params: ( callback ) =>
			write paramsFileName, mustache.render( templates.params, mjson ), callback

		vars: ( callback ) =>
			write varsFileName, "", callback

		myvars: ( callback ) =>
			write myvarsFileName, "", callback

		index: ( callback ) =>
			write fileName, mustache.render( templates.widget, mjson ), callback

	, ( err, res ) =>

		if err?
			log.error "An error while initialized widget."
			process.stdin.destroy()

		else
			process.stdin.destroy()






# **Publish**
# current version of the widget.

exports.publish = ( options ) ->
	
	mjson = maxmertkit.json()

	async.series

		widget: ( callback ) =>
			
			archives.pack '.', callback


		password: ( callback ) =>
			callback null, 'linolium'
			# dialog.password '\nEnter your password: ', ( password ) ->
			# 	callback null, password

		readme: ( callback ) =>
			# Read README.md
			readme = ''
			readmeHTML = ''
			# titleImage = ''
			fs.exists path.join('.', 'README.md'), ( exist ) =>
				if exist
					readme = fs.readFileSync path.join('.', 'README.md'), "utf8"
					readmeHTML = md.toHTML readme
					# jsdom.env
					# 	html: readmeHTML
					# 	scripts: ["http://code.jquery.com/jquery-1.5.min.js"]
					# 	done: (err, window) =>
					# 		$ = window.jQuery
					# 		titleImage = $(readmeHTML).find('img').attr 'src'
					# callback null,
					# 	readme: readme
					# 	readmeHTML: readmeHTML
						# titleImage: titleImage
				callback null,
					readme: readme
					readmeHTML: readmeHTML
					# titleImage: titleImage
				

	, ( err, res ) =>

		if err?
			log.error "Publishing canceled."
			process.stdin.destroy()

		else
			
			packFile = path.join '.', "#{mjson.name}@#{mjson.version}.tar"


			if JSON.stringify(mjson.dependences)? then deps = JSON.stringify(mjson.dependences) else deps = ''
			if JSON.stringify(mjson.modifyers)? then mods = JSON.stringify(mjson.modifyers) else mods = ''
			if JSON.stringify(mjson.themes)? then thms = JSON.stringify(mjson.themes) else thms = ''
			
			# Check data for existance
			ok = yes
			
			if not mjson.tags?
				log.error "You didn\'t set tags in maxmertkit.json. Publishing canceled."
				process.stdin.destroy()
				ok = no


			if ok
				request
					.post( "#{pack.homepage}/api/0.1/widgets/#{mjson.name}/#{mjson.version}" )
					.set( 'X-Requested-With', 'XMLHttpRequest' )
					
					.attach( 'pack', packFile )
					.field( 'packName', path.basename( packFile ) )
					.field( 'titleImage', mjson.titleImage )
					.field( 'password', res.password )
					.field( 'name', mjson.name )
					.field( 'version', mjson.version )
					.field( 'description', mjson.description )
					.field( 'repository', mjson.repository )
					.field( 'license', mjson.license )
					.field( 'tags', mjson.tags )
					.field( 'username', mjson.author )
					.field( 'dependences', deps )
					.field( 'modifyers', mods )
					.field( 'themes', thms )
					.field( 'readme', res.readme.readme )
					.field( 'readmeHTML', res.readme.readmeHTML )
					
					.end ( res ) ->
						
						if res.ok
							log.requestSuccess "widget #{mjson.name}@#{mjson.version} successfully published."
							process.stdin.destroy()

						else
							log.requestError res.body.msg, 'ERRR', res.status
							process.stdin.destroy()

						fs.unlink packFile




# **Unpublish**
# current version of the widget.

exports.unpublish = ( options ) ->

	mjson = maxmertkit.json()

	fileName = "#{mjson.name}@#{mjson.version}.tar"

	async.series

		password: ( callback ) =>
			callback null, 'linolium'
			# dialog.password '\nEnter your password: ', ( password ) ->
			# 	callback null, password

	, ( err, res ) =>

		if err
			log.error "Could not unpublish widget."
			if not callback? or typeof callback is 'object' then process.stdin.destroy() else callback err, mjson.name

		else
			request
				.del( "#{pack.homepage}/api/0.1/widgets/#{mjson.name}/#{mjson.version}" )
				.set( 'X-Requested-With', 'XMLHttpRequest' )
				.field( 'packName', fileName)
				.field( 'name', mjson.name)
				.field( 'version', mjson.version)
				.field( 'password', res.password)
				.field( 'username', mjson.author )
				.end ( res ) ->
					if res.ok
						log.requestSuccess "widget #{mjson.name}@#{mjson.version} successfully unpublished."
						if not callback? or typeof callback is 'object' then process.stdin.destroy() else callback null, mjson.name

					else
						log.requestError res.body.msg, 'ERRR', res.status						
						if not callback? or typeof callback is 'object' then process.stdin.destroy() else callback yes, mjson.name






# **Install**
# widget dependences.
# exports.install = ( parentInstall, pth, dependences, themesGlobal, ifDepent ) ->



























# Function with json write.

write = ( file, data, callback ) ->

	fs.writeFile file, data, ( err ) ->

		if err
			log.error "initializing – #{err}."
			callback err, null

		else
		
			log.success "file #{file} successfully created."
			callback null, data







exports.install = ( pth, mjson, calll, depent, themesss ) ->
	# TODO: Two requests???
	# console.log mjson
	arr = []
	_.each mjson.dependences, ( ver, name ) ->
		arr.push
			name: name
			version: if ver.version? then ver.version else ver
			themes: if ver.themes? then ver.themes else mjson.themes
	# console.log arr
	async.eachSeries arr, ( widget, callback ) ->
		
		@calll = calll
		@depent = depent

		process.nextTick ( calll, depent, themesss ) =>
			# console.log widget.name, 'begin'
			fileName = "#{widget.name}@#{widget.version}.tar"
			
			req = request
				.get( "#{pack.homepage}/api/0.1/widgets/#{widget.name}/#{widget.version}" )
				.set( 'X-Requested-With', 'XMLHttpRequest' )
				.end ( res ) =>

					if res.ok

						req = request
							.get( "#{pack.homepage}/api/0.1/widgets/#{widget.name}/#{widget.version}" )
							.set( 'X-Requested-With', 'XMLHttpRequest' )

						stream = fs.createWriteStream( path.join(pth, fileName) )

						req.pipe stream

						stream.on 'close', =>
							
							archives.unpack path.join(pth, fileName), ( err ) =>
								
								if err?
									log.error "Couldn\'t unpack #{widget.name}@#{widget.version}.tar"
									callback yes, null
								
								else
									fs.unlink path.join(pth, fileName)

									
									if path.dirname(path.join(pth,'../../_myvars.sass')) isnt '.'
										fs.readFile path.join(pth,'../../_myvars.sass'),( err, data ) ->
											if not err?
												fs.appendFile '_vars.sass', "\n#{data}\n", ( err ) ->


									fs.readFile path.join(pth,'../../_imports.sass'), ( err, data ) =>
										if err?
											log.error "Coluld not read #{path.join(pth,'../../_imports.sass')}."
											process.stdin.destroy()

										else
											data = data + "@import 'dependences/widgets/#{widget.name}/_index.sass'\n"
											
											fs.writeFile path.join(pth,'../../_imports.sass'), data, ( err ) =>
												# console.log widget.name, 'inside'
												if err?
													callback yes, null

												else
													
													# if @depent
													# 	depent = yes
													
													# if widget.themes?
													# 	depent = yes

													fs.writeFileSync path.join(pth, widget.name, '_params.sass'), "$dependent: #{depent}\n"
													# console.log depent, widget.themes?, themesss?
													
													if widget.themes?
														if themesss?
															themesss = _.extend(widget.themes, themesss)
														else
															themesss = widget.themes
														# depent = yes

													@calll path.join(pth, widget.name), @depent, themesss
													callback()
													
													# if themesss?
														# themes.install path.join( pth, widget.name, 'dependences/themes' ), themesss, depent

	# 												if widget.themes?
	# 													themes.install path.join( pth, widget.name, 'dependences/themes' ), widget.themes, depent
	# # 												# else
													# if themesss?
													# 	themes.install path.join( pth, widget.name, 'dependences/themes' ), themesss, depent


	# 												if widget.modifyers?
	# 													modifyers.install path.join( pth, widget.name, 'dependences/modifyers' ), widget.modifyers

						

					else
						log.requestError res.body.msg, 'ERRR', res.status						
						if not callback? or typeof callback is 'object' then process.stdin.destroy() else callback yes, widget.name


	, ( err ) ->
		if err?
			log.error "An error while installing widgets: #{err}"
			process.stdin.destroy()