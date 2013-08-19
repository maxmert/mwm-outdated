module.exports = (grunt) ->
	grunt.loadNpmTasks 'grunt-jstemplater'
	grunt.loadNpmTasks 'grunt-contrib-watch'
	grunt.loadNpmTasks 'grunt-coffeelint'
	grunt.loadNpmTasks 'grunt-contrib-coffee'

	grunt.loadNpmTasks 'grunt-docco'

	grunt.initConfig
		pkg: grunt.file.readJSON 'package.json'
		
		coffeelint:
			tests:
				files:
					src: ['coffee/**/*.coffee']
				options:
					'no_trailing_whitespace':
						'level': 'warn'
					'camel_case_classes':
						'level': 'warn'
					'no_tabs':
						'level': 'ignore'
					'indentation':
						'level': 'ignore'
					'max_line_length':
						'level': 'ignore'
					'no_backticks':
						'level': 'ignore'
		coffee:
			global:
				options:
					bare: yes
				expand: true
				cwd: 'coffee'
				src: ['**/!(Gruntfile)*.coffee']
				dest: '.'
				ext: '.js'

		template:
			prod:
				src: 'templates/**/*.mustache'
				dest: 'templates.json'
				variables:
					name: 'TEMPLATES'
					staticPath: 'templates'

		docco:
			docs:
				src: ['coffee/public/js/**/*.coffee']
				options:
					output: 'docs/'




		watch:
			coffee:
				files: [ 'coffee/**/*.coffee' ]
				tasks: [ 'coffeelint', 'coffee:global', 'docco' ]

			docco:
				files: [ '<%= docco.docs.src %>' ]
				tasks: [ 'docco' ]

			template:
				files: [ '<%= template.prod.src %>' ]
				tasks: [ 'template' ]