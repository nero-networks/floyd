
module.exports =
	
	class NaviContext extends floyd.gui.ViewContext
		
		configure: (config)->
		
			super new floyd.Config
				
				data:
					items: {}
				
				##		
				content: ->
					path = location.pathname
					
					list = (items, depth=0)->
						_i=0
						
						ul class:('depth'+depth), ->
						
							for href, item of items
							
								li ->
									attribs = 
										href: href
									
									_href = if href is '/' then '/home/' else href
									if path.substr(0, _href.length) is _href
										active = true
										attribs.class = 'active'
										
									else
										active = false
									
									a attribs, ->
										
										if !depth
											span class: 'bullet', ->
												text if _i < 10 then '0'+(_i++) else _i++
												text ' | '
																						
										span class: 'text', (item.text || item)
																		
									if item.items && active
										list item.items, depth + 1
								
					##							
					
					list @data.items

			
			, config
		
			
			