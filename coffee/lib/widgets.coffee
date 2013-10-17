pack = require '../package.json'
templates = require '../templates.json'

config = require './config'
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
modifiers = require './modifiers'


if global.setImmediate?
	immediately = global.setImmediate


# **Initializing**
# widget

exports.init = ( options ) ->

	fileName = path.join config.directory(), '_index.sass'
	paramsFileName = path.join config.directory(), '_params.sass'
	varsFileName = path.join config.directory(), '_vars.sass'
	myvarsFileName = path.join config.directory(), '_myvars.sass'
	mjson = maxmertkit.json()

	async.series

		paths: (callback) =>
			write path.join(config.directory(), '_paths.sass'), "// Generated with mwm – maxmertkit widget manager\n", callback

		imports: ( callback ) =>
			write path.join(config.directory(), '_imports.sass'), "// Generated with mwm – maxmertkit widget manager\n", callback

		params: ( callback ) =>
			write paramsFileName, mustache.render( templates.params, mjson ), callback

		vars: ( callback ) =>
			write varsFileName, "", callback

		myvars: ( callback ) =>
			write myvarsFileName, "$#{mjson.name}: -#{mjson.name}", callback

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
		
		checkFields: ( callback ) =>
			if not mjson.themeUse?
				callback "Set themeUse option and then publish"

			else if not mjson.name?
				callback "Set name option and then publish"
			else if not mjson.version?
				callback "Set version option and then publish"
			else if not mjson.tags?
				callback "Set tags option and then publish"
			else
				callback null, yes

		widget: ( callback ) =>
			
			archives.pack config.directory(), callback


		password: ( callback ) =>
			dialog.password '\nEnter your password: ', ( password ) ->
				callback null, password

		readme: ( callback ) =>
			# Read README.md
			readme = ''
			readmeHTML = ''
			# titleImage = ''
			fs.exists path.join(config.directory(), 'README.md'), ( exist ) =>
				if exist
					readme = fs.readFileSync path.join(config.directory(), 'README.md'), "utf8"
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

		test: ( callback ) =>
			testHTML = ''
			fs.exists path.join(config.directory(), 'test.html'), ( exist ) =>
				if exist
					testHTML = fs.readFileSync path.join('.', 'test.html'), "utf8"
					jsdom.env
						html: testHTML
						scripts: ["http://code.jquery.com/jquery-1.5.min.js"]
						done: (err, window) =>
							$ = window.jQuery

							if $(testHTML)? and $(testHTML).find('body')
								testHTMLresult = $(testHTML).find('body').html()
							else
								testHTMLresult = ''
							
							callback null, testHTMLresult
				else
					callback null, testHTML


		testCSS: ( callback ) =>
			testCSS = ''
			fs.exists path.join(config.directory(), 'index.css'), ( exist ) =>
				if exist
					testCSS = fs.readFileSync path.join(config.directory(), 'index.css'), "utf8"
					callback null, testCSS
				else
					callback null, testCSS


				

	, ( err, res ) =>
		if err?
			log.error "Publishing canceled. #{err}"
			process.stdin.destroy()

		else
			
			if not mjson.repository? and not mjson.site? and not res.test? and not res.readme? and not res.readme.readme?
				log.error "Yout dont have any repository, widget site, test file or readme file. Other users will not understand how to use it."
				process.stdin.destroy()

			else

				packFile = path.join config.directory(), "#{mjson.name}@#{mjson.version}.tar"


				if JSON.stringify(mjson.dependences)? then deps = JSON.stringify(mjson.dependences) else deps = ''
				if JSON.stringify(mjson.modifiers)? then mods = JSON.stringify(mjson.modifiers) else mods = ''
				if JSON.stringify(mjson.themes)? then thms = JSON.stringify(mjson.themes) else thms = ''
				if JSON.stringify(mjson.animations)? then anims = JSON.stringify(mjson.animations) else anims = ''
				
				# Check data for existance
				ok = yes
				
				if not mjson.tags?
					log.error "You didn\'t set tags in maxmertkit.json. Publishing canceled."
					process.stdin.destroy()
					ok = no
				if not mjson.titleImage?
					mjson.titleImage = ''
				if not mjson.repository?
					mjson.repository = ''
				if not mjson.site?
					mjson.site = ''
				if not mjson.themeUse? or not mjson.themeUse
					mjson.themeUse = 'false'
				else
					mjson.themeUse = 'true'

				if ok
					request
						.post( "#{pack.homepage}/api/0.1/widgets/#{mjson.name}/#{mjson.version}" )
						.set( 'X-Requested-With', 'XMLHttpRequest' )
						
						.attach( 'pack', packFile )
						.field( 'packName', path.basename( packFile ) )
						# .field( 'titleImage', mjson.titleImage )
						.field( 'password', res.password )
						.field( 'name', mjson.name )
						.field( 'version', mjson.version )
						.field( 'description', mjson.description )
						.field( 'repository', mjson.repository )
						.field( 'site', mjson.site )
						.field( 'license', mjson.license )
						.field( 'tags', mjson.tags )
						.field( 'themeUse', mjson.themeUse )
						.field( 'username', mjson.author )
						.field( 'test', res.test )
						.field( 'testCSS', res.testCSS )
						.field( 'dependences', deps )
						.field( 'modifiers', mods )
						.field( 'themes', thms )
						.field( 'animations', anims )
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
			dialog.password '\nEnter your password: ', ( password ) ->
				callback null, password

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
				.get( "#{pack.homepage}/api/0.1/widgets/#{widget.name}/#{widget.version}/exist" )
				.set( 'X-Requested-With', 'XMLHttpRequest' )
				.end ( res ) =>

					if res.ok and res.body.exist
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

									if path.dirname(path.join(pth, widget.name, '_myvars.sass')) isnt '.'
										fs.readFile path.join(pth, widget.name, '_myvars.sass'),( err, data ) ->
											if not err?
												widgetPath = path.join(pth, widget.name)
												fs.appendFile path.join(config.directory(),'_paths.sass'), "$#{widget.name}-path: '#{widgetPath}'\n", ( err ) ->
												fs.appendFile path.join(config.directory(),'_vars.sass'), "\n#{data}\n", ( err ) ->


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


	# 												if widget.modifiers?
	# 													modifiers.install path.join( pth, widget.name, 'dependences/modifiers' ), widget.modifiers

						

					else
						log.requestError res.body.msg, 'ERRR', res.status						
						if not callback? or typeof callback is 'object' then process.stdin.destroy() else callback yes, widget.name


	, ( err ) ->
		if err?
			log.error "An error while installing widgets: #{err}"
			process.stdin.destroy()