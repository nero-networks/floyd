module.exports =

    class ComboBox extends floyd.gui.ViewContext
        
        ##
        ##
        ##
        configure: (config)->
            super new floyd.Config

                template: ->
                    div class:'ComboBox floyd-loading'
                
                
                content: ->
                    
                    input type:@data.type, name:@data.name
                    
                    button class:'icon '+@data.dropdown.button, title: @data.text, ->
                        span @data.text
                    
                    div class:'dropdown '+@data.dropdown.class+' floyd-loading', style:'display:none'
                    
                    
                data:
                    
                    type: 'text'
                    
                    name: 'value'
                                        
                    dropdown:
                        button: 'select'
                        class: 'right down'
                    
                    text: 'Auswahl'
                                        
                dropdown:
                    
                    type: 'gui.widgets.List'

                    data:
                        selector: 'div.dropdown'
                    
                    _loadData: (offset, limit, fn)-> 
                        @parent._loadData (err, _items)=>
                            if floyd.tools.objects.isArray _items
                                items = _items
                                
                            else
                                items = []
                                for key, value of _items
                                    items.push
                                        class: key
                                        text: (value.text || value)
                            
                            fn null, items
            
            , config
            
            
            
                
        ##
        ##
        ##
        start: (done)->
            super (err)=>
                return done(err) if err
                                
                @_input = @find '[name='+@data.name+']'
                
                dropdown = @find '.dropdown'
                
                dropdown.find('li').click (e)=>
                    li = $(e.currentTarget)
                    
                    if cls=li.attr('class')
                        @_setAction cls.split(' ').pop(), li.text()
                    
                    else
                        @_setAction li.text(), li.text()
                    
                    dropdown.hide()
                    return false
                
                @find('.'+@data.dropdown.button).click (e)=>
                    $('.dropdown').not(dropdown).fadeOut();
                    
                    dropdown.toggle()
                    
                    return false
                
                $(document).click ()=> 
                    dropdown.fadeOut();
                
                ##
                done()
        
        ##
        ##
        ##
        _loadData: (fn)->
            
            fn null, @data.items
            
        ##
        ##
        ##
        _setAction: (@_action, @_value)->
        
            @_input.focus().val @_value
            
            @_emit 'change',
                name: @data.name
                action: @_action
                value: @_value
            
            
            