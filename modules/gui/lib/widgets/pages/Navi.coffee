
module.exports =
    
    class NaviContext extends floyd.gui.ViewContext
        
        configure: (config)->
        
            super new floyd.Config
                
                data:
                    items: {}
                
                template: ->
                    nav class:'gui widgets pages Navi floyd-loading'
                
                ##        
                content: ->
                    path = location.pathname
                    
                    bullets = @data.bullets
                    
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
                                        
                                        if bullets && depth <= (bullets.depth||0)
                                            span class: 'bullet', ->
                                                if bullets.type is 'numbers'
                                                    text if _i < 10 then '0'+(_i++) else _i++
                                                    text ' | '    
                                                else if bullets.type is 'letters'
                                                    text String.fromCharCode 97 + _i++                                                                                
                                                    text ' | '
                                                     
                                        span class: 'text', (item.text || item)
                                                                        
                                    if item.items && active
                                        list item.items, depth + 1
                                
                    ##                            
                    if typeof (_items=@data.items) is 'function'
                        _items (err, items)=>
                            list items
                    
                    else
                        list _items 

            
            , config
        
            
            