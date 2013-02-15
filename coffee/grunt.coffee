module.exports = (grunt) ->
	grunt.loadNpmTasks 'grunt-jstemplater'

	grunt.initConfig
		pkg: grunt.file.readJSON 'package.json'
		meta:
			banner: '/*\n\n<%= pkg.name %> v<%= pkg.version %>\nhttp://double.fm\n\nIncludes jQuery.js\nhttp://jquery.com\n\nCopyright <%= grunt.template.today("yyyy") %> Double.fm\n\nDate: <%= grunt.template.today() %>\n\n*/'



		template:
			prod:
				src: 'templates/**/*.mustache'
				dest: 'templates.json'
				variables:
					name: 'TEMPLATES'
					staticPath: 'templates'
					nodejs: yes



		watch:
			prod:
				files: ['<config:template.prod.src>', 'grunt.js']
				tasks: 'template'


	grunt.registerTask 'default', 'template'