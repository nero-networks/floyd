
module.exports =
    
    class List extends floyd.gui.ViewContext
        
        ##
        ##
        ##
        configure: (config)->
            
            config = super new floyd.Config

                widget: ->
                    li ->
                        @text

                data:
                    items: []
                    limit: 5
                    offset: 0
                    listSelector: 'ul:first'
                    content: ->
                        ul()
                    
            , config
                
            if config.browse
            
                config.children.push new floyd.Config
                
                    id: 'browse'
                    type: 'musiknetz.views.widgets.ListBrowser'
                    
                    data:
                        selector: 'div.browse'
                
                , config.browse            
            
            @_widget = floyd.tools.gui.ck config.widget
            
            return config
        
        
        start: (done)->
        
            super (err)=>
                return done(err) if err

                if @children.browse
                    @children.browse.on 'browse', (e)=>
                        @_loadData e.offset, e.limit, (err, items, data)=>
                            return done(err) if err
                            @_display items, data
                    
                @_ul = @find @data.listSelector
                
                if !@_ul.children().length
                    @_reload done
                    
                else done()
                
                            
        _reload: (done)->
            @_loadData @data.offset, @data.limit, (err, items, data)=>
                return @logger.error(err) if err                        
                @_display.call @, items, data, done
                
            
            
        _loadData: (offset, limit, fn)->
            items = []

            if (_items = @data.items) 
                if limit > -1
                    _items = _items.slice offset, offset+limit
                else
                    _items = _items.slice offset
                    
                for image in _items
                    items.push floyd.tools.objects.clone image            
            
            fn null, items,
                offset: offset
                limit: limit
                size: @data.items.length
        
        
        ##
        ##
        ##
        _display: (items, data, fn)->
            if @data.key
                items = floyd.tools.objects.resolve @data.key, items, false
            
            @_ul.html ''
            @_items = items
            @_elements = []
            
            @_process items,
                
                each: (item, next)=>
                    @_item item, (err, html)=>
                        
                        if html
                            html = $ html
                            @_elements.push html
                            @_ul.append html
                        
                        next err
                            
                done: (err)=>
                    return fn(err) if err
                    
                    @_emit 'display',
                        items: items
                        data: data
                    
                    if @children.browse
                        @children.browse._display items, data, fn
                    
                    else fn?()
