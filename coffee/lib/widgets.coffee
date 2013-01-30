exports.getList = (args...) ->
	list = []
	
	
	for arg in args
		# console.log typeof arg is 'object' and arg.length > 0
		switch typeof arg
			
			when 'string'
				list.push arg

			when 'object'
				if arg.length > 0
					for item in arg
						if typeof item is 'string'
							list.push item

	list

	


	
